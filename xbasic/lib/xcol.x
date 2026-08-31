'
'
' ####################  Max Reason
' #####  PROLOG  #####  copyright 1988-2000
' ####################  Linux XBasic compiler
'
' subject to GPL license - see COPYING
'
' maxreason@maxreason.com
'
' for Linux XBasic
'
'
PROGRAM  "xcol"
VERSION  "6.4.5"        '64-bit version
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "elf32"
IMPORT  "kernel32"
IMPORT  "clib"
'
' #####  IMPORTANT  #####
'
' To run and debug this program in the XBasic development environment,
' you must first replace all occurences of "EXTERNAL /xxx/" with the upper-case
' equivalent, "EXTERNAL /XXX/" and when you rebuild a new XBasic executable, you must
' replace all occurences of "/XXX/" with the lower-case equivalent. (76 occurrences)
' Otherwise total disaster will strike!
'
' ##########################################################
'
' OBJECT contains all information about an object except parallel arrays
' symbol$[], string$[], label$[] hold symbol, literal, and label strings.
' OBJECT is defined below, but is unimplemented in the code so far !!!
'
TYPE OBJECT
	XLONG     .id             ' redundant object #
	XLONG     .alias          ' id # of master copy of object (master instance of shared objects)
	XLONG     .kind           ' variable, array, function, statement, operator...
	XLONG     .sharename      ' ditto
	XLONG     .section        ' code, data, bss...
	XLONG     .program        ' program number  (0 = system/environment)
	XLONG     .function       ' function number (0 = shared/external)
	XLONG     .register       ' allocation register or base register
	XLONG     .address        ' memory address or offset
	XLONG     .addressMode    ' addressing mode
	XLONG     .type           ' data type  (system defined or user defined)
	XLONG     .visibleType    ' data type specified by suffix  (a%, a#, a$)
	XLONG     .scope          ' scope  (AUTO, AUTOX, STATIC, SHARED, EXTERNAL)
	XLONG     .visibleScope   ' scope specified by prefix... #Shared, ##External
	XLONG     .hash           '  hash value  (sum of hash[char] for all char)
	XLONG     .hashRaw        ' hash value  (sum of all characters)
	XLONG     .xlongValue     ' SBYTE, UBYTE, SSHORT, USHORT, SLONG, ULONG, XLONG
	GIANT     .giantValue     ' GIANT
	SINGLE    .singleValue    ' SINGLE
	DOUBLE    .doubleValue    ' DOUBLE
	XLONG     .whomask        ' system/user  (keep system objects across programs)
	XLONG     .name4          ' 1st four characters in name (quick test)
	GIANT     .name8          ' 1st eight characters in name (quick test)
	XLONG     .flags          ' misc flags (declared, referenced, system, etc)
	XLONG     .res27
	XLONG     .res28
	XLONG     .res29

	XLONG     .res31
END TYPE
'
TYPE TOKIX
	UBYTE  .ndex      ' number of tokens / token index / etc
	UBYTE  .errno     ' compile error sequence number
	UBYTE  .byte2
	UBYTE  .bpexe     ' breakpoint and executions flags
END TYPE
'
TYPE TAKS
	UBYTE  .type      ' data type
	UBYTE  .allo      ' allocation of data objects
	UBYTE  .kind      ' kind of token
	SBYTE  .stsp      ' -tabs or spaces following token symbol
END TYPE
'
TYPE TOKEN
	UNION
		ULONG  .tindex  ' token index / symbols index / etc
		TOKIX  .ti
	END UNION
	UNION
		ULONG  .tproto
		TAKS   .tp
	END UNION
END TYPE
'
TYPE FUNCARG
' XLONG      .token
	TOKEN      .token
	XLONG      .varType
	XLONG      .argType
	SBYTE      .stack
	SBYTE      .byRef
	UBYTE      .kind
	UBYTE      .res
END TYPE
'
'
' OPCODE86: 80486 opcode
'
TYPE OPCODE86
	UBYTE     .nbytes   ' number of bytes in opcode
	UBYTE     .byte1    ' first byte
	UBYTE     .byte2    ' second byte
	UBYTE     .param    ' special (usually "reg" from mod-reg-rm) for assembling
	GOADDR    .optype   ' address in Code() to assemble opcode of this type
END TYPE
'
'
' ********************************
' *****  Compiler Functions  *****
' ********************************
'
DECLARE FUNCTION   Xnt                        ()
DECLARE FUNCTION   XxxXBasic                  ()
'
INTERNAL FUNCTION  TOKEN AddLabel             (label$, kind, type, action)
INTERNAL FUNCTION  TOKEN AddSymbol            (symbol$, spaces, kind, allo, type, f_number)
INTERNAL FUNCTION  AlloToken                  (TOKEN token)
INTERNAL FUNCTION  AssemblerSymbol            (symbol$)
INTERNAL FUNCTION  AssignAddress              (TOKEN token)
INTERNAL FUNCTION  AssignComposite            (dreg, dtype, sreg, stype)
INTERNAL FUNCTION  AtOps                      (xtype, opcode, mode, base, offset, sourceData)
INTERNAL FUNCTION  BinStringToAsmString$      (rawString$)
INTERNAL FUNCTION  CheckOneLine               ()
INTERNAL FUNCTION  CheckState                 (TOKEN token)
INTERNAL FUNCTION  CloneArrayTOKEN            (TOKEN dest[], TOKEN source[])
INTERNAL FUNCTION  Code                       (op, mode, dreg, GIANT gsreg, xreg, dtype, label$, remark$)
INTERNAL FUNCTION  CodeAbs8Byte               (immvalue)
INTERNAL FUNCTION  CodeLabelAbs               (label$, offset)
INTERNAL FUNCTION  CodeLabelDisp              (label$)
INTERNAL FUNCTION  Compile                    ()
INTERNAL FUNCTION  CompileFile                (file$)
INTERNAL FUNCTION  Component                  (com, TOKEN varToken, base, off, theType, TOKEN token, length)
INTERNAL FUNCTION  Composite                  (com, theType, TOKEN theReg, theOffset, theLength)
INTERNAL FUNCTION  Conv                       (rad, toType, ras, fromType)
INTERNAL FUNCTION  Deallocate                 (TOKEN token)
INTERNAL FUNCTION  Deparse$                   (prefix$)
INTERNAL FUNCTION  EmitAsm                    (@line$)
INTERNAL FUNCTION  EmitData                   ()
INTERNAL FUNCTION  EmitFunctionLabel          (funcName$)
INTERNAL FUNCTION  EmitLabel                  (labelName$)
INTERNAL FUNCTION  EmitLine                   (lineNum)
INTERNAL FUNCTION  EmitLocation               ()
INTERNAL FUNCTION  EmitNull                   (comment$)
INTERNAL FUNCTION  EmitString                 (theLabel$, theString$)
INTERNAL FUNCTION  EmitText                   ()
INTERNAL FUNCTION  EmitUserLabel              (TOKEN labelToken)
INTERNAL FUNCTION  TOKEN Eval                 (rtype)
INTERNAL FUNCTION  TOKEN EvalArg              (argNum, result_type)
INTERNAL FUNCTION  ExpressArray               (TOKEN oldOp, oldPrec, TOKEN newData, newType, accArray, excess, theType, sourceReg)
INTERNAL FUNCTION  Expresso                   (oldTest, TOKEN oldOp, oldPrec, TOKEN oldData, oldType)
INTERNAL FUNCTION  FloatLoad                  (dreg, stindex, stype)
INTERNAL FUNCTION  FloatStore                 (sreg, stindex, stype)
INTERNAL FUNCTION  FunctionCallPost           ()
INTERNAL FUNCTION  FunctionCallPrep           ()
INTERNAL FUNCTION  GenerateMakefile           ()
INTERNAL FUNCTION  GetAddrLabel64$            (branchAddr)
INTERNAL FUNCTION  GetArg                     (dreg, dtype, source)
INTERNAL FUNCTION  GetExternalAddresses_OLD   ()
INTERNAL FUNCTION  GetExternalAddresses       ()
INTERNAL FUNCTION  GetFuncaddrInfo            (TOKEN token, eleElements, TOKEN argInfo[], dataPtr)
INTERNAL FUNCTION  GetSubPath                 (sub$, file$, path$[])
INTERNAL FUNCTION  GetSymbol$                 (info)
INTERNAL FUNCTION  GetTokenOrAddress          (TOKEN token, style, TOKEN nextToken, dataType, nType, TOKEN base, offset, length)
INTERNAL FUNCTION  GetWords                   (srcTindex, gtype, w3, w2, w1, w0)
INTERNAL FUNCTION  InitArrays                 ()
INTERNAL FUNCTION  InitComplex                ()
INTERNAL FUNCTION  InitEntry                  ()
INTERNAL FUNCTION  InitErrors                 ()
INTERNAL FUNCTION  InitOptions                ()
INTERNAL FUNCTION  InitProgram                ()
INTERNAL FUNCTION  InitVariables              ()
INTERNAL FUNCTION  InvalidExternalSymbol      (symbol$)
INTERNAL FUNCTION  LastElement                (TOKEN token, lastPlace, excessComma)
INTERNAL FUNCTION  Literal                    (xx)
INTERNAL FUNCTION  LoadLitnum                 (dreg, dtype, sourceTindex, stype)
INTERNAL FUNCTION  TOKEN MakeToken            (keyword$, kind, allo, type)
INTERNAL FUNCTION  MinTypeFromDouble          (value#)
INTERNAL FUNCTION  MinTypeFromGiant           (value$$)
INTERNAL FUNCTION  Move                       (dest, dtype, source, stype)
INTERNAL FUNCTION  NextToken                  (TOKEN token)
INTERNAL FUNCTION  NullStringerCheck          (tindex)
INTERNAL FUNCTION  Op                         (rad, ras, TOKEN theOp, rax, dtype, stype, otype, xtype)
INTERNAL FUNCTION  OpenAccForType             (theType)
INTERNAL FUNCTION  OpenBothAccs               ()
INTERNAL FUNCTION  OpenOneAcc                 ()
INTERNAL FUNCTION  TOKEN ParseChar            ()
INTERNAL FUNCTION  ParseLine                  (TOKEN tok[])
INTERNAL FUNCTION  TOKEN ParseNumber          ()
INTERNAL FUNCTION  ParseOutError              (TOKEN token)
INTERNAL FUNCTION  ParseOutToken              (TOKEN token)
INTERNAL FUNCTION  TOKEN ParseSymbol          ()
INTERNAL FUNCTION  TOKEN ParseWhite           ()
INTERNAL FUNCTION  PassCfuncArg               (FUNCARG farg, argNum)
INTERNAL FUNCTION  PeekToken                  (TOKEN token)
INTERNAL FUNCTION  Pop                        (dreg, dtype)
INTERNAL FUNCTION  PrintError                 (errNumber)
INTERNAL FUNCTION  PrintTokens                ()
INTERNAL FUNCTION  TOKEN Printoid             ()
INTERNAL FUNCTION  Push                       (sreg, stype)
INTERNAL FUNCTION  PushXfuncArg               (FUNCARG arg)
INTERNAL FUNCTION  RangeCheck                 (ctype, symbol$)
INTERNAL FUNCTION  Reg                        (xx)
INTERNAL FUNCTION  RegOnly                    (xx)
INTERNAL FUNCTION  TOKEN ReturnValue          (rtype)
INTERNAL FUNCTION  ScopeToken                 (TOKEN token)
INTERNAL FUNCTION  SignHex$                   (GIANT value)
INTERNAL FUNCTION  Shuffle                    (oreg, areg, atype, ptype, argTindex, pkind, mode, argOffset)
INTERNAL FUNCTION  Shuffle_C                  (atype, ptype, argTindex, pkind, argNum, argOffset)
INTERNAL FUNCTION  StackIt                    (toType, theData, fromType, offset)
INTERNAL FUNCTION  StackOneArg                (tokenPos, argNum, argType, rparen)
INTERNAL FUNCTION  StatementExport            (TOKEN token)
INTERNAL FUNCTION  StatementImport            (TOKEN token)
INTERNAL FUNCTION  StatementProgram           (TOKEN token)
INTERNAL FUNCTION  StatementVersion           (TOKEN token)
INTERNAL FUNCTION  StripExtent                (filename$)
INTERNAL FUNCTION  StripNonSymbol             (name$)
INTERNAL FUNCTION  StripSuffix$               (symbol$)
INTERNAL FUNCTION  TOKEN TestForKeyword       (symbol$)
INTERNAL FUNCTION  TheType                    (TOKEN token)
INTERNAL FUNCTION  TOKEN Tok                  (symbol$, space, kind, allo, type, raddr, value, value$)
INTERNAL FUNCTION  TokenMatch                 (TOKEN token1, TOKEN token2)
INTERNAL FUNCTION  TokenRestOfLine            ()
INTERNAL FUNCTION  TokensDefined              ()
INTERNAL FUNCTION  Top                        ()
INTERNAL FUNCTION  Topaccs                    (topa, topb)
INTERNAL FUNCTION  Topax1                     ()
INTERNAL FUNCTION  Topax2                     (topa, topb)
INTERNAL FUNCTION  Topx                       (tr, trx, nr, nrx)
INTERNAL FUNCTION  TypenameToken              (TOKEN token)
INTERNAL FUNCTION  TypeToken                  (TOKEN token)
INTERNAL FUNCTION  Uop                        (rad, TOKEN theOp, rax, dtype, otype, xtype)
INTERNAL FUNCTION  UpdateToken                (TOKEN token)
INTERNAL FUNCTION  Value                      (label$, addrmode)
INTERNAL FUNCTION  WriteDeclarationFile       (string$)
INTERNAL FUNCTION  WriteDefinitionFile        (string$)
INTERNAL FUNCTION  XcowlErr                   (id)
'
DECLARE FUNCTION  XxxCheckLine                (lineNumber, TOKEN tok[])
DECLARE FUNCTION  XxxCloseCompileFiles        ()
DECLARE FUNCTION  XxxCompilePrep              ()
DECLARE FUNCTION  XxxCreateCompileFiles       ()
DECLARE FUNCTION  XxxDeleteFunction           (funcNumber)
DECLARE FUNCTION  XxxDeparseFunction          (func$, TOKEN func[], lastLine, flags)
DECLARE FUNCTION  XxxDeparser                 (TOKEN tok[], deparsed$)
DECLARE FUNCTION  XxxEmitXProfilerCall        (funcNumber, lineNumber)
DECLARE FUNCTION  XxxErrorInfo                (xerror, rawPtr, srcPtr, srcLine$)
DECLARE FUNCTION  XxxFunctionName             (command, funcName$, funcNumber)
DECLARE FUNCTION  XxxFunctionNumber           (funcName$)
DECLARE FUNCTION  XxxGetAddressGivenLabel     (label$)
DECLARE FUNCTION  XxxGetFunctionVariables     (funcNumber, kinds[], TOKEN tok[], symbol$[], reg[], addr[])
DECLARE FUNCTION  XxxGetLabelGivenAddress     (addr, labels$[])
DECLARE FUNCTION  XxxGetPatchErrors           (symbol$[], TOKEN token[], addr[])
DECLARE FUNCTION  XxxGetProgramName           (@name$)
DECLARE FUNCTION  XxxGetSymbolInfo            (tokNumber, TOKEN token, theType, symbol$, r_addr$, m_addr$)
DECLARE FUNCTION  XxxGetUserTypes             (varTypes$[])
DECLARE FUNCTION  XxxGetXerror$               (xerror)
DECLARE FUNCTION  XxxInitAll                  ()
DECLARE FUNCTION  XxxInitParse                ()
DECLARE FUNCTION  XxxInitVariablesPass1       ()
DECLARE FUNCTION  XxxLibraryAPI               (libname$)
DECLARE FUNCTION  XxxLoadLibrary              (TOKEN token)
DECLARE FUNCTION  XxxParseLibrary             (TOKEN token)
DECLARE FUNCTION  XxxParseSourceLine          (sourceLine$, TOKEN tok[])
DECLARE FUNCTION  XxxPassFunctionArrays       (command, symbol$[], TOKEN token[], scope[])
DECLARE FUNCTION  XxxPassTypeArrays           (command, pSize[], pSize$[], pAlias[], pAlign[], pSymbol$[], TOKEN pToken[], pEleCount[], pEleSymbol$[], TOKEN pEleToken[], pEleAddr[], pEleSize[], pEleType[], pEleStringSize[], pEleUBound[])
DECLARE FUNCTION  XxxSetProgramName           (name$)
DECLARE FUNCTION  XxxTheType                  (TOKEN token, funcNumber)
DECLARE FUNCTION  TOKEN XxxUndeclaredFunction (TOKEN funcToken)
DECLARE FUNCTION  XxxXBasicVersion$           ()
DECLARE FUNCTION  XxxXntBlowback              ()
DECLARE FUNCTION  XxxXntFreeLibraries         ()
'
' xdis functions
'
EXTERNAL FUNCTION  Frames$                    ()
EXTERNAL FUNCTION  XxxDisassemble64$	        (pbyte, useLabel)
EXTERNAL FUNCTION  XxxGetRbpRsp               (@frame, @stack)
EXTERNAL FUNCTION  XxxLog                     (text$)
EXTERNAL FUNCTION  XxxLog2                    (text$, int)
'
' xst functions
'
EXTERNAL FUNCTION  XxxXstLoadLibrary          (libname$)
'
'
' ********************************
' *****  EXTERNAL VARIABLES  *****  Also referenced by "xit.x"
' ********************************
'
	EXTERNAL /xxx/  i486asm
	EXTERNAL /xxx/  i486bin
	EXTERNAL /xxx/  library
	EXTERNAL /xxx/  freezeFlag
	EXTERNAL /xxx/  bogusFunction
	EXTERNAL /xxx/  freezeFunction
	EXTERNAL /xxx/  checkattach
	EXTERNAL /xxx/  checkBounds
	EXTERNAL /xxx/  entryFunction
	EXTERNAL /xxx/  maxFuncNumber
	EXTERNAL /xxx/  xpc
	EXTERNAL /xxx/  errorCount
	EXTERNAL /xxx/  litStringAddr
	EXTERNAL /xxx/  autoUpperCase
'
'
' ***********************************
' *****  SHARED VARIABLES NOTES *****
' ***********************************
'
'  SHARED typeName$[]          ' "sbyte", "ubyte"...
'  SHARED typeSize[]           ' size in bytes
'  SHARED typeSize$[]          ' "1", "2", "4", "8", "16"...
'  SHARED typeAlias[]          ' normal type that user-type is alias for
'  SHARED typeAlign[]          ' alignment for this type
'  SHARED typeSuffix$[]        ' @  @@  %  %%  &  &&  ~  !  #  $$  $
'  SHARED typeSymbol$[]        ' SBYTE, UBYTE...  SCOMPLEX, DCOMPLEX, USERTYPE...
'  SHARED typeToken[]          ' #T_TYPE token, low word = type #
'  SHARED typeEleCount[]       ' # of elements in this type
'  SHARED typeEleSymbol$[]     ' symbol for each n elements
'  SHARED typeEleToken[]       ' token for each n elements
'  SHARED typeEleAddr[]        ' offset address of each n elements
'  SHARED typeEleSize[]        ' size of each n elements ([]: typesize*(dim+1))
'  SHARED typeEleType[]        ' type of each n elements
'  SHARED typeEleArg[]         ' kind/type of funcaddr component arguments
'  SHARED typeElePtr[]         ' # indirection levels for each n elements
'  SHARED typeEleVal[]         ' init value of each n elements
'  SHARED typeEleStringSize[]  ' # bytes in fixed string for element n
'  SHARED typeEleUBound[]      ' Upper bound of 1D array for element n
'  SHARED compositeNumber[]    ' number of composite
'  SHARED compositeToken[]     ' token of composite
'  SHARED compositeStart[]     ' starting address of composite
'  SHARED compositeNext[]      ' next available address after composite
'  SHARED charToken[]          ' tokens for single characters where they exist
'
'
'
' *****  KEYWORD TOKENS  *****
'
	TOKEN #T_ABS
	TOKEN #T_ALL
	TOKEN #T_AND
	TOKEN #T_ANY
	TOKEN #T_ASC
	TOKEN #T_ATTACH
	TOKEN #T_AUTO
	TOKEN #T_AUTOX
	TOKEN #T_BIN_D
	TOKEN #T_BINB_D
	TOKEN #T_BITFIELD
	TOKEN #T_CASE
	TOKEN #T_CFUNCTION
	TOKEN #T_CHR_D
	TOKEN #T_CJUST_D
	TOKEN #T_CLOSE
	TOKEN #T_CLR
	TOKEN #T_CSIZE
	TOKEN #T_CSIZE_D
	TOKEN #T_CSTRING_D
	TOKEN #T_DEC
	TOKEN #T_DECLARE
	TOKEN #T_DEF
	TOKEN #T_DHIGH
	TOKEN #T_DIM
	TOKEN #T_DLOW
	TOKEN #T_DMAKE
	TOKEN #T_DO
	TOKEN #T_DOUBLE
	TOKEN #T_DOUBLEAT
	TOKEN #T_ELSE
	TOKEN #T_END
	TOKEN #T_ENDIF
	TOKEN #T_EOF
	TOKEN #T_ERROR
	TOKEN #T_ERROR_D
	TOKEN #T_EXIT
	TOKEN #T_EXPORT
	TOKEN #T_EXTERNAL
	TOKEN #T_EXTS
	TOKEN #T_EXTU
	TOKEN #T_FALSE
	TOKEN #T_FIX
	TOKEN #T_FOR
	TOKEN #T_FORMAT_D
	TOKEN #T_FUNCADDR
	TOKEN #T_FUNCADDRAT
	TOKEN #T_FUNCADDRESS
	TOKEN #T_FUNCTION
	TOKEN #T_GHIGH
	TOKEN #T_GIANT
	TOKEN #T_GIANTAT
	TOKEN #T_GLOW
	TOKEN #T_GMAKE
	TOKEN #T_GOADDR
	TOKEN #T_GOADDRAT
	TOKEN #T_GOADDRESS
	TOKEN #T_GOSUB
	TOKEN #T_GOTO
	TOKEN #T_HEX_D
	TOKEN #T_HEXX_D
	TOKEN #T_HIGH0
	TOKEN #T_HIGH1
	TOKEN #T_IF
	TOKEN #T_IFF
	TOKEN #T_IFT
	TOKEN #T_IFZ
	TOKEN #T_IMPORT
	TOKEN #T_INC
	TOKEN #T_INCHR
	TOKEN #T_INCHRI
	TOKEN #T_INFILE_D
	TOKEN #T_INLINE_D
	TOKEN #T_INSTR
	TOKEN #T_INSTRI
	TOKEN #T_INT
	TOKEN #T_INTERNAL
	TOKEN #T_ISDATA
	TOKEN #T_ISNODE
	TOKEN #T_LCASE_D
	TOKEN #T_LCLIP_D
	TOKEN #T_LEFT_D
	TOKEN #T_LEN
	TOKEN #T_LIBRARY
	TOKEN #T_LJUST_D
	TOKEN #T_LOF
	TOKEN #T_LOOP
	TOKEN #T_LTRIM_D
	TOKEN #T_MAKE
	TOKEN #T_MAX
	TOKEN #T_MID_D
	TOKEN #T_MIN
	TOKEN #T_MOD
	TOKEN #T_NEXT
	TOKEN #T_NOT
	TOKEN #T_NULL_D
	TOKEN #T_OCT_D
	TOKEN #T_OCTO_D
	TOKEN #T_OPEN
	TOKEN #T_OR
	TOKEN #T_PACKED
	TOKEN #T_POF
	TOKEN #T_PRINT
	TOKEN #T_PROGRAM
	TOKEN #T_PROGRAM_D
	TOKEN #T_QUIT
	TOKEN #T_RCLIP_D
	TOKEN #T_READ
	TOKEN #T_REDIM
	TOKEN #T_RETURN
	TOKEN #T_RIGHT_D
	TOKEN #T_RINCHR
	TOKEN #T_RINCHRI
	TOKEN #T_RINSTR
	TOKEN #T_RINSTRI
	TOKEN #T_RJUST_D
	TOKEN #T_ROTATEL
	TOKEN #T_ROTATER
	TOKEN #T_RTRIM_D
	TOKEN #T_SBYTE
	TOKEN #T_SBYTEAT
	TOKEN #T_SEEK
	TOKEN #T_SELECT
	TOKEN #T_SET
	TOKEN #T_SGN
	TOKEN #T_SHARED
	TOKEN #T_SFUNCTION
	TOKEN #T_SHELL
	TOKEN #T_SIGN
	TOKEN #T_SIGNED_D
	TOKEN #T_SINGLE
	TOKEN #T_SINGLEAT
	TOKEN #T_SIZE
	TOKEN #T_SLONG
	TOKEN #T_SLONGAT
	TOKEN #T_SMAKE
	TOKEN #T_SPACE_D
	TOKEN #T_SSHORT
	TOKEN #T_SSHORTAT
	TOKEN #T_STARTS
	TOKEN #T_STATIC
	TOKEN #T_STEP
	TOKEN #T_STOP
	TOKEN #T_STR_D
	TOKEN #T_STRING
	TOKEN #T_STRING_D
	TOKEN #T_STUFF_D
	TOKEN #T_SUB
	TOKEN #T_SUBADDR
	TOKEN #T_SUBADDRAT
	TOKEN #T_SUBADDRESS
	TOKEN #T_SWAP
	TOKEN #T_TAB
	TOKEN #T_THEN
	TOKEN #T_TO
	TOKEN #T_TRIM_D
	TOKEN #T_TRUE
	TOKEN #T_TYPE
	TOKEN #T_UBOUND
	TOKEN #T_UBYTE
	TOKEN #T_UBYTEAT
	TOKEN #T_UCASE_D
	TOKEN #T_ULONG
	TOKEN #T_ULONGAT
	TOKEN #T_UNION
	TOKEN #T_UNTIL
	TOKEN #T_USHORT
	TOKEN #T_USHORTAT
	TOKEN #T_VERSION
	TOKEN #T_VERSION_D
	TOKEN #T_VOID
	TOKEN #T_WHILE
	TOKEN #T_WRITE
	TOKEN #T_XLONG
	TOKEN #T_XLONGAT
	TOKEN #T_XMAKE
	TOKEN #T_XOR
	TOKEN #T_ZERO
'
' characters and character combos
'
	TOKEN #T_LPAREN             '  (
	TOKEN #T_RPAREN             '  )
	TOKEN #T_LBRAK              '  [
	TOKEN #T_RBRAK              '  ]
	TOKEN #T_LBRACE             '  {
	TOKEN #T_RBRACE             '  }
	TOKEN #T_LBRACES            '  {{
	TOKEN #T_COMMA              '  ,
	TOKEN #T_SEMI               '  ;
	TOKEN #T_COLON              '  :
	TOKEN #T_REM                '  '
	TOKEN #T_RSHIFT             '  >>
	TOKEN #T_LSHIFT             '  <<
	TOKEN #T_DSHIFT             '  >>>  (sign extend signed types)
	TOKEN #T_USHIFT             '  <<<
	TOKEN #T_NOTBIT,  #T_TILDA  '  ~
	TOKEN #T_ANDBIT             '  &
	TOKEN #T_XORBIT             '  ^
	TOKEN #T_ORBIT              '  |
	TOKEN #T_TESTL              '  !!
	TOKEN #T_NOTL               '  !
	TOKEN #T_ANDL               '  &&
	TOKEN #T_XORL               '  ^^
	TOKEN #T_ORL                '  ||
	TOKEN #T_CMPL               '  ::
	TOKEN #T_EQL                '  ==
	TOKEN #T_EQ,  #T_NNE        '  =     !<>
	TOKEN #T_NE,  #T_NEQ        '  <>    !=
	TOKEN #T_LT,  #T_NGE        '  <     !>=
	TOKEN #T_LE,  #T_NGT        '  <=    !>
	TOKEN #T_GE,  #T_NLT        '  >=    !<
	TOKEN #T_GT,  #T_NLE        '  >     !<=
	TOKEN #T_SUBTRACT           '  -
	TOKEN #T_ADD                '  +
	TOKEN #T_IDIV               '  \
	TOKEN #T_MUL                '  *
	TOKEN #T_DIV                '  /
	TOKEN #T_REMAINDER          '  %
	TOKEN #T_POWER              '  **  (not ^, ^ is bitwise XOR)
	TOKEN #T_PLUS               '  +
	TOKEN #T_MINUS              '  -
	TOKEN #T_ADDR_OP            '  &
	TOKEN #T_HANDLE_OP          '  &&
	TOKEN #T_STORE_OP           '  (internal)
	TOKEN #T_ETC                '  ...
	TOKEN #T_PERCENT            '  %
	TOKEN #T_XMARK              '  !
	TOKEN #T_ATSIGN             '  @
	TOKEN #T_POUND              '  #
	TOKEN #T_DOLLAR             '  $
	TOKEN #T_DQUOTE             '  "
	TOKEN #T_DOT                '  .
	TOKEN #T_VBAR               '  |
	TOKEN #T_ULINE              '  _
	TOKEN #T_QMARK              '  ?
	TOKEN #T_TICK               '  `
	TOKEN #T_MARK               '  \x7F
'
'
' Compiler Constants
'
	$$VALUEABS          = 0        ' addressing modes for Value ()
	$$VALUEDISP         = 1
	$$TEXTSECTION       = 0
	$$DATASECTION       = 1
	$$USERSECTION       = 2
	$$STACKSECTION      = 3
	$$XGET              = 0        ' get token (also generic GET)
	$$XSET              = 1        ' set token (also generic SET)
	$$XADD              = 1        ' add token
	$$XNEW              = 2        ' add token (override existing)
	$$GETADDR           = 0        ' see Composite()
	$$GETHANDLE         = 1        ' see Composite()
	$$GETDATAADDR       = 2        ' see Composite()
	$$GETDATA           = 3        ' see Composite()
	$$NORMAL_SYMBOL     = 0        ' see GetSymbol()      normalSymbol
	$$LOCAL_CONSTANT    = 1        ' see GetSymbol()      $LOCAL_CONSTANT
	$$GLOBAL_CONSTANT   = 2        ' see GetSymbol()      $$GLOBAL_CONSTANT
	$$SHARED_VARIABLE   = 3        ' see GetSymbol()      #SharedVariable
	$$EXTERNAL_VARIABLE = 4        ' see GetSymbol()      ##ExternalVariable
	$$SOLO_POUND        = 5        ' see GetSymbol()      solo #
	$$DUAL_POUND        = 6        ' see GetSymbol()      dual ##
	$$COMPONENT         = 7        ' see GetSymbol()      .component
	$$NONE              = 0        ' not data kind
	$$VAR_TOKEN         = 1        ' variable  (built-in or user-defined)
	$$ARRAY_TOKEN       = 2        ' whole array of any type
	$$ARRAY_NODE        = 3        ' array node of any type
	$$DATA_ADDR         = 4        ' data address of any type
'
' r30 offsets for system variables:
'    replace with computed values as soon as available
'
	$$xerrorOffset      = 0x0180            ' &($$XERROR) - r30
	$$walkbaseOffset    = 0x01B8
	$$walkoffsetOffset  = 0x01BC
	$$softBreakOffset   = 0x01C0
'
	$$BPEXECLR     = 0                    ' BreakPoint & Execution flags cleared
	$$EXE          = 1                    ' Execution flag
	$$BP           = 2                    ' Breakpoint flag
	$$BPEXE        = 3                    ' Breakpoint and Execution flag set
'
'
' *****  BITFIELDS  *****
'
	$$BYTE0          = BITFIELD ( 8,  0)    ' byte 0  (low byte)
	$$BYTE1          = BITFIELD ( 8,  8)    ' byte 1
	$$BYTE2          = BITFIELD ( 8, 16)    ' byte 2
	$$BYTE3          = BITFIELD ( 8, 24)    ' byte 3  (high byte)
	$$WORD0          = BITFIELD (16,  0)    ' word 0  (low word)
	$$WORD1          = BITFIELD (16, 16)    ' word 1  (high word)
'
'
' *****  TOKEN PROTOCALL  *****    TOKEN.tproto component
'
	$$TP_ZERO          = 0x00000000
	$$TP_VARIABLES     = 0x00010000
	$$TP_ARRAYS        = 0x00020000
	$$TP_LITERALS      = 0x00030000
	$$TP_CONSTANTS     = 0x00040000
	$$TP_COMPOSITES    = 0x00050000
	$$TP_LABELS        = 0x00060000
	$$TP_FUNCTIONS     = 0x00070000
	$$TP_ARRAY_SYMBOLS = 0x00080000
	$$TP_SYMBOLS       = 0x00090000
	$$TP_CHARCONS      = 0x000B0000
	$$TP_SYSCONS       = 0x000C0000
	$$TP_STATEMENTS    = 0x000D0000
	$$TP_INTRINSICS    = 0x000E0000
	$$TP_STATE_INTRIN  = 0x000F0000
	$$TP_TYPES         = 0x00100000
	$$TP_STARTS        = 0x00110000
	$$TP_SEPARATORS    = 0x00120000
	$$TP_TERMINATORS   = 0x00130000
	$$TP_LPARENS       = 0x00140000
	$$TP_RPARENS       = 0x00150000
	$$TP_BINARY_OPS    = 0x00160000
	$$TP_UNARY_OPS     = 0x00170000
	$$TP_ADDR_OPS      = 0x00180000
	$$TP_COMMENTS      = 0x00190000
	$$TP_CHARACTERS    = 0x001A0000
	$$TP_WHITES        = 0x001B0000
'
'
' *****  TOKEN INDEX  *****   TOKEN.tindex component initialization value
'
	$$TI_ZERO          = 0
	$$SYSCON           = 0
'
'
' *****  TOKEN KINDS  *****    TOKEN.tp.kind component
'
	$$KIND_VARIABLES      = 0x01
	$$KIND_ARRAYS         = 0x02
	$$KIND_LITERALS       = 0x03
	$$KIND_CONSTANTS      = 0x04
'  $$KIND_COMPOSITES    = 0x05      ' not used
	$$KIND_LABELS         = 0x06
	$$KIND_FUNCTIONS      = 0x07
	$$KIND_ARRAY_SYMBOLS  = 0x08
	$$KIND_SYMBOLS        = 0x09
	$$KIND_CHARCONS       = 0x0B
	$$KIND_SYSCONS        = 0x0C
	$$KIND_STATEMENTS     = 0x0D
	$$KIND_INTRINSICS     = 0x0E
	$$KIND_STATE_INTRIN   = 0x0F
'
	$$KIND_STATEMENTS_INTRINSICS  = 0x0F    ' long name duplicate
'
	$$KIND_TYPES          = 0x10
	$$KIND_STARTS         = 0x11
	$$KIND_SEPARATORS     = 0x12
	$$KIND_TERMINATORS    = 0x13
	$$KIND_LPARENS        = 0x14
	$$KIND_RPARENS        = 0x15
	$$KIND_BINARY_OPS     = 0x16
	$$KIND_UNARY_OPS      = 0x17
	$$KIND_ADDR_OPS       = 0x18
	$$KIND_COMMENTS       = 0x19
	$$KIND_CHARACTERS     = 0x1A
	$$KIND_WHITES         = 0x1B
'
'
' *****  PRECEDENCE  *****
'
	$$PREC_NONE       = 0
	$$PREC_ORL        = 1:    $$PREC_LOR      = 1
	$$PREC_XORL       = 1:    $$PREC_LXOR     = 1
	$$PREC_ANDL       = 2
	$$PREC_EQ         = 3:    $$PREC_NNE      = 3:    $$PREC_EQL    = 3
	$$PREC_NE         = 3:    $$PREC_NEQ      = 3
	$$PREC_LT         = 4:    $$PREC_NGE      = 4
	$$PREC_LE         = 4:    $$PREC_NGT      = 4
	$$PREC_GE         = 4:    $$PREC_NLT      = 4
	$$PREC_GT         = 4:    $$PREC_NLE      = 4
	$$PREC_OR         = 5:    $$PREC_ORBIT    = 5
	$$PREC_XOR        = 5:    $$PREC_XORBIT    = 5
	$$PREC_AND        = 6:    $$PREC_ANDBIT    = 6
	$$PREC_SUBTRACT   = 7
	$$PREC_ADD        = 7
	$$PREC_MOD        = 8
	$$PREC_REMAINDER  = 8
	$$PREC_IDIV       = 8
	$$PREC_MUL        = 8
	$$PREC_DIV        = 8
	$$PREC_POWER      = 9
	$$PREC_RSHIFT     = 10
	$$PREC_LSHIFT     = 10
	$$PREC_DSHIFT     = 10
	$$PREC_USHIFT     = 10
	$$PREC_UNARY      = 11
	$$PREC_MINUS      = 11
	$$PREC_PLUS       = 11
	$$PREC_NOT        = 11:   $$PREC_NOTBIT  = 11:   $$PREC_TILDA   = 11
	$$PREC_TESTL      = 11
	$$PREC_NOTL       = 11
	$$PREC_ADDR_OP    = 11
	$$PREC_HANDLE_OP  = 11
	$$PREC_STORE_OP   = 11
'
'
' *****  OPERATOR CONVERSION TABLE NUMBERS  *****
'
	$$COP0  = 0x00
	$$COP1  = 0x10
	$$COP2  = 0x20
	$$COP3  = 0x30
	$$COP4  = 0x40
	$$COP5  = 0x50
	$$COP6  = 0x60
	$$COP7  = 0x70
	$$COP8  = 0x80
	$$COP9  = 0x90
	$$COPA  = 0xA0
	$$COPB  = 0xB0
'
	$$R0 = 0:    $$R8  =  8:    $$R16 = 16:    $$R24 = 24
	$$R1 = 1:    $$R9  =  9:    $$R17 = 17:    $$R25 = 25
	$$R2 = 2:    $$R10 = 10:    $$R18 = 18:    $$R26 = 26
	$$R3 = 3:    $$R11 = 11:    $$R19 = 19:    $$R27 = 27
	$$R4 = 4:    $$R12 = 12:    $$R20 = 20:    $$R28 = 28
	$$R5 = 5:    $$R13 = 13:    $$R21 = 21:    $$R29 = 29
	$$R6 = 6:    $$R14 = 14:    $$R22 = 22:    $$R30 = 30
	$$R7 = 7:    $$R15 = 15:    $$R23 = 23:    $$R31 = 31
'
	$$RA0             = $$R14
	$$RA1             = $$R16
	$$IMM16           = 32
	$$NEG16           = 33
	$$LITNUM          = 34
	$$CONNUM          = 35
'
	$$TYPE_ALLO       = 0xE0  ' allocation TYPE_MASK
	$$TYPE_TYPE       = 0x1F  ' data type  TYPE_MASK
	$$TYPE_DECLARED   = 0x80  ' for functions, go_labels, sub_labels
	$$TYPE_DEFINED    = 0x40  ' for functions, go_labels, sub_labels
	$$TYPE_INPUT      = 0x11
'
	$$MASK_ALLO       = 0xE00000
	$$MASK_DECDEF     = 0xC00000    ' declared | defined mask
	$$MASK_DECLARED   = 0x800000    ' declared in DECLARE, EXTERNAL, INTERNAL
	$$MASK_DEFINED    = 0x400000    ' defined in FUNCTION block
'
	$$XFUNC           = 0x01        ' Native function (see funcKind[])
	$$SFUNC           = 0x02        ' System function (see funcKind[])
	$$CFUNC           = 0x03        ' C function      (see funcKind[])
'
'  DECLARE FUNCTION STYLES
'
	$$FUNC_DECLARE    = 2
	$$FUNC_INTERNAL   = 1
	$$FUNC_EXTERNAL   = 0
'
	$$ALLO_DECLARED   = 0x80  ' for functions, go_labels, sub_labels
	$$ALLO_DEFINED    = 0x40  ' for functions, go_labels, sub_labels
'
	$$ALLO_CASE_ALL   = 0x80
	$$ALLO_CASE_TRUE  = 0x40
	$$ALLO_CASE_FALSE = 0x20
	$$ALLO_CASE_STR   = 0x10
'
'  $$ARGS0          = 0x00
'  $$ARGS1          = 0x20
'  $$ARGS2          = 0x40
'  $$ARGS3          = 0x60
'  $$ARGS4          = 0x80
'
	$$ARGS0           = 0x00
	$$ARGS1           = 0x01
	$$ARGS2           = 0x02
	$$ARGS3           = 0x03
	$$ARGS4           = 0x04
'
	$$MIN_SBYTE       = -128
	$$MAX_SBYTE       =  127
	$$MIN_UBYTE       = 0
	$$MAX_UBYTE       = 255
	$$MIN_SSHORT      = -32768
	$$MAX_SSHORT      = 32767
	$$MIN_USHORT      = 0
	$$MAX_USHORT      = 65535
	$$MIN_SLONG       = -2147483648
	$$MAX_SLONG       = 2147483647
	$$MIN_ULONG       = 0
	$$MAX_ULONG       = 4294967295$$
	$$MIN_XLONG       = $$MIN_SLONG
	$$MAX_XLONG       = $$MAX_ULONG
	$$MIN_GOADDR      = $$MIN_XLONG
	$$MAX_GOADDR      = $$MAX_XLONG
	$$MIN_SUBADDR     = $$MIN_XLONG
	$$MAX_SUBADDR     = $$MAX_XLONG
	$$MIN_FUNCADDR    = $$MIN_XLONG
	$$MAX_FUNCADDR    = $$MAX_XLONG
	$$MIN_SINGLE      = 0sFF7FFFFF
	$$MAX_SINGLE      = 0s7F7FFFFF
	$$MIN_DOUBLE      = 0dFFEFFFFFFFFFFFFF
	$$MAX_DOUBLE      = 0d7FEFFFFFFFFFFFFF
	$$MIN_GIANT       = 0x8000000000000000
	$$MAX_GIANT       = 0x7FFFFFFFFFFFFFFF
	$$outdisk         = 2
	$$errors          = 3
	$$infile          = 4
	$$termfile        = 0
	$$diskfile        = 1
'
'
' i486 register equivalences
'
	$$al    = $$R2
	$$dl    = $$R3
	$$bl    = $$R4
	$$cl    = $$R5
	$$ax    = $$R6
	$$dx    = $$R7
	$$bx    = $$R8
	$$cx    = $$R9
	$$eax   = $$R10
	$$edx   = $$R11
	$$ebx   = $$R12
	$$ecx   = $$R13
	$$rax   = $$R14
	$$rdx   = $$R15
	$$rbx   = $$R16
	$$rcx   = $$R17
	$$r8    = $$R18
	$$r9    = $$R19
	$$rsi   = $$R26
	$$rdi   = $$R27
	$$rbp   = $$R31
	$$rsp   = $$R1
'
	$$o0    = 0x0000
	$$o1    = 0x0001
	$$o2    = 0x0002
	$$o3    = 0x0003
	$$o4    = 0x0004
	$$o5    = 0x0005
	$$o6    = 0x0006
	$$o7    = 0x0007
	$$o8    = 0x0008
	$$o9    = 0x0009
	$$o10   = 0x000A
	$$o11   = 0x000B
	$$o12   = 0x000C
	$$o13   = 0x000D
	$$o14   = 0x000E
	$$o15   = 0x000F
	$$o16   = 0x0010
	$$o17   = 0x0011
	$$o18   = 0x0012
	$$o19   = 0x0013
	$$o20   = 0x0014
	$$o21   = 0x0015
	$$o22   = 0x0016
	$$o23   = 0x0017
	$$o24   = 0x0018
	$$o25   = 0x0019
	$$o26   = 0x001A
	$$o27   = 0x001B
	$$o28   = 0x001C
	$$o29   = 0x001D
	$$o30   = 0x001E
	$$o31   = 0x001F
	$$o32   = 0x0000
'
' 80486 machine instructions
'
	$$nope                  = 0
	$$adc                   = 1
	$$add                   = 2
	$$and                   = 3
	$$bsf                   = 4
	$$bsr                   = 5
	$$bt                    = 6
	$$btc                   = 7
	$$btr                   = 8
	$$bts                   = 9
	$$call                  = 10
	$$cbw                   = 11
	$$cdq                   = 12
	$$clc                   = 13
	$$cld                   = 14
	$$cmc                   = 15
	$$cmp                   = 16
	$$cmpsb                 = 17
	$$cmpsw                 = 18
	$$cmpsd                 = 19
	$$cwd                   = 20
	$$cwde                  = 21
	$$dec                   = 22
	$$div                   = 23
	$$f2xm1                 = 24
	$$fabs                  = 25
	$$fadd                  = 26
	$$faddp                 = 27
	$$fchs                  = 28
	$$fclex                 = 29
	$$fnclex                = 30
	$$fcom                  = 31
	$$fcomp                 = 32
	$$fcompp                = 33
	$$fcos                  = 34
	$$fdecstp               = 35
	$$fdiv                  = 36
	$$fdivp                 = 37
	$$fdivr                 = 38
	$$fdivrp                = 39
	$$fild                  = 40
	$$fincstp               = 41
	$$fist                  = 42
	$$fistp                 = 43
	$$fld                   = 44
	$$fldlg2                = 45
	$$fldln2                = 46
	$$fldl2e                = 47
	$$fldl2t                = 48
	$$fldpi                 = 49
	$$fldz                  = 50
	$$fld1                  = 51
	$$fmul                  = 52
	$$fmulp                 = 53
	$$fnop                  = 54
	$$fpatan                = 55
	$$fprem                 = 56
	$$fprem1                = 57
	$$fptan                 = 58
	$$frndint               = 59
	$$fscale                = 60
	$$fsin                  = 61
	$$fsincos               = 62
	$$fsqrt                 = 63
	$$fst                   = 64
	$$fstp                  = 65
	$$fstsw                 = 66
	$$fnstsw                = 67
	$$fsub                  = 68
	$$fsubp                 = 69
	$$fsubr                 = 70
	$$fsubrp                = 71
	$$ftst                  = 72
	$$fucom                 = 73
	$$fucomp                = 74
	$$fucompp               = 75
	$$fxam                  = 76
	$$fxch                  = 77
	$$fxtract               = 78
	$$fyl2x                 = 79
	$$fyl2xp1               = 80
	$$f2xn1                 = 81
	$$idiv                  = 82
	$$imul                  = 83
	$$inc                   = 84
	$$int                   = 85
	$$ja                    = 86
	$$jae                   = 87
	$$jbe                   = 88
	$$jc                    = 89
	$$jcxz                  = 90
	$$jecxz                 = 91
	$$je                    = 92
	$$jg                    = 93
	$$jge                   = 94
	$$jl                    = 95
	$$jle                   = 96
	$$jna                   = 97
	$$jnae                  = 98
	$$jnb                   = 99
	$$jnbe                  = 100
	$$jnc                   = 101
	$$jne                   = 102
	$$jng                   = 103
	$$jnge                  = 104
	$$jnl                   = 105
	$$jnle                  = 106
	$$jno                   = 107
	$$jnp                   = 108
	$$jns                   = 109
	$$jnz                   = 110
	$$jo                    = 111
	$$jp                    = 112
	$$jpe                   = 113
	$$jpo                   = 114
	$$js                    = 115
	$$jz                    = 116
	$$jmp                   = 117
	$$lahf                  = 118
	$$ld                    = 119
	$$lea                   = 120
	$$lodsb                 = 121
	$$lodsw                 = 122
	$$lodsd                 = 123
	$$loop                  = 124
	$$loopz                 = 125
	$$loopnz                = 126
	$$movsb                 = 127
	$$movsw                 = 128
	$$movsd                 = 129
	$$mul                   = 130
	$$neg                   = 131
	$$nop                   = 132
	$$not                   = 133
	$$or                    = 134
	$$pop                   = 135
	$$popad                 = 136
	$$popfd                 = 137
	$$push                  = 138
	$$pushad                = 139
	$$pushfd                = 140
	$$rcl                   = 141
	$$rcr                   = 142
	$$rol                   = 143
	$$ror                   = 144
	$$rep                   = 145
	$$repz                  = 146
	$$repnz                 = 147
	$$ret                   = 148
	$$sahf                  = 149
	$$sal                   = 150  'not used
	$$sar                   = 151
	$$sll                   = 152
	$$slr                   = 153
	$$sbb                   = 154
	$$scasb                 = 155
	$$scasw                 = 156
	$$scasd                 = 157
	$$shld                  = 158
	$$shrd                  = 159
	$$st                    = 160
	$$stc                   = 161
	$$std                   = 162
	$$stosb                 = 163
	$$stosw                 = 164
	$$stosd                 = 165
	$$sub                   = 166
	$$test                  = 167
	$$xchg                  = 168
	$$xor                   = 169
	$$jb                    = 170
	$$into                  = 171
	$$mov                   = 172
	$$movsx                 = 173
	$$movzx                 = 174
	$$movslq                = 175
	$$stosq                 = 176
	$$zlast                 = 177
	$$ufld                  = 0x002C0000      ' make = $$fld  << 16
	$$ufstp                 = 0x00410000      ' make = $$fstp << 16
	$$uld                   = 0x00770000      ' make = $$ld   << 16
	$$ulda                  = 0x00780000      ' make = $$lda  << 16
	$$ust                   = 0x00A00000      ' make = $$st   << 16
'
' 80486 addressing modes
'
	$$none                  = 0
	$$abs                   = 1
	$$rel                   = 2
	$$reg                   = 3
	$$imm                   = 4
	$$r0                    = 5
	$$ro                    = 6
	$$rr                    = 7
	$$rs                    = 8
	$$regreg                = 9
	$$regimm                = 10
	$$regabs                = 11
	$$regr0                 = 12
	$$regro                 = 13
	$$regrr                 = 14
	$$regrs                 = 15
	$$absreg                = 16
	$$r0reg                 = 17
	$$roreg                 = 18
	$$rrreg                 = 19
	$$rsreg                 = 20
	$$absimm                = 21
	$$r0imm                 = 22
	$$roimm                 = 23
	$$rrimm                 = 24
	$$rsimm                 = 25
	$$regimm8               = 26    ' special bogus addressing modes for
	$$absimm8               = 27    ' bit-twiddling instructions in Code()
	$$r0imm8                = 28
	$$roimm8                = 29
	$$rrimm8                = 30
	$$rsimm8                = 31
'
	$$linux                       = $$TRUE              ' this is linux
	$$rmk$                        = "### "              ' comment/remark
	$$rmk1$                       = "#"                 ' comment/remark
	$$rmk2$                       = "##"                ' comment/remark
	$$ulpc$                       = "_"
	$$ulpc2$                      = "__"
	$$ulpc3$                      = "___"
	$$ulpc4$                      = "____"
	$$ulat$                       = "_"
	$$ftrail$                     = "_"                              '    @
	$$flead$                      = ""                               '    _
	$$GOTOlead$                   = "_g_"                            '    %g%
	$$SUBlead$                    = "_s_"                            '    %s%
'
$$ENDPROLOG = 0
'
'
' ####################
' #####  Xnt ()  #####  If running as the user program in the environment,
' ####################  the entry function should start running the program.
'
FUNCTION  Xnt ()
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "Linux XBasic compiler"
	a$ = "maxreason@maxreason.com"
	a$ = ""
'
'	FOR commandNumber = 0 TO 0
'	FOR commandNumber = 5 TO 5
	FOR commandNumber = 1 TO 15
		GOSUB DebugSetup                                   '*cw* for testing only
		addr = &Xnt ()
		IF ((addr > ##UCODE) AND (addr < ##UCODEZ)) THEN XxxXBasic ()
	NEXT commandNumber
	IF ##WHOMASK THEN
		PRINT "Finished"
	END IF
	EXIT FUNCTION
'
'
' *****  DebugSetup  *****
'
SUB DebugSetup
	IFZ ##WHOMASK THEN EXIT SUB
	IF ##XBDV THEN
		##TRACE = $$FALSE
		DIM argv$[2]
		XstGetCurrentDirectory (@curDir$)
'		curDir$ = "/home/cw/xb64/xbasic-6.4.4"
		argv$[0] = "xb64"
		argv$[2] = "-lib"
		SELECT CASE commandNumber
			CASE 1 : argv$[1] = curDir$ + "/src/linux/xin.x"
			CASE 2 : argv$[1] = curDir$ + "/src/shared/xcm.x"
			CASE 3 : argv$[1] = curDir$ + "/src/shared/xma.x"
			CASE 4 : argv$[1] = curDir$ + "/src/linux/xst.x"
			CASE 5 : argv$[1] = curDir$ + "/src/linux/xgr.x"
			CASE 6 : argv$[1] = curDir$ + "/src/linux/kernel32.x"
			CASE 7 : argv$[1] = curDir$ + "/src/linux/gdi32.x"
			CASE 8 : argv$[1] = curDir$ + "/src/linux/user32.x"
			CASE 9 : argv$[1] = curDir$ + "/src/shared/xui.x"
			CASE 10 : argv$[1] = curDir$ + "/src/shared/xut.x"
			CASE 11 : argv$[1] = curDir$ + "/src/linux/xit.x"
			CASE 12 : argv$[1] = curDir$ + "/src/linux/xcol.x"
			CASE 13 : argv$[1] = curDir$ + "/src/shared/xdis.x"
			CASE 14 : argv$[1] = curDir$ + "/src/shared/xutpde.x"
			CASE 15 : argv$[1] = curDir$ + "/src/linux/xrun.x"
		END SELECT

		IFZ argv$[1] THEN
'			argv$[1] = "/home/cw/xb64/xxx/zany.x"
'			argv$[1] = "/home/cw/xb64/RobinWarner/Artifex307.x"
'			argv$[1] = "/home/cw/xb64/RobinWarner/cw.x"
'			argv$[1] = "/home/cw/xb64/build64/demo/acrc32.x"
			argv$[1] = "/home/cw/xb64/xxx/a64.x"
'			argv$[1] = "/home/cw/xb64/build64/src/linux/xcol.x"
'			argv$[2] = "-c"                             ' for bounds checking
			REDIM argv$[1]                              ' to remove -lib or bounds checking
		END IF
		argCount = UBOUND(argv$[]) + 1
		XstSetCommandLineArguments (argCount, @argv$[])

		#traceStart = 0
		#traceStop  = 0

		IF (#traceStop  < #traceStart) THEN
			#traceStop  = #traceStart
		END IF
	END IF
END SUB
'
END FUNCTION
'
'
' ##########################
' #####  XxxXBasic ()  #####
' ##########################
'
FUNCTION  XxxXBasic ()
	EXTERNAL /xxx/  maxFuncNumber,  errorCount,  library,  i486bin,  i486asm
' SHARED  tab_sym_ptr,  labelPtr    'for debugging
' SHARED  lastmax,  lastlabmax      'for debugging
	SHARED  XERROR
'
' *****  Initialize everything, then start the compiler  *****
'
	oldLibrary  = library
	library     = $$FALSE
	i486bin     = $$FALSE
	i486asm     = $$FALSE
	XxxInitAll ()
	InitOptions ()
	library     = oldLibrary
	c = Compile ()
	IFF c THEN
		IF XERROR THEN PrintError (XERROR)
		PRINT "*****  ERRORS: "; errorCount
'   PRINT "tab_sym_ptr  = "; tab_sym_ptr
'   PRINT "labelPtr     = "; labelPtr
'   PRINT "lastmax      = "; lastmax
'   PRINT "lastlabmax   = "; lastlabmax
'   PRINT "maxFuncNum   = "; maxFuncNumber
	END IF
	RETURN (errorCount)
END FUNCTION
'
'
' #########################
' #####  AddLabel ()  #####
' #########################
'
' action =  XGET (0):  Get label token if label has been defined.
'           XADD (1):  Add label token if label not defined (else error).
'           XNEW (2):  Add label token if label not defined this program.
'                       (XNEW is for functions only at this time).
' return token:
'   token.tp.stsp = 0
'   token.tp.kind = kind
'   token.tp.allo = 0
'   token.tp.type = type
'   token.tindex  = labelPtr
'
FUNCTION  TOKEN AddLabel (label$, kind, type, action)
	SHARED  tab_lab$[],  labhash[],  labaddr[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  labelPtr,  ulabel,  pastSystemLabels
	SHARED USHORT  hx[]
	SHARED TOKEN  tab_lab[]
	TOKEN  token
'
	IFZ label$ THEN PRINT "AddLabel(): Error: (label$ = empty string)": RETURN
	labelLength = LEN (label$)
	FOR i = 1 TO labelLength
		integer = ASC(label$, i)
		IFZ integer THEN
			PRINT "AddLabel(): Error: (label$ has nulls)"
			RETURN
		END IF
	NEXT i

	labhash     = 0
	x           = 0
	DO
		labhash = labhash + hx[label${x}]
'   labhash = labhash + label${x}
		INC x
	LOOP WHILE (x < labelLength)
	labhash     = labhash AND 0x00FF
	last        = labhash[labhash, 0]
	ulabhash    = UBOUND(labhash[labhash, ])
	IF (last >= ulabhash) THEN
		ATTACH labhash[labhash, ] TO temp[]
		ulabhash  = ulabhash + (ulabhash >> 1) + 3
		REDIM temp[ulabhash]
		ATTACH temp[] TO labhash[labhash, ]
'   PRINT "AddLabel(46):ulabhash", ulabhash, labhash
	END IF
'
' there are labels with this hash in label symbol table
'
	IF last THEN
		found = $$FALSE
		i     = last
		DO
			check  = labhash[labhash, i]
			IF (action = $$XNEW) THEN
				IF (check < pastSystemLabels) THEN EXIT DO
			END IF
			IF (labelLength = LEN (tab_lab$[check])) THEN
				IF (tab_lab$[check] = label$) THEN found = $$TRUE: EXIT DO
			END IF
			DEC i
		LOOP WHILE (i)
		IF action THEN
			IF found THEN
				RETURN (tab_lab[check])
			ELSE
				INC last
				labhash[labhash, 0]     = last
				labhash[labhash, last]  = labelPtr
				token.tp.kind = kind
				token.tp.type = type
				token.tindex = labelPtr
				IF (labelPtr >= ulabel) THEN
'         PRINT "AddLabel(69):ulabel increased from"; ulabel; " to"; ulabel + ulabel + 1
					ulabel = ulabel + ulabel + 1
					REDIM labaddr[ulabel]
					REDIM tab_lab[ulabel]
					REDIM tab_lab$[ulabel]
				END IF
				tab_lab[labelPtr]   = token
				tab_lab$[labelPtr]  = label$
				INC labelPtr
				RETURN (token)
			END IF
		ELSE
			IF found THEN RETURN (tab_lab[check]) ELSE RETURN
		END IF
	ELSE
'
' there are no labels with this hash in label symbol table
'
		IF action THEN
			labhash[labhash, 0] = 1
			labhash[labhash, 1] = labelPtr
			token.tp.kind = kind
			token.tp.type = type
			token.tindex = labelPtr
			IF (labelPtr >= ulabel) THEN
'       PRINT "AddLabel(99):ulabel increased from"; ulabel; " to"; ulabel + ulabel + 1
				ulabel = ulabel + ulabel
				REDIM labaddr[ulabel]
				REDIM tab_lab[ulabel]
				REDIM tab_lab$[ulabel]
			END IF
			tab_lab[labelPtr]   = token
			tab_lab$[labelPtr]  = label$
			INC labelPtr
			RETURN (token)
		END IF
	END IF
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  AddSymbol ()  #####
' ##########################
'
' token = AddSymbol (symbol$, spaces, kind, allo, type, func_number)
'
' symbol$  = new symbol name to add to the list
' kind     = kind of symbol
' allo     = allowed scope
' type     = symbol TYPE number
' f_number = function number  (0 = PROLOG)
'
FUNCTION  TOKEN AddSymbol (symbol$, spaces, kind, allo, type, f_number)
	EXTERNAL /xxx/  maxFuncNumber
	EXTERNAL /xxx/  bogusFunction,  freezeFlag,  freezeFunction
	TOKEN   token, token1, token2, checks
	SHARED  hash%[]
	SHARED  funcSymbol$[],  funcLabel$[]
	SHARED  funcScope[],  funcType[],  funcKind[],  funcArgSize[]
	SHARED  defaultType[]
	SHARED  funcFrameSize[]
	SHARED  autoAddr[],  autoxAddr[],  inargAddr[]
	SHARED  compositeNumber[]
	SHARED  r_addr[],  r_addr$[],  m_reg[],  m_addr[], m_addr$[]
	SHARED  tabType[],  tab_sym$[]
	SHARED  typeSize[],  typeSize$[],  typeAlias[],  typeAlign[]
	SHARED  typeSuffix$[],  typeSymbol$[]
	SHARED  typeEleCount[],  typeEleSymbol$[],  typeEleAddr[]
	SHARED  typeEleSize[],  typeEleType[]
	SHARED  typeEleVal[],  typeElePtr[]
	SHARED  typeEleStringSize[],  typeEleUBound[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  func_number,  function_line
	SHARED  parse_got_function,  got_function,  hfn$
	SHARED  tab_sym_ptr,  typePtr,  uFunc,  uType
	SHARED USHORT  hx[]
'
	SHARED  TOKEN compositeNext[]
	SHARED  TOKEN compositeStart[]
	SHARED  TOKEN compositeToken[]
	SHARED  TOKEN funcArg[]
	SHARED  TOKEN funcToken[]
	SHARED  TOKEN tabArg[]
	SHARED  TOKEN tab_sym[]
	SHARED  TOKEN tokens[]
	SHARED  TOKEN typeEleArg[]
	SHARED  TOKEN typeEleToken[]
	SHARED  TOKEN typeToken[]
'
' IFZ symbol$ THEN XcowlErr (40052): GOTO eeeCompiler
'
	scope   = allo
	found   = 0
	token.tp.stsp = spaces
	token.tp.kind = kind
	token.tp.type = type
	f_num   = f_number
	slength = LEN (symbol$)
	token1  = tokens[1]
	token1.tp.stsp = 0
'
	IFZ kind THEN
		PRINT "AddSymbol():No token kind ", HEXX$(tokoid), f_number, symbol$
		XcowlErr (40067): GOTO eeeCompiler
	END IF
'
' see if symbol has explicit scope prefix - # or ##
' see if first token on source line is a scope keyword
' see if first token on source line is a built-in data-type
' see if first token on source line is a user-defined data-type
'
	intypes = TypeToken(token1)
	IF (token1.tp.kind = $$KIND_TYPES) THEN intypes = $$TRUE
'
	IF symbol$ THEN
		IF (symbol${0} == '#') THEN
			IF (symbol${1} == '#') THEN scope = $$EXTERNAL ELSE scope = $$SHARED
		END IF
	END IF
'
' catch scope mismatches during compilation
'
' ########  ".composites" symbol causes mismatches  ##########
'
' scopeOfTok1 = ScopeToken(token1)
' IF scope THEN
'   IF scopeOfTok1 THEN
'     IF (scope != scopeOfTok1) THEN
'       PRINT "scope mismatch", scope, scopeOfTok1, symbol$
'     END IF
'   END IF
' END IF
'
	IF TokenMatch (@token1, @#T_SHARED) THEN
		inshared = $$TRUE
	ELSE
		IF TokenMatch (@token1, @#T_EXTERNAL) THEN
			token2 = tokens[2]
			IF (token2.tp.kind == $$KIND_WHITES) THEN token2 = tokens[3]
			token2.tp.stsp = 0
			SELECT CASE token2.tindex
				CASE #T_FUNCTION.tindex:
				CASE #T_SFUNCTION.tindex:
				CASE #T_CFUNCTION.tindex:
				CASE ELSE              : inshared = $$TRUE
			END SELECT
		END IF
	END IF
'
	SELECT CASE kind
		CASE $$KIND_FUNCTIONS
					GOTO add_function_symbol
		CASE $$KIND_TYPES
					GOTO add_type_symbol
		CASE $$KIND_VARIABLES
					IFZ got_function THEN
						IFZ (parse_got_function OR inshared OR intypes OR scope) THEN
							kind  = $$KIND_SYMBOLS
							token.tp.kind = $$KIND_SYMBOLS
						END IF
					END IF
		CASE $$KIND_ARRAYS
					IFZ got_function THEN
						IFZ (parse_got_function OR inshared OR intypes OR scope) THEN
							kind  = $$KIND_ARRAY_SYMBOLS
							token.tp.kind = $$KIND_ARRAY_SYMBOLS
						END IF
					END IF
	END SELECT
	GOTO add_normal_symbol
'
'
' ******************************
' *****  FUNCTION SYMBOLS  *****
' ******************************
'
add_function_symbol:
	FOR x = 0 TO maxFuncNumber
		funcLength = LEN (funcSymbol$[x])
		IF (slength = funcLength) THEN
			IF (symbol$ = funcSymbol$[x]) THEN found = $$TRUE: EXIT FOR
		END IF
	NEXT x
'
	IF found THEN
		token = funcToken[x]
		token.tp.stsp = spaces
	ELSE
		INC maxFuncNumber
		IF (maxFuncNumber >= uFunc) THEN
			uFunc = uFunc + 64
			REDIM compositeNumber[uFunc]
			REDIM compositeStart[uFunc, ]
			REDIM compositeToken[uFunc, ]
			REDIM compositeNext[uFunc, ]
			REDIM funcFrameSize[uFunc]
			REDIM defaultType[uFunc]
			REDIM funcSymbol$[uFunc]
			REDIM funcLabel$[uFunc]
			REDIM inargAddr[uFunc]
			REDIM autoxAddr[uFunc]
			REDIM autoAddr[uFunc]
			REDIM funcToken[uFunc]
			REDIM funcScope[uFunc]
			REDIM funcKind[uFunc]
			REDIM funcType[uFunc]
			REDIM funcArgSize[uFunc]
			REDIM funcArg[uFunc, ]
			REDIM hash%[uFunc, ]
'			PRINT "AddLabel(173):uFunc", uFunc
		END IF
		DIM temp%[255, ]
		ATTACH temp%[] TO hash%[maxFuncNumber, ]    ' hash array for new function
		token.tindex  = maxFuncNumber
		funcSymbol$[maxFuncNumber]  = symbol$
		funcToken[maxFuncNumber]    = token
		token.tp.stsp = spaces
	END IF
'
	IF function_line THEN
		parse_got_function = $$TRUE
		checkNumber = token.tindex
		IF freezeFlag AND (checkNumber != freezeFunction) THEN
			bogusFunction = $$TRUE
			token = funcToken[freezeFunction]
		ELSE
			func_number = checkNumber
			hfn$ = HEX$(func_number)
		END IF
	END IF
	RETURN (token)
'
'
' **************************
' *****  TYPE SYMBOLS  *****
' **************************
'
add_type_symbol:
' usymbol$ = UCASE$ (symbol$)
' FOR i = 1 TO typePtr
'   IF (usymbol$ = typeSymbol$[i]) THEN XcowlErr (400204): GOTO eeeDupType
' NEXT i
'
	IF (typePtr >= uType) THEN
		uType = uType + 32
'   PRINT "AddSymbol(198):uType", uType
		REDIM typeSize[uType]
		REDIM typeSize$[uType]
		REDIM typeAlias[uType]
		REDIM typeAlign[uType]
		REDIM typeToken[uType]
		REDIM typeSuffix$[uType]
		REDIM typeSymbol$[uType]
		REDIM typeEleCount[uType]
		REDIM typeEleSymbol$[uType,]
		REDIM typeEleToken[uType,]
		REDIM typeEleAddr[uType,]
		REDIM typeEleSize[uType,]
		REDIM typeEleType[uType,]
		REDIM typeEleArg[uType,]
		REDIM typeEleVal[uType,]
		REDIM typeElePtr[uType,]
		REDIM typeEleStringSize[uType,]
		REDIM typeEleUBound[uType,]
	END IF
	typeSymbol$[typePtr]  = symbol$
	token.tindex = typePtr
	typeToken[typePtr]    = token
	INC typePtr
	RETURN (token)
'
'
' ****************************
' *****  NORMAL SYMBOLS  *****
' ****************************
'
add_normal_symbol:
	SELECT CASE kind
		CASE $$KIND_SYMBOLS, $$KIND_ARRAY_SYMBOLS:              f_num = 0
		CASE $$KIND_LITERALS, $$KIND_SYSCONS, $$KIND_CHARCONS:  f_num = 0
	END SELECT
'
' 2000/12/30 - ??? maybe not necessary ???
'
	IF scope THEN
		token.tp.allo = scope
	END IF
'
	hash = 0
	FOR x = 0 TO slength - 1
		hash = hash + hx[symbol${x}]
	NEXT x
	hash = hash AND 0x00FF
'
' no symbol with this hash yet ???
'
	IFZ hash%[f_num, hash, ] THEN
		DIM temp%[7]
		temp%[0]              = 1
		temp%[1]              = tab_sym_ptr
		token.tindex          = tab_sym_ptr
		tab_sym[tab_sym_ptr]  = token
		tabType[tab_sym_ptr]  = type
		tab_sym$[tab_sym_ptr] = symbol$
		ATTACH temp%[] TO hash%[f_num, hash, ]
		INC tab_sym_ptr
		IF (tab_sym_ptr > UBOUND(tab_sym[])) THEN
			uTab = tab_sym_ptr + (tab_sym_ptr >> 2) OR 7
'     PRINT "AddSymbol(261):uTab0: "; UBOUND(tab_sym[]); " -> "; uTab
			REDIM r_addr[uTab]
			REDIM r_addr$[uTab]
			REDIM m_reg[uTab]
			REDIM m_addr[uTab]
			REDIM m_addr$[uTab]
			REDIM tab_sym$[uTab]
			REDIM tabType[uTab]
			REDIM tab_sym[uTab]
			REDIM tabArg[uTab, ]
		END IF
		RETURN (token)
	END IF
'
' already a symbol with this hash
'
	ATTACH hash%[f_num, hash, ] TO temp%[]
	uhash   = UBOUND(temp%[])
	last    = temp%[0]
	IF (last = uhash) THEN
		uhash = uhash + 8
		REDIM temp%[uhash]
	END IF
'
' Look for object in symbol table
'
	found       = $$FALSE
	FOR hash_ptr = 1 TO last
		entry     = temp%[hash_ptr]
		checks    = tab_sym[entry]
		IF (kind != checks.tp.kind) THEN DO NEXT
		IF (slength = LEN(tab_sym$[entry])) THEN
			IF (symbol$ = tab_sym$[entry]) THEN found = $$TRUE: EXIT FOR
		END IF
	NEXT hash_ptr
'
' if symbol was found, return its token, otherwise make a symbol table entry
'
	IF found THEN
		ATTACH temp%[] TO hash%[f_num, hash, ]
		token = tab_sym[entry]
	ELSE
		temp%[0]              = last + 1
		temp%[hash_ptr]       = tab_sym_ptr
		ATTACH temp%[] TO hash%[f_num, hash, ]
		token.tindex         = tab_sym_ptr
		tabType[tab_sym_ptr]  = type
		tab_sym[tab_sym_ptr]  = token
		tab_sym$[tab_sym_ptr] = symbol$
		INC tab_sym_ptr
		IF (tab_sym_ptr > UBOUND(tab_sym[])) THEN
			uTab = tab_sym_ptr + (tab_sym_ptr >> 2) OR 7
'     PRINT "AddSymbol(324):uTab1: "; UBOUND(tab_sym[]); " -> "; uTab
			REDIM r_addr[uTab]
			REDIM r_addr$[uTab]
			REDIM m_reg[uTab]
			REDIM m_addr[uTab]
			REDIM m_addr$[uTab]
			REDIM tab_sym$[uTab]
			REDIM tabType[uTab]
			REDIM tab_sym[uTab]
			REDIM tabArg[uTab, ]
		END IF
	END IF
	RETURN (token)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  AlloToken ()  #####
' ##########################
'
FUNCTION  AlloToken (TOKEN token)
'
	SELECT CASE token.tindex
		CASE #T_AUTO.tindex   :
		CASE #T_AUTOX.tindex  :
		CASE #T_STATIC.tindex :
		CASE #T_SHARED.tindex :
'
		CASE ELSE             :  RETURN ($$FALSE)
	END SELECT
	RETURN ($$TRUE)
END FUNCTION
'
'
' ################################
' #####  AssemblerSymbol ()  #####
' ################################
'
FUNCTION  AssemblerSymbol (symbol$)
	SHARED UBYTE  charsetSymbolInner[]
	SHARED XERROR, ERROR_COMPILER
'
	IFZ symbol$ THEN XcowlErr (60011): GOTO eeeCompiler
	offset = LEN(symbol$) - 1
	charz = symbol${offset}
	IF charsetSymbolInner[charz] THEN RETURN
	IF (offset <= 0) THEN RETURN
	DEC offset
	chary = symbol${offset}
	IF charsetSymbolInner[chary] THEN
		SELECT CASE charz
			CASE '@':   symbol$ = RCLIP$(symbol$, 1) + $$ulpc$ + "SBYTE"
			CASE '%':   symbol$ = RCLIP$(symbol$, 1) + $$ulpc$ + "SSHORT"
			CASE '&':   symbol$ = RCLIP$(symbol$, 1) + $$ulpc$ + "SLONG"
			CASE '~':   symbol$ = RCLIP$(symbol$, 1) + $$ulpc$ + "XLONG"
			CASE '!':   symbol$ = RCLIP$(symbol$, 1) + $$ulpc$ + "SINGLE"
			CASE '#':   symbol$ = RCLIP$(symbol$, 1) + $$ulpc$ + "DOUBLE"
			CASE '$':
			CASE ELSE:  XcowlErr (60027): GOTO eeeCompiler
		END SELECT
	ELSE
		SELECT CASE chary
			CASE '@':   symbol$ = RCLIP$(symbol$, 2) + $$ulpc$ + "UBYTE"
			CASE '%':   symbol$ = RCLIP$(symbol$, 2) + $$ulpc$ + "USHORT"
			CASE '&':   symbol$ = RCLIP$(symbol$, 2) + $$ulpc$ + "ULONG"
			CASE '$':   symbol$ = RCLIP$(symbol$, 2) + $$ulpc$ + "GIANT"
			CASE ELSE:  XcowlErr (60035): GOTO eeeCompiler
		END SELECT
	END IF
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #############################
' #####  AssignAddress () #####
' #############################
'
FUNCTION  AssignAddress (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc,  library
	TOKEN   compositeToken, cn, cs, ct, newNext, newStart, ta, ts, labelToken
	TOKEN   ct[], cs[], cn[]
	SHARED TOKEN tab_sym[]
	SHARED  arg_count
	SHARED  autoAddr[],  autoxAddr[],  inargAddr[]
	SHARED  r_addr[],  r_addr$[],  m_reg[],  m_addr[],  m_addr$[]
	SHARED  tabType[],              tab_sym$[],  labaddr[]
	SHARED  typeAlign[]
	SHARED  typeSize[],  typeSize$[]
	SHARED  XERROR,  ERROR_BAD_CHARCON,  ERROR_BAD_SYMBOL,  ERROR_COMPILER
	SHARED  ERROR_DUP_DECLARATION,  ERROR_DUP_DEFINITION,  ERROR_SCOPE_MISMATCH
	SHARED  ERROR_TOO_MANY_ARGS,  ERROR_TYPE_MISMATCH,  ERROR_UNDEFINED
	SHARED  func_number,  sharename$
	SHARED  funcKind[]
	SHARED  externalAddr
	SHARED  got_executable
	SHARED  compositeNumber[]
	SHARED  TOKEN  compositeToken[]
	SHARED  TOKEN  compositeNext[]
	SHARED  TOKEN  compositeStart[]
	SHARED UBYTE  charsetSymbolInner[]
	SHARED UBYTE  charsetBackslash[]
	STATIC GOADDR makeAddrKind[]
	STATIC GOADDR makeAddrAllo[]
	STATIC stealmax
'
	IFZ makeAddrKind[] THEN GOSUB InitArrays
	d_allo = token.tp.allo
	kind = token.tp.kind
	IF (kind > $$KIND_WHITES) THEN
		PRINT "AssignAddress(): Invalid kind", HEX$(token.tproto,8); "." HEX$(token.tindex,8)
		GOTO eeeCompiler
	END IF
	e = token.tindex
	tab_type = tabType[e]
	IFZ tab_type THEN
		d_type = TheType (token)
	ELSE
		d_type = tab_type
	END IF
'
' handle explicit #Shared and ##External scope
'
	a = d_allo                                        ' scope
	stealtype = 0                                     ' #: ##
	asymbol$ = tab_sym$[e]
	IF asymbol$ THEN                                  ' symbol$
		IF (asymbol${0} = '#') THEN                     ' # 1st byte
			a = $$SHARED                                  ' #SharedVariable
			IF (d_type == $$XLONG) THEN
				IF (asymbol${UBOUND(asymbol$)} != '~') THEN ' ~ specifies XLONG
					stealtype = got_executable                ' steal if also got executable
				END IF
			END IF
			IF (asymbol${1} = '#') THEN a = $$EXTERNAL    ' ##ExternalVariable
			IF d_allo THEN                                ' explicit scope in token
				IF (a != d_allo) THEN XcowlErr (70065): GOTO eeeScopeMismatch  ' AUTOX #Shared, ##External
			END IF
		ELSE
			IFZ (tab_type OR got_executable) THEN
				stealtype = $$TRUE
			END IF
		END IF
	END IF
'
	d_allo = a
	tab_sym[e].tp.allo = d_allo    ' put scope in token
'
	o_type = d_type
	alloType = d_type
'
	SELECT CASE d_allo
		CASE $$AUTO, $$AUTOX: f_num = func_number
		CASE $$ARGUMENT     : f_num = func_number
														IF (d_type >= $$SCOMPLEX) THEN
															alloType = $$XLONG
															d_type = $$XLONG
														END IF
		CASE ELSE           : f_num = 0
	END SELECT
'
	IF m_addr$[e] THEN
		IF (d_allo = $$ARGUMENT) THEN XcowlErr (70091): GOTO eeeDupDefinition    ' same argument twice
		RETURN
	END IF
'
' special allocation size cases
'
	SELECT CASE kind
'		CASE $$KIND_VARIABLES: IF (d_type < $$XLONG) THEN d_type = $$XLONG: alloType = $$XLONG      '*cw* 220909-
		CASE $$KIND_VARIABLES:	IF (d_type < $$XLONG) THEN                                          '*cw* 220909+
															d_type = $$XLONG: alloType = $$XLONG                              '*cw* 220909+
														ELSE                                                                '*cw* 220909+
															IF (d_type = $$SINGLE) THEN d_type = $$XLONG: alloType = $$XLONG  '*cw* 220909+
														END IF                                                              '*cw* 220909+
		CASE $$KIND_ARRAYS   : alloType = $$XLONG
	END SELECT
'
' get allocation size and alignment values
'
	IF (alloType < $$SCOMPLEX) THEN
		osize     = typeSize[alloType]
		osize$    = typeSize$[alloType]
		asize     = typeAlign[alloType]
		usize     = asize - 1
		amask     = -asize
		userType  = $$FALSE
	ELSE
		osize     = 8
		osize$    = "8"
		asize     = 8
		usize     = 7
		amask     = -8
		ccsize    = typeSize[alloType]
		align     = typeAlign[alloType]
		calign    = align - 1
		cmask     = -align
		userType  = $$TRUE
		onum      = compositeNumber[f_num]          ' old composite number
		nnum      = onum + 1                        ' new composite number
		compositeNumber[f_num] = nnum               ' ditto
		IFZ onum THEN                               ' 1st composite this function
			DIM ct[15]
			DIM cs[15]
			DIM cn[15]
			ATTACH ct[] TO compositeToken[f_num, ]
			ATTACH cs[] TO compositeStart[f_num, ]
			ATTACH cn[] TO compositeNext[f_num, ]
			IF f_num THEN scope = $$AUTOX ELSE scope = $$SHARED
			compositeToken = AddSymbol (".composites", 0, $$KIND_VARIABLES, scope, $$XLONG, f_num)
			compositeToken.tp.allo = scope
			tab_sym[compositeToken.tindex] = compositeToken
			compositeToken[f_num, 0] = compositeToken
			AssignAddress (compositeToken)
			IF XERROR THEN EXIT FUNCTION
		END IF
		IFZ nnum{4, 0} THEN                         ' if MOD 16, make more room
			unum    = onum + 16
'     PRINT "AssignAddress(142):unum: "; onum; " -> "; unum, f_num, nnum
			ATTACH compositeToken[f_num, ] TO ct[]
			ATTACH compositeStart[f_num, ] TO cs[]
			ATTACH compositeNext[f_num, ] TO cn[]
			REDIM ct[unum]
			REDIM cs[unum]
			REDIM cn[unum]
			ATTACH ct[] TO compositeToken[f_num,]
			ATTACH cs[] TO compositeStart[f_num,]
			ATTACH cn[] TO compositeNext[f_num,]
		END IF
		newStart  = compositeNext[f_num, onum]
		newStart.tindex = (newStart.tindex + calign) AND cmask
		newNext.tindex    = newStart.tindex + ccsize
		compositeToken[f_num, nnum] = token
		compositeStart[f_num, nnum] = newStart
		compositeNext[f_num, nnum] = newNext
	END IF
'
' Dispatch on basis of kind to routine to assign address
'
	GOTO @makeAddrKind[kind]
	PRINT "ass1", kind, HEX$(token.tproto, 8); "."; HEX$(token.tindex,8)
	XcowlErr (700165): GOTO eeeCompiler
'
'
' *********************************************************************
' *****  Routines to assign addresses to different kinds of data  *****
' *********************************************************************
'
' *****************************
' *****  $$KIND_CHARCONS  *****
' *****************************
'
make_addr_charcon:
	charcon$    = tab_sym$[e]
	chartest    = charcon${1}
	IF (chartest = '\\') THEN
		chartest  = charcon${2}
		chartest  = charsetBackslash[chartest]
	END IF
	r_addr$     = HEXX$ (chartest, 4)
	r_addr[e]   = $$IMM16
	r_addr$[e]  = r_addr$
	m_addr$[e]  = r_addr$
	RETURN
'
' ******************************
' *****  $$KIND_CONSTANTS  *****
' ******************************
'
make_addr_constant:
	IF (d_type = $$STRING) THEN
		IF m_addr$[e] THEN XcowlErr (700195): GOTO eeeDupDeclaration
		m_addr$[e] = "declared"
		RETURN
	END IF
	IF (d_allo != $$SHARED) THEN m_addr$[e] = "local": RETURN
	m_addr$[e]  = "shared.local"
	symbol$     = tab_sym$[e]
	ts = AddSymbol (symbol$, spaces, kind, allo, type, f_number)
	IF XERROR THEN RETURN
	tse     = ts.tindex
	r_addr  = r_addr[tse]
	IF r_addr THEN r_addr[e] = r_addr ELSE XcowlErr (700206): GOTO eeeUndefined
	token.tindex = tse
	tab_sym[e] = token                  ' point local entry at shared entry
	RETURN
'
' *****************************
' *****  $$KIND_LITERALS  *****
' *****************************
'
make_addr_literal:
	IF (d_type = $$STRING) THEN
		m_addr$       = $$ulat$ + "_string." + HEX$(e, 4)
		m_addr$[e]    = m_addr$
		RETURN
	END IF
'
	lit$    = tab_sym$[e]
	litLen  = LEN (lit$)
	lastOff = litLen - 1
	nonAsm  = $$FALSE
	suffix  = $$FALSE
	DO UNTIL charsetSymbolInner[lit${lastOff}]            ' strip type-suffix
		DEC lastOff
		test  = $$TRUE
	LOOP
	IF test THEN lit$ = LEFT$(lit$, lastOff+1)
	IF (litLen >= 2) THEN
		IF (lit${0} = '0') THEN
			IF ((lit${1} = 'b') OR (lit${1} = 'o')) THEN      ' "0b..." or "0o..."
				nonAsm  = $$TRUE
			END IF
		END IF
	END IF
'
	SELECT CASE token.tp.type
		CASE $$DOUBLE:  GOTO literalFLOAT
		CASE $$SINGLE:  GOTO literalFLOAT
		CASE $$GIANT:   GOTO literalGIANT
		CASE $$USHORT:  GOTO literalUSHORT
		CASE $$ULONG:   GOTO literalULONG
		CASE ELSE:      GOTO literalSLONG
	END SELECT
'
literalFLOAT:
	r_addr[e]   = $$LITNUM
	IF nonAsm THEN XcowlErr (700251): GOTO eeeCompiler
	r_addr$[e]  = lit$
	m_addr$[e]  = lit$
	RETURN
'
literalGIANT:
	r_addr[e]   = $$LITNUM
	IF nonAsm THEN lit$ = HEXX$(GIANT(lit$), 8)
	r_addr$[e]  = lit$
	m_addr$[e]  = lit$
	RETURN
'
literalSLONG:
	value       = XLONG (lit$)
	IF ((value < 0) AND (value >= -65535)) THEN
		r_addr[e] = $$NEG16
	ELSE
		r_addr[e] = $$LITNUM
	END IF
	IF nonAsm THEN lit$ = HEXX$(XLONG(lit$), 8)
	r_addr$[e]  = lit$
	m_addr$[e]  = lit$
	RETURN
'
literalUSHORT:
	r_addr[e]   = $$IMM16
	IF nonAsm THEN lit$ = HEXX$(XLONG(lit$), 8)
	r_addr$[e]  = lit$
	m_addr$[e]  = lit$
	RETURN
'
literalULONG:
	r_addr[e] = $$LITNUM
	IF nonAsm THEN lit$ = HEXX$(ULONG(lit$), 8)
	r_addr$[e]  = lit$
	m_addr$[e]  = lit$
	RETURN
'
' **************************************************
' *****  $$KIND_VARIABLES  and  $$KIND_ARRAYS  *****
' **************************************************
'
make_addr_array:
make_addr_variable:
	GOTO @makeAddrAllo[d_allo]
	PRINT "ass2"
	XcowlErr (700297): GOTO eeeCompiler
'
'
' ************************************************************************
' *****  FOR VARIABLES AND ARRAYS  ******  (and structures someday)  *****
' ************************************************************************
' *****  Routines to assign addresses to data of various allocation  *****
' ************************************************************************
'
' **********************
' *****  ARGUMENT  *****
' **********************
'
make_addr_argument:
	IF autoAddr[func_number] THEN XcowlErr (700311): GOTO eeeCompiler
	x_addr      = inargAddr[func_number]
	IFZ x_addr THEN x_addr = 16                'low 2 words = return addr, entry rbp
	IF (funcKind[func_number] == $$CFUNC) THEN  'CFUNCTION has 6 args in registers
		IF (arg_count < 6) THEN
			x_addr = (8 * arg_count) + 32
			GOTO make_addr_auto_arg
		ELSE
			IF (arg_count == 6) THEN x_addr = 16
			x_addr      = (x_addr + usize) AND amask
		END IF
	END IF
	m_addr$[e]  = "rbp" + SIGNED$ (x_addr)
	m_addr[e]   = x_addr
	m_reg[e]    = $$rbp
	z_addr      = x_addr + osize
	inargAddr[func_number] = z_addr
	IF (z_addr > 136) THEN XcowlErr (700328): GOTO eeeTooManyArgs
	RETURN
'
' ****************************
' *****  AUTO and AUTOX  *****
' ****************************
'
make_addr_auto:
make_addr_autox:
	x_addr      = autoxAddr[func_number]
	IF (x_addr < 40) THEN x_addr = 40
	x_addr      = ((x_addr + usize) AND amask) + asize
make_addr_auto_arg:
	m_reg[e]    = $$rbp
	m_addr[e]   = -x_addr
	m_addr$[e]  = "rbp" + STRING (-x_addr)
	autoxAddr[func_number] = x_addr
	RETURN
'
' ********************
' *****  STATIC  *****
' ********************
'
make_addr_static:
	IF (externalAddr < ##GLOBAL0) THEN externalAddr = ##GLOBAL0
	IF (externalAddr > ##GLOBALZ) THEN externalAddr = ##GLOBAL0
'	PRINT "AssignAddress(361)", HEX$(externalAddr)
	SELECT CASE kind
		CASE $$KIND_VARIABLES: symbol$ = $$ulpc$ + HEX$(func_number) + $$ulpc$ + tab_sym$[e]
		CASE $$KIND_ARRAYS   : symbol$ = $$ulpc2$ + HEX$(func_number) + $$ulpc2$ + tab_sym$[e]
'   CASE $$KIND_VARIABLES: symbol$ = "." + HEX$(func_number) + "." + tab_sym$[e]   ' post unspas
'   CASE $$KIND_ARRAYS   : symbol$ = "." + HEX$(func_number) + ".." + tab_sym$[e]  ' post unspas
	END SELECT
	x_addr        = (externalAddr + usize) AND amask
	symLen        = LEN (symbol$)
	last          = symbol${symLen-1}
	IFZ charsetSymbolInner[last] THEN AssemblerSymbol (@symbol$)
	IF m_addr[e] THEN XcowlErr (700365): GOTO eeeCompiler
	tabType[e]    = o_type
	m_addr$[e]    = symbol$
	m_addr[e]     = x_addr
	externalAddr  = x_addr + osize
	SELECT CASE TRUE
		CASE i486bin
		CASE i486asm: EmitData ()
									EmitNull (".align " + osize$)
									EmitNull (symbol$ + ":  .zero  " + osize$)
									EmitText ()
	END SELECT
	RETURN
'
' ********************
' *****  SHARED  *****
' ********************
'
make_addr_shared:
	IF (externalAddr < ##GLOBAL0) THEN externalAddr = ##GLOBAL0
	IF (externalAddr >= ##GLOBALZ) THEN externalAddr = ##GLOBAL0
'	PRINT "AssignAddress(393)", HEX$(externalAddr)
'
	asymbol$ = tab_sym$[e]
	symbol$ = tab_sym$[e]
'
	IFZ symbol$ THEN XcowlErr (700391): GOTO eeeCompiler
	IF $$linux THEN
		IF (symbol${0} = '#') THEN symbol${0} = '_'                         ' linux
	END IF
'
	SELECT CASE kind
		CASE $$KIND_VARIABLES: symbol$ = sharename$ + symbol$
		CASE $$KIND_ARRAYS   : symbol$ = sharename$ + $$ulpc2$ + symbol$ ' unspas compatible
'   CASE $$KIND_ARRAYS   : symbol$ = sharename$ + "." + symbol$        ' post unspas method
	END SELECT
'
	symLen        = LEN (symbol$)
	last          = symbol${symLen-1}
	IFZ charsetSymbolInner[last] THEN AssemblerSymbol (@symbol$)
'
	IF m_addr[e] THEN XcowlErr (700406): GOTO eeeCompiler
'
	ta = AddSymbol (@asymbol$, token.tp.stsp, token.tp.kind, token.tp.allo, token.tp.type, 0)
	ts = AddSymbol (@symbol$, token.tp.stsp, token.tp.kind, token.tp.allo, token.tp.type, 0)
	s = ts.tindex
	a = ta.tindex
	aaa = tabType[a]
	aas = tabType[s]
	aao = o_type
'
	IFZ func_number THEN
		stealmax = e
	ELSE
		IF (a <= stealmax) THEN
			IF stealtype THEN
				SELECT CASE TRUE
					CASE aaa: o_type = aaa
					CASE aas: o_type = aas
				END SELECT
			END IF
		END IF
	END IF
'
	tabType[e] = o_type
	symbol$ = $$ulpc$ + symbol$
'
	IF m_addr[s] THEN
		m_addr$[e]  = symbol$
		m_addr[e]   = m_addr[s]
		IF (tabType[s] != o_type) THEN XcowlErr (700435): GOTO eeeTypeMismatch
	ELSE
		x_addr  = (externalAddr + usize) AND amask
		m_addr$[e]    = symbol$
		m_addr$[s]    = symbol$
		m_addr[e]     = x_addr
		m_addr[s]     = x_addr
		tabType[s]    = o_type
		tabType[e]    = o_type
		externalAddr  = x_addr + osize
		SELECT CASE TRUE
			CASE i486bin
			CASE i486asm: EmitData ()
										EmitNull (".align " + osize$)
										EmitNull (symbol$ + ":  .zero  " + osize$)
										EmitText ()
		END SELECT
	END IF
	RETURN
'
'
' **********************
' *****  EXTERNAL  *****
' **********************
'
make_addr_external:
	IF (externalAddr < ##GLOBAL0) THEN externalAddr = ##GLOBAL0
	IF (externalAddr >= ##GLOBALZ) THEN externalAddr = ##GLOBAL0
'	PRINT "AssignAddress(463)", HEX$(externalAddr)
	IF (kind = $$KIND_ARRAYS) THEN array$ = $$ulpc$
'
	asymbol$ = sharename$ + tab_sym$[e]
	symbol$ = tab_sym$[e]
'
	IFZ symbol$ THEN XcowlErr (700469): GOTO eeeCompiler
	IF $$linux THEN
		IF (symbol${0} = '#') THEN symbol${0} = '_'               ' linux
		IF (symbol${1} = '#') THEN symbol${1} = '_'               ' linux
	END IF
'
	IFZ sharename$ THEN
		IF $$linux THEN
			symbol$ = array$ + symbol$
		ELSE
			symbol$ = "_" + array$ + symbol$
		END IF
	ELSE
		IF $$linux THEN
			symbol$ = sharename$ + array$ + symbol$
		ELSE
			symbol$ = "_" + sharename$ + array$ + symbol$
		END IF
	END IF
'
	symLen = LEN (symbol$)
	last = symbol${symLen-1}
	IFZ charsetSymbolInner[last] THEN AssemblerSymbol (@symbol$)
	ta = AddSymbol (@asymbol$, token.tp.stsp, token.tp.kind, token.tp.allo, token.tp.type, 0)
	ts = AddSymbol (@symbol$, token.tp.stsp, token.tp.kind, token.tp.allo, token.tp.type, 0)
	s = ts.tindex
	aaa = tabType[a]
	aas = tabType[s]
	aao = o_type
'
	IFZ func_number THEN
		stealmax = e
	ELSE
		IF (a <= stealmax) THEN
			IF stealtype THEN
				SELECT CASE TRUE
					CASE aaa: o_type = aaa
					CASE aas: o_type = aas
				END SELECT
			END IF
		END IF
	END IF
'
	IF tabType[s] THEN
		IF (tabType[s] != o_type) THEN XcowlErr (700513): GOTO eeeTypeMismatch
	ELSE
		tabType[s]      = o_type
	END IF
'
	tabType[e]        = o_type
'
	IF i486bin THEN
		exaddr          = XxxGetAddressGivenLabel (symbol$)
		IF exaddr THEN
			m_addr$[s]    = symbol$
			m_addr$[e]    = symbol$
			m_addr[s]     = exaddr
			m_addr[e]     = exaddr
			RETURN
		END IF
	END IF
'
	IF m_addr$[s] THEN
		m_addr$[e]    = m_addr$[s]
		m_addr[e]     = m_addr[s]
		m_reg[e]      = m_reg[s]
	ELSE
		labelToken    = AddLabel (@symbol$, $$KIND_LABELS, 0, $$XADD)
		ln            = labelToken.tindex
		labaddr       = labaddr[ln]
		IF labaddr THEN
			x_addr = labaddr
		ELSE
			x_addr      = (externalAddr + usize) AND amask
'     labaddr[ln] = x_addr
		END IF
		m_reg[s]      = 0
		m_reg[e]      = 0
		m_addr[s]     = x_addr
		m_addr[e]     = x_addr
		m_addr$       = symbol$
		m_addr$[e]    = m_addr$
		m_addr$[s]    = m_addr$
		externalAddr  = x_addr + osize
		tabType[s]    = tabType[e]
		SELECT CASE TRUE
			CASE i486bin: IF (##GLOBAL >= ##GLOBALZ) THEN XcowlErr (700555): GOTO eeeCompiler
										IFZ labaddr THEN
											##GLOBAL    = x_addr
											##GLOBALX   = x_addr
										END IF
			CASE i486asm: EmitData ()
										EmitNull (".comm  " + symbol$ + ",  " + osize$ + "")
										EmitText ()
		END SELECT
	END IF
	RETURN
'
'
' *****************************
' *****  SUB  InitArrays  *****
' *****************************
'
SUB InitArrays
	DIM makeAddrKind[31]
	makeAddrKind[ $$KIND_VARIABLES ] = GOADDRESS (make_addr_variable)
	makeAddrKind[ $$KIND_CONSTANTS ] = GOADDRESS (make_addr_constant)
	makeAddrKind[ $$KIND_SYSCONS   ] = GOADDRESS (make_addr_constant)
	makeAddrKind[ $$KIND_LITERALS  ] = GOADDRESS (make_addr_literal)
	makeAddrKind[ $$KIND_CHARCONS  ] = GOADDRESS (make_addr_charcon)
	makeAddrKind[ $$KIND_ARRAYS    ] = GOADDRESS (make_addr_array)
	makeAddrKind[ $$KIND_FUNCTIONS ] = GOADDRESS (make_addr_function)
'
	DIM makeAddrAllo[31]
	makeAddrAllo[ $$AUTO      ] = GOADDRESS (make_addr_auto)
	makeAddrAllo[ $$AUTOX     ] = GOADDRESS (make_addr_autox)
	makeAddrAllo[ $$STATIC    ] = GOADDRESS (make_addr_static)
	makeAddrAllo[ $$SHARED    ] = GOADDRESS (make_addr_shared)
	makeAddrAllo[ $$EXTERNAL  ] = GOADDRESS (make_addr_external)
	makeAddrAllo[ $$ARGUMENT  ] = GOADDRESS (make_addr_argument)
END SUB
'
make_addr_function:
	PRINT "ass4"
	XcowlErr (700593): GOTO eeeCompiler
	EXIT FUNCTION
'
'
' ********************
' *****  ERRORS  *****
' ********************
'
eeeBadCharcon:
	XERROR = ERROR_BAD_CHARCON
	EXIT FUNCTION
'
eeeBadSymbol:
	XERROR = ERROR_BAD_SYMBOL
	EXIT FUNCTION
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeDupDeclaration:
	XERROR = ERROR_DUP_DECLARATION
	EXIT FUNCTION
'
eeeDupDefinition:
	XERROR = ERROR_DUP_DEFINITION
	EXIT FUNCTION
'
eeeScopeMismatch:
	XERROR = ERROR_SCOPE_MISMATCH
'
eeeTooManyArgs:
	XERROR = ERROR_TOO_MANY_ARGS
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
'
eeeUndefined:
	XERROR = ERROR_UNDEFINED
	EXIT FUNCTION
END FUNCTION
'
'
' ################################
' #####  AssignComposite ()  #####
' ################################
'
FUNCTION  AssignComposite (d_reg, d_type, s_reg, s_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED  typeSize[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_TYPE_MISMATCH
'
	IF (d_type != s_type) THEN XcowlErr (80012): GOTO eeeTypeMismatch
	IFZ d_reg THEN XcowlErr (80013): GOTO eeeCompiler
	IFZ s_reg THEN XcowlErr (80014): GOTO eeeCompiler
'
	IF (d_reg != $$rdi) THEN Move ($$rdi, $$XLONG, d_reg, $$XLONG)
	IF (s_reg != $$rsi) THEN Move ($$rsi, $$XLONG, s_reg, $$XLONG)
'
	Code ($$mov, $$regimm, $$rcx, typeSize[d_type], 0, $$XLONG, "", $$rmk$+"1")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_AssignComposite", $$rmk$+"2")
	EXIT FUNCTION
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' #####################
' #####  AtOps () #####
' #####################
'
FUNCTION  AtOps (xtype, opcode, mode, base, offset, source)
	TOKEN   token, newOpToken, baseToken, offsetToken
	SHARED  r_addr[],  r_addr$[],  typeSize[]
	SHARED  q_type_long[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_SYNTAX
	SHARED  ERROR_TOO_FEW_ARGS,  ERROR_TYPE_MISMATCH
	SHARED  toes,  toms,  stackType[]
'
	stacked = 0
	htoes   = toes
	float   = $$FALSE
	scale   = $$FALSE
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (90020): GOTO eeeSyntax
	SELECT CASE xtype
		CASE $$SINGLE, $$DOUBLE
					float = $$TRUE
					SELECT CASE opcode
						CASE $$ld:  opcode  = $$fld
						CASE $$st:  opcode  = $$fstp
					END SELECT
	END SELECT
'
' Get base address
'
	new_test = 0: new_prec = 0: baseType = 0
	newOpToken = #T_ZERO
	baseToken = #T_ZERO
	Expresso (@new_test, @newOpToken, @new_prec, @baseToken, @baseType)
	IF XERROR THEN EXIT FUNCTION
	IFF q_type_long[baseType] THEN XcowlErr (90037): GOTO eeeTypeMismatch
	SELECT CASE TRUE
		CASE TokenMatch (@newOpToken, @#T_RPAREN): shortForm = $$TRUE: GOTO shortForm
		CASE TokenMatch (@newOpToken, @#T_COMMA) : shortForm = $$FALSE
		CASE ELSE    : XcowlErr (90041): GOTO eeeSyntax
	END SELECT
'
' form with base and offset
'
	PeekToken (@token)
	IF TokenMatch (@token, @#T_LBRAK) THEN                 ' "["
		scale   = $$TRUE
		NextToken (@token)
	END IF
'
	new_test = 0: new_prec = 0: offsetType = 0
	newOpToken = #T_ZERO
	offsetToken = #T_ZERO
	Expresso (@new_test, @newOpToken, @new_prec, @offsetToken, @offsetType)
	IF XERROR THEN EXIT FUNCTION
	IFZ offsetType THEN XcowlErr (90057): GOTO eeeTooFewArgs
	IF scale THEN
		IFF TokenMatch (@newOpToken, @#T_RBRAK) THEN XcowlErr (90059): GOTO eeeSyntax
		NextToken (@newOpToken)
	END IF
	IFF TokenMatch (@newOpToken, @#T_RPAREN) THEN XcowlErr (90062): GOTO eeeSyntax
	IFF q_type_long[offsetType] THEN XcowlErr (90063): GOTO eeeTypeMismatch
'
	IFF TokenMatch (@offsetToken, @#T_ZERO) THEN
		IF r_addr[offsetToken.tindex] THEN
			offset    = XLONG (r_addr$[offsetToken.tindex])
			IF scale THEN
				scale   = $$FALSE
				offimm  = $$TRUE
				offset  = offset * typeSize[xtype]
			ELSE
				offimm  = $$TRUE
			END IF
		ELSE
			offimm    = $$FALSE
			offset    = $$rdi
			Move (offset, $$XLONG, offsetToken.tindex, $$XLONG)
		END IF
	ELSE
		offimm      = $$FALSE
		stacked     = stacked + 1
	END IF
'
shortForm:
	IFF TokenMatch (@baseToken, @#T_ZERO) THEN
		base      = $$rsi
		Move (base, $$XLONG, baseToken.tindex, $$XLONG)
	ELSE
		stacked   = stacked + 2
	END IF
'
	IF source THEN
		SELECT CASE stacked
			CASE 0:   source = Topax1 ()
			CASE 1:   Topax2 (@offset, @source)
			CASE 2:   Topax2 (@base, @source)
			CASE 3:   Topax2 (@offset, @base)
								Pop ($$rsi, stackType[toms-1])
								source  = $$rsi
								DEC toes
		END SELECT
	ELSE
		SELECT CASE stacked
			CASE 1:   offset  = Topax1 ()
			CASE 2:   base    = Topax1 ()
			CASE 3:   Topax2 (@offset, @base)
		END SELECT
	END IF
'
	IF shortForm THEN
		SELECT CASE opcode
			CASE $$ld:      mode  = $$regr0
			CASE $$st:      mode  = $$r0reg
			CASE $$fld:     mode  = $$r0
			CASE $$fstp:    mode  = $$r0
		END SELECT
	ELSE
		IF scale THEN
			IF offimm THEN
			XcowlErr (900121): GOTO eeeCompiler
			ELSE
				SELECT CASE opcode
					CASE $$ld:    mode  = $$regrs
					CASE $$st:    mode  = $$rsreg
					CASE $$fld:   mode  = $$rs
					CASE $$fstp:  mode  = $$rs
				END SELECT
			END IF
		ELSE
			IF offimm THEN
				SELECT CASE opcode
					CASE $$ld:    mode  = $$regro
					CASE $$st:    mode  = $$roreg
					CASE $$fld:   mode  = $$ro
					CASE $$fstp:  mode  = $$ro
				END SELECT
			ELSE
				SELECT CASE opcode
					CASE $$ld:    mode  = $$regrr
					CASE $$st:    mode  = $$rrreg
					CASE $$fld:   mode  = $$rr
					CASE $$fstp:  mode  = $$rr
				END SELECT
			END IF
		END IF
	END IF
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooFewArgs:
	XERROR = ERROR_TOO_FEW_ARGS
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ######################################
' #####  BinStringToAsmString$ ()  #####
' ######################################
'
' Convert string with unprintable bytes (0x00 - 0x1F and 0x80 - 0xFF) into
' a string with all unprintable bytes converted into assembler compatible
' backslash sequences.
'
' NOTE:  0x22 converted to \"
' NOTE:  0x5C converted to \\
' NOTE:  0x00 - 0x06 converted to \OOO form
' NOTE:  0x07 - 0x0D converted to \a  \b  \t  \n  \v  \f  \r
' NOTE:  0x0E - 0x1F converted to \OOO form
' NOTE:  0x7F - 0xFF converted to \OOO form
'
FUNCTION  BinStringToAsmString$ (rawString$)
	SHARED UBYTE  charsetNormalChar[]
	SHARED UBYTE  charsetBackslashChar[]
	SHARED assemblerBackslashAsm$[]
'
	FOR i = 1 TO LEN (rawString$)
		rawChar = ASC (rawString$, i)
		rawByte = charsetNormalChar[rawChar]
		IF rawByte THEN
			newString$ = newString$ + CHR$ (rawByte)
		ELSE
			rawByte = charsetBackslashChar[rawChar]
			IF rawByte THEN
				newString$ = newString$ + "\\" + CHR$ (rawByte)             ' \.
			ELSE
				newString$ = newString$ + assemblerBackslashAsm$[rawChar]   '\ooo
			END IF
		END IF
	NEXT i
	RETURN (newString$)
END FUNCTION
'
'
' #############################
' #####  CheckOneLine ()  #####
' #############################
'
FUNCTION  CheckOneLine ()
'	EXTERNAL /xxx/  i486asm
	EXTERNAL /xxx/  xpc, i486asm, i486bin
	TOKEN   token, token2
	SHARED  TOKEN   tokens[]
	SHARED  XERROR
	SHARED  ifLine,  tokenPtr
	SHARED  export
	SHARED  stopComment
	SHARED  lineNumber
'
	ifLine      = 0
	tokenPtr    = 0
	NextToken (@token): tp1 = tokenPtr
	tokenPtr    = tp1
	count = tokens[0].ti.ndex
'
	compileLine = $$TRUE
	IF export THEN GOSUB Export
	IF (count < 2) THEN compileLine = $$FALSE
	IF (token.tp.kind = $$KIND_COMMENTS) THEN compileLine = $$FALSE
'
	IF i486asm THEN
		IFZ stopComment THEN
			deparse$ = Deparse$ ("")
			IF deparse$ THEN
				IF (LTRIM$(deparse$){0} == 39) THEN     ' (comment character)
					EmitNull ($$rmk1$ + " " + LTRIM$(deparse$))		' emit comment line only
				ELSE
					EmitNull ($$rmk1$ + "\n" + $$rmk1$ + " " + LTRIM$(deparse$))  ' emit source line as comment
				END IF
			ELSE
					EmitNull ($$rmk1$)		' emit blank line as comment
			END IF
		END IF
	END IF
'
	IFZ compileLine THEN RETURN
	tokenPtr = tp1
'
	GOSUB DebugTrace                                                            '*cw* for testing only
'
	DO
		CheckState (@token)
		IF XERROR THEN EXIT DO
		SELECT CASE token.tp.kind
			CASE $$KIND_STARTS, $$KIND_COMMENTS: EXIT DO
		END SELECT
	LOOP
'
	RETURN
'
' --------------------------------------------------------------------------
'
' *****  Export  *****
'
SUB Export
	IF (token.tproto == $$TP_STATEMENTS) THEN
		NextToken (@token2)
		SELECT CASE token.tindex
			CASE #T_END.tindex    : IF TokenMatch (@token2, @#T_EXPORT) THEN
																	compileLine = $$FALSE
																	export = $$FALSE
																	EXIT SUB
																END IF
																deparse$ = Deparse$ ("")
																WriteDeclarationFile (@deparse$)
																EXIT SUB
			CASE #T_EXPORT.tindex : compileLine = $$FALSE
																EXIT SUB
			CASE #T_DECLARE.tindex: IF (token2.tproto == $$TP_STATEMENTS) THEN
																SELECT CASE token2.tindex
																	CASE #T_FUNCTION.tindex, #T_SFUNCTION.tindex, #T_CFUNCTION.tindex:
																				deparse$ = Deparse$ ("")
																				d = INSTR (deparse$, "DECLARE")
																				deparse$ = LEFT$ (deparse$,d-1) + "EXTERNAL" + MID$ (deparse$, d+7)
																				WriteDeclarationFile (@deparse$)
																				EXIT SUB
																END SELECT
															END IF
			CASE #T_INTERNAL.tindex: IF (token2.tproto == $$TP_STATEMENTS) THEN
																	SELECT CASE token2.tindex
																		CASE #T_FUNCTION.tindex : EXIT SUB
																		CASE #T_SFUNCTION.tindex: EXIT SUB
																		CASE #T_CFUNCTION.tindex: EXIT SUB
																	END SELECT
																	' do not include INTERNAL xFUNCTION lines
																END IF
		END SELECT
	END IF
	deparse$ = Deparse$ ("")
	WriteDeclarationFile (@deparse$)
END SUB
'
'
' *****  DebugTrace  *****     '*cw* for testing only
'
SUB DebugTrace
	IFZ ##WHOMASK THEN EXIT SUB
	IFZ ##XBDV THEN EXIT SUB
	IFZ #traceStart THEN EXIT SUB
	IF (lineNumber > #traceStop) THEN
		##TRACE = $$FALSE
		log = ##TRACE
		EXIT SUB
	END IF
	'
	IF (lineNumber >= #traceStart) THEN
		PRINT
		PRINT "CheckOneLine(112) line number", lineNumber, deparse$
		FOR i = 0 TO count
			PRINT i, HEX$(tokens[i].tproto,8); "."; HEX$(tokens[i].tindex,8)
		NEXT i
		##TRACE = lineNumber
'		log = ##TRACE
'
'		DIM bin@@[1023]
'		xpc = &bin@@[]
'		i486bin = $$TRUE
'		i486asm = $$FALSE
'
		STOP
	END IF
'
END SUB
'
END FUNCTION
'
'
' ###########################
' #####  CheckState ()  #####
' ###########################
'
FUNCTION  CheckState (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc,  library
	EXTERNAL /xxx/  checkBounds,  errorCount,  entryFunction
	EXTERNAL /xxx/  litStringAddr,  maxFuncNumber
	EXTERNAL /xxx/  runAssm
	EXTERNAL /xxx/  needMoreMemory
	TOKEN check, ctoken, typeToken, testToken, eleToken
	TOKEN hold_token, old_data, ot, new_op, new_data, s_data, s_op
	TOKEN funcToken, function_token, temp[], tempArg, tempArg[], tokTmp, funcaddrArg[]
	TOKEN check1, check2, d_reg
	TOKEN nestObject, nestToken, checkToken, levelToken, dbtoken, tk, stk, p2
	TOKEN cregToken
	TOKEN forToken, fltoken, fstoken, funcArg, anyArg, ftoken, rtoken, s_token, stoken
	TOKEN dtoken, termToken, dbase, wtoken
	TOKEN compositeToken, compositeStart, compositeNext, base
	TOKEN itk
'
	SHARED  TOKEN crvtoken
	SHARED  TOKEN compositeNext[]
	SHARED  TOKEN compositeStart[]
	SHARED  TOKEN compositeToken[]
	SHARED  TOKEN errToken[]
	SHARED  TOKEN funcArg[]
	SHARED  TOKEN funcToken[]
	SHARED  TOKEN nestToken[]
	SHARED  TOKEN nestVar[]
	SHARED  TOKEN patchDest[]
	SHARED  TOKEN tabArg[]
	SHARED  TOKEN tab_lab[]
	SHARED  TOKEN tab_sym[]
	SHARED  TOKEN typeEleArg[]
	SHARED  TOKEN typeEleToken[]
	SHARED  TOKEN typeToken[]
'
	STATIC TOKEN typeType
'
	SHARED SSHORT typeConvert[]
	SHARED UBYTE  charsetSymbolInner[]
	SHARED  arg_count
	SHARED  libraryName$[]
	SHARED  m_reg[],  m_addr[],  m_addr$[]
	SHARED  autoAddr[],  autoxAddr[],  inargAddr[],  defaultType[]
	SHARED  patchType[],  patchAddr[]
	SHARED  xargNum,  xargAddr[],  xargName$[]
	SHARED  typeSize[],  typeAlias[],  typeAlign[]
	SHARED  typeEleCount[]
	SHARED  typeEleSymbol$[]
	SHARED  typeEleSize[],  typeEleType[]
	SHARED  typeEleAddr[],  typeEleVal[],  typeElePtr[]
	SHARED  typeEleStringSize[],  typeEleUBound[]
	SHARED  funcFrameSize[]
	SHARED  funcSymbol$[],  funcLabel$[]
	SHARED  funcScope[],  funcKind[],  funcType[],  funcArgSize[]
	SHARED  hash%[]
	SHARED  labelPtr
	SHARED  nestCount[],  nestInfo[],  nestLevel[],  nestLimit[]
	SHARED  nestStep[],  q_type_long[]
	SHARED  r_addr$[],  r_addr[]
	SHARED  tabType[],  tab_sym$[]
	SHARED  tab_lab$[],  labaddr[]
	SHARED  compositeNumber[]
	SHARED  errSymbol$[],  errAddr[]
	SHARED  ERROR_AFTER_ELSE,  ERROR_BAD_CASE_ALL
	SHARED  ERROR_BAD_GOTO,  ERROR_BAD_GOSUB,  ERROR_BAD_SYMBOL
	SHARED  ERROR_COMPILER,  ERROR_COMPONENT,  ERROR_CROSSED_FUNCTIONS
	SHARED  ERROR_DECLARE,  ERROR_DECLARE_FUNCS_FIRST
	SHARED  ERROR_DUP_DECLARATION,  ERROR_DUP_DEFINITION,  ERROR_DUP_TYPE
	SHARED  ERROR_DUP_MISMATCH
	SHARED  ERROR_ELSE_IN_CASE_ALL,  ERROR_ENTRY_FUNCTION
	SHARED  ERROR_EXPECT_ASSIGNMENT,  ERROR_EXPRESSION_STACK
	SHARED  ERROR_INTERNAL_EXTERNAL
	SHARED  ERROR_KIND_MISMATCH
	SHARED  ERROR_NEED_EXCESS_COMMA,  ERROR_NEED_SUBSCRIPT
	SHARED  ERROR_NEST,  ERROR_NODE_DATA_MISMATCH
	SHARED  ERROR_NEST_DO, ERROR_NEST_FOR, ERROR_NEST_IF, ERROR_NEST_SELECT, ERROR_NEST_SUB
	SHARED  ERROR_OUTSIDE_FUNCTIONS,  ERROR_OVERFLOW,  ERROR_PROGRAM_NOT_NAMED
	SHARED  ERROR_SCOPE_MISMATCH,  ERROR_SHARENAME,  ERROR_SYNTAX
	SHARED  ERROR_TOO_FEW_ARGS,  ERROR_TOO_LATE,  ERROR_TOO_MANY_ARGS
	SHARED  ERROR_TYPE_MISMATCH,  ERROR_UNDECLARED,  ERROR_UNDEFINED
	SHARED  ERROR_UNIMPLEMENTED,  ERROR_WITHIN_FUNCTION
	SHARED  XERROR
	SHARED  a0,  a0_type,  a1,  a1_type,  caseCount
	SHARED  dim_array
	SHARED  redim_array
	SHARED  excessComma
	SHARED  end_program
	SHARED  export
	SHARED  func_number
	SHARED  got_declare,  got_executable,  got_function
	SHARED  got_object_declaration,  got_type
	SHARED  hfn$,  ifLine,  insub,  insub$
	SHARED  libraryFunctionLabel$
	SHARED  nestCount,  nestLevel,  nestError
	SHARED  oos,  patchPtr
	SHARED  sharename$,  subCount,  tab_sym_ptr
	SHARED  toes,  tokenPtr,  toms,  xit,  labelNumber
	SHARED  inTYPE,  inUNION,  compositeArg,  comStk
	SHARED  UBYTE oos[]
	SHARED  pass2errors,  prologCode,  preExports,  program$,  programName$,  programPath$
	SHARED  externalAddr
	STATIC  funcKind,  eleCount,  eleCountUNION,  addrUNION,  uEle
	STATIC  typeNumber,  typeThisAddr,  typeNextAddr,  typeMaxAlign
	STATIC  first_static,  last_static
	STATIC  tsymbol$[]
	STATIC  TOKEN ttoken[]
	STATIC  tsize[]
	STATIC  taddr[]
	STATIC  ttype[]
	STATIC  TOKEN atype[]
	STATIC  tval[]
	STATIC  tptr[]
	STATIC  tss[]
	STATIC  tub[]
	STATIC  TOKEN arg[]
	STATIC GOADDR  typeBeforeFunc[]
	STATIC GOADDR  kindBeforeFunc[]
	STATIC GOADDR  stateBeforeFunc[]
	STATIC GOADDR  kindAfterFunc[]
	STATIC GOADDR  stateAfterFunc[]
'
' Initialize computed GOTO arrays on 1st entry to this function
'
	IFZ kindBeforeFunc[] THEN
		GOSUB TypeBeforeFunc    ' dispatch based on types before 1st FUNCTION
		GOSUB KindBeforeFunc    ' dispatch based on KIND before 1st FUNCTION
		GOSUB StateBeforeFunc   ' dispatch based on TOKEN # before 1st FUNCTION
		GOSUB KindAfterFunc     ' dispatch based on KIND after 1st FUNCTION
		GOSUB StateAfterFunc    ' dispatch based on TOKEN # after 1st FUNCTION
	END IF
	IF XERROR THEN EXIT FUNCTION
'
	comStk = 0
	kind = token.tp.kind
	tt = token.tindex
'
	SELECT CASE kind
		CASE $$KIND_STARTS, $$KIND_COMMENTS:
				RETURN
	END SELECT
'
	IF got_function THEN GOTO past_declares
	IF typeNumber THEN GOTO p_intype
'
' ****************************************************
' *****  if 1st FUNCTION is not yet encountered  *****
' *****  dispatch based on kindBeforeFunc[kind]  *****
' ****************************************************
'
	pallo = 0
	GOTO @kindBeforeFunc[kind]    ' dispatch on basis of KIND of token
	XcowlErr (1200157): GOTO eeeOutsideFunctions     ' any other kind is an error before 1st func
'
' kindBeforeFunc[kind] may invoke one of the following...
'
b_types:IF got_declare THEN GOTO p_types ELSE XcowlErr (1200161): GOTO eeeDeclareFuncs
b_syscons:GOTO assign_syscons
b_constants:GOTO assign_constants
b_comments:RETURN
b_starts:RETURN
b_terminators: NextToken (@token): RETURN
b_statements:IF got_declare THEN GOTO @typeBeforeFunc[tt] ' data-type: presume SHARED scope
								GOTO @stateBeforeFunc[tt]   ' statements before 1st function
								XcowlErr (1200169): GOTO eeeOutsideFunctions   ' if invalid before 1st function
'
' stateBeforeFunc[tt] may invoke one of the following...
'
b_all:       GOTO p_all
b_shared:    IF got_declare THEN GOTO p_shared ELSE XcowlErr (1200174): GOTO eeeDeclareFuncs
b_function:  funcKind = $$XFUNC:            GOTO p_xfunction
b_sfunction: funcKind = $$SFUNC:            GOTO p_xfunction
b_cfunction: funcKind = $$CFUNC:            GOTO p_xfunction
b_declare:   funcScope = $$FUNC_DECLARE:    GOTO p_declare_func
b_internal:  funcScope = $$FUNC_INTERNAL: GOTO p_internal_func
b_external:  funcScope = $$FUNC_EXTERNAL
							PeekToken (@check)
							SELECT CASE TRUE
								CASE TokenMatch (@check, @#T_FUNCTION): GOTO p_external_func
								CASE TokenMatch (@check, @#T_SFUNCTION): GOTO p_external_func
								CASE TokenMatch (@check, @#T_CFUNCTION): GOTO p_external_func
							END SELECT
							IF got_declare THEN GOTO p_external ELSE XcowlErr (1200187): GOTO eeeDeclareFuncs
b_packed:  typeType = #T_PACKED: GOTO p_type
b_type:    typeType = #T_TYPE: GOTO p_type
b_union:   XcowlErr (1200190): GOTO eeeSyntax
b_import:  StatementImport (@token): RETURN
b_export:  StatementExport (@token): RETURN
b_library: StatementImport (@token): RETURN
b_program: StatementProgram (@token): RETURN
b_version: StatementVersion (@token): RETURN
b_end:     NextToken (@token)
						IFF TokenMatch (@token, @#T_EXPORT) THEN XcowlErr (1200197): GOTO eeeSyntax
						IFZ export THEN XcowlErr (1200198): GOTO eeeNest
						export = $$FALSE
						token.tproto = $$TP_STARTS
						token.tindex = $$TI_ZERO
						RETURN
'
'
' ************************************
' If 1st FUNCTION has been encountered, dispatch based on kindAfterFunc[kind]
' ************************************
'
past_declares:
	GOTO @kindAfterFunc[kind]              ' dispatch on basis of KIND of token
	XcowlErr (1200211): GOTO eeeSyntax     ' if invalid KIND when expecting statement
'
' kindAfterFunc[kind] may invoke one of the following...
'
a_variables:GOTO assign_variables
a_arrays:GOTO assign_array
a_constants:GOTO assign_constants
a_functions:GOTO p_func
a_labels:GOTO p_label
a_starts:RETURN
a_comments:RETURN
a_whites: NextToken (@token): RETURN
a_terminators: NextToken (@token): RETURN
a_characters:SELECT CASE TRUE
									CASE TokenMatch (@token, @#T_ATSIGN): GOTO p_atsign
									CASE ELSE:      XcowlErr (1200226): GOTO eeeSyntax
								END SELECT
a_types:GOTO p_user_type
a_addr_ops:GOTO p_addr_ops
a_intrinsics:SELECT CASE TRUE
									CASE TokenMatch (@token, @#T_CLOSE)  : GOTO p_close
									CASE TokenMatch (@token, @#T_INLINE_D): GOTO p_inline_d
									CASE TokenMatch (@token, @#T_QUIT)   : GOTO p_quit
									CASE TokenMatch (@token, @#T_SEEK)   : GOTO p_seek
									CASE TokenMatch (@token, @#T_SHELL)  : GOTO p_shell
									CASE TokenMatch (@token, @#T_MID_D)  : GOTO assignMidString
									CASE ELSE:       XcowlErr (1200237)  : GOTO eeeSyntax
								END SELECT
a_statements:
a_state_intrin:GOTO @stateAfterFunc[tt]
								XcowlErr (1200241): GOTO eeeSyntax
'
'
' stateAfterFunc[tt] may invoke one of the following...
'
p_if:ifc = $$FALSE:         GOTO p_ifx
p_ift:ifc = $$FALSE:          GOTO p_ifx
p_ifz:ifc = $$TRUE:           GOTO p_ifx
p_iff:ifc = $$TRUE:           GOTO p_ifx
p_function:funcKind = $$XFUNC:      GOTO p_xfunction
p_sfunction:funcKind = $$SFUNC:     GOTO p_xfunction
p_cfunction:funcKind = $$CFUNC:     GOTO p_xfunction
'
'
' *************************************
' *****  ASSIGNMENT TO CONSTANTS  *****
' *************************************
'
assign_syscons:
	IF got_function THEN XcowlErr (1200260): GOTO eeeTooLate
	syscon = $$TRUE
	GOTO assign_constantx
'
assign_constants:
	IF (got_function = $$FALSE) THEN XcowlErr (1200265): GOTO eeeOutsideFunctions
	IF got_executable THEN XcowlErr (1200266): GOTO eeeTooLate
	syscon = $$FALSE
'
assign_constantx:
	ctoken      = token
	hold_place  = tokenPtr
	cc          = token.tindex
	ctype       = token.tp.type
	callo       = token.tp.allo
	dupDef = $$FALSE
	IF r_addr$[cc] THEN dupDef = $$TRUE
	IF dupDef THEN
		PRINT "CheckState(278)dupDef", ctype, $$STRING, tab_sym$[cc], r_addr$[cc]
	END IF
	NextToken (@token)
	IFF TokenMatch (@token, @#T_EQ) THEN XcowlErr (1200281): GOTO eeeSyntax
	NextToken (@token)
	IF TokenMatch (@token, @#T_BITFIELD) THEN
		NextToken (@token)
		IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (1200285): GOTO eeeSyntax
		NextToken (@token)
		bitCheck = $$TRUE
		bitPass = $$FALSE
	ELSE
		bitCheck = $$FALSE
	END IF
	IF (ctype = $$STRING) THEN GOTO assign_to_string_constant
'
' now look at value to assign to constant
'
bitLoop:
	IF TokenMatch (@token, @#T_SUBTRACT) THEN
		IF bitCheck THEN XcowlErr (1200298): GOTO eeeSyntax
		NextToken (@token)
		nc = $$TRUE
	ELSE
		nc = $$FALSE
	END IF
	vv = token.tindex
	IFZ m_addr$[vv] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
	vkind = token.tp.kind
	SELECT CASE vkind
		CASE $$KIND_LITERALS, $$KIND_CONSTANTS, $$KIND_SYSCONS
		CASE $$KIND_CHARCONS
					vtype = $$USHORT
					IF nc THEN XcowlErr (1200312): GOTO eeeSyntax
		CASE ELSE: XcowlErr (1200313): GOTO eeeSyntax
	END SELECT
	vtype = TheType (token)
	IF (vtype = $$STRING) THEN XcowlErr (1200316): GOTO eeeTypeMismatch
	IFF r_addr$[vv] THEN XcowlErr (1200317): GOTO eeeUndefined
	IF nc THEN vs$ = "-" + r_addr$[vv] ELSE vs$ = r_addr$[vv]
	IF (vtype = $$GIANT) THEN
		vs$$  = GIANT (vs$)
		vs#   = vs$$
	ELSE
		vs#   = DOUBLE (vs$)
	END IF
	IF nc THEN GOTO acx
'
acc:
	SELECT CASE vtype
		CASE $$SBYTE, $$SSHORT
			r_addr = $$NEG16:  ctype = vtype: GOTO acf
		CASE $$UBYTE, $$USHORT
			r_addr = $$IMM16:  ctype = vtype: GOTO acf
		CASE $$GIANT, $$SINGLE, $$DOUBLE
			r_addr = $$LITNUM: ctype = vtype: GOTO acf
	END SELECT
'
acx:
	SELECT CASE TRUE
		CASE ((vs# > 0) AND (vs# <= 65535))
				r_addr = $$IMM16:  ctype = $$USHORT
		CASE ((vs# >= -65535) AND (vs# < 0))
				r_addr = $$NEG16:  ctype = $$SLONG
		CASE ELSE
				r_addr = $$LITNUM
				IF (vtype = $$GIANT) THEN
					q_type = MinTypeFromGiant (vs$$)
					IF (q_type < $$GIANT) THEN
						ctype = q_type
					ELSE
						ctype = $$GIANT
					END IF
				ELSE
					ctype = vtype
				END IF
	END SELECT
'
acf:
	IF bitCheck THEN
		IF ((vs# < 0) OR (vs# > 63)) THEN XcowlErr (1200359): GOTO eeeOverflow
		IF bitPass THEN
			bitOffset = vs#
			bitValue = (bitWidth << 6) + bitOffset
			vs$ = HEXX$(bitValue, 4)
			ctype = $$USHORT
		ELSE
			bitWidth = vs#
			bitPass = $$TRUE
			NextToken (@token)
			IFF TokenMatch (@token, @#T_COMMA) THEN XcowlErr (1200369): GOTO eeeSyntax
			NextToken (@token)
			GOTO bitLoop
		END IF
	END IF
	IF dupDef THEN
		IF (r_addr$[cc] != vs$) THEN PRINT "CheckState(375)", r_addr$[cc], vs$
		IF (r_addr$[cc] != vs$) THEN XcowlErr (1200376): GOTO eeeDupMismatch
	END IF
	r_addr[cc]  = r_addr
	r_addr$[cc] = vs$
	tabType[cc] = ctype
	ctoken.tp.type = ctype
	UpdateToken (ctoken)
	NextToken (@token)
	IF bitCheck THEN
		IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (1200385): GOTO eeeSyntax
		NextToken (@token)
	END IF
	RETURN
'
assign_to_string_constant:
	ctoken.tp.allo = $$EXTERNAL
	tab_sym[cc] = ctoken
	vv = token.tindex
	vkind = token.tp.kind
	vtype = TheType (token)
	IF (vtype != $$STRING) THEN XcowlErr (1200396): GOTO eeeTypeMismatch
atscin:
	SELECT CASE vkind
		CASE $$KIND_CONSTANTS, $$KIND_SYSCONS
				IFZ r_addr$[vv] THEN XcowlErr (1200400): GOTO eeeUndefined
				IFZ m_addr$[vv] THEN XcowlErr (1200401): GOTO eeeUndefined
				what$ = r_addr$[vv]
				what = r_addr[vv]
				IF what THEN
					r_addr[cc] = what
				END IF
		CASE $$KIND_LITERALS
				IFZ m_addr$[vv] THEN AssignAddress (token)
				IF XERROR THEN EXIT FUNCTION
				what$ = tab_sym$[vv]
		CASE ELSE
				XcowlErr (1200412): GOTO eeeSyntax
	END SELECT
	IF dupDef THEN
		IF (r_addr$[cc] != vs$) THEN PRINT "CheckState(415)", r_addr$[cc], what$
		IF (r_addr$[cc] != what$) THEN XcowlErr (1200416): GOTO eeeDupMismatch
	END IF
	m_addr$[cc] = m_addr$[vv]
	m_addr[cc]  = m_addr[vv]
	m_reg[cc]   = m_reg[vv]
	r_addr$[cc] = what$
	tabType[cc] = vtype
	NextToken (@token)
	RETURN
'
'
' ************************************
' *****  ASSIGNMENT TO VARIABLE  *****
' ************************************
'
assign_variables:
	got_executable = $$TRUE
	hold_place  = tokenPtr
	hold_token  = token
	old_data    = token
'
	ot = token
	oo = token.tindex
	IFZ m_addr$[oo] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
'
	old_type = tabType[oo]          ' xxxxx
'
	IFZ old_type THEN old_type = TheType (token)    ' xxxxx
'
	orego = r_addr[oo]
	NextToken (@token)
	IF (old_type >= $$SCOMPLEX) THEN GOTO assign_composite
'
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_EQ)    : ' fall through
		CASE TokenMatch (@token, @#T_LBRACE): GOTO assignBraceString
		CASE ELSE     : XcowlErr (1200453): GOTO eeeSyntax
	END SELECT
'
' evaluate the expression
'
in_ass:
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	excessComma = $$FALSE
	pass_type = old_type
	Expresso (@new_test, @new_op, @new_prec, @new_data, @pass_type)
	new_type = pass_type
	IF XERROR THEN EXIT FUNCTION
	IF excessComma THEN XcowlErr (1200467): GOTO eeeSyntax
	IFZ new_type THEN
		IF ##XBDV THEN PRINT "CheckState(469):new_type is zero"
	END IF
	token = new_op
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		IF TokenMatch (@hold_token, @new_data) THEN GOTO zover
		nn = new_data.tindex
	ELSE
		nn = Top ()
	END IF
	IFZ nn THEN XcowlErr (1200478): GOTO eeeTooFewArgs
'
' string assignment
'
asx:
	IF ((old_type != $$STRING) AND (new_type != $$STRING)) THEN GOTO nsa
	IF (old_type <> new_type) THEN tokenPtr = hold_place: XcowlErr (1200484): GOTO eeeTypeMismatch
	IF (oo = nn) THEN DEC oos: GOTO zass
'
	IF (oos[oos] = 'v') THEN
		IF NullStringerCheck (nn) THEN
			Code ($$xor, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"3")
		ELSE
			Move ($$RA0, old_type, nn, new_type)
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0", $$rmk$+"4")
		END IF
		nn      = $$RA0
		toes    = 1
		a0      = toes
		a0_type = new_type
	END IF
	oos[oos] = 's'
'
	oo$   = tab_sym$[oo]
	m$    = m_addr$[oo]
	ma    = m_addr[oo]
	mr    = m_reg[oo]
'
	SELECT CASE nn
		CASE $$RA0: acc = $$R14:  accx = $$R16
								a0 = 0: a0_type = 0
		CASE $$RA1: acc = $$R16:  accx = $$R14
								a1 = 0: a1_type = 0
		CASE ELSE: XcowlErr (1200511): GOTO eeeCompiler
	END SELECT
'
	IFZ mr THEN
		Code ($$mov, $$regimm, accx, ma, 0, $$XLONG, m$, $$rmk$+"5")
	ELSE
		Code ($$lea, $$regro, accx, mr, ma, $$XLONG, "", $$rmk$+"6")
	END IF
	Code ($$ld, $$regr0, $$rdi, accx, 0, $$XLONG, "", $$rmk$+"7")
	Code ($$st, $$r0reg, acc, accx, 0, $$XLONG, "", $$rmk$+"8")
	Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"9")
	DEC oos
	DEC toes
	GOTO zass
'
'
' *********************************************
' *****  ASSIGN TO COMPOSITE DESTINATION  *****
' *********************************************
'
'   subComposite == a composite expression including sub-element references
'   varComposite == a composite variable/array without sub-element references
'
'   Destination:  GETADDR invalid for varComposites/subComposites
'                 GETHANDLE invalid for varComposites
'                 GETHANDLE valid only for pointer sub-elements to allow
'                     assigning address to pointer (tested in Composite() )
'
p_addr_ops:
	got_executable = $$TRUE
'
	IFF TokenMatch (@token, @#T_HANDLE_OP) THEN XcowlErr (1200542): GOTO eeeSyntax
	NextToken (@token)
	kind = token.tp.kind
	SELECT CASE kind
		CASE $$KIND_VARIABLES, $$KIND_ARRAYS
		CASE ELSE:  XcowlErr (1200547): GOTO eeeSyntax
	END SELECT
'
	old_type    = TheType (token)
	IF (old_type < $$SCOMPLEX) THEN XcowlErr (1200551): GOTO eeeSyntax
'
	lastElement = LastElement (token, 0, 0)   ' Handle invalid for varComposites
	IF XERROR THEN EXIT FUNCTION
	IF lastElement THEN XcowlErr (1200555): GOTO eeeSyntax
'
	compositeHandle = $$TRUE
	hold_place  = tokenPtr
	hold_token  = token
'
	ot = token
	oo = token.tindex
	IFZ m_addr$[oo] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
'
	old_type = TheType (token)    ' xxxxx                    ??????????????????
	old_type = tabType[oo]        ' xxxxx
'
	IFZ old_type THEN old_type = TheType (token)    ' xxxxx
'
	orego = r_addr[oo]
	NextToken (@token)
'
assign_composite:
	DO UNTIL TokenMatch (@token, @#T_EQ)              ' skip past "=" (assignment)
		NextToken (@token)
	LOOP WHILE (token.tp.kind != $$KIND_STARTS)
	IFF TokenMatch (@token, @#T_EQ) THEN XcowlErr (1200578): GOTO eeeExpectAssignment
	s_test = 0: s_prec = 0: s_type = 0
	s_op = #T_ZERO
	s_data = #T_ZERO
	Expresso (@s_test, @s_op, @s_prec, @s_data, @s_type)
	IF XERROR THEN EXIT FUNCTION
	IFZ s_type THEN XcowlErr (1200584): GOTO eeeTooFewArgs
	IFF TokenMatch (@s_data, @#T_ZERO) THEN
		ss = r_addr[s_data.tindex]
		sourceStacked = 0
	ELSE
		ss = Top ()
		sourceStacked = 1
	END IF
'
' *****  get address of destination  *****
'
	d_reg = hold_token
	term_ptr = tokenPtr
	tokenPtr = hold_place
	IF (d_reg.tp.kind = $$KIND_ARRAYS) THEN   ' a[] = ...  invalid
		NextToken (@check1)
		NextToken (@check2)
		tokenPtr = hold_place
		IF TokenMatch (@check1, @#T_LBRAK) THEN
			IF TokenMatch (@check2, @#T_RBRAK) THEN XcowlErr (1200603): GOTO eeeSyntax
		END IF
	END IF
	IF compositeHandle THEN
		command = $$GETHANDLE
	ELSE
		command = $$GETDATAADDR
	END IF
	Composite (@command, @d_type, @d_reg, @d_offset, @d_length)
	IF XERROR THEN EXIT FUNCTION
	IF compositeHandle THEN
		d_type = $$XLONG
		compositeHandle = $$FALSE
	END IF
	NextToken (@token)
	IFF TokenMatch (@token, @#T_EQ) THEN XcowlErr (1200618): GOTO eeeSyntax
'
' *******************************************
' *****  Assign composite to composite  *****
' *******************************************
'
	IF ((d_type >= $$SCOMPLEX) OR (s_type >= $$SCOMPLEX)) THEN
		IF (d_type != s_type) THEN XcowlErr (1200625): GOTO eeeTypeMismatch
		IFF TokenMatch (@s_data, @#T_ZERO) THEN
			Composite ($$GETDATA, @s_type, @s_data, 0, 0)
			IF XERROR THEN EXIT FUNCTION
			s_data = #T_ZERO
			sourceStacked = 1
			flipStack = $$TRUE
		END IF
		IF command THEN                       ' address of dest in tos
			IF sourceStacked THEN               ' address of source in tos-1
				IF flipStack THEN
					Topax2 (@sr, @dr)               ' remove dest and source from stack
				ELSE
					Topax2 (@dr, @sr)               ' remove dest and source from stack
				END IF
				GOSUB GetCompositeDest            ' rdi = address of dest
				Code ($$mov, $$regreg, $$rsi, sr, 0, $$XLONG, "", $$rmk$+"10")
				sr = $$rsi
			ELSE
				PRINT "CheckState(644):assign_composite.1"
				XcowlErr (1200645): GOTO eeeCompiler
			END IF
		ELSE
			IF d_reg.tproto THEN XcowlErr (1200648): GOTO eeeCompiler
			dr    = d_reg.tindex                ' register with composite address
			GOSUB GetCompositeDest              ' rdi = address of dest
			IF sourceStacked THEN               ' address of src in tos
				sr = Topax1 ()                    ' remove source from stack
				Code ($$mov, $$regreg, $$rsi, sr, 0, $$XLONG, "", $$rmk$+"11")
				sr    = $$rsi                     ' ditto
			ELSE
				PRINT "CheckState(656):assign_composite.2"
				XcowlErr (1200657): GOTO eeeCompiler
			END IF
		END IF
		AssignComposite (dr, d_type, sr, s_type)
		tokenPtr = term_ptr
		token = s_op
		GOTO zass
	END IF
'
' *********************************************************
' *****  Assign simple type to simple type component  *****
' *********************************************************
'
	IF command THEN
		IF sourceStacked THEN
			Topax2 (@dr, @sr)
		ELSE
			sr = OpenAccForType (s_type)
			Move (sr, s_type, s_data.tindex, s_type)
			Topax2 (@sr, @dr)
		END IF
	ELSE
		dr    = d_reg.tindex
		IF sourceStacked THEN
			sr = Topax1 ()
		ELSE
			sr = OpenAccForType (s_type)
			Move (sr, s_type, s_data.tindex, s_type)
			Topax1 ()
		END IF
	END IF
	IF (d_type != s_type) THEN            ' problem with s_type = GIANT ???
		SELECT CASE typeConvert[d_type, s_type] {{$$BYTE0}}
			CASE  0
			CASE -1:    XcowlErr (1200691): GOTO eeeTypeMismatch
			CASE ELSE: IFZ ((d_type <= $$XLONG) AND (s_type <= $$XLONG)) THEN
										Conv (sr, d_type, sr, s_type)   '  (GIANTS overwrite $$rdi ???)
									END IF
		END SELECT
	END IF
	IF (d_type = $$STRING) THEN
		suf$ = "." + CHR$(oos[oos])
		DEC oos
		IFZ d_offset THEN
			IF (dr != $$rdi) THEN
				Code ($$mov, $$regreg, $$rdi, dr, 0, $$XLONG, "", $$rmk$+"12")
			END IF
		ELSE
			Code ($$lea, $$regro, $$rdi, dr, d_offset, $$XLONG, "", $$rmk$+"13")
		END IF
		IF (sr != $$rsi) THEN Code ($$mov, $$regreg, $$rsi, sr, 0, $$XLONG, "", $$rmk$+"14")
		Code ($$mov, $$regimm, $$rcx, d_length, 0, $$XLONG, "", $$rmk$+"15")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_assignCompositeStringlet" + suf$, $$rmk$+"17")
	ELSE
		IF ((d_type = $$SINGLE) OR (d_type = $$DOUBLE)) THEN
			Code ($$fstp, $$ro, sr, dr, d_offset, d_type, "", $$rmk$+"18")
		ELSE
			Code ($$st, $$roreg, sr, dr, d_offset, d_type, "", $$rmk$+"19")
		END IF
	END IF
	tokenPtr  = term_ptr
	token     = s_op
	a0_type   = 0
	a1_type   = 0
	GOTO zass
'
'
' *****  GetCompositeDest  *****
'
SUB GetCompositeDest
	IF d_offset OR (dr != $$rdi) THEN
		IFZ d_offset THEN
			Code ($$mov, $$regreg, $$rdi, dr, 0, $$XLONG, "", $$rmk$+"20")
		ELSE
			Code ($$lea, $$regro, $$rdi, dr, d_offset, $$XLONG, "", $$rmk$+"21")
		END IF
		dr    = $$rdi
	END IF
END SUB
'
'
'
' ***********************************
' *****  NON-STRING ASSIGNMENT  *****
' ***********************************
'
nsa:
	literal     = $$FALSE
	doneAssign  = $$FALSE
	IF ((old_type >= $$SCOMPLEX) OR (new_type >= $$SCOMPLEX)) THEN
		IF (old_type != new_type) THEN XcowlErr (1200747): GOTO eeeTypeMismatch
	END IF
	SELECT CASE old_type
		CASE $$SINGLE:  oldFlop = $$TRUE:   ttype = $$XLONG
		CASE $$DOUBLE:  oldFlop = $$TRUE: ttype = $$GIANT
		CASE ELSE:      oldFlop = $$FALSE:  ttype = old_type
	END SELECT
	SELECT CASE new_type
		CASE $$SINGLE:  newFlop = $$TRUE:   ftype = $$XLONG
		CASE $$DOUBLE:  newFlop = $$TRUE: ftype = $$GIANT
		CASE ELSE:      newFlop = $$FALSE:  ftype = new_type
	END SELECT
	kind  = new_data.tp.kind
	SELECT CASE kind
		CASE $$KIND_LITERALS, $$KIND_CONSTANTS, $$KIND_SYSCONS
					ftype   = new_type
					literal = $$TRUE
	END SELECT
'
	IF oldFlop THEN
		IF newFlop THEN GOTO flopflop ELSE GOTO flopint
	ELSE
		IF newFlop THEN GOTO intflop ELSE GOTO intint
	END IF
'
flopflop:
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		IF (ttype = ftype) THEN
			Move ($$RA0, ttype, new_data.tindex, ttype)
			Move (old_data.tindex, ttype, $$RA0, ttype)
			a0 = 0: a0_type = 0
		ELSE
			Move ($$RA0, new_type, new_data.tindex, new_type)
			Move (old_data.tindex, old_type, $$RA0, old_type)
			a0 = 0: a0_type = 0
		END IF
	ELSE
		Move (old_data.tindex, old_type, $$RA0, old_type)
		DEC toes
		a0      = 0
		a0_type = 0
	END IF
	GOTO zover
'
flopint:
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		IF literal THEN
			Move ($$RA0, new_type, new_data.tindex, new_type)
			Code ($$st, $$roreg, $$RA0, $$rbp, -8, new_type, "", $$rmk$+"22")
			Code ($$fild, $$ro, 0, $$rbp, -8, new_type, "", $$rmk$+"23")
			FloatStore ($$RA0, old_data.tindex, old_type)
		ELSE
			FloatLoad ($$RA0, new_data.tindex, new_type)
			FloatStore ($$RA0, old_data.tindex, old_type)
		END IF
		a0      = 0
		a0_type = 0
	ELSE
		Code ($$st, $$roreg, $$RA0, $$rbp, -8, new_type, "", $$rmk$+"24")
		Code ($$fild, $$ro, 0, $$rbp, -8, new_type, "", $$rmk$+"25")
		Move (old_data.tindex, old_type, $$RA0, old_type)
		DEC toes
		a0      = 0
		a0_type = 0
	END IF
	GOTO zover
'
intflop:
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		FloatLoad ($$RA0, new_data.tindex, new_type)
		FloatStore ($$RA0, old_data.tindex, old_type)
		a0 = 0: a0_type = 0
	ELSE
		FloatStore ($$RA0, old_data.tindex, old_type)
		DEC toes
		a0      = 0
		a0_type = 0
	END IF
	GOTO zover
'
intint:
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		IF (old_type = new_type) THEN
			Move ($$RA0, new_type, new_data.tindex, new_type)
			Move (old_data.tindex, old_type, $$RA0, old_type)
			a0 = 0: a0_type = 0
		ELSE
			Move ($$RA0, new_type, new_data.tindex, new_type)
			Conv ($$RA0, old_type, $$RA0, new_type)
			Move (old_data.tindex, old_type, $$RA0, old_type)
			a0 = 0: a0_type = 0
		END IF
	ELSE
		IF (old_type = new_type) THEN
			Move (old_data.tindex, old_type, $$RA0, old_type)
		ELSE
			Conv ($$RA0, old_type, $$RA0, new_type)
			Move (old_data.tindex, old_type, $$RA0, old_type)
		END IF
		DEC toes
		a0      = 0
		a0_type = 0
	END IF
	GOTO zover
'
zover:
	IF a0 AND (a0 = toes) THEN DEC toes: a0 = 0: a0_type = 0: GOTO zass
	IF a1 AND (a1 = toes) THEN DEC toes: a1 = 0: a1_type = 0: GOTO zass
'
zass:
	IF (toes OR toms OR a0 OR a1 OR a0_type OR a1_type) THEN
		XcowlErr (1200858): GOTO eeeExpressionStack
	END IF
	RETURN
'
'
' ****************************************
' *****  ASSIGNMENT TO BRACE STRING  *****
' ****************************************
'
assignBraceString:
	got_executable = $$TRUE
	IF (old_type != $$STRING) THEN XcowlErr (1200869): GOTO eeeSyntax
	old_type    = $$UBYTE
	hold_type   = $$UBYTE
	hold_place  = tokenPtr - 1
	reg_type    = $$XLONG
'
' skip past "=" to source expression
'
	DO
		NextToken (@check)
	LOOP UNTIL (TokenMatch(@check, @#T_EQ) OR (check.tp.kind = $$KIND_STARTS))
	IFF TokenMatch (@check, @#T_EQ) THEN XcowlErr (1200880): GOTO eeeExpectAssignment
'
' evaluate the source expression
'
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	IF (new_type > $$XLONG) THEN XcowlErr (1200889): GOTO eeeTypeMismatch
	holdp = tokenPtr
	token = new_op
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		Move ($$RA0, $$XLONG, new_data.tindex, $$XLONG)
		ss      = $$RA0
		toes    = 1
		a0      = toes
		a0_type = new_type
		ss = new_data.tindex
	ELSE
		ss = Top ()
		IFZ ss THEN XcowlErr (1200901): GOTO eeeTooFewArgs
	END IF
'
' get address of destination string element
'
	new_op = #T_ADDR_OP
	tokenPtr = hold_place - 1
	new_prec = $$PREC_ADDR_OP
	new_type = 0: new_test = 0
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	IF (new_type > $$XLONG) THEN XcowlErr (1200913): GOTO eeeTypeMismatch
	IFF TokenMatch (@new_op, @#T_EQ) THEN XcowlErr (1200914): GOTO eeeCompiler
	IFF TokenMatch (@new_data, @#T_ZERO) THEN XcowlErr (1200915): GOTO eeeCompiler
	nn = Top ()
	IFZ nn THEN XcowlErr (1200917): GOTO eeeTooFewArgs
'
	SELECT CASE nn
		CASE $$RA0
					ss = $$RA1
					IFZ a1 THEN Pop ($$RA1, @stype)
					Code ($$st, $$r0reg, $$RA1, $$RA0, 0, $$UBYTE, "", $$rmk$+"26")
		CASE $$RA1
					ss = $$RA0
					IFZ a0 THEN Pop ($$RA0, @stype)
					Code ($$st, $$r0reg, $$RA0, $$RA1, 0, $$UBYTE, "", $$rmk$+"27")
		CASE ELSE
					PRINT "CheckState(929):xxx4"
					XcowlErr (1200930): GOTO eeeCompiler
	END SELECT
'
	IF XERROR THEN
		tokenPtr = hold_place
		EXIT FUNCTION
	END IF
	toes = toes - 2
	a0 = 0: a0_type = 0
	a1 = 0: a1_type = 0
	tokenPtr = holdp
	RETURN

'
'
' ***************************************
' *****  ASSIGNMENT TO MID$ STRING  *****
' ***************************************
'
' MID$(string$, start, length) = string$
'
assignMidString:
	got_executable = $$TRUE
	old_type    = $$STRING
	hold_type   = $$STRING
	hold_place  = tokenPtr
	reg_type    = $$XLONG
'
' skip past "=" to source expression
'
	DO
		NextToken (@check)
	LOOP UNTIL (TokenMatch(@check, @#T_EQ) OR (check.tp.kind = $$KIND_STARTS))
	IFF TokenMatch (@check, @#T_EQ) THEN XcowlErr (1200963): GOTO eeeExpectAssignment
	equalPos = tokenPtr
'
	tokenPtr = hold_place
	max_args    = token.tp.allo
'
	StackOneArg (tokenPos, 0, @argType, @rparen)
	IF rparen THEN XcowlErr (1200970): GOTO eeeTooFewArgs
	IF (argType != $$STRING) THEN XcowlErr (1200971): GOTO eeeTypeMismatch
'
	StackOneArg (@equalPos, 1, @argType, @rparen)
	IF rparen THEN XcowlErr (1200974): GOTO eeeTooFewArgs
	IF (argType != $$STRING) THEN XcowlErr (1200975): GOTO eeeTypeMismatch
'
	StackOneArg (tokenPos, 2, @argType, @rparen)
	IFF q_type_long[argType] THEN XcowlErr (1200978): GOTO eeeTypeMismatch
'
	IFZ rparen THEN
		StackOneArg (tokenPos, 3, @argType, @rparen)
		IFZ rparen THEN XcowlErr (1200982): GOTO eeeTooManyArgs
		IFF q_type_long[argType] THEN XcowlErr (1200983): GOTO eeeTypeMismatch
	ELSE
		Code ($$st, $$roimm, -1, $$rsp, 12, $$XLONG,"", $$rmk$+"28")
	END IF
'
	NextToken (@check)
	IFF TokenMatch (@check, @#T_EQ) THEN XcowlErr (1200989): GOTO eeeExpectAssignment
'
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_stuff.d.s" + CHR$(oos[oos]), $$rmk$+"29")
	StackOneArg (0, -1, 0, 0)
'
	tokenPtr = equalPos -1
	NextToken (@token)
	RETURN
'
'
' *********************************
' *****  ASSIGNMENT TO ARRAY  *****
' *********************************
'
assign_array:
	got_executable = $$TRUE
	hold_type  = TheType (token)
	hold_place = tokenPtr
	hold_token = token
	IF (hold_type < $$SLONG) THEN
		reg_type = $$SLONG
	ELSE
		reg_type = hold_type
	END IF
'
	oo = token.tindex
	IFZ m_addr$[oo] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
'
	hold_type = tabType[oo]         ' xxxxx
'
	IFZ hold_type THEN hold_type = TheType (token)    ' xxxxx
'
	IF (hold_type >= $$SCOMPLEX) THEN GOTO assign_composite
'
	DO
		NextToken (@check)
	LOOP UNTIL (TokenMatch(@check, @#T_EQ) OR (check.tp.kind = $$KIND_STARTS))
	IFF TokenMatch(@check, @#T_EQ) THEN XcowlErr (12001027): GOTO eeeExpectAssignment
'
' evaluate the source expression
'
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	excessComma = $$FALSE
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	IF excessComma THEN XcowlErr (12001037): GOTO eeeSyntax
	holdp = tokenPtr
	token = new_op
	stype = new_type
	IFF TokenMatch (new_data, @#T_ZERO) THEN ss = new_data.tindex ELSE ss = Top ()
	IFZ ss THEN XcowlErr (12001042): GOTO eeeTooFewArgs
'
	IF (new_type = $$STRING) THEN
		Move ($$RA0, old_type, ss, new_type)
		IF (oos[oos] = 'v') THEN
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0", $$rmk$+"30")
			oos[oos] = 's'
		END IF
		ss = $$RA0
		toes = 1
		a0 = toes
		a0_type = new_type
	ELSE
		IFZ toes THEN
			Move ($$RA0, old_type, ss, new_type)
			ss = $$RA0
			toes = 1
			a0 = toes
			a0_type = new_type
		END IF
	END IF
'
' get address of destination array element
'
	IF (hold_type = $$STRING) THEN
		new_op = #T_HANDLE_OP
	ELSE
		new_op = #T_ADDR_OP
	END IF
	tokenPtr = hold_place - 1
	new_prec = $$PREC_ADDR_OP
	new_data = #T_ZERO
	new_type = 0
	new_test = 0
	excessComma = $$FALSE
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	IF excessComma THEN DEC tokenPtr: XcowlErr (12001079): GOTO eeeSyntax
	IFZ toes THEN XcowlErr (12001080): GOTO eeeSyntax
	IFF TokenMatch (@new_op, @#T_EQ) THEN XcowlErr (12001081): GOTO eeeCompiler
	SELECT CASE hold_type
		CASE $$STRING, $$SUBADDR:
					IF (hold_type <> stype) THEN
						XcowlErr (12001085): GOTO eeeTypeMismatch
					END IF
		CASE $$FUNCADDR:
					IF (hold_type <> stype) AND (stype <> $$XLONG) THEN
						XcowlErr (12001089): GOTO eeeTypeMismatch
					END IF
	END SELECT
	IFF TokenMatch (@new_data, @#T_ZERO) THEN nn = new_data.tindex ELSE nn = Top ()
	IFZ nn THEN XcowlErr (12001093): GOTO eeeTooFewArgs
'
	IF (nn = $$RA0) THEN
		ss = $$RA1
		IFZ a1 THEN Pop ($$RA1, @stype)
'
' if source was a literal, a conversion may not be necessary to range check
'
		IF (hold_type <> stype) THEN
			IF ((hold_type >= $$GIANT) OR (stype >= $$GIANT)) THEN
				Conv ($$RA1, hold_type, $$RA1, stype)
			END IF
		END IF
'
		IF (hold_type = $$STRING) THEN
			Code ($$ld, $$regr0, $$rdi, $$rax, 0, $$XLONG, "", $$rmk$+"31")
			Code ($$st, $$r0reg, $$rbx, $$rax, 0, $$XLONG, "", $$rmk$+"32")
			Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"33")
			DEC oos
		ELSE
			SELECT CASE hold_type
				CASE $$SINGLE, $$DOUBLE
							Code ($$fstp, $$r0, 0, $$rax, 0, hold_type, "", $$rmk$+"34")
				CASE ELSE
							Code ($$st, $$r0reg, $$rbx, $$rax, 0, hold_type, "", $$rmk$+"35")
			END SELECT
		END IF
		GOTO aaax
	END IF
'
	IF (nn = $$RA1) THEN
		ss = $$RA0
		IFZ a0 THEN Pop ($$RA0, @stype)
'
' if source was a literal, a conversion may not be necessary to range check
'
		IF (hold_type <> stype) THEN
			IF ((hold_type >= $$SINGLE) OR (stype >= $$SINGLE)) THEN
				Conv ($$RA0, hold_type, $$RA0, stype)
			END IF
		END IF
		IF (hold_type == $$STRING) THEN
			Code ($$ld, $$regr0, $$rdi, $$rbx, 0, $$XLONG, "", $$rmk$+"36")
			Code ($$st, $$r0reg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"37")
			Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"38")
			DEC oos
		ELSE
			SELECT CASE hold_type
				CASE $$SINGLE, $$DOUBLE
							Code ($$fstp, $$r0, 0, $$rbx, 0, hold_type, "", $$rmk$+"39")
				CASE ELSE
							Code ($$st, $$r0reg, $$rax, $$rbx, 0, hold_type, "", $$rmk$+"40")
			END SELECT
		END IF
		GOTO aaax
	END IF
	PRINT "CheckState(1149):xxx4"
	XcowlErr (12001150): GOTO eeeCompiler
aaax:
	IF XERROR THEN
		tokenPtr = hold_place
		EXIT FUNCTION
	END IF
	toes = toes - 2
	a0 = 0: a0_type = 0
	a1 = 0: a1_type = 0
	tokenPtr = holdp
' IFF TokenMatch (@token, @holdt) THEN PRINT "CheckState(1160)"
	RETURN
'
'
' *****************************************************
' *****  typenameAT (base, [index]) = expression  *****
' *****************************************************
'
p_sbyteat:
p_ubyteat:
p_sshortat:
p_ushortat:
p_slongat:
p_ulongat:
p_xlongat:
p_goaddrat:
p_subaddrat:
p_funcaddrat:
p_giantat:
p_singleat:
p_doubleat:
	got_executable = $$TRUE
	hold_place = tokenPtr
	hold_type  = TheType (token)
	hold_toes  = toes
	hold_toms  = toms
	DO
		NextToken (@check)
	LOOP UNTIL (TokenMatch(@check, @#T_EQ) OR (check.tp.kind = $$KIND_STARTS))
	IFF TokenMatch (@check, @#T_EQ) THEN XcowlErr (12001189): GOTO eeeExpectAssignment
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	holdp = tokenPtr
	token = new_op
	stype = new_type
	IFZ stype THEN XcowlErr (12001198): GOTO eeeTooFewArgs
	IF (stype >= $$STRING) THEN XcowlErr (12001199): GOTO eeeTypeMismatch
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		source  = OpenAccForType (stype)
		Move (source, stype, new_data.tindex, stype)
	ELSE
		source  = Top ()
	END IF
	opcode    = $$st
	tokenPtr  = hold_place
' AtOps (hold_type, @opcode, @mode, @base, @offset, @source)
	baseIndex = base.tindex
	AtOps (hold_type, @opcode, @mode, @baseIndex, @offset, @source)
	Code (opcode, mode, source, baseIndex, offset, hold_type, "", $$rmk$+"41")
	tokenPtr  = holdp
' IFF TokenMatch (@token, @holdt) THEN PRINT "CheckState(1213)"
	RETURN
'
'
' *************************
' *****  GOTO LABELS  *****
' *************************
'
p_label:
	got_executable = $$TRUE
	IF (tokenPtr <> 1) THEN XcowlErr (12001223): GOTO eeeSyntax
	IF (token.tp.type <> $$GOADDR) THEN XcowlErr (12001224): GOTO eeeTypeMismatch
	EmitUserLabel (token)
	IF XERROR THEN EXIT FUNCTION
'
' Checking for messages should not be necessary when doing a GOTO
'
' IF (i486bin || runAssm) THEN Code ($$call, $$rel, 0, 0, 0, 0, "XxxCheckMessages"+$$ftrail$+"0", $$rmk$+"42")
	NextToken (@token)
	RETURN
'
'
' ******************************
' *****  EXECUTE FUNCTION  *****
' ******************************
'
p_func:
p_atsign:
	got_executable = $$TRUE
	DEC tokenPtr
	token = Eval (@result_type)
	IF XERROR THEN EXIT FUNCTION
	IF (toes <> 1) THEN XcowlErr (12001245): GOTO eeeCompiler
	IF (result_type = $$STRING) THEN
		Code ($$mov, $$regreg, $$rdi, $$rax, 0, $$XLONG, "", $$rmk$+"43")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"44")
		DEC oos
	END IF
	toes = 0
	a0 = 0: a0_type = 0
	a1 = 0: a1_type = 0
	RETURN
'
'
'
' **********************************
' **********  STATEMENTS  **********
' **********************************
'
'
' *****  AUTO, STATIC, SHARED, SHARED /sharename/, EXTERNAL, EXTERNAL /sharename/  *****
'
p_types:
	pallo = $$SHARED    ' in PROLOG, SHARED allocation is assumed
'
p_auto:
p_autox:
p_static:
p_shared:
p_external:
	IF got_executable THEN XcowlErr (12001273): GOTO eeeTooLate
	IFZ program$ THEN program$ = programName$
	IFZ got_function THEN
		IFZ got_object_declaration THEN
			IFZ prologCode THEN
				EmitText()
				SELECT CASE TRUE
					CASE library :  Code ($$jmp, $$rel, 0, 0, 0, 0, $$ulpc$+"_StartLibrary_" + program$, $$rmk$+"45")
					CASE ELSE    :  Code ($$jmp, $$rel, 0, 0, 0, 0, $$ulpc$+"_StartApplication", $$rmk$+"46")
				END SELECT
				prologCode = $$TRUE
				EmitLabel ("PrologCode")
				Code ($$push, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"47")
				Code ($$mov, $$regreg, $$rbp, $$rsp, 0, $$XLONG, "", $$rmk$+"48")
				Code ($$sub, $$regimm, $$rsp, 256, 0, $$XLONG, "", $$rmk$+"49")
				IF i486asm THEN EmitNull ($$rmk1$)
			END IF
		END IF
	END IF
'
	got_object_declaration = $$TRUE
	gotAllo = $$TRUE
	sharename$ = ""
'
	IF pallo THEN
		allo = pallo
	ELSE
		allo = token.tp.allo
		NextToken (@token)
	END IF
'
	IF ((allo = $$SHARED) OR (allo = $$EXTERNAL)) THEN
		IF TokenMatch (@token, @#T_DIV) THEN              ' SHARED /sharename/ or EXTERNAL /sharename/
			NextToken (@token)
			kind = token.tp.kind
			SELECT CASE kind
				CASE $$KIND_SYMBOLS, $$KIND_VARIABLES
							s$    = tab_sym$[token.tindex]
							'
							' IF a program is being run in the PDE mode,
							' EXTERNAL symbols with the "xxx" must be changed to "XXX" to
							' avoid conflict with the same symbol in the executing program
							'
							IF ##XBDV THEN
								IF (s$ == "xxx") THEN
									IF i486bin THEN
										s$ = "XXX"
									END IF
								ELSE
									IF (s$ == "XXX") THEN
									END IF
								END IF
							END IF
							'
							NextToken (@token)
							IFF TokenMatch (@token, @#T_DIV) THEN XcowlErr (12001328): GOTO eeeSharename
							sharename$ = $$ulpc$ + s$ + $$ulpc$
							NextToken (@token)
				CASE ELSE
							XcowlErr (12001332): GOTO eeeSharename
			END SELECT
		END IF
	END IF
	dataType = TypenameToken (@token)
	GOTO p_type_data
'
'
' *****  SBYTE, UBYTE, SSHORT, USHORT, SLONG, ULONG, XLONG
' *****  GOADDR, SUBADDR, FUNCADDR, SINGLE, DOUBLE, GIANT, STRING
' *****  USER-DEFINED-TYPES
'
p_sbyte:
p_ubyte:
p_sshort:
p_ushort:
p_slong:
p_ulong:
p_xlong:
p_goaddr:
p_subaddr:
p_funcaddr:
p_single:
p_double:
p_giant:
p_string:
p_user_type:
	IF got_executable THEN XcowlErr (12001359): GOTO eeeTooLate
	got_object_declaration = $$TRUE
	dataType = TypenameToken (@token)
	sharename$ = ""
'
p_type_data:
	e     = token.tindex
	adt   = dataType
	SELECT CASE adt
		CASE $$GOADDR, $$SUBADDR
			IF (allo = $$SHARED) THEN XcowlErr (12001369): GOTO eeeScopeMismatch
			IF (allo = $$EXTERNAL) THEN XcowlErr (12001370): GOTO eeeScopeMismatch
		CASE $$FUNCADDR
			DIM funcaddrArg[]
			term    = GetFuncaddrInfo (@token, @eleElements, @funcaddrArg[], @dataPtr)
			kind    = token.tp.kind
			e       = token.tindex
			tdt     = token.tp.type
			IF (tdt AND (tdt != $$FUNCADDR)) THEN XcowlErr (12001377): GOTO eeeTypeMismatch
			ATTACH funcaddrArg[] TO tabArg[e, ]
			token.tp.allo = allo
			tabType[e]  = adt
			UpdateToken (token)
			AssignAddress (token)
			IF XERROR THEN EXIT FUNCTION
			array = $$FALSE
			SELECT CASE kind
				CASE $$KIND_VARIABLES
							IF eleElements THEN XcowlErr (12001387): GOTO eeeCompiler
				CASE $$KIND_ARRAYS
							IF eleElements THEN
								IF func_number THEN XcowlErr (12001390): GOTO eeeSyntax
								holdPtr   = tokenPtr
								tokenPtr  = dataPtr - 1
								dim_array = $$TRUE
								token     = Eval (@result_type)
								dim_array = $$FALSE
								IF XERROR THEN EXIT FUNCTION
								tokenPtr  = holdPtr
							END IF
			END SELECT
			token.tproto = $$TP_STARTS
			token.tindex = $$TI_ZERO
			RETURN
	END SELECT
'
' Get scope and check for scope mismatches like:::    STATIC  #Bill, ##Fred
'
	a = allo                                          ' scope
	IF tab_sym$[e] THEN                               ' symbol$
		IF (tab_sym$[e]{0} = '#') THEN                  ' # 1st byte
			a = $$SHARED                                  ' #SharedVariable
			IF (tab_sym$[e]{1} = '#') THEN a = $$EXTERNAL ' ##ExternalVariable
			IF gotAllo THEN                               ' got explicit scope name
				IF (a != allo) THEN XcowlErr (12001413): GOTO eeeScopeMismatch   ' AUTOX #Shared, ##External
			END IF
		END IF
	END IF
'
	tdt   = token.tp.type                             ' type in token$, token$$
	kind  = token.tp.kind                             ' kind in token$, token$[]
	SELECT CASE kind
		CASE $$KIND_VARIABLES:  arrayKind = $$FALSE
		CASE $$KIND_ARRAYS:     arrayKind = $$TRUE
		CASE ELSE:              XcowlErr (12001423): GOTO eeeSyntax
	END SELECT
	IF ((adt && tdt) AND (adt != tdt)) THEN XcowlErr (12001425): GOTO eeeTypeMismatch
	IFZ adt THEN adt = tdt
	IF m_addr$[e] THEN XcowlErr (12001427): GOTO eeeDupDeclaration
'
	token.tp.allo = a                               ' put scope into token
	tabType[e]  = adt
	UpdateToken (token)
	AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
'
	htp     = tokenPtr - 1
	NextToken (@token)
'
' Dimension arrays with subscripts, skip brackets[]
'
	IF arrayKind THEN
		IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (12001441): GOTO eeeCompiler
		NextToken (@token)
		IF TokenMatch (@token, @#T_RBRAK) THEN
			NextToken (@token)
		ELSE
			tokenPtr  = htp
			dim_array = $$TRUE
			IF (a == $$STATIC) THEN
				redim_array = $$TRUE
			ELSE
				redim_array = $$FALSE
			END IF
			token     = Eval (@result_type)
			dim_array = $$FALSE
			redim_array = $$FALSE
			IF XERROR THEN EXIT FUNCTION
		END IF
	END IF
'
	IF TokenMatch (@token, @#T_COMMA) THEN
		NextToken (@token)
		kind  = token.tp.kind
		GOTO p_type_data
	END IF
'
	IFF TokenMatch (@token, @#T_STARTS) THEN XcowlErr (12001466): GOTO eeeSyntax
'
	NextToken (@token)
	sharename$ = ""
	RETURN
'
'
' *****  ALL  *****
'
p_all:
	got_executable = $$FALSE          ' remove eventually  (debug convenience)
	PeekToken (@check)
	IF TokenMatch (@check, @#T_ALL) THEN
		e = 0
		NextToken (@check)
	ELSE
		e = 36
	END IF
' PRINT " ##  token    symbol                   r_addr$        m_addr$            type"
	DO
		symbol$ = tab_sym$[e]
		token = tab_sym[e]
		kind  = token.tp.kind
		SELECT CASE kind
			CASE $$KIND_ARRAYS, $$KIND_ARRAY_SYMBOLS
			symbol$ = symbol$ + "[]"
		END SELECT
'   PRINT HEX$(e, 4);; HEX$(tab_sym[e], 8);; symbol$; TAB(39);; r_addr$[e]; TAB(54);; m_addr$[e]; TAB(73);; HEX$(tabType[e])
		INC e
	LOOP WHILE (e < tab_sym_ptr)
	token.tproto = $$TP_STARTS
	token.tindex = $$TI_ZERO
	RETURN
'
'
' *****  ATTACH  *****  ATTACH fromArray[*] TO toArray[*]
'
p_attach:
	attachoid   = $$TRUE
	GOTO p_swapper
'
'
' *****  CASE  *****
'
p_case:
	got_executable = $$TRUE
	nestObject  = nestVar[nestLevel]            ' token for test expression
	caseItem    = 0
	caseFloat   = $$FALSE
	caseString  = $$FALSE
	nestType    = nestObject.tp.type            ' test expression type
	SELECT CASE nestType
		CASE $$STRING:    caseString  = $$TRUE
		CASE $$SINGLE:    caseFloat   = $$TRUE
		CASE $$DOUBLE:    caseFloat   = $$TRUE
	END SELECT
	nestToken   = nestToken[nestLevel]
	nestKinds   = nestToken.tp.allo             ' ALL, TRUE, FALSE flags
	caseCount   = nestInfo[nestLevel]
	IF (caseCount = $$TRUE) THEN XcowlErr (12001525): GOTO eeeAfterElse
	IF (nestKinds AND 0x80) THEN caseAll = $$TRUE ELSE caseAll = $$FALSE
	IF (nestKinds AND 0x60) THEN caseTFs = $$TRUE ELSE caseTFs = $$FALSE
	IF (nestToken.tp.kind <> #T_SELECT.tp.kind) THEN XcowlErr (12001528): GOTO eeeNest
	IF (nestToken.tp.type <> #T_SELECT.tp.type) THEN XcowlErr (12001529): GOTO eeeNest
	IF (nestToken.tindex  <> #T_SELECT.tindex)  THEN XcowlErr (12001530): GOTO eeeNest
'
' end of previous CASE block unless this is the 1st case block
'
	IF caseCount THEN
		IFF caseAll THEN
			d1$ = "end.select." + HEX$(nestCount[nestLevel], 4)
			Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"50")
		END IF
		EmitLabel ("case." + HEX$(nestCount[nestLevel], 4) +"."+ HEX$(caseCount, 4))
	END IF
'
' *****  CASE ELSE
' *****  CASE ALL
'
	PeekToken (@token)
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_ELSE):
									IF caseAll THEN XcowlErr (12001548): GOTO eeeElseInCaseAll
									nestInfo[nestLevel] = $$TRUE
									NextToken (@token)
									NextToken (@token)
									RETURN
		CASE TokenMatch (@token, @#T_ALL):
									IFF caseAll THEN XcowlErr (12001554): GOTO eeeBadCaseAll
									nestInfo[nestLevel] = $$TRUE
									NextToken (@token)
									NextToken (@token)
									RETURN
	END SELECT
'
' *****  CASE <expression>  *****
'
	DO
		GOSUB Tester
		IF caseTFs THEN nestType = new_type
		SELECT CASE (nestKinds AND 0x60)      ' 00 = <exp>: 40 = TRUE: 20 = FALSE
			CASE 0x40:  ifc = $$TRUE:  GOSUB SelectCaseTrue
			CASE 0x20:  ifc = $$FALSE: GOSUB SelectCaseFalse
			CASE 0x00:  ifc = $$FALSE: GOSUB SelectCaseExpression
			CASE ELSE:  XcowlErr (12001570): GOTO eeeSyntax
		END SELECT
		toes = 0
		INC caseItem
		a0 = 0: a0_type = 0
		a1 = 0: a1_type = 0
	LOOP WHILE TokenMatch (@new_op, @#T_COMMA)
	IF (caseItem > 1) THEN
		EmitLabel ("caser." + HEX$(nestCount[nestLevel], 4) +"."+ HEX$(caseCount,4))
	END IF
	INC caseCount
	nestInfo[nestLevel] = caseCount
	token.tproto = new_op.tproto
	token.tindex = new_op.tindex
	RETURN
'
'
'
' *****  SELECT CASE TRUE  *****
'
SUB SelectCaseTrue
	IF TokenMatch (@new_op, @#T_COMMA) THEN
		where$ = "caser." + HEX$(nestCount[nestLevel], 4) +"."+ HEX$(caseCount, 4)
		GOSUB TestTrue
	ELSE
		where$ = "case." + HEX$(nestCount[nestLevel], 4) +"."+ HEX$(caseCount+1,4)
		GOSUB TestFalse
	END IF
END SUB
'
'
' *****  SELECT CASE FALSE  *****
'
SUB SelectCaseFalse
	IF TokenMatch (@new_op, @#T_COMMA) THEN
		where$ = "caser." + HEX$(nestCount[nestLevel], 4) +"."+ HEX$(caseCount, 4)
		GOSUB TestFalse
	ELSE
		where$ = "case." + HEX$(nestCount[nestLevel], 4) +"."+ HEX$(caseCount+1,4)
		GOSUB TestTrue
	END IF
END SUB
'
'
' *****  SELECT CASE <expression>  *****
'
SUB SelectCaseExpression
	IF (newType >= $$SCOMPLEX) THEN XcowlErr (12001617): GOTO eeeTypeMismatch
	IF (nestType <> new_type) THEN
		SELECT CASE typeConvert[nestType, new_type] {{$$BYTE0}}
			CASE -1:    XcowlErr (12001620): GOTO eeeTypeMismatch
			CASE  0:    ' convert not required
			CASE ELSE:  Conv ($$rax, nestType, $$rax, new_type)
		END SELECT
	END IF
	IF XERROR THEN EXIT FUNCTION
	IF caseString THEN
		ooos      = oos[oos]
		oos[oos]  = 'v'
		INC oos
		oos[oos]  = ooos
		IF (acc != $$rax) THEN
			Move ($$rax, $$XLONG, acc, $$XLONG)       ' added from xx8v  05/10/92
			acc = $$rax
		END IF
	END IF
	IF caseFloat THEN expression = $$TRUE
	IFZ caseItem THEN expression = $$TRUE
	IF expression THEN
		Move ($$rbx, nestType, nestObject.tindex, nestType)
		expression = $$FALSE
	END IF
	Op ($$rax, $$rbx, #T_EQ, $$rax, $$XLONG, nestType, nestType, nestType)
	IF TokenMatch (@new_op, @#T_COMMA) THEN
		d1$ = "caser." + HEX$(nestCount[nestLevel], 4) + "." + HEX$(caseCount, 4)
		Code ($$je, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"51")
	ELSE
		x1$ = "case." + HEX$(nestCount[nestLevel], 4) + "." + HEX$(caseCount+1, 4)
		Code ($$jne, $$rel, 0, 0, 0, 0, x1$, $$rmk$+"52")
	END IF
END SUB
'
'
' ***********************
' *****  NEXT CASE  *****
' ***********************
'
p_next_case:
	NextToken (@token)                              ' token = possible "level" literal
	levelKind   = token.tp.kind
	IF (levelKind = $$KIND_LITERALS) THEN
		ll = token.tindex
		IFZ m_addr$[ll] THEN AssignAddress (token)
		IF XERROR THEN EXIT FUNCTION
		ll = token.tindex
		exitLevels = XLONG (r_addr$[ll])
		skipLevels = $$TRUE
	ELSE
		skipLevels = $$FALSE
		exitLevels = 1
	END IF
	checkLevel = nestLevel
	checkToken = #T_SELECT
	GOSUB NestWalk
	caseCount = nestInfo[checkLevel]
	dx$       = "case." + HEX$(nestCount[checkLevel], 4) +"."+ HEX$(caseCount, 4)
	Code ($$jmp, $$rel, 0, 0, 0, 0, dx$, $$rmk$+"53")
	IF skipLevels THEN NextToken (@token)
	expression  = $$TRUE
	RETURN
'
' ********************************************
' *****  CLOSE   (fileNumber)            *****
' *****  QUIT    (status)                *****
' *****  SEEK    (fileNumber, position)  *****
' *****  SHELL   (command$)              *****
' ********************************************
'
p_close:
p_quit:
p_seek:
p_shell:
	got_executable = $$TRUE
	DEC tokenPtr
	token = Eval (@result_type)
	IF XERROR THEN EXIT FUNCTION
	DEC toes
	a0      = 0
	a1      = 0
	a0_type = 0
	a1_type = 0
	RETURN
'
'
' *******************************
' *****  INLINE$ (prompt$)  *****  Allows INLINE$() to begin a line
' *******************************
'
p_inline_d:
	got_executable = $$TRUE
	DEC tokenPtr
	token = Eval (@result_type)
	IF XERROR THEN EXIT FUNCTION
	IF (oos[oos] = 's') THEN
		acc = Top ()
		Code ($$mov, $$regreg, $$rdi, acc, 0, $$XLONG, "", $$rmk$+"54")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"55")
	END IF
	DEC oos
	DEC toes
	a0      = 0
	a1      = 0
	a0_type = 0
	a1_type = 0
	RETURN
'
'
' *****************
' *****  DEC  *****
' *****************
' *****  INC  *****
' *****************
'
p_dec:
	op86  = $$dec
	GOTO p_inc_dec
p_inc:
	op86  = $$inc
	GOTO p_inc_dec
'
p_inc_dec:
	holdPtr = tokenPtr
	NextToken (@token)
	tvart   = token.tindex
	tkind   = token.tp.kind
	SELECT CASE tkind
		CASE $$KIND_VARIABLES, $$KIND_ARRAYS
		CASE ELSE:    XcowlErr (12001747): GOTO eeeSyntax
	END SELECT
	IFZ m_addr$[tvart] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
	ttype   = TheType (token)
	IF (ttype = $$STRING) THEN XcowlErr (12001752): GOTO eeeTypeMismatch
	IF (ttype < $$SCOMPLEX) THEN
		IF (tkind = $$KIND_ARRAYS) THEN GOTO p_inc_dec_array
	END IF
	IF (ttype < $$SBYTE) THEN XcowlErr (12001756): GOTO eeeCompiler
	IF (ttype < $$SLONG) THEN ttype = $$SLONG
'
	IF (ttype < $$SCOMPLEX) THEN
		ctype   = $$FALSE
		mReg    = m_reg[tvart]
		mAddr   = m_addr[tvart]
		mAddr$  = m_addr$[tvart]
		treg    = r_addr[tvart]
	ELSE
		cregToken   = token
		ctype   = ttype
		command = $$GETDATAADDR
		Composite (command, @ttype, @cregToken, @offset, 0)
		creg    = cregToken.tindex
		IF XERROR THEN EXIT FUNCTION
		IF toes THEN xx = Topax1 ()
		SELECT CASE TRUE
			CASE (ttype < $$SBYTE):     XcowlErr (12001774): GOTO eeeTypeMismatch
			CASE (ttype > $$DOUBLE):    XcowlErr (12001775): GOTO eeeTypeMismatch
			CASE (ttype = $$GOADDR):    XcowlErr (12001776): GOTO eeeTypeMismatch
			CASE (ttype = $$SUBADDR):   XcowlErr (12001777): GOTO eeeTypeMismatch
			CASE (ttype = $$FUNCADDR):  XcowlErr (12001778): GOTO eeeTypeMismatch
		END SELECT
		IFZ creg THEN
			Move ($$RA1, $$XLONG, token.tindex, $$XLONG)
			creg = $$RA1
		END IF
		htype = ttype
		IF (ttype < $$SLONG) THEN ttype = $$SLONG
		SELECT CASE ttype
			CASE $$SINGLE, $$DOUBLE
			CASE ELSE
						Code ($$ld, $$regro, $$rsi, creg, offset, ttype, "", $$rmk$+"56")
		END SELECT
		ttype = htype
		treg  = $$rsi
		mReg  = creg
		mAddr = offset
	END IF
	oreg    = treg
	oregx   = oreg + 1
	GOSUB IncOrDecValue
	NextToken (@token)
	RETURN
'
' INC or DEC array element
'
p_inc_dec_array:
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (12001806): GOTO eeeCompiler
	NextToken (@token)
	IF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (12001808): GOTO eeeSyntax
	tokenPtr  = holdPtr
	new_test  = 0
	new_op = #T_ADDR_OP
	new_prec = $$PREC_ADDR_OP
	new_data = #T_ZERO
	new_type = 0
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	IFF TokenMatch (@new_data, @#T_ZERO) THEN XcowlErr (12001817): GOTO eeeCompiler
	IF (new_type != $$XLONG) THEN XcowlErr (12001818): GOTO eeeCompiler
	creg      = Topax1 ()
	oreg      = $$rsi
	oregx     = $$rdi
	ctype     = ttype
	mReg      = creg
	mAddr     = 0
	offset    = 0
	GOSUB IncOrDecValue
	NextToken (@token)
	RETURN
'
'
' INC or DEC value in oreg
' IF ctype THEN store result at (creg + offset)
' ELSE store back in original variable "tvart"
'
SUB IncOrDecValue
	SELECT CASE ttype
		CASE $$SBYTE, $$SSHORT, $$SLONG
					IF mReg THEN
						Code (op86, $$ro, 0, mReg, mAddr, ttype, "", $$rmk$+"57")
						INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
						Code ($$jno, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"58a")
						Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"58b")
						EmitLabel (@d1$)
					ELSE
						Code (op86, $$abs, 0, 0, mAddr, ttype, mAddr$, $$rmk$+"59")
						INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
						Code ($$jno, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"60a")
						Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"60b")
						EmitLabel (@d1$)
					END IF
					ctype = 0
					treg  = $$TRUE
		CASE $$UBYTE, $$USHORT, $$ULONG
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					IF mReg THEN
						IF (op86 == $$inc) THEN
							Code ($$add, $$roimm, 1, mReg, mAddr, ttype, "", $$rmk$+"61")  'add 1 = inc
						ELSE
							Code ($$sub, $$roimm, 1, mReg, mAddr, ttype, "", $$rmk$+"62")  'sub 1 = dec
						END IF
					ELSE
						IF (op86 == $$inc) THEN
							Code ($$add, $$absimm, 0, 1, mAddr, ttype, mAddr$, $$rmk$+"63")  'add 1 = inc
						ELSE
							Code ($$sub, $$absimm, 0, 1, mAddr, ttype, mAddr$, $$rmk$+"64")  'sub 1 = dec
						END IF
					END IF
					Code ($$jnc, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"65")
					Code ($$int, $$imm, 4, 0, 0, 0, "", $$rmk$+"66")
					EmitLabel (@d1$)
					ctype = 0
					treg  = $$TRUE
		CASE $$XLONG, $$GIANT
					IF mReg THEN
						Code (op86, $$ro, 0, mReg, mAddr, $$XLONG, "", $$rmk$+"67")
					ELSE
						Code (op86, $$abs, 0, 0, mAddr, $$XLONG, mAddr$, $$rmk$+"68")
					END IF
					ctype = 0
					treg  = $$TRUE
		CASE $$SINGLE
					IF mReg THEN
						Code ($$fld, $$ro, 0, mReg, mAddr, $$SINGLE, "", $$rmk$+"76")
					ELSE
						Code ($$fld, $$abs, 0, 0, mAddr, $$SINGLE, "", $$rmk$+"77")
					END IF
					Code ($$fld1, $$none, 0, 0, 0, 0, "", $$rmk$+"78")
					SELECT CASE op86
						CASE $$inc: Code ($$fadd, $$none, 0, 0, 0, 0, "", $$rmk$+"79")
						CASE $$dec: Code ($$fsub, $$none, 0, 0, 0, 0, "", $$rmk$+"80")
						CASE ELSE: XcowlErr (12001891): GOTO eeeCompiler
					END SELECT
		CASE $$DOUBLE
					IF mReg THEN
						Code ($$fld, $$ro, 0, mReg, mAddr, $$DOUBLE, "", $$rmk$+"81")
					ELSE
						Code ($$fld, $$abs, 0, 0, mAddr, $$DOUBLE, "", $$rmk$+"82")
					END IF
					Code ($$fld1, $$none, 0, 0, 0, 0, "", $$rmk$+"83")
					SELECT CASE op86
						CASE $$inc: Code ($$fadd, $$none, 0, 0, 0, 0, "", $$rmk$+"84")
						CASE $$dec: Code ($$fsub, $$none, 0, 0, 0, 0, "", $$rmk$+"85")
						CASE ELSE: XcowlErr (12001903): GOTO eeeCompiler
					END SELECT
		CASE ELSE
					XcowlErr (12001906): GOTO eeeTypeMismatch
	END SELECT
	IF ctype THEN
		SELECT CASE ttype
			CASE $$SINGLE, $$DOUBLE
						Code ($$fstp, $$ro, 0, creg, offset, ttype, "", $$rmk$+"86")
			CASE ELSE
						Code ($$st, $$roreg, oreg, creg, offset, ttype, "", $$rmk$+"87")
		END SELECT
	ELSE
		SELECT CASE ttype
			CASE $$SINGLE, $$DOUBLE
						FloatStore ($$RA0, tvart, ttype)
			CASE ELSE
						IFZ treg THEN Move (tvart, ttype, oreg, ttype)
		END SELECT
	END IF
END SUB
'
'
' *****  EXTERNAL FUNCTION  *****
' *****  INTERNAL FUNCTION  *****
' *****  DECLARE  FUNCTION  *****
'
' DECLARE [C|S]FUNCTION [type.name] function.name ( [parameter.list] )
'
p_external_func:
p_internal_func:
p_declare_func:
	IF got_function THEN XcowlErr (12001935): GOTO eeeDeclare
	IFZ program$ THEN program$ = programName$
	IFZ got_declare THEN
		got_declare = $$TRUE
		IF i486asm THEN
			EmitData ()
			EmitNull (".align 8")
			EmitLabel ($$ulpc3$+"firstStatic")
			EmitLabel ($$ulpc3$+"entered")
			EmitNull (".zero  8")
			EmitNull ($$rmk1$)
		END IF
		EmitText ()
		ef$ = funcSymbol$[entryFunction]
		xit = (ef$ = "Xit")
	END IF
'
	NextToken (@token)
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_FUNCTION): declareFuncKind = $$XFUNC
		CASE TokenMatch (@token, @#T_CFUNCTION): declareFuncKind = $$CFUNC
		CASE TokenMatch (@token, @#T_SFUNCTION): IF $$linux THEN
																								declareFuncKind = $$CFUNC   ' Linux
																							ELSE
																								declareFuncKind = $$XFUNC   ' Windows
																							END IF
		CASE ELSE       : XcowlErr (12001961): GOTO eeeSyntax
	END SELECT
'
	NextToken (@token)
	func_type = TypenameToken (@token)
	kind = token.tp.kind
	IF (kind <> $$KIND_FUNCTIONS) THEN XcowlErr (12001967): GOTO eeeSyntax
	IF token.tp.allo THEN XcowlErr (12001968): GOTO eeeDupDeclaration
	func_num = token.tindex
	DIM tempArg[19]
	funcScope[func_num] = funcScope
	IF ((func_num = entryFunction) AND (funcScope = $$FUNC_EXTERNAL)) THEN
		XcowlErr (12001973): GOTO eeeEntryFunction
	END IF
	funcName$ = funcSymbol$[func_num]
	lastChar  = funcName${LEN(funcName$)-1}
	IFZ charsetSymbolInner[lastChar] THEN AssemblerSymbol (@funcName$)
'
	rt = token.tp.type
	IF rt THEN
		IF func_type AND (rt <> func_type) THEN XcowlErr (12001981): GOTO eeeTypeMismatch
		func_type = rt
	END IF
	IF (func_type < $$SLONG) THEN func_type = $$XLONG
	funcType[func_num] = func_type
	tempArg[0].tp.kind = $$KIND_VARIABLES
	tempArg[0].tindex = func_type
	function_token = token
	function_token.tp.allo = $$ALLO_DECLARED
	IF (func_type >= $$SCOMPLEX) THEN func_type = 0
	funcKind[func_num] = declareFuncKind
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (12001993): GOTO eeeSyntax
'
	arg               = 0
	argNum            = 1
	declare_arg_addr  = 0
	PeekToken (@token)
	IF TokenMatch (@token, @#T_RPAREN) THEN NextToken (@token): GOTO p_dec_end_of_parameters
'
' *****  collect and log the parameter kinds and types  *****
'
p_dec_p_loop:
	DO
		NextToken (@token)
		akind       = $$KIND_VARIABLES
		temp_type   = TypenameToken (@token)
		IF TokenMatch (@token, @#T_ATSIGN) THEN NextToken (@token)      ' ignore @ prefix
		SELECT CASE temp_type
			CASE $$ETC
						declare_arg_addr = 64           ' allow 16 words of args on "..."
						IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (12002012): GOTO eeeSyntax
						IF (declareFuncKind != $$CFUNC) THEN XcowlErr (12002013): GOTO eeeSyntax
			CASE ELSE
						pkind = token.tp.kind
						SELECT CASE pkind
							CASE $$KIND_STATEMENTS
										IFF TokenMatch (@token, @#T_ANY) THEN XcowlErr (12002018): GOTO eeeSyntax
										NextToken (@token)
										pkind     = token.tp.kind
										temp_type = $$ANY
										SELECT CASE TRUE
											CASE (pkind = $$KIND_ARRAY_SYMBOLS)
														akind     = $$KIND_ARRAYS
														NextToken (@tokTmp)
														IFF TokenMatch (@tokTmp, @#T_LBRAK) THEN XcowlErr (12002026): GOTO eeeSyntax
														NextToken (@tokTmp)
														IFF TokenMatch (@tokTmp, @#T_RBRAK) THEN XcowlErr (12002028): GOTO eeeSyntax
														GOSUB ValidateParameterSymbol
														NextToken (@token)
											CASE TokenMatch (@token, @#T_LBRAK)
														NextToken (@tokTmp)
														IFF TokenMatch (@tokTmp, @#T_RBRAK) THEN XcowlErr (12002033): GOTO eeeSyntax
														pkind     = $$KIND_ARRAY_SYMBOLS
														akind     = $$KIND_ARRAYS
														NextToken (@token)
											CASE (TokenMatch(@token, @#T_COMMA) OR TokenMatch(@token, @#T_RPAREN))
														pkind     = $$KIND_SYMBOLS
														akind     = $$KIND_VARIABLES
											CASE ELSE
														XcowlErr (12002041): GOTO eeeSyntax
										END SELECT
							CASE $$KIND_SYMBOLS
										akind = $$KIND_VARIABLES
										GOSUB ValidateParameterSymbol
										NextToken (@token)
							CASE $$KIND_ARRAY_SYMBOLS
										akind = $$KIND_ARRAYS
										NextToken (@tokTmp)
										IFF TokenMatch (@tokTmp, @#T_LBRAK) THEN XcowlErr (12002050): GOTO eeeSyntax
										NextToken (@tokTmp)
										IFF TokenMatch (@tokTmp, @#T_RBRAK) THEN XcowlErr (12002052): GOTO eeeSyntax
										GOSUB ValidateParameterSymbol
										NextToken (@token)
							CASE ELSE
										IF temp_type THEN
											SELECT CASE TRUE
												CASE TokenMatch (@token, @#T_COMMA): akind = $$KIND_VARIABLES
												CASE TokenMatch (@token, @#T_RPAREN): akind = $$KIND_VARIABLES
												CASE TokenMatch (@token, @#T_LBRAK):
													NextToken (@token)
													IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (12002062): GOTO eeeSyntax
													NextToken (@token)
													akind = $$KIND_ARRAYS
												CASE ELSE
													XcowlErr (12002066): GOTO eeeSyntax
											END SELECT
										END IF
						END SELECT
		END SELECT
'
		tempArg[argNum].tp.kind = akind
		tempArg[argNum].tindex = temp_type
		IF (akind = $$KIND_ARRAYS) THEN
				IF (declareFuncKind == $$CFUNC) THEN
					IF (arg > 5) THEN
						declare_arg_addr = declare_arg_addr + 8
					END IF
				ELSE
					declare_arg_addr = declare_arg_addr + 8
				END IF
		ELSE
			SELECT CASE temp_type
				CASE $$GIANT, $$DOUBLE
							IF (declareFuncKind == $$CFUNC) THEN
								IF (arg > 5) THEN
									declare_arg_addr = declare_arg_addr + 8
								END IF
							ELSE
								declare_arg_addr = declare_arg_addr + 8
							END IF
				CASE $$ETC
							' nop
				CASE ELSE
							IF (declareFuncKind == $$CFUNC) THEN
								IF (arg > 5) THEN
									declare_arg_addr = declare_arg_addr + 8
								END IF
							ELSE
								declare_arg_addr = declare_arg_addr + 8
							END IF
			END SELECT
		END IF
		INC arg
		INC argNum
	LOOP WHILE TokenMatch (@token, @#T_COMMA)
'
' *****
' *****  all parameters collected  *****
' *****
'
p_dec_end_of_parameters:
	tempArg[0].tp.type = arg
	funcArgSize[func_num] = declare_arg_addr
	ATTACH funcArg[func_num, ] TO temp[]: DIM temp[]
	ATTACH tempArg[] TO funcArg[func_num, ]
	IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (12002117): GOTO eeeSyntax
	SELECT CASE declareFuncKind
		CASE $$XFUNC: funcName$ = funcName$ + $$ftrail$ + STRING(declare_arg_addr)
		CASE $$SFUNC: IF $$linux THEN
										XcowlErr (12002121): GOTO eeeCompiler
									ELSE
										funcName$ = funcName$ + $$ftrail$ + STRING(declare_arg_addr)
									END IF
	END SELECT
	SELECT CASE funcScope
		CASE $$FUNC_DECLARE
					funcName$ = $$flead$ + funcName$
					IF i486asm THEN EmitNull (".globl " + funcName$)
					AddLabel (@funcName$, $$KIND_LABELS, 0, $$XNEW)
		CASE $$FUNC_EXTERNAL
					funcName$ = $$flead$ + funcName$
					IF i486asm THEN EmitNull (".globl " + funcName$)
		CASE $$FUNC_INTERNAL
					AddLabel (@funcName$, $$KIND_LABELS, 0, $$XNEW)
		CASE ELSE
					XcowlErr (12002137): GOTO eeeCompiler
	END SELECT
'
	libraryFunctionLabel$ = funcName$
	funcLabel$[func_num] = funcName$
	funcToken[func_num] = function_token
'
	IF i486asm THEN
		IF export THEN
			IF (funcScope = $$FUNC_DECLARE) THEN
				IFZ preExports THEN
					preExports = $$TRUE
					string$ = "EXPORTS  " + $$ulpc4$ + "blowback_" + program$
					WriteDefinitionFile (@string$)
					string$ = "EXPORTS  " + $$ulpc$+"_StartLibrary_" + program$
					WriteDefinitionFile (@string$)
				END IF
				string$ = "EXPORTS  " + funcSymbol$[func_num]
				WriteDefinitionFile (@string$)
			END IF
		END IF
	END IF
'
	NextToken (@token)
	RETURN
'
' *****  subroutine for DECLARE  *****
'
SUB ValidateParameterSymbol
	token_type = token.tp.type
	IF token_type THEN
		IF temp_type THEN
			IF (token_type <> temp_type) THEN XcowlErr (12002169): GOTO eeeTypeMismatch
		END IF
		temp_type = token_type
	ELSE
		IFZ temp_type THEN temp_type = $$XLONG
	END IF
END SUB
'
'
' *****  DIM  *****
'
p_redim:
	redim_array = $$TRUE
p_dim:
	got_executable = $$TRUE
	dim_array = $$TRUE
p_dim_loop:
	NextToken (@token)
	kind = token.tp.kind
	IF (kind <> $$KIND_ARRAYS) THEN dim_array = $$FALSE: XcowlErr (12002188): GOTO eeeSyntax
	DEC tokenPtr
	token = Eval (@result_type)
	IF TokenMatch (@token, @#T_COMMA) THEN GOTO p_dim_loop
	dim_array = $$FALSE
	redim_array = $$FALSE
	RETURN
'
'
' *****  DO  *****
'
p_do:
	got_executable = $$TRUE
	NextToken (@token)
	nothing = $$TRUE
	PeekToken (@levelToken)
	levelKind = levelToken.tp.kind
	IF (levelKind = $$KIND_LITERALS) THEN
		ll = levelToken.tindex
		IFZ m_addr$[ll] THEN AssignAddress (levelToken)
		IF XERROR THEN EXIT FUNCTION
		ll = levelToken.tindex
		exitLevels = XLONG (r_addr$[ll])
		skipLevels = $$TRUE
	ELSE
		skipLevels = $$FALSE
		exitLevels = 1
	END IF
'
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_DO)
					checkLevel = nestLevel
					checkToken = #T_DO
					GOSUB NestWalk
					d1$ = "do." + HEX$(nestCount[checkLevel], 4)
					Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"89")
					IF skipLevels THEN NextToken (@token)
					NextToken (@token)
					RETURN
		CASE TokenMatch (@token, @#T_FOR)
					checkLevel = nestLevel
					checkToken = #T_FOR
					GOSUB NestWalk
					d1$ = "for." + HEX$(nestCount[checkLevel], 4)
					Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"90")
					IF skipLevels THEN NextToken (@token)
					NextToken (@token)
					RETURN
		CASE TokenMatch (@token, @#T_LOOP)
					checkLevel = nestLevel
					checkToken = #T_DO
					GOSUB NestWalk
					d1$ = "do.loop." + HEX$(nestCount[checkLevel], 4)
					Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"91")
					IF skipLevels THEN NextToken (@token)
					NextToken (@token)
					RETURN
		CASE TokenMatch (@token, @#T_NEXT)
					checkLevel = nestLevel
					checkToken = #T_FOR
					GOSUB NestWalk
					d1$ = "do.next." + HEX$(nestCount[checkLevel], 4)
					Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"92")
					IF skipLevels THEN NextToken (@token)
					NextToken (@token)
					RETURN
		CASE TokenMatch (@token, @#T_WHILE): nothing = $$FALSE: ifc = $$FALSE
		CASE TokenMatch (@token, @#T_UNTIL): nothing = $$FALSE: ifc = $$TRUE
	END SELECT
	INC nestCount
	INC nestLevel
	nestVar[nestLevel]    = #T_ZERO
	nestInfo[nestLevel]   = 0
	nestToken[nestLevel]  = #T_DO
	nestLevel[nestLevel]  = nestLevel
	nestCount[nestLevel]  = nestCount
	IF (i486bin || runAssm) THEN
		dbname$ = ".dobreak" + HEX$(func_number) + "." + HEX$(nestCount,4)
		dbtoken = AddSymbol (@dbname$, 0, $$KIND_VARIABLES, 0, $$XLONG, func_number)
		db = dbtoken.tindex
		IF m_addr$[db] THEN XcowlErr (12002268): GOTO eeeCompiler
		AssignAddress (dbtoken)
		IF XERROR THEN EXIT FUNCTION
		Code ($$mov, $$regimm, $$rax, 0, 0, $$XLONG, "", $$rmk$+"93")
		Move (dbtoken.tindex, $$XLONG, $$rax, $$XLONG)
	END IF
	EmitLabel ("do." + HEX$(nestCount[nestLevel], 4))
	IF (i486bin || runAssm) THEN
		INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
		Move ($$rax, $$XLONG, dbtoken.tindex, $$XLONG)
		Code ($$inc, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"94")
		Move (dbtoken.tindex, $$XLONG, $$rax, $$XLONG)
		Code ($$and, $$regimm, $$rax, 0x000000ff, 0, $$XLONG, "", $$rmk$+"95")
		Code ($$jnz, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"96")
		Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxCheckMessages"+$$ftrail$+"0", $$rmk$+"97")
		EmitLabel (@d1$)
	END IF
	IF nothing THEN RETURN
	where$ = "end.do." + HEX$(nestCount[nestLevel], 4)
	GOSUB Tester
	IF ifc THEN
		GOSUB TestTrue
	ELSE
		GOSUB TestFalse
	END IF
	RETURN
'
'
' *****  ELSE  *****
'
p_else:
	got_executable = $$TRUE
	IF (nestInfo[nestLevel]) THEN XcowlErr (12002300): GOTO eeeNest
	IFF TokenMatch (nestToken[nestLevel], @#T_IF) THEN XcowlErr (12002301): GOTO eeeNest
	nestInfo[nestLevel] = $$TRUE
	d1$ = "end.if." + HEX$(nestCount[nestLevel], 4)
	Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"98")
	EmitLabel ("else." + HEX$(nestCount[nestLevel], 4))
	NextToken (@token)
	RETURN
'
'
' *****  END  *****
'
' END, END FUNCTION, END IF, END PROGRAM, END SELECT, END SUB
'
p_end:
	NextToken (@token)
	IFF TokenMatch (@token, @#T_EXPORT) THEN got_executable = $$TRUE
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_EXPORT): GOTO p_end_export
		CASE TokenMatch (@token, @#T_FUNCTION): GOTO p_end_function
		CASE TokenMatch (@token, @#T_IF)    : GOTO p_end_if
		CASE TokenMatch (@token, @#T_PROGRAM): GOTO p_end_program
		CASE TokenMatch (@token, @#T_SELECT): GOTO p_end_select
		CASE TokenMatch (@token, @#T_SUB)   : GOTO p_end_sub
		CASE TokenMatch (@token, @#T_STARTS): GOTO p_end_program
		CASE TokenMatch (@token, @#T_REM)   : GOTO p_end_program
		CASE TokenMatch (@token, @#T_COLON) : GOTO p_end_program
		CASE ELSE                            : XcowlErr (12002327): GOTO eeeSyntax
	END SELECT
'
'
' ************************
' *****  END EXPORT  *****
' ************************
'
p_end_export:
	export = $$FALSE
	token.tproto = $$TP_STARTS
	token.tindex = $$TI_ZERO
	RETURN
'
'
' **************************
' *****  END FUNCTION  *****
' **************************
'
p_end_function:
p_end_functions:
	got_executable = $$FALSE
	got_object_declaration = $$FALSE
	IF (insub OR nestLevel) THEN
		insub = 0: errNestLevel = nestLevel: nestLevel = 0
		XcowlErr (12002352): GOTO eeeNest
	END IF
	token = ReturnValue (@rt)
	IF XERROR THEN EXIT FUNCTION
	funcKind = funcKind[func_number]
	hfn$ = HEX$(func_number)
'
' Emit function EPILOG
'
	IF i486asm THEN EmitNull ($$rmk2$)
	EmitLabel ("end.func" + hfn$)
'
' Deallocate AUTO and AUTOX composite data
'
	IF compositeNumber[func_number] THEN
		Deallocate (compositeToken[func_number, 0])
	END IF
'
' Deallocate AUTO and AUTOX strings and arrays
'
	IF hash%[func_number, ] THEN
		FOR i = 0 TO 255
			IF hash%[func_number, i, ] THEN
				FOR j = 1 TO hash%[func_number, i, 0]
					k     = hash%[func_number, i, j]
					tk    = tab_sym[k]
					kind  = tk.tp.kind
					ttype = TheType (tk)
					tallo = tk.tp.allo
					IF ((tallo = $$AUTO) OR (tallo = $$AUTOX)) THEN
						SELECT CASE kind
							CASE $$KIND_VARIABLES
								IF (ttype = $$STRING) THEN  Deallocate (tk)
							CASE $$KIND_ARRAYS:           Deallocate (tk)
						END SELECT
					END IF
				NEXT j
			END IF
		NEXT i
	END IF
'
'
' Compute base addresses of the areas on the stack frame
'
'	inarg_base = (autoxAddr[func_number] + 15) AND 0xFFFFFFF0    '*cw* 220912-
	inarg_base = (autoxAddr[func_number] + 50) AND 0xFFFFFFFFFFFFFFF0    '*cw* 230302-+
	IF (inarg_base < 0x0200) THEN inarg_base = 0x0200
	funcFrameSize[func_number] = inarg_base
	first_auto    = inargAddr[func_number]
	after_auto    = autoAddr[func_number]
	first_reg     = (first_auto >> 2) + 2
	after_reg     = (after_auto >> 2) + 2
	restore_after = after_reg + 4
	restore_addr  = 0x70
	restore_reg   = 14
'
'
' call "end_program" routine if done with entry function
'
	IFZ library THEN
		IF (func_number = entryFunction) THEN
			IF i486asm THEN EmitNull ($$rmk1$)
			Code ($$call, $$rel, 0, 0, 0, 0, "end_program", $$rmk$+"99")
		END IF
	END IF
'
' return to calling function, abandon frame
'
' ****************************
' *****  IMPORTANT NOTE  *****
' ****************************
'
' Don't try to restore rsi, rdi, ebx with "pop" instructions.
' That may work in C, but it doesn't work here because rsp may
' not be where necessary - as when a function is exited from
' within a subroutine.
'
	IF (funcKind == $$CFUNC) THEN
		IF (arg_count >= 6) THEN
			Code ($$mov, $$regro, $$r9, $$rbp, -72, $$XLONG, "", $$rmk$+"100a")
		END IF
		IF (arg_count >= 5) THEN
			Code ($$mov, $$regro, $$r8, $$rbp, -64, $$XLONG, "", $$rmk$+"100b")
		END IF
		IF (arg_count >= 4) THEN
			Code ($$mov, $$regro, $$rcx, $$rbp, -56, $$XLONG, "", $$rmk$+"100c")
		END IF
		IF (arg_count >= 3) THEN
			Code ($$mov, $$regro, $$rdx, $$rbp, -48, $$XLONG, "", $$rmk$+"100d")
		END IF
	END IF
'
' For CFUNCTION rdi is arg0, rsi is arg1 and rbx ia arg2
'
	Code ($$mov, $$regro, $$rsi, $$rbp, -40, $$XLONG, "", $$rmk$+"100")
	Code ($$mov, $$regro, $$rdi, $$rbp, -32, $$XLONG, "", $$rmk$+"101")
	Code ($$mov, $$regro, $$rbx, $$rbp, -24, $$XLONG, "", $$rmk$+"102")
	Code ($$mov, $$regreg, $$rsp, $$rbp, 0, $$XLONG, "", $$rmk$+"103")
	Code ($$pop, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"104")
	funcArgSize = funcArgSize[func_number]
	IF funcArgSize THEN
		SELECT CASE funcKind
			CASE $$XFUNC: Code ($$ret, $$imm, funcArgSize, 0, 0, 0, "", $$rmk$+"105")
			CASE $$SFUNC: IF $$linux THEN
											XcowlErr (12002455): GOTO eeeCompiler                        ' Linux
										ELSE
											Code ($$ret, $$imm, funcArgSize, 0, 0, 0, "", $$rmk$+"106")  ' Windows
										END IF
			CASE $$CFUNC: Code ($$ret, $$none, 0, 0, 0, 0, "", $$rmk$+"107")
		END SELECT
	ELSE
		Code ($$ret, $$none, 0, 0, 0, 0, "", $$rmk$+"108")
	END IF
'
'
' **********************************
' *****  Emit function PROLOG  *****
' **********************************
'
	#emitasm = 2
'
	IF i486asm THEN
		EmitNull ($$rmk1$ + "  *****")
		EmitNull ($$rmk1$ + "  *****  FUNCTION  " + funcSymbol$[func_number] + " ()  *****")
		EmitNull ($$rmk1$ + "  *****")
	END IF
'
	EmitLabel ("func" + hfn$)
	IF (funcKind == $$XFUNC)                                                                    '*cw* 230721+
		IF (i486bin || runAssm) THEN
			Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxCheckStack"+$$ftrail$+"0", $$rmk$+"109")
		END IF
	END IF                                                                                      '*cw* 230712+
	INC labelNumber: d0$ = $$ulpc$ + HEX$(labelNumber, 4)
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$push, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"110")
	Code ($$mov, $$regreg, $$rbp, $$rsp, 0, $$XLONG, "", $$rmk$+"111")
	Code ($$sub, $$regimm, $$rsp, inarg_base, 0, $$XLONG, "", $$rmk$+"112")
'
' For CFUNCTION rdi is first arg, rsi is second arg
'
	Code ($$mov, $$roreg, $$rbx, $$rbp, -24, $$XLONG, "", $$rmk$+"113")
	Code ($$mov, $$roreg, $$rdi, $$rbp, -32, $$XLONG, "", $$rmk$+"114")
	Code ($$mov, $$roreg, $$rsi, $$rbp, -40, $$XLONG, "", $$rmk$+"115")
	IF (funcKind == $$CFUNC) THEN
		IF (arg_count >= 3) THEN
			Code ($$st, $$roreg, $$rdx, $$rbp, -48, $$XLONG, "", $$rmk$+"115b")  '*cw* 230822-+ $$mov to $$st
		END IF
		IF (arg_count >= 4) THEN
			Code ($$st, $$roreg, $$rcx, $$rbp, -56, $$XLONG, "", $$rmk$+"115c")  '*cw* 230822-+ $$mov to $$st
		END IF
		IF (arg_count >= 5) THEN
			Code ($$st, $$roreg, $$r8, $$rbp, -64, $$XLONG, "", $$rmk$+"115d")  '*cw* 230822-+ $$mov to $$st
		END IF
		IF (arg_count >= 6) THEN
			Code ($$st, $$roreg, $$r9, $$rbp, -72, $$XLONG, "", $$rmk$+"115e")  '*cw* 230822-+ $$mov to $$st
		END IF
	END IF
	IF (func_number = entryFunction) THEN Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc4$+"initOnce", $$rmk$+"116")
'
	zeroz = -autoxAddr[func_number]
	IF zeroz THEN
		count = ((-40 - zeroz) >>> 3) + 1                       ' with nothing at rbp-20
		IF (funcKind == $$CFUNC) THEN
			count = (-8 * arg_count) -32
			IF (count < zeroz) THEN count = zeroz
			countz = (count - zeroz)
			count = ((count - zeroz) >>> 3) + 1
		END IF
		IF (count < 0) THEN XcowlErr (12002518): GOTO eeeCompiler      ' with nothing at rbp-20
		IF count THEN
			Code ($$cld, $$none, 0, 0, 0, 0, "", $$rmk$+"117")
			Code ($$lea, $$regro, $$rdi, $$rbp, zeroz, $$XLONG, "", $$rmk$+"118")
			Code ($$mov, $$regimm, $$rcx, count, 0, $$XLONG, "", $$rmk$+"119")
			Code ($$xor, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"120")
			Code ($$rep, $$none, 0, 0, 0, 0, "", $$rmk$+"121")
			Code ($$stosq, $$none, 0, 0, 0, 0, "", $$rmk$+"122")
		END IF
	END IF
'
' Assign addresses to AUTO and AUTOX composite handles
'
	cn = compositeNumber[func_number]
	IF cn THEN
		totalSize = compositeNext[func_number, cn].tindex
		Code ($$mov, $$regimm, $$rdi, totalSize, 0, $$XLONG, "", $$rmk$+"123")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_calloc", $$rmk$+"124")
		base = compositeToken[func_number, 0]
		Move (base.tindex, $$XLONG, $$rdi, $$XLONG)
		FOR i = 1 TO cn
			compositeToken = compositeToken[func_number, i]
			compositeStart = compositeStart[func_number, i]
			Code ($$lea, $$regro, $$rsi, $$rdi, compositeStart.tindex, $$XLONG, "", $$rmk$+"125")
			Move (compositeToken.tindex, $$XLONG, $$rsi, $$XLONG)
		NEXT i
	END IF
'
' if composite then save address where caller wants composite return value
'
	IFF TokenMatch (@crvtoken, @#T_ZERO) THEN
		Move (crvtoken.tindex, $$XLONG, $$rbx, $$XLONG)
	END IF
'
' branch to body of function
'
	IF i486bin THEN Code ($$jmp, $$rel, 0, 0, 0, 0, "funcBody" + hfn$, $$rmk$+"126")    ' v0.0201
'
	#emitasm = 2                ' 0 = "emit-this-now": 1 = "buffer-this": 2 = "flush-buffer"
	EmitAsm ($$rmk1$)           ' flush everything in assembly language output buffer
	#emitasm = 0                ' 0 = "emit-this-now": 1 = "buffer-this": 2 = "flush-buffer"
'
	IF (func_number = entryFunction) THEN
		SELECT CASE TRUE
			CASE i486asm
						EmitNull ($$rmk1$)
						EmitNull ($$rmk1$)
						EmitLabel ($$ulpc4$ + "initOnce")
						Code ($$mov, $$regabs, $$rax, 0, 0, $$XLONG, $$ulpc3$+"entered", $$rmk$+"127")
						Code ($$or,  $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"128")
						Code ($$jnz, $$rel, 0, 0, 0, 0, $$ulpc4$ + "initOnceDone", $$rmk$+"129")
						Code ($$mov, $$regimm, $$rdi, 0, 0, $$XLONG, $$ulpc3$+"firstStatic", $$rmk$+"130")
						Code ($$mov, $$regimm, $$rsi, 0, 0, $$XLONG, $$ulpc3$+"lastStatic", $$rmk$+"131")
			CASE i486bin
						EmitLabel ($$ulpc4$ + "initOnce")
						Code ($$call, $$rel, 0, 0, 0, 0, "EnteredRead", $$rmk$+"132")
						Code ($$or,  $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"133")
						Code ($$jnz, $$rel, 0, 0, 0, 0, $$ulpc4$ + "initOnceDone", $$rmk$+"134")
						Code ($$mov, $$regimm, $$rdi, ##GLOBAL0, 0, $$XLONG, "", $$rmk$+"135")
						Code ($$mov, $$regimm, $$rsi, ##GLOBALZ, 0, $$XLONG, "", $$rmk$+"136")
		END SELECT
'
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_ZeroMemory", $$rmk$+"137")
		Code ($$call, $$rel, 0, 0, 0, 0, "PrologCode", $$rmk$+"138")
		Code ($$call, $$rel, 0, 0, 0, 0, "InitSharedComposites", $$rmk$+"139")
'
		SELECT CASE TRUE
			CASE i486asm: Code ($$mov, $$absimm, 0, -1, 0, $$XLONG, $$ulpc3$+"entered", $$rmk$+"140")
			CASE i486bin: Code ($$call, $$rel, 0, 0, 0, 0, "__EnteredSetTrue", $$rmk$+"141")

		END SELECT
'
		EmitLabel ($$ulpc4$ + "initOnceDone")
		Code ($$ret, $$none, 0, 0, 0, 0, "", $$rmk$+"142")
'
		IF i486asm THEN
			EmitNull ($$rmk1$)
			EmitNull ($$rmk1$)
			EmitNull (".globl " + $$ulpc4$ + "blowback_" + program$)
			EmitLabel ($$ulpc4$ + "blowback_" + program$)
			Code ($$mov, $$absimm, 0, 0, 0, $$XLONG, $$ulpc3$+"entered", $$rmk$+"143")
			Code ($$ret, $$none, 0, 0, 0, 0, "", $$rmk$+"144")
		END IF
	END IF
'
	ina_function  = $$FALSE
	funcKind      = $$FALSE
	funcType      = $$FALSE
	func_number   = $$FALSE
	hfn$          = ""
'
	IF xargNum THEN
		FOR i = 0 TO xargNum - 1
			IF i486asm THEN
				EmitNull ("def  " + xargName$[i] + "," + STRING$ (inarg_base + xargAddr[i]))
				xargName$[i]  = ""
				xargAddr[i]   = 0
			END IF
		NEXT i
		xargNum = 0
	END IF
	RETURN
'
'
' *****  END IF  *****
'
p_endif:
p_end_if:
	got_executable = $$TRUE
	IF (nestLevel < 0) THEN XcowlErr (12002627): GOTO eeeNest
	IFF TokenMatch (nestToken[nestLevel], @#T_IF) THEN XcowlErr (12002628): GOTO eeeNest
	IF (nestLevel[nestLevel] != nestLevel) THEN XcowlErr (12002629): GOTO eeeNest
	IFZ nestInfo[nestLevel] THEN
		EmitLabel ("else." + HEX$(nestCount[nestLevel], 4))
	END IF
	EmitLabel ("end.if." + HEX$(nestCount[nestLevel], 4))
	DEC nestLevel
	NextToken (@token)
	RETURN
'
'
' *****  END SELECT *****
'
p_end_select:
	got_executable = $$TRUE
	stk = nestVar[nestLevel]
	sty = TheType (stk)
	itk = nestToken[nestLevel]
	ifc = nestInfo[nestLevel]
	isc = nestCount[nestLevel]
'
' the following line can't be: "IFF ifc THEN"  (need to test for -1)
'
	IF (ifc <> $$TRUE) THEN
		EmitLabel ("case." + HEX$(nestCount[nestLevel], 4) + "." + HEX$(ifc, 4))
	END IF
	IF (nestLevel < 0) THEN nestLevel = 0: XcowlErr (12002654): GOTO eeeNest
	IF (nestLevel[nestLevel] <> nestLevel) THEN XcowlErr (12002655): GOTO eeeNest
	IF (itk.tindex <> #T_SELECT.tindex) THEN XcowlErr (12002656): GOTO eeeNest
	IF (itk.tp.kind <> #T_SELECT.tp.kind) THEN XcowlErr (12002657): GOTO eeeNest
	EmitLabel ("end.select." + HEX$(nestCount[nestLevel], 4))
	DEC nestLevel
	NextToken (@token)
	RETURN
'
'
'
' *****  END SUB  *****
'
p_end_sub:
	got_executable = $$TRUE
	IFF insub THEN XcowlErr (12002669): GOTO eeeNest
	IF nestLevel THEN XcowlErr (12002670): GOTO eeeNest
	EmitLabel ("end.sub" + hfn$ + "." + HEX$(subCount))
	Code ($$ret, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"145")
	EmitLabel ("out.sub" + hfn$ + "." + HEX$(subCount))
	insub$ = ""
	insub = $$FALSE
	INC subCount
	NextToken (@token)
	RETURN
'
'
' *****  END PROGRAM  *****
'
p_end_program:
	got_executable = $$FALSE
	got_object_declaration = $$FALSE
	IF func_number THEN XcowlErr (12002686): GOTO eeeWithinFunction
	IF nestLevel THEN
		errNestLevel = nestLevel
		nestLevel = 0
		XcowlErr (12002690): GOTO eeeNest
	END IF
	IFZ program$ THEN program$ = programName$
	IFZ programName$ THEN programName$ = program$
'
	EmitLabel ("end_program")
	IF i486asm THEN
		EmitData ()
		EmitNull (".zero  8")
		EmitLabel ($$ulpc3$+"lastStatic")
		EmitNull (".zero  8")
		EmitText ()
	END IF
	Code ($$push, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"146")
	Code ($$mov, $$regreg, $$rbp, $$rsp, 0, $$XLONG, "", $$rmk$+"147")
	Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"148")
	IF i486asm THEN EmitNull ($$rmk1$)
'
' deallocate composite data area
'
	IF compositeNumber[0] THEN
		tk  = compositeToken[0, 0]
		Move ($$rdi, $$XLONG, tk.tindex, $$XLONG)
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"149")
	END IF
'
' deallocate STATIC and SHARED strings and arrays
'
	FOR f = 1 TO maxFuncNumber
		IF hash%[f, ] THEN
			FOR h = 0 TO 255
				IF hash%[f, h, ] THEN
					FOR j = 1 TO hash%[f, h, 0]
						k     = hash%[f, h, j]
						tk    = tab_sym[k]
						kind  = tk.tp.kind
						ttype = TheType (tk)
						tallo = tk.tp.allo
						IF ((tallo = $$STATIC) OR (tallo = $$SHARED)) THEN
							SELECT CASE kind
								CASE $$KIND_VARIABLES: IF (ttype = $$STRING) THEN Deallocate (tk)
								CASE $$KIND_ARRAYS  : Deallocate (tk)
							END SELECT
						END IF
					NEXT j
				END IF
			NEXT h
		END IF
	NEXT f
'
' return to invoking program or XBasic environment
'
	past_statics = (externalAddr + 0x0100) AND 0xFFFFFF00
	IF i486asm THEN EmitNull ($$rmk1$)
'
' from Windows version - may need when DLLs are supported
'
	IFF $$linux THEN         'win32 only
		IF i486asm THEN
			EmitNull ($$rmk1$)
			IFZ library THEN
				EmitNull (".globl "+$$flead$+"XxxTerminate"+$$ftrail$+"0")
				Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxTerminate"+$$ftrail$+"0", $$rmk$+"150")
			END IF
			EmitNull ($$rmk1$)
		END IF
	END IF
'
	Code ($$mov, $$regreg, $$rsp, $$rbp, 0, $$XLONG, "", $$rmk$+"151")
	Code ($$pop, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"152")
	Code ($$ret, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"153")
'
' assign addresses to EXTERNAL, SHARED, STATIC composite handles
'
	IF i486asm THEN
		EmitNull ($$rmk1$)
		EmitNull ($$rmk1$)
	END IF
	EmitLabel ("InitSharedComposites")
	cn = compositeNumber[0]
	IF cn THEN
		totalSize = compositeNext[0, cn].tindex
		Code ($$push, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"154")
		Code ($$mov, $$regreg, $$rbp, $$rsp, 0, $$XLONG, "", $$rmk$+"155")
		Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"156")
		Code ($$mov, $$regimm, $$rdi, totalSize, 0, $$XLONG, "", $$rmk$+"157")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_calloc", $$rmk$+"158")
		Code ($$mov, $$regreg, $$rax, $$rdi, 0, $$XLONG, "", $$rmk$+"159")
		base = compositeToken[0, 0]
		Move (base.tindex, $$XLONG, $$rax, $$XLONG)
		FOR i = 1 TO cn
			compositeToken = compositeToken[0, i]
			compositeStart = compositeStart[0, i]
			Code ($$lea, $$regro, $$rdi, $$rax, compositeStart.tindex, $$XLONG, "", $$rmk$+"160")
			Move (compositeToken.tindex, $$XLONG, $$rdi, $$XLONG)
		NEXT i
		Code ($$mov, $$regreg, $$rsp, $$rbp, 0, $$XLONG, "", $$rmk$+"161")
		Code ($$pop, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"162")
	END IF
	Code ($$ret, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"163")
'
	IF i486asm THEN
		EmitNull ($$rmk1$)
		EmitNull ($$rmk1$)
		EmitNull ($$rmk1$ + " *****  DEFINE LITERAL STRINGS  *****")
		EmitNull ($$rmk1$)
	END IF
'
' NOTE: Literal strings are compiled into READ-ONLY program memory !!!
'
	EmitText()
	EmitNull (".align 8")
	IF i486bin THEN litStringAddr = xpc
'
	xx = 0
	hfn$ = "02591"
	func_number = 0
	DO WHILE (xx < tab_sym_ptr)
		IF ((##UCODEZ - xpc) < 0x1000) THEN         ' Run out of UCODE room?
			needMoreMemory = $$TRUE
			token = #T_STARTS
			EXIT FUNCTION
		END IF
		check = tab_sym[xx]
		ktest = check.tp.kind
		ttest = check.tp.type
		IF ((ktest = $$KIND_LITERALS) AND (ttest = $$STRING)) THEN
			lit$   = tab_sym$[xx]
			litlen = LEN (lit$) - 2
			inlit$ = MID$ (lit$, 2, litlen)
			label$ = $$ulat$ + "_string." + HEX$(xx, 4)
			EmitString (label$, inlit$)
		END IF
		INC xx
	LOOP
'
	EmitString ($$ulat$ + "_string.Entry", "Entry")
	EmitString ($$ulat$ + "_string.StartLibrary", $$ulpc$ + "_StartLibrary_")
'
' Make sure all referenced GOTO and GOSUB labels were defined  (asm only)
'
	i = 0
	pass2errors = 0
	DIM errSymbol$[]
	DIM errToken[]
	DIM errAddr[]
	IF i486asm THEN GOSUB PatchAsm
	IF i486bin THEN GOSUB PatchBin
	IF pass2errors THEN
		REDIM errSymbol$[pass2errors-1]
		REDIM errToken[pass2errors-1]
		REDIM errAddr[pass2errors-1]
	END IF
'
'	PRINT "CheckState(2844)", i486asm
	IF i486asm THEN GenerateMakefile ()
'
	XxxCloseCompileFiles ()
	end_program = $$TRUE
	NextToken (@token)
	RETURN
'
' *****  PatchAsm  *****
'
SUB PatchAsm
	DO WHILE (i <= labelPtr)
		token = tab_lab[i]
		laddr = labaddr[i]
		ltype = token.tp.type
		SELECT CASE ltype
			CASE $$GOADDR, $$SUBADDR
				IFZ laddr THEN
					lab$  = MID$ (tab_lab$[i], 4)
'         name  = RINSTR (lab$, ".") - 1            ' gas ?
					name  = RINSTR (lab$, $$ulpc$) - 1            ' unspas
					lab$  = LEFT$ (lab$, name)
					IFZ pass2errors THEN PRINT "CheckState(2866):*****  PATCH ERRORS  *****"
					PRINT "GOTO label <"; lab$; "> never defined."
					INC pass2errors
				END IF
		END SELECT
		INC i
	LOOP
'
' Make sure all DECLARE functions and INTERNAL functions were defined.
'
	i = 0
	DO WHILE (i <= maxFuncNumber)
		token = funcToken[i]
		IFF TokenMatch (@token, @#T_ZERO) THEN
			flocal = funcScope[i]
			IF flocal THEN                              ' INTERNAL or DECLARE
				IFZ (token.tp.allo AND $$ALLO_DEFINED) THEN
					lab$ = funcSymbol$[i]
					laddr = 0
					IFZ pass2errors THEN PRINT "CheckState(2885):*****  PATCH ERRORS  *****"
					PRINT "Function <"; lab$; "()> declared but never defined."
					INC pass2errors
					cs_line = 3010: GOSUB AddPatchError
				END IF
			END IF
		END IF
		INC i
	LOOP
END SUB
'
' *****  PatchBin  *****
'
SUB PatchBin
	FOR i = 0 TO patchPtr - 1
		p0 = patchType[i]         ' VALUELOW, VALUEHIGH, OFFSETSHORT, OFFSETLONG, XARGOFFSET
		p1 = patchAddr[i]         ' Address to patch
		p2 = patchDest[i]         ' Token of destination label (func# for XARGOFFSET)
		pp = p2.tindex          ' Token #: destination label
		kind = p2.tp.kind         ' Token kind
		IF #cw THEN PRINT "CheckState(2908)PatchBin", HEXX$(p0), HEXX$(p1), HEXX$(pp), HEXX$(kind), HEXX$(p3), lab$
		SELECT CASE kind
			CASE $$KIND_LABELS
				p3 = labaddr[pp]      ' Address of destination
				IFZ p3 THEN
					lab$ = tab_lab$[pp]
					token = p2
					laddr = p1
					PRINT "CheckState(2916)PatchBin", HEXX$(p0), HEXX$(p1), HEXX$(pp), HEXX$(kind), HEXX$(p3), lab$
					cs_line = 3035: GOSUB AddPatchError
					DO NEXT
				END IF
			CASE $$KIND_VARIABLES, $$KIND_ARRAYS
				p3 = external_base + external_offset
				external_offset = external_offset + 8
		END SELECT
		SELECT CASE p0
			CASE $$VALUEABS
				absOffset = UBYTEAT(p1) OR (UBYTEAT(p1, 1) << 8) OR (UBYTEAT(p1, 2) << 16) OR (UBYTEAT(p1, 3) << 24)
				IF absOffset THEN PRINT "CheckState(2927): absOffset != 0"
				addr = p3 + absOffset
				UBYTEAT (p1) = addr AND 0xFF
				UBYTEAT (p1, 1) = (addr AND 0xFF00) >> 8
				UBYTEAT (p1, 2) = (addr AND 0xFF0000) >> 16
				UBYTEAT (p1, 3) = (addr AND 0xFF000000) >> 24
			CASE $$VALUEDISP
				addr = p3 - (p1 + 4)
				UBYTEAT (p1) = addr AND 0xFF
				UBYTEAT (p1, 1) = (addr AND 0xFF00) >> 8
				UBYTEAT (p1, 2) = (addr AND 0xFF0000) >> 16
				UBYTEAT (p1, 3) = (addr AND 0xFF000000) >> 24
			CASE ELSE
				PRINT "CheckState(2940):patch error"
				XcowlErr (12002937): GOTO eeeCompiler
		END SELECT
	NEXT i
'
' Check for never defined functions
'
	i = 0
	DO WHILE (i <= maxFuncNumber)
		token = funcToken[i]
		IFF TokenMatch (@token, @#T_ZERO) THEN
			flocal = funcScope[i]
			IF flocal THEN                              ' INTERNAL or DECLARE
				IFZ (token.tp.allo AND $$ALLO_DEFINED) THEN
					lab$ = funcSymbol$[i]
					laddr = 0
					cs_line = 2956: GOSUB AddPatchError
				END IF
			END IF
		END IF
		INC i
	LOOP
END SUB
'
' *****  Log Patch Errors  *****
'
SUB AddPatchError
	upper = UBOUND (errAddr[])
	IF (pass2errors > upper) THEN
		upper = upper + 64
		REDIM errSymbol$[upper]
		REDIM errToken[upper]
		REDIM errAddr[upper]
	END IF
	kind = p2.tp.kind
	tnum = p2.tindex
	SELECT CASE kind
		CASE $$KIND_LABELS
					ltype = token.tp.type
					IF ((ltype = $$GOADDR) OR (ltype = $$SUBADDR)) THEN
						lab$ = MID$ (lab$, 4)
'           name = RINSTR (lab$, ".") - 1           ' gas ?
						name = RINSTR (lab$, $$ulpc$) - 1
						lab$ = LEFT$ (lab$, name)
					END IF
		CASE ELSE
					PRINT "CheckState(2982): Error: (patch token kind != label): EXIT SUB"
	END SELECT
	IF ##XBDV THEN PRINT "CheckState(2984)AddPatchError", cs_line, HEX$(token.tproto,8);;HEX$(token.tindex,8);; HEX$(laddr,8);; lab$
	errSymbol$[pass2errors] = lab$
	errToken[pass2errors] = token
	errAddr[pass2errors] = laddr
	INC pass2errors
END SUB
'
'
' *****  EXIT  *****  EXIT  { DO | FOR | FUNCTION | IF | SELECT | SUB }
'
p_exit:
	got_executable = $$TRUE
	NextToken (@token)
	PeekToken (@levelToken)
	levelKind = levelToken.tp.kind
	IF (levelKind = $$KIND_LITERALS) THEN
		ll = levelToken.tindex
		IFZ m_addr$[ll] THEN AssignAddress (levelToken)
		IF XERROR THEN EXIT FUNCTION
		ll = levelToken.tindex
		exitLevels = XLONG (r_addr$[ll])
		skipLevels = $$TRUE
	ELSE
		skipLevels = $$FALSE
		exitLevels = 1
	END IF
'
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_DO)
				checkLevel = nestLevel
				checkToken = #T_DO
				GOSUB NestWalk
				d1$ = "end.do." + HEX$(nestCount[checkLevel], 4)
				Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"164")
		CASE TokenMatch (@token, @#T_FOR)
				checkLevel = nestLevel
				checkToken = #T_FOR
				GOSUB NestWalk
				d1$ = "end.for." + HEX$(nestCount[checkLevel], 4)
				Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"165")
		CASE TokenMatch (@token, @#T_FUNCTION)
				IF (exitLevels != 1) THEN XcowlErr (12003025): GOTO eeeSyntax
				GOTO p_return
		CASE TokenMatch (@token, @#T_IF)
				checkLevel = nestLevel
				checkToken = #T_IF
				GOSUB NestWalk
				d1$ = "end.if." + HEX$(nestCount[checkLevel], 4)
				Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"166")
		CASE TokenMatch (@token, @#T_SELECT)
				checkLevel = nestLevel
				checkToken = #T_SELECT
				GOSUB NestWalk
				d1$ = "end.select." + HEX$(nestCount[checkLevel], 4)
				Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"167")
		CASE TokenMatch (@token, @#T_SUB)
				IFZ insub THEN XcowlErr (12003040): GOTO eeeNest
				IF (exitLevels != 1) THEN XcowlErr (12003041): GOTO eeeSyntax
				d1$ = "end.sub" + hfn$ + "." + HEX$(subCount)
				Code ($$jmp, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"168")
		CASE ELSE
				XcowlErr (12003045): GOTO eeeSyntax
	END SELECT
	IF skipLevels THEN NextToken (@token)
	NextToken (@token)
	RETURN
'
'
' *****
' *****  Walk down "nest-stack" to find nth checkToken (IF, DO, FOR, SELECT)
' *****
'
SUB NestWalk
	checkLevel = nestLevel
	DO WHILE checkLevel
		nestToken = nestToken[checkLevel]
		IF (nestToken.tindex == checkToken.tindex) THEN
			IF (nestToken.tp.kind == checkToken.tp.kind) THEN
				DEC exitLevels
				IFZ exitLevels THEN EXIT DO
			END IF
		END IF
		DEC checkLevel
	LOOP
	IFZ checkLevel THEN XcowlErr (12003068): GOTO eeeNest
END SUB
'
'
' *****  FOR  *****
'
p_for:
	got_executable = $$TRUE
	INC nestCount
	INC nestLevel
	nestVar[nestLevel]    = #T_ZERO
	nestInfo[nestLevel]   = 0
	nestStep[nestLevel]   = 0
	nestLimit[nestLevel]  = 0
	nestToken[nestLevel]  = token
	nestLevel[nestLevel]  = nestLevel
	nestCount[nestLevel]  = nestCount
	NextToken (@forToken)
	kind      = forToken.tp.kind
	forVar    = forToken.tindex
	forType   = TheType (forToken)
	IF (kind <> $$KIND_VARIABLES) THEN XcowlErr (12003089): GOTO eeeSyntax
	IF (forType < $$SLONG) THEN forType = $$SLONG
	IF (forType > $$DOUBLE) THEN XcowlErr (12003091): GOTO eeeTypeMismatch
	IFZ m_addr[forVar] THEN AssignAddress (forToken)
	IF XERROR THEN EXIT FUNCTION
	forReg    = r_addr[forVar]
	nestVar[nestLevel] = forToken
'
	PeekToken (@check)
	IFF TokenMatch (@check, @#T_EQ) THEN XcowlErr (12003098): GOTO eeeSyntax
' PRINT "CheckState(3099):forToken", HEX$(forToken.tproto,8); "."; HEX$(forToken.tindex)
	token = forToken
	CheckState (@token)
	IF XERROR THEN EXIT FUNCTION
	IFF TokenMatch (@token, @#T_TO) THEN XcowlErr (12003103): GOTO eeeSyntax
	token = Eval (@result_type)
	IF XERROR THEN EXIT FUNCTION
	xr = Top ()
	IFZ xr THEN XcowlErr (12003107): GOTO eeeSyntax
	Conv (xr, forType, xr, result_type)
	flname$ = ".forlimit" + HEX$(func_number) + "." + HEX$(nestCount, 4)
	fltoken = AddSymbol (@flname$, 0, $$KIND_VARIABLES, 0, forType, func_number)
	fl      = fltoken.tindex
	IF m_addr$[fl] THEN XcowlErr (12003112): GOTO eeeCompiler
	AssignAddress (fltoken)
	IF XERROR THEN EXIT FUNCTION
	limReg  = r_addr[fl]
	Move (fltoken.tindex, forType, xr, forType)
	nestLimit[nestLevel] = fltoken.tindex
	SELECT CASE xr
		CASE $$RA0:   a0 = 0: a0_type = 0: DEC toes
		CASE $$RA1:   a1 = 0: a1_type = 0: DEC toes
	END SELECT
	stepType = forType
	IF TokenMatch (@token, @#T_STEP) THEN
		token = Eval (@result_type)
		IF XERROR THEN EXIT FUNCTION
		acc = Top ()
		IFZ acc THEN XcowlErr (12003127): GOTO eeeSyntax
		def_step = $$FALSE
		' The step-type must be signed to allow for negative step-values.
		IF stepType == $$ULONG THEN stepType = $$SLONG
		IF stepType == $$USHORT THEN stepType = $$SSHORT
		IF stepType == $$UBYTE THEN stepType = $$SBYTE
		Conv (acc, stepType, acc, result_type)
		fsname$ = ".forstep" + HEX$(func_number) + "." + HEX$(nestCount, 4)
		fstoken = AddSymbol (@fsname$, 0, $$KIND_VARIABLES, 0, forType, func_number)
		fs = fstoken.tindex
		IF m_addr$[fs] THEN XcowlErr (12003137): GOTO eeeCompiler
		AssignAddress (fstoken)
		IF XERROR THEN EXIT FUNCTION
		stepReg = r_addr[fs]
		IF (stepReg >= $$IMM16) THEN stepReg = 0
		Move (fstoken.tindex, forType, acc, forType)
		nestStep[nestLevel] = fstoken.tindex
		SELECT CASE acc
			CASE $$RA0:   a0 = 0: a0_type = 0: DEC toes
			CASE $$RA1:   a1 = 0: a1_type = 0: DEC toes
		END SELECT
	ELSE
		def_step = $$TRUE
		nestStep[nestLevel] = 0
	END IF
	nestInfo[nestLevel] = def_step
	IF (i486bin  || runAssm) THEN
		dbname$ = ".forbreak" + HEX$(func_number) + "." + HEX$(nestCount,4)
		dbtoken = AddSymbol (@dbname$, 0, $$KIND_VARIABLES, 0, $$XLONG, func_number)
		db = dbtoken.tindex
		IF m_addr$[db] THEN XcowlErr (12003157): GOTO eeeCompiler
		AssignAddress (dbtoken)
		IF XERROR THEN EXIT FUNCTION
		Code ($$mov, $$regimm, $$rax, 0, 0, $$XLONG, "", $$rmk$+"169")
		Move (dbtoken.tindex, $$XLONG, $$rax, $$XLONG)
	END IF
'
' setup of FOR variables complete... now do "test at top" code
'
	EmitLabel ("for." + HEX$(nestCount[nestLevel], 4))
	endfor$ = "end.for." + HEX$(nestCount[nestLevel], 4)
	Move ($$RA0, forType, forVar, forType)
	Move ($$RA1, forType, fltoken.tindex, forType)
	IF (forType = $$ULONG) THEN jmp486 = $$ja ELSE jmp486 = $$jg
'
' compare forVar with limit and branch based on SIGN of step value
'
	IFZ def_step THEN
		INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber,4)
		SELECT CASE forType
			CASE $$DOUBLE:  fakeType = $$GIANT: treg = $$rdi
			CASE $$SINGLE:  fakeType = $$XLONG: treg = $$rsi
			CASE $$GIANT:   fakeType = $$GIANT: treg = $$rdi
			CASE ELSE:      fakeType = $$XLONG: treg = $$rsi
		END SELECT
		Move ($$rsi, fakeType, fstoken.tindex, fakeType)
	END IF
	SELECT CASE forType
		CASE  $$DOUBLE, $$SINGLE
					IFZ def_step THEN
						Code ($$or, $$regreg, treg, treg, 0, $$XLONG, "", $$rmk$+"170")
						Code ($$jns, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"171")
						Code ($$fxch, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"172")
						EmitLabel (@d1$)
					END IF
					Code ($$fcompp, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"173")
					Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"174")
					Code ($$sahf, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"175")
					Code ($$jb, $$rel, 0, 0, 0, 0, endfor$, $$rmk$+"176")
		CASE ELSE
					IFZ def_step THEN
						Code ($$or, $$regreg, treg, treg, 0, $$XLONG, "", $$rmk$+"191")
						Code ($$jns, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"192")
						Code ($$xchg, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"193")
						EmitLabel (@d1$)
					END IF
					Code ($$cmp, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"194")
					Code (jmp486, $$rel, 0, 0, 0, 0, endfor$, $$rmk$+"195")
	END SELECT
	a0_type = 0
	a1_type = 0
	IF (i486bin || runAssm) THEN
		INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
		Move ($$rax, $$XLONG, dbtoken.tindex, $$XLONG)
		Code ($$inc, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"196")
		Move (dbtoken.tindex, $$XLONG, $$rax, $$XLONG)
		Code ($$and, $$regimm, $$rax, 0x000000ff, 0, $$XLONG, "", $$rmk$+"197")
		Code ($$jnz, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"198")
		Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxCheckMessages"+$$ftrail$+"0", $$rmk$+"199")
		EmitLabel (@d1$)
		a0_type = 0
		a1_type = 0
	END IF
	RETURN
'
'
' *****  FUNCTION  *****
'
' [C|S]FUNCTION [type.name] function.name ( [argument.list] ) [default.type]
'
p_xfunction:
	IF ina_function THEN XcowlErr (12003228): GOTO eeeWithinFunction
	IFZ program$ THEN program$ = programName$
	EmitText()
'
	SELECT CASE funcKind
		CASE $$XFUNC: funcKind = $$XFUNC
		CASE $$SFUNC: IF $$linux THEN
										funcKind = $$CFUNC  ' Linux
									ELSE
										funcKind = $$XFUNC  ' Windows
									END IF
		CASE $$CFUNC: funcKind = $$CFUNC
		CASE ELSE   : XcowlErr (12003240): GOTO eeeCompiler
	END SELECT
'
	IFZ got_function THEN
		IFZ prologCode THEN
			EmitText()
			SELECT CASE TRUE
				CASE library:  Code ($$jmp, $$rel, 0, 0, 0, 0, $$ulpc$+"_StartLibrary_" + program$, $$rmk$+"200")
				CASE ELSE   :  Code ($$jmp, $$rel, 0, 0, 0, 0, $$ulpc$+"_StartApplication", $$rmk$+"201")
			END SELECT
			prologCode = $$TRUE
			EmitLabel ("PrologCode")
			Code ($$ret, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"202")
		ELSE
			Code ($$mov, $$regreg, $$rsp, $$rbp, 0, $$XLONG, "", $$rmk$+"203")    ' end of PrologCode
			Code ($$pop, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"204")
			Code ($$ret, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"205")
		END IF
		IF i486asm THEN EmitNull ($$rmk1$)
	END IF
	insub = 0
	insub$ = ""
	subCount = 0
	nestLevel = 0
	nestError = $$FALSE
	got_function = $$TRUE
	NextToken (@token)
	tn = TypenameToken (@token)
	IFZ tn THEN tn = token.tp.type
	IF (tn < $$SLONG) THEN tn = $$XLONG
	ft = TheType (token)
	IF (tn <> ft) THEN XcowlErr (12003271): GOTO eeeTypeMismatch
'
	kind = token.tp.kind
	IF (kind != $$KIND_FUNCTIONS) THEN XcowlErr (12003274): GOTO eeeSyntax
	IFZ (token.tp.allo AND $$ALLO_DECLARED) THEN XcowlErr (12003275): GOTO eeeUndeclared
	IF (token.tp.allo AND $$ALLO_DEFINED) THEN XcowlErr (12003276): GOTO eeeDupDefinition
	ina_function  = $$TRUE
	func_number   = token.tindex
	funcScope     = funcScope[func_number]
	IF (funcKind != funcKind[func_number]) THEN XcowlErr (12003280): GOTO eeeCrossedFunctions
	SELECT CASE funcScope
		CASE $$FUNC_DECLARE
		CASE $$FUNC_INTERNAL
		CASE $$FUNC_EXTERNAL: XcowlErr (12003284): GOTO eeeInternalExternal
		CASE ELSE:            XcowlErr (12003285): GOTO eeeCompiler
	END SELECT
	funcToken               = token
	funcToken.tp.allo       = token.tp.allo OR $$ALLO_DEFINED
	funcToken[func_number]  = funcToken
	autoxAddr[func_number]  = 0x00
	inargAddr[func_number]  = 0x00
	autoAddr[func_number]   = 0x00
	hfn$                    = HEX$(func_number)
	f$                      = "func" + hfn$
	compositeArg            = 0
	crvtoken                = #T_ZERO
'
	IF (func_number = entryFunction) THEN
		SELECT CASE TRUE
			CASE library: EmitNull  (".globl  " + $$ulpc$+"_StartLibrary_" + program$)
											EmitLabel ($$ulpc$+"_StartLibrary_" + program$)
			CASE ELSE   : EmitNull  (".globl  " + $$ulpc$+"_StartApplication")
											EmitLabel ($$ulpc$+"_StartApplication")
		END SELECT
'
' In case entry function takes arguments
'
		atsign = RINSTR (funcLabel$[func_number], $$ftrail$)
		IF atsign THEN
			size$ = MID$ (funcLabel$[func_number],atsign+1)
			IF size$ THEN
				after = size${0}
				IF (after >= '0') THEN
					IF (after <= '9') THEN
						bytes = XLONG(size$)
						byte$ = STRING$(bytes)
						IF (size$ = byte$) THEN
							IF bytes THEN
								IF (bytes AND 0x0003) THEN XcowlErr (12003319): GOTO eeeCompiler     ' must be mod 4
								pushes = (bytes >> 2)
								Code ($$xor, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"206")
								FOR i = 1 TO pushes
									Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"207")
								NEXT i
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
		Code ($$call, $$rel, 0, 0, 0, 0, @f$, $$rmk$+"208")
		Code ($$ret, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"209")
		IF i486asm THEN EmitNull ($$rmk1$)
	END IF
'
	IF (ft >= $$SCOMPLEX) THEN
		crvname$  = ".compositeReturnValue"
		crvtoken  = AddSymbol (@crvname$, 0, $$KIND_VARIABLES, $$AUTOX, type, func_number)
		crvtoken.tp.allo = crvtoken.tp.allo OR $$AUTOX
		crvnum    = crvtoken.tindex
		IF m_addr[crvnum] THEN XcowlErr (12003341): GOTO eeeCompiler
		tab_sym[crvnum] = crvtoken
		tabType[crvnum] = ft
		AssignAddress (crvtoken)
		IF XERROR THEN EXIT FUNCTION
	END IF
'
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (12003349): GOTO eeeSyntax
'
	arg_count     = 0
	argNum        = 1
	PeekToken (@token)
	paramCount    = funcArg[func_number, 0].tp.type
	IF TokenMatch (@token, @#T_RPAREN) THEN
		NextToken (@token)
		IF paramCount THEN XcowlErr (12003357): GOTO eeeTooFewArgs
	ELSE
		anyArg = #T_ZERO
		anyOpen   = $$FALSE
		DO
			NextToken (@token)
			SELECT CASE TRUE
				CASE TokenMatch (@token, @#T_ATSIGN): NextToken (@token) ' ignore @ prefix
				CASE TokenMatch (@token, @#T_LPAREN): IF anyOpen THEN XcowlErr (12003365): GOTO eeeSyntax
												NextToken (@token)
												anyOpen = $$TRUE
			END SELECT
			temp_type = TypenameToken (@token)
			IF (temp_type = $$ETC) THEN XcowlErr (12003370): GOTO eeeSyntax
			kind = token.tp.kind
			SELECT CASE kind
				CASE $$KIND_VARIABLES
				CASE $$KIND_ARRAYS:     NextToken (@tokTmp)
																IFF TokenMatch (@tokTmp, @#T_LBRAK) THEN  XcowlErr (12003375): GOTO eeeSyntax
																NextToken (@tokTmp)
																IFF TokenMatch (@tokTmp, @#T_RBRAK) THEN  XcowlErr (12003377): GOTO eeeSyntax
				CASE ELSE:              XcowlErr (12003378): GOTO eeeSyntax
			END SELECT
			tt = token.tindex
			token_type  = token.tp.type
			IF token_type THEN
				IF (temp_type AND (token_type <> temp_type)) THEN XcowlErr (12003383): GOTO eeeTypeMismatch
				temp_type = token_type
			ELSE
				IFZ temp_type THEN temp_type = $$XLONG
			END IF
			token.tp.allo = $$ARGUMENT
			tabType[tt] = temp_type
			UpdateToken (token)
			IF (arg_count >= paramCount) THEN XcowlErr (12003391): GOTO eeeTooManyArgs
			funcArg     = funcArg[func_number, argNum]
			p_type      = funcArg.tindex
			p_kind      = funcArg.tp.kind
			IF (p_type = $$ANY) THEN
				SELECT CASE p_kind
					CASE $$KIND_ARRAYS
								IF (kind = $$KIND_VARIABLES) THEN XcowlErr (12003398): GOTO eeeKindMismatch
					CASE $$KIND_VARIABLES
								IF (kind = $$KIND_VARIABLES) THEN
'									IF ((temp_type = $$GIANT) OR (temp_type = $$DOUBLE)) THEN                         '*cw* 220915-
'										IF (arg_count < (paramCount-1)) THEN XcowlErr (12003402): GOTO eeeTypeMismatch  '*cw* 220915-
										IF (arg_count < (paramCount-2)) THEN XcowlErr (12003402): GOTO eeeTypeMismatch  '*cw* 220915+
'										XcowlErr (12003403): GOTO eeeTypeMismatch                                       '*cw* 220915-
'									END IF                                                                            '*cw* 220915-
								END IF
				END SELECT
				IFF TokenMatch (@anyArg, @#T_ZERO) THEN
					tt          = token.tindex
					m_addr$[tt] = m_addr$[anyArgNum]
					r_addr$[tt] = r_addr$[anyArgNum]
					m_addr[tt]  = m_addr[anyArgNum]
					r_addr[tt]  = r_addr[anyArgNum]
					m_reg[tt]   = m_reg[anyArgNum]
				ELSE
					AssignAddress (token)
					IF XERROR THEN EXIT FUNCTION
					anyArg      = tab_sym[token.tindex]
					anyArgNum   = anyArg.tindex
				END IF
				NextToken (@token)
				IF anyOpen THEN
					IFF TokenMatch (token,#T_RPAREN) THEN DO LOOP
					NextToken (@token)
				END IF
				anyOpen     = $$FALSE
				anyArg = #T_ZERO
				anyArgNum   = $$FALSE
				INC argNum
				INC arg_count
				DO LOOP
			ELSE
				IF anyOpen THEN XcowlErr (12003432): GOTO eeeSyntax
				IF (kind != p_kind) THEN XcowlErr (12003433): GOTO eeeKindMismatch
				IF (temp_type != p_type) THEN
					IF (p_type != $$ETC) THEN
						XcowlErr (12003436): GOTO eeeTypeMismatch
					END IF
				END IF
			END IF
			AssignAddress (token)
			INC argNum
			INC arg_count
			IF XERROR THEN EXIT FUNCTION
			NextToken (@token)
		LOOP WHILE TokenMatch (@token, @#T_COMMA)
		IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (12003446): GOTO eeeSyntax
	END IF
	IF (arg_count < paramCount) THEN XcowlErr (12003448): GOTO eeeTooFewArgs
'
' check for optional default.type field
'
	NextToken (@token)
	fdtype  = TypenameToken (@token)
	IFZ fdtype THEN fdtype = $$XLONG
	upperDT = UBOUND(defaultType[])
	IF (upperDT < func_number) THEN
		REDIM defaultType[func_number]
		PRINT "CheckState(3458)", upperDT, func_number
	END IF
	defaultType[func_number] = fdtype
'
' Put branch to function entry point instruction, then "funcBody" label
'
	EmitFunctionLabel (funcLabel$[func_number])
'
' #####  v0.0201  #####
' The following section of code was added so the beginning part of
' the function could be emitted here rather than after the function.
'
	#emitasm = 2                ' 0 = "emit-this-now": 1 = "buffer-this": 2 = "flush-buffer"
	EmitAsm ($$rmk1$)           ' flush all assembly language output from the asm buffer
	#emitasm = 1                ' 0 = "emit-this-now": 1 = "buffer-this": 2 = "flush-buffer"
'
	IF i486bin THEN Code ($$jmp, $$rel, 0, 0, 0, 0, f$, $$rmk$+"210")     ' v0.0201
'
	EmitLabel ("funcBody" + HEX$(func_number))
	RETURN
'
'
' *****  GOSUB  *****
'
p_gosub:
	got_executable = $$TRUE
	code_l  = $$call
	code_v  = $$call
	gsub    = $$TRUE
	GOTO p_gox
'
'
' ****  GOTO  *****
'
p_goto:
	got_executable = $$TRUE
	code_l  = $$jmp
	code_v  = $$jmp
	gsub    = $$FALSE
'
p_gox:
	computed = $$FALSE
	NextToken (@token)
	IF TokenMatch (@token, @#T_ATSIGN) THEN computed = $$TRUE: NextToken (@token)
	go_type = TheType (token)
	tt    = token.tindex
	kind  = token.tp.kind
	SELECT CASE kind
		CASE $$KIND_LABELS  : GOTO p_goto_label
		CASE $$KIND_VARIABLES: GOTO p_goto_expression
		CASE $$KIND_ARRAYS  : GOTO p_goto_expression
		CASE ELSE            : XcowlErr (12003509): GOTO eeeTypeMismatch
	END SELECT
'
'
p_goto_label:
	IF computed THEN XcowlErr (12003514): GOTO eeeTypeMismatch
	GOSUB CheckGoType
	tt$ = tab_lab$[tt]
	Code (code_l, $$rel, 0, 0, 0, 0, tt$, $$rmk$+"211")
	NextToken (@token)
	RETURN
'
p_goto_expression:
	IFZ computed THEN XcowlErr (12003522): GOTO eeeTypeMismatch
	DEC tokenPtr
	token = Eval (@go_type)
	IF XERROR THEN EXIT FUNCTION
	GOSUB CheckGoType
	acc = Topax1 ()
	IFZ acc THEN XcowlErr (12003528): GOTO eeeSyntax
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"212")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"213")
	Code (code_v, $$reg, acc, 0, 0, 0, "", $$rmk$+"214")
	EmitLabel (@d1$)
	RETURN
'
'
' *****  CheckGoType  *****
'
SUB CheckGoType
	IF gsub THEN
		IF (go_type <> $$SUBADDR) THEN XcowlErr (12003541): GOTO eeeBadGosub
	ELSE
		IF (go_type <> $$GOADDR) THEN XcowlErr (12003543): GOTO eeeBadGoto
	END IF
END SUB
'
' *****  IF  and IFT  *****  IF TRUE  (non-zero)
' *****  IFF and IFZ  *****  IF FALSE   (zero)
'
p_ifx:
	got_executable = $$TRUE
	IF ifLine THEN XcowlErr (12003552): GOTO eeeNest
	ifLine = $$TRUE
	INC nestCount
	INC nestLevel
	nestLevel[nestLevel] = nestLevel
	nestCount[nestLevel] = nestCount
	nestToken[nestLevel] = #T_IF
	nestInfo[nestLevel] = 0
	where$ = "else." + HEX$(nestCount[nestLevel], 4)
	GOSUB Tester
	IF ifc THEN
		GOSUB TestTrue
	ELSE
		GOSUB TestFalse
	END IF
p_if_q_then_part:
	tokTmp = token
	tokTmp.tp.type = 0
	tokTmp.tp.allo = 0
	SELECT CASE TRUE
		CASE TokenMatch (@tokTmp, @#T_REM)   : RETURN
		CASE TokenMatch (@tokTmp, @#T_STARTS): RETURN
		CASE TokenMatch (@tokTmp, @#T_THEN)  : NextToken (@token): GOTO p_if_q_then_part
		CASE TokenMatch (@tokTmp, @#T_COMMA) : NextToken (@token): GOTO p_if_q_then_part
		CASE TokenMatch (@tokTmp, @#T_SEMI)  : NextToken (@token): GOTO p_if_q_then_part
		CASE TokenMatch (@tokTmp, @#T_COLON) : NextToken (@token): GOTO p_if_q_then_part
	END SELECT
p_if_then:
	CheckState (@token)
	IF XERROR THEN EXIT FUNCTION
	kind = token.tp.kind
	IF TokenMatch (@token, @#T_COLON) THEN NextToken (@token):  GOTO p_if_then
	SELECT CASE kind
		CASE $$KIND_TERMINATORS: GOTO p_end_if_line
		CASE $$KIND_COMMENTS   : GOTO p_end_if_line
		CASE $$KIND_STARTS     : GOTO p_end_if_line
	END SELECT
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_IF) : XcowlErr (12003590): GOTO eeeNest
		CASE TokenMatch (@token, @#T_END): NextToken (@token): GOTO p_q_end_if_line
		CASE ELSE:                            GOTO p_if_then
	END SELECT
p_q_end_if_line:
	IFF TokenMatch (@token, @#T_IF) THEN XcowlErr (12003595): GOTO eeeNest
p_end_if_line:
	IFZ nestInfo[nestLevel] THEN
		EmitLabel ("else." + HEX$(nestCount[nestLevel], 4))
	END IF
	EmitLabel ("end.if." + HEX$(nestCount[nestLevel], 4))
	nestInfo[nestLevel] = 0
	DEC nestLevel
	NextToken (@token)
	RETURN
'
'
' *****  GENERIC test for true/false and branch to specified label  *****
'        Used by CASE, DO, IF, LOOP  (works on strings and null arrays)
'        NOTE:  True and False routines CANNOT be consolidated.  Don't try!
'
SUB Tester
	new_test = $$TRUE: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	nn = new_data.tindex
	token = new_op
	rn = Reg (nn)
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		SELECT CASE TRUE
			CASE (rn AND (rn < $$IMM16))
				mode    = $$regreg
				acc     = rn
				accx    = rn + 1
			CASE ELSE
				mode    = $$regreg
				acc     = $$rax
				accx    = $$rdx
				Move ($$rax, new_type, new_data.tindex, new_type)
				a0      = 0
				a0_type = 0
		END SELECT
	ELSE
		mode  = $$regreg
		acc   = Topax1 ()
		accx  = acc + 1
		IFZ acc THEN XcowlErr (12003638): GOTO eeeSyntax
		IF (acc != $$RA0) THEN XcowlErr (12003639): GOTO eeeCompiler
		expression = $$TRUE
	END IF
END SUB
'
' **************************
' *****  SUB TestTrue  *****  (Use after SUB Tester)
' **************************
'
SUB TestTrue
	SELECT CASE new_type
		CASE $$DOUBLE:  GOTO TrueDouble
		CASE $$SINGLE:  GOTO TrueSingle
		CASE $$STRING:  GOTO TrueString
		CASE ELSE:      GOTO TrueOthers
	END SELECT
'
TrueGiant:
	Code ($$mov, $$regreg, $$rsi, acc, 0, $$XLONG, "", $$rmk$+"215")
	Code ($$or, $$regreg, $$rsi, accx, 0, $$XLONG, "", $$rmk$+"216")
	Code ($$jnz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"217")
	EXIT SUB
'
TrueDouble:
	Code ($$fldz, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"218")
	Code ($$fcompp, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"219")
	Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"220")
	Code ($$sahf, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"221")
	Code ($$jnz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"222")
	EXIT SUB
'
TrueSingle:
	Code ($$fldz, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"223")
	Code ($$fcompp, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"224")
	Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"225")
	Code ($$sahf, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"226")
	Code ($$jnz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"227")
	EXIT SUB
'
TrueString:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	IF (oos[oos] = 's') THEN
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"228")
		Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"229")
		Code ($$mov, $$regreg, $$rdi, acc, 0, $$XLONG, "", $$rmk$+"230")
		Code ($$ld, $$regro, acc, acc, -16, $$XLONG, "", $$rmk$+"231")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"232")
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"233")
		Code ($$jnz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"234")
	ELSE
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"235")
		Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"236")
		Code ($$ld, $$regro, acc, acc, -16, $$XLONG, "", $$rmk$+"237")
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"238")
		Code ($$jnz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"239")
	END IF
	EmitLabel (@d1$)
	DEC oos
	EXIT SUB
'
TrueOthers:
	IF new_test THEN
		GOSUB ConvCondBitTrue
		Code (jmp486, $$rel, 0, 0, 0, 0, where$, $$rmk$+"240")
	ELSE
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"241")
		Code ($$jnz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"242")
	END IF
END SUB
'
' ***************************
' *****  SUB TestFalse  *****  (Use after SUB Tester)
' ***************************
'
SUB TestFalse
	SELECT CASE new_type
		CASE $$GIANT:   GOTO FalseGiant
		CASE $$DOUBLE:  GOTO FalseDouble
		CASE $$SINGLE:  GOTO FalseSingle
		CASE $$STRING:  GOTO FalseString
		CASE ELSE:      GOTO FalseOthers
	END SELECT
'
FalseGiant:
	Code ($$mov, $$regreg, $$rsi, acc, 0, $$XLONG, "" , $$rmk$+"243")
	Code ($$or, $$regreg, $$rsi, accx, 0, $$XLONG, "", $$rmk$+"244")
	Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"245")
	EXIT SUB
'
FalseDouble:
	Code ($$fldz, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"246")
	Code ($$fcompp, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"247")
	Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"248")
	Code ($$sahf, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"249")
	Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"250")
	EXIT SUB
'
FalseSingle:
	Code ($$fldz, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"251")
	Code ($$fcompp, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"252")
	Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"253")
	Code ($$sahf, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"254")
	Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"255")
	EXIT SUB
'
FalseString:
	IF (oos[oos] = 's') THEN
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "" , $$rmk$+"256")
		Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"257")
		Code ($$mov, $$regreg, $$rdi, acc, 0, $$XLONG, "", $$rmk$+"258")
		Code ($$ld, $$regro, acc, acc, -16, $$XLONG, "", $$rmk$+"259")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"260")
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"261")
		Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"262")
	ELSE
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "" , $$rmk$+"263")
		Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"264")
		Code ($$ld, $$regro, acc, acc, -16, $$XLONG, "", $$rmk$+"265")
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"266")
		Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"267")
	END IF
	DEC oos
	EXIT SUB
'
FalseOthers:
	IF new_test THEN
		GOSUB ConvCondBitFalse
		Code (jmp486, $$rel, 0, 0, 0, 0, where$, $$rmk$+"268")
	ELSE
		Code ($$or, $$regreg, acc, acc, 0, $$XLONG, "", $$rmk$+"269")
		Code ($$jz, $$rel, 0, 0, 0, 0, where$, $$rmk$+"270")
	END IF
END SUB
'
'
' *****  ConvCondBitTrue  *****
'
' Sets jmp486 to 80386 conditional jump opcode that corresponds to
' the 88000 condition bit in new_test being true.
'
SUB ConvCondBitTrue
	SELECT CASE new_test
		CASE 2:     jmp486 = $$je
		CASE 3: jmp486 = $$jne
		CASE 4:     jmp486 = $$jg
		CASE 5:     jmp486 = $$jle
		CASE 6:     jmp486 = $$jl
		CASE 7:     jmp486 = $$jge
		CASE 8:     jmp486 = $$ja
		CASE 9:     jmp486 = $$jbe
		CASE 10:    jmp486 = $$jb
		CASE 11:    jmp486 = $$jae
		CASE ELSE:  jmp486 = -1
	END SELECT
END SUB
'
' *****  ConvCondBitFalse  *****
'
' Sets jmp486$ to 80386 conditional jump mnemonic that corresponds to
' the 88000 condition bit in new_test being false.
'
SUB ConvCondBitFalse
	SELECT CASE new_test
		CASE 2:     jmp486 = $$jne
		CASE 3: jmp486 = $$je
		CASE 4:     jmp486 = $$jle
		CASE 5:     jmp486 = $$jg
		CASE 6:     jmp486 = $$jge
		CASE 7:     jmp486 = $$jl
		CASE 8:     jmp486 = $$jbe
		CASE 9:     jmp486 = $$ja
		CASE 10:    jmp486 = $$jae
		CASE 11:    jmp486 = $$jb
		CASE ELSE:  jmp486 = -1
	END SELECT
END SUB
'
'
' *****  LOOP  *****
'
p_loop:
	got_executable = $$TRUE
	IF (nestLevel < 0) THEN nestLevel = 0: XcowlErr (12003821): GOTO eeeNest
	IFF TokenMatch (nestToken[nestLevel], @#T_DO) THEN XcowlErr (12003822): GOTO eeeNest
	IF (nestLevel[nestLevel] <> nestLevel) THEN XcowlErr (12003823): GOTO eeeNest
	NextToken (@token)
	EmitLabel ("do.loop." + HEX$(nestCount[nestLevel], 4))
	IF TokenMatch (@token, @#T_WHILE) THEN ifc = $$TRUE:  GOTO loopx
	IF TokenMatch (@token, @#T_UNTIL) THEN ifc = $$FALSE: GOTO loopx
	Code ($$jmp, $$rel, 0, 0, 0, 0, "do." + HEX$(nestCount[nestLevel], 4), $$rmk$+"271")
	GOTO finish_loop
loopx:
	where$ = "do." + HEX$(nestCount[nestLevel], 4)
	GOSUB Tester
	IF ifc THEN
		GOSUB TestTrue
	ELSE
		GOSUB TestFalse
	END IF
finish_loop:
	EmitLabel ("end.do." + HEX$(nestCount[nestLevel], 4))
	DEC nestLevel
	RETURN
'
'
' *****  NEXT  *****
'
p_next:
	got_executable = $$TRUE
	PeekToken (@check)
	IF TokenMatch (@check, @#T_CASE) THEN NextToken (@token): GOTO p_next_case
	IF (nestLevel < 0) THEN nestLevel = 0: XcowlErr (12003850): GOTO eeeNest
	IFF TokenMatch (nestToken[nestLevel], @#T_FOR) THEN XcowlErr (12003851): GOTO eeeNest
	IF (nestLevel[nestLevel] <> nestLevel) THEN XcowlErr (12003852): GOTO eeeNest
	NextToken (@token)
	kind  = token.tp.kind
	IF (kind = $$KIND_VARIABLES) THEN
		IFF TokenMatch (@token, nestVar[nestLevel]) THEN XcowlErr (12003856): GOTO eeeNest
		NextToken (@token)
	END IF
	forToken  = nestVar[nestLevel]
	forType   = TheType (forToken)
	forStep   = nestStep[nestLevel]
	forLimit  = nestLimit[nestLevel]
	def_step  = nestInfo[nestLevel]
	IF (forType < $$SLONG) THEN forType = $$SLONG
	forVar    = forToken.tindex
	forReg    = r_addr[forVar]
	nativeReg = forReg
	stepVar   = forStep
	stepReg   = r_addr[stepVar]
	EmitLabel ("do.next." + HEX$(nestCount[nestLevel], 4))
	fortop$   = "for." + HEX$(nestCount[nestLevel], 4)
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
'
	IF def_step THEN
		SELECT CASE forType
			CASE $$DOUBLE, $$SINGLE
						Move ($$rax, forType, forVar, forType)
						Code ($$fld1, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"272")
						Code ($$fadd, $$none, 0, 0, 0,  $$DOUBLE, "", $$rmk$+"273")
						Move (forVar, forType, $$rax, forType)
						Code ($$jmp, $$rel, 0, 0, 0, 0, fortop$, $$rmk$+"274")
			CASE $$GIANT
						Move ($$rax, forType, forVar, forType)
						Code ($$add, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"275")
						Code ($$adc, $$regimm, $$rdx, 0, 0, $$XLONG, "", $$rmk$+"276")
						Move (forVar, forType, $$rax, forType)
						Code ($$jmp, $$rel, 0, 0, 0, 0, fortop$, $$rmk$+"277")
			CASE ELSE
						mReg  = m_reg[forVar]
						mAddr = m_addr[forVar]
						IF mReg THEN
							Code ($$inc, $$ro, 0, mReg, mAddr, $$XLONG, "", $$rmk$+"278")
						ELSE
							Code ($$inc, $$abs, 0, 0, mAddr, $$XLONG, m_addr$[forVar], $$rmk$+"279")
						END IF
						Code ($$jmp, $$rel, 0, 0, 0, 0, fortop$, $$rmk$+"280")
		END SELECT
	ELSE
		Move ($$rax, forType, forVar, forType)
		Move ($$rbx, forType, stepVar, forType)
		SELECT CASE forType
			CASE $$DOUBLE, $$SINGLE
						Code ($$fadd, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"281")
						Move (forToken.tindex, forType, $$rax, forType)
						Code ($$jmp, $$rel, 0, 0, 0, 0, fortop$, $$rmk$+"282")
			CASE $$GIANT
						Code ($$add, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"283")
						Code ($$adc, $$regreg, $$rdx, $$rcx, 0, $$XLONG, "", $$rmk$+"284")
						Move (forToken.tindex, forType, $$rax, forType)
						Code ($$jmp, $$rel, 0, 0, 0, 0, fortop$, $$rmk$+"285")
'
'     Check for overflow is invalid when negative step-values are allowed!
'
			CASE ELSE
						Code ($$add, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"290")
						Move (forToken.tindex, forType, $$rax, forType)
						Code ($$jmp, $$rel, 0, 0, 0, 0, fortop$, $$rmk$+"291")
		END SELECT
	END IF
	a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	EmitLabel ("end.for." + HEX$(nestCount[nestLevel], 4))
	DEC nestLevel
	RETURN
'
'
' *****  PRINT  *****
'
p_print:
	got_executable = $$TRUE
	token = Printoid()
	RETURN
'
'
' *****  READ  *****
'
p_read:
	got_executable = $$TRUE
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (12003939): GOTO eeeSyntax        ' READ [ifile], var
	token = Eval (@result_type)
	IF XERROR THEN EXIT FUNCTION
	IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (12003942): GOTO eeeSyntax
	NextToken (@token)
	IFF TokenMatch (@token, @#T_COMMA) THEN XcowlErr (12003944): GOTO eeeSyntax
	IFF q_type_long[result_type] THEN XcowlErr (12003945): GOTO eeeTypeMismatch
	IFZ toes THEN XcowlErr (12003946): GOTO eeeSyntax
'
	xx = Topax1 ()
	symbol$ = ".filenumber"
	ftoken = AddSymbol (symbol$, 0, $$KIND_VARIABLES, 0, $$XLONG, func_number)
	fnum = ftoken.tindex
	IFZ m_addr$[fnum] THEN AssignAddress (ftoken)
	IF XERROR THEN EXIT FUNCTION
	Move (ftoken.tindex, $$XLONG, xx, $$XLONG)
'
' READ the variables
'
	DO
		PeekToken (@rtoken)
		kind    = rtoken.tp.kind
		rt      = rtoken.tindex
		SELECT CASE kind
			CASE $$KIND_VARIABLES:  array = $$FALSE
			CASE $$KIND_ARRAYS:     array = $$TRUE
															NextToken (@token)
															NextToken (@token)
															IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (12003967): GOTO eeeCompiler
															PeekToken (@token)
															IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (12003969): GOTO eeeSyntax
			CASE ELSE:              NextToken (@token): XcowlErr (12003970): GOTO eeeKindMismatch
		END SELECT
		IFZ m_addr$[rt] THEN AssignAddress (rtoken)
		IF XERROR THEN EXIT FUNCTION
		rtype   = TheType (rtoken)
		IF (array OR (rtype < $$SCOMPLEX)) THEN
			IF (array OR (rtype = $$STRING)) THEN
				IF array THEN
					r$ = $$ulpc$+"_ReadArray"
					IF (rtype = $$STRING) THEN XcowlErr (12003979): GOTO eeeTypeMismatch
				ELSE
					r$ = $$ulpc$+"_ReadString"
				END IF
				NextToken (@token)
				Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"292")
				Move ($$rax, $$XLONG, ftoken.tindex, $$XLONG)
				Code ($$st, $$roreg, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"293")
				Move ($$rax, $$XLONG, rtoken.tindex, $$XLONG)
				Code ($$st, $$roreg, $$rax, $$rsp, 8, $$XLONG, "", $$rmk$+"294")
				Code ($$call, $$rel, 0, 0, 0, 0, r$, $$rmk$+"295")
				Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"296")
			ELSE
				SELECT CASE rtype
					CASE $$SINGLE:  rtype = $$XLONG
					CASE $$DOUBLE:  rtype = $$GIANT
				END SELECT
				xsize   = typeSize[rtype]
				size$   = HEXX$(xsize, 4)
				NextToken (@token)
				mReg    = m_reg[rt]
				mAddr   = m_addr[rt]
				Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"297")
				Move ($$rax, $$XLONG, ftoken.tindex, $$XLONG)
				Code ($$st, $$roreg, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"298")
				Code ($$st, $$roreg, $$rsp, $$rsp, 8, $$XLONG, "", $$rmk$+"299")
				Code ($$st, $$roimm, xsize, $$rsp, 16, $$XLONG, "", $$rmk$+"300")
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_Read", $$rmk$+"301")
				Code ($$ld, $$regro, $$rax, $$rsp, 0, rtype, "", $$rmk$+"302")
				IF (rtype < $$SLONG) THEN rtype = $$SLONG
				IF mReg THEN
					Code ($$st, $$roreg, $$rax, mReg, mAddr, rtype, "", $$rmk$+"303")
				ELSE
					Code ($$st, $$absreg, $$rax, 0, mAddr, rtype, m_addr$[rt], $$rmk$+"304")
				END IF
				Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"305")
			END IF
		ELSE
			Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"306")
			Move ($$rax, $$XLONG, ftoken.tindex, $$XLONG)
			Code ($$st, $$roreg, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"307")
			ctype   = rtype
			NextToken (@tokTmp)
			Composite ($$GETDATAADDR, ctype, @tokTmp, @offset, @xsize)
			creg = tokTmp.tindex
			IF XERROR THEN EXIT FUNCTION
			IF toes THEN Topax1 ()
			IFZ creg THEN XcowlErr (12004026): GOTO eeeCompiler
			IF offset THEN Code ($$add, $$regimm, creg, offset, 0, $$XLONG, "", $$rmk$+"308")
			Code ($$st, $$roreg, creg, $$rsp, 8, $$XLONG, "", $$rmk$+"309")
			Code ($$st, $$roimm, xsize, $$rsp, 16, $$XLONG, "", $$rmk$+"310")
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_Read", $$rmk$+"311")
			Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"312")
		END IF
		a0_type = 0
		NextToken (@token)
	LOOP WHILE TokenMatch (@token, @#T_COMMA)
	RETURN
'
'
' *****  RETURN  *****
'
p_return:
	got_executable = $$TRUE
	token = ReturnValue (@rt)
	IF XERROR THEN EXIT FUNCTION
	Code ($$jmp, $$rel, 0, 0, 0, 0, "end.func" + HEX$(func_number), $$rmk$+"313")
	RETURN
'
'
' *****  SELECT  *****  SELECT CASE
'
p_select:
	got_executable = $$TRUE
	tf      = $$FALSE
	s_token = token
	NextToken (@token)
	IFF TokenMatch (@token, @#T_CASE) THEN XcowlErr (12004056): GOTO eeeSyntax
'
allx:
	stp     = tokenPtr
	NextToken (@token)
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_ALL)
					s_token.tp.allo = s_token.tp.allo OR $$ALLO_CASE_ALL
					GOTO allx
		CASE TokenMatch (@token, @#T_TRUE)
					s_token.tp.allo = s_token.tp.allo OR $$ALLO_CASE_TRUE
					NextToken (@token)
					expression  = $$FALSE
					tf          = $$TRUE
		CASE TokenMatch (@token, @#T_FALSE)
					s_token.tp.allo = s_token.tp.allo OR $$ALLO_CASE_FALSE
					NextToken (@token)
					expression  = $$FALSE
					tf          = $$TRUE
		CASE ELSE
					expression  = $$TRUE
					tokenPtr    = stp
	END SELECT
	INC nestCount
	INC nestLevel
	nestLevel[nestLevel] = nestLevel
	nestCount[nestLevel] = nestCount
	nestToken[nestLevel] = s_token
	nestInfo[nestLevel] = 0
	IF tf THEN new_type = $$XLONG: GOTO select_xx
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	expression  = $$TRUE
	token       = new_op
	nn          = new_data.tindex
	rn          = Reg (nn)
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		IF rn AND (rn < $$IMM16) THEN
			acc = rn
		ELSE
			acc = $$rax
			Move ($$rax, new_type, new_data.tindex, new_type)
			a0      = 0
			a0_type = 0
		END IF
	ELSE
		acc = Topax1 ()
		IFZ acc THEN XcowlErr (12004106): GOTO eeeSyntax
		IF (acc != $$rax) THEN XcowlErr (12004107): GOTO eeeCompiler
	END IF
	IF (new_type = $$STRING) THEN
		s_token.tp.allo = s_token.tp.allo OR $$ALLO_CASE_STR
		nestToken[nestLevel] = s_token
		IF (oos[oos] = 'v') THEN
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0" , $$rmk$+"314")
			acc     = $$RA0
			a0      = 0
			a0_type = 0
		END IF
		DEC oos
	END IF
'
select_xx:
	IFF tf THEN
		sname$ = ".select" + HEX$(func_number) + "." + HEX$(nestCount, 4)
		stoken = AddSymbol (@sname$, 0, $$KIND_VARIABLES, 0, new_type, func_number)
		ss = stoken.tindex
		' Hack! It is possible that the symbol .selectXXX already exists (from
		' a previous incarnation of the function) with another type! In that case
		' AddSymbol returns that symbol, with the wrong type; so we have to correct
		' the type of the symbol!
		stoken.tp.type = new_type
		tab_sym[ss] = stoken
		tabType[ss] = new_type
'
		AssignAddress (stoken)
		IF XERROR THEN EXIT FUNCTION
		IF (new_type = $$STRING) THEN
			Move ($$rdi, new_type, stoken.tindex, new_type)
			Move (stoken.tindex, new_type, acc, new_type)
			Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"315")
		ELSE
			Move (stoken.tindex, new_type, acc, new_type)
		END IF
		nestVar[nestLevel] = stoken
	ELSE
		nestVar[nestLevel].tp.type = new_type
	END IF
	RETURN
'
'
' *****  STOP  *****   must be the last statement of a line
'
p_stop:
	got_executable = $$TRUE
	Code ($$int, $$imm, 3, 0, 0, $$XLONG, "", $$rmk$+"316")
	NextToken (@token)
	IF (token.tp.kind != $$KIND_STARTS) THEN XcowlErr (12004156): GOTO eeeSyntax
	RETURN
'
'
' *****  SUB subname  *****
'
p_sub:
	got_executable = $$TRUE
	IF (insub OR nestLevel) THEN
		insub = 0: errNestLevel = nestLevel: nestLevel = 0
		XcowlErr (12004166): GOTO eeeNest
	END IF
	NextToken (@token)
	kind  = token.tp.kind
	gtype = token.tp.type
	IF (kind <> $$KIND_LABELS) THEN XcowlErr (12004171): GOTO eeeSyntax
	IF (gtype <> $$SUBADDR) THEN XcowlErr (12004172): GOTO eeeTypeMismatch
	symbol$ = "out.sub" + hfn$ + "." + HEX$(subCount)
	Code ($$jmp, $$rel, 0, 0, 0, 0, symbol$, $$rmk$+"317")
	EmitUserLabel (token)
	IF XERROR THEN EXIT FUNCTION
	insub  = $$TRUE
	sname$ = ".sub" + HEX$(func_number) + "." + HEX$(subCount, 4)
	stoken = AddSymbol (@sname$, 0, $$KIND_VARIABLES, 0, $$SUBADDR, func_number)
	ss = stoken.tindex
	IF m_addr$[ss] THEN XcowlErr (12004181): GOTO eeeCompiler
	AssignAddress (stoken)
	IF XERROR THEN EXIT FUNCTION
	NextToken (@token)
	RETURN
'
'
' *****  SWAP  *****
'
p_swap:
	attachoid   = $$FALSE
	GOTO p_swapper
'
p_swapper:
	NextToken (@dtoken)
	dholdPtr = tokenPtr
	IFZ GetTokenOrAddress (@dtoken, @dstyle, @termToken, @dtype, @dntype, @dbase, @doffset, @dlength) THEN XcowlErr (12004197): GOTO eeeSyntax
	IFZ dstyle THEN tokenPtr = dholdPtr: XcowlErr (12004198): GOTO eeeSyntax
	IF attachoid THEN
		IFF TokenMatch (@termToken, @#T_TO) THEN XcowlErr (12004200): GOTO eeeSyntax
	ELSE
		IFF TokenMatch (@termToken, @#T_COMMA) THEN XcowlErr (12004202): GOTO eeeSyntax
	END IF
	NextToken (@stoken)
	sholdPtr = tokenPtr
	IFZ GetTokenOrAddress (@stoken, @sstyle, @termToken, @stype, @sntype, @tokTmp, @soffset, @slength) THEN XcowlErr (12004206): GOTO eeeSyntax
	sbase = tokTmp.tindex
	IFZ sstyle THEN tokenPtr = sholdPtr: XcowlErr (12004208): GOTO eeeSyntax
'
	IF (sntype <> dntype) THEN
		IF ((sntype > $$STRING) || (dntype > $$STRING)) THEN XcowlErr (12004211): GOTO eeeTypeMismatch
		IF ((sstyle <> 2) || (dstyle <> 2)) THEN XcowlErr (12004212): GOTO eeeTypeMismatch
	END IF
'
	SELECT CASE dtype
		CASE $$SINGLE: dtype = $$XLONG
		CASE $$DOUBLE: dtype = $$GIANT
	END SELECT
'
	SELECT CASE stype
		CASE $$SINGLE: stype = $$XLONG
		CASE $$DOUBLE: stype = $$GIANT
	END SELECT
'
	SELECT CASE dstyle
		CASE $$NONE       : XcowlErr (12004226): GOTO eeeSyntax
		CASE $$VAR_TOKEN  : GOTO varToken
		CASE $$ARRAY_TOKEN: GOTO arrayToken
		CASE $$ARRAY_NODE : GOTO arrayNode
		CASE $$DATA_ADDR  : GOTO dataAddr
		CASE ELSE         : XcowlErr (12004231): GOTO eeeCompiler
	END SELECT
'
'
' *****  dtoken = varToken  *****
'
varToken:
	IF attachoid THEN tokenPtr = dholdPtr: XcowlErr (12004238): GOTO eeeSyntax
	SELECT CASE sstyle
		CASE $$NONE        : XcowlErr (12004240): GOTO eeeSyntax
		CASE $$VAR_TOKEN   : GOTO varTokenVarToken
		CASE $$ARRAY_TOKEN : XcowlErr (12004242): GOTO eeeKindMismatch
		CASE $$ARRAY_NODE  : XcowlErr (12004243): GOTO eeeNodeDataMismatch
		CASE $$DATA_ADDR   : GOTO varTokenDataAddr
		CASE ELSE          : XcowlErr (12004245): GOTO eeeCompiler
	END SELECT
'
varTokenVarToken:
	IF (dtype < $$XLONG) THEN dtype = $$XLONG
	IF (stype < $$XLONG) THEN stype = $$XLONG
	IF (dtype != stype) THEN tokenPtr = sholdPtr: XcowlErr (12004251): GOTO eeeTypeMismatch
	IF (dtype < $$SCOMPLEX) THEN
		Move ($$RA0, stype, stoken.tindex, stype)
		Move ($$RA1, dtype, dtoken.tindex, dtype)
		Move (dtoken.tindex, dtype, $$RA0, dtype)
		Move (stoken.tindex, stype, $$RA1, stype)
	ELSE
		Move ($$RA0, dtype, dtoken.tindex, dtype)
		Move ($$RA1, stype, stoken.tindex, stype)
		Code ($$push, $$imm, dlength, 0, 0, $$XLONG, "", $$rmk$+"318")
		Code ($$push, $$reg, $$RA1, 0, 0, $$XLONG, "", $$rmk$+"319")
		Code ($$push, $$reg, $$RA0, 0, 0, $$XLONG, "", $$rmk$+"320")
		Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxSwapMemory"+$$ftrail$+"24", $$rmk$+"322")
	END IF
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
varTokenDataAddr:
	sbase = Topax1 ()
	sdata = sbase + 1
	SELECT CASE sbase
		CASE $$RA0 : ddata = $$RA1
		CASE $$RA1 : ddata = $$RA0
		CASE ELSE  : XcowlErr (12004276): GOTO eeeCompiler
	END SELECT
	IF (dtype != stype) THEN tokenPtr = sholdPtr: XcowlErr (12004278): GOTO eeeTypeMismatch
	IF (dtype < $$SCOMPLEX) THEN
		SELECT CASE dtype
			CASE $$GIANT
						Move (ddata, dtype, dtoken.tindex, dtype)
						Code ($$ld, $$regro, $$R26, sbase, soffset, stype, "", $$rmk$+"323")
						Code ($$st, $$roreg, ddata, sbase, soffset, stype, "", $$rmk$+"324")
						Move (dtoken.tindex, dtype, $$R26, dtype)
			CASE ELSE
						Move (ddata, dtype, dtoken.tindex, dtype)
						Code ($$ld, $$regro, sdata, sbase, soffset, stype, "", $$rmk$+"325")
						Code ($$st, $$roreg, ddata, sbase, soffset, stype, "", $$rmk$+"326")
						Move (dtoken.tindex, dtype, sdata, dtype)
		END SELECT
	ELSE
		Code ($$push, $$imm, dlength, 0, 0, $$XLONG, "", $$rmk$+"327")
		Move (ddata, $$XLONG, dtoken.tindex, $$XLONG)
		Code ($$push, $$reg, ddata, 0, 0, $$XLONG, "", $$rmk$+"328")
		Code ($$lea, $$regro, sbase, sbase, soffset, stype, "", $$rmk$+"329")
		Code ($$push, $$reg, sbase, 0, 0, $$XLONG, "", $$rmk$+"330")
		Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxSwapMemory"+$$ftrail$+"24", $$rmk$+"332")
	END IF
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
'
' *****  dtoken = arrayToken  *****
'
arrayToken:
	SELECT CASE sstyle
		CASE $$NONE        : XcowlErr (12004310): GOTO eeeSyntax
		CASE $$VAR_TOKEN   : XcowlErr (12004311): GOTO eeeKindMismatch
		CASE $$ARRAY_TOKEN : GOTO arrayTokenArrayToken
		CASE $$ARRAY_NODE  : GOTO arrayTokenArrayNode
		CASE $$DATA_ADDR   : XcowlErr (12004314): GOTO eeeNodeDataMismatch
		CASE ELSE          : XcowlErr (12004315): GOTO eeeCompiler
	END SELECT
'
arrayTokenArrayToken:
	Move ($$RA0, $$XLONG, stoken.tindex, $$XLONG)
	IF attachoid THEN
		INC labelNumber: dx$ = $$ulpc$ + HEX$(labelNumber, 4)
		Code ($$or, $$regreg, $$RA0, $$RA0, 0, $$XLONG, "", $$rmk$+"333")
		Code ($$jz, $$rel, 0, 0, 0, 0, @dx$, $$rmk$+"334")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_NeedNullNode", $$rmk$+"335")
		EmitLabel (@dx$)
	END IF
	Move (stoken.tindex, $$XLONG, dtoken.tindex, $$XLONG)
	Move (dtoken.tindex, $$XLONG, $$RA0, $$XLONG)
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
arrayTokenArrayNode:
	Move ($$R26, $$XLONG, dtoken.tindex, $$XLONG)
	Code ($$ld, $$regro, $$R27, sbase, soffset, $$XLONG, "", $$rmk$+"336")
	IF attachoid THEN
		INC labelNumber: dx$ = $$ulpc$ + HEX$(labelNumber, 4)
		Code ($$or, $$regreg, $$R27, $$R27, 0, $$XLONG, "", $$rmk$+"337")
		Code ($$jz, $$rel, 0, 0, 0, 0, @dx$, $$rmk$+"338")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_NeedNullNode", $$rmk$+"339")
		EmitLabel (@dx$)
	END IF
	Code ($$st, $$roreg, $$R26, sbase, soffset, $$XLONG, "", $$rmk$+"340")
	Move (dtoken.tindex, $$XLONG, $$R27, $$XLONG)
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
'
' *****  dtoken = arrayNode  *****
'
arrayNode:
	SELECT CASE sstyle
		CASE $$NONE        : XcowlErr (12004356): GOTO eeeSyntax
		CASE $$VAR_TOKEN   : XcowlErr (12004357): GOTO eeeKindMismatch
		CASE $$ARRAY_TOKEN : GOTO arrayNodeArrayToken
		CASE $$ARRAY_NODE  : GOTO arrayNodeArrayNode
		CASE $$DATA_ADDR   : XcowlErr (12004360): GOTO eeeNodeDataMismatch
		CASE ELSE          : XcowlErr (12004361): GOTO eeeCompiler
	END SELECT
'
arrayNodeArrayToken:
	Move ($$R26, $$XLONG, stoken.tindex, $$XLONG)
	Code ($$ld, $$regro, $$R27, dbase.tindex, doffset, $$XLONG, "", $$rmk$+"341")
	IF attachoid THEN
		INC labelNumber: dx$ = $$ulpc$ + HEX$(labelNumber, 4)
		Code ($$or, $$regreg, $$R26, $$R26, 0, $$XLONG, "", $$rmk$+"342")
		Code ($$jz, $$rel, 0, 0, 0, 0, @dx$, $$rmk$+"343")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_NeedNullNode", $$rmk$+"344")
		EmitLabel (@dx$)
	END IF
	Code ($$st, $$roreg, $$R26, dbase.tindex, doffset, $$XLONG, "", $$rmk$+"345")
	Move (stoken.tindex, $$XLONG, $$R27, $$XLONG)
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
arrayNodeArrayNode:
	Topax2 (@sbase, @dbaser)
	Code ($$ld, $$regro, $$R26, sbase, soffset, $$XLONG, "", $$rmk$+"346")
	Code ($$ld, $$regro, $$R27, dbaser, doffset, $$XLONG, "", $$rmk$+"347")
	IF attachoid THEN
		INC labelNumber: dx$ = $$ulpc$ + HEX$(labelNumber, 4)
		Code ($$or, $$regreg, $$R26, $$R26, 0, $$XLONG, "", $$rmk$+"348")
		Code ($$jz, $$rel, 0, 0, 0, 0, @dx$, $$rmk$+"349")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_NeedNullNode", $$rmk$+"350")
		EmitLabel (@dx$)
	END IF
	Code ($$st, $$roreg, $$R26, dbaser, doffset, $$XLONG, "", $$rmk$+"351")
	Code ($$st, $$roreg, $$R27, sbase, soffset, $$XLONG, "", $$rmk$+"352")
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
'
' *****  dtoken = dataAddr  *****
'
dataAddr:
	IF (dtype != stype) THEN XcowlErr (12004403): GOTO eeeTypeMismatch
	SELECT CASE sstyle
		CASE $$NONE        : XcowlErr (12004405): GOTO eeeSyntax
		CASE $$VAR_TOKEN   : GOTO dataAddrVarToken
		CASE $$ARRAY_TOKEN : XcowlErr (12004407): GOTO eeeNodeDataMismatch
		CASE $$ARRAY_NODE  : XcowlErr (12004408): GOTO eeeNodeDataMismatch
		CASE $$DATA_ADDR   : GOTO dataAddrDataAddr
		CASE ELSE          : XcowlErr (12004410): GOTO eeeCompiler
	END SELECT
'
dataAddrVarToken:
	dbase.tindex = Topax1 ()
	dbase.tproto = 0
	dbasex = dbase.tindex + 1
	SELECT CASE dbase.tindex
		CASE $$RA0 : sdata = $$RA1: sdatax = sdata + 1
		CASE $$RA1 : sdata = $$RA0: sdatax = sdata + 1
		CASE ELSE  : XcowlErr (12004420): GOTO eeeCompiler
	END SELECT
	IF (stype < $$SCOMPLEX) THEN
		SELECT CASE dtype
			CASE $$GIANT
						Move (sdata, stype, stoken.tindex, stype)
						Code ($$ld, $$regro, $$R26, dbase.tindex, doffset, dtype, "", $$rmk$+"353")
						Code ($$st, $$roreg, sdata, dbase.tindex, doffset, dtype, "", $$rmk$+"354")
						Move (stoken.tindex, stype, $$R26, stype)
			CASE ELSE
						Move (sdata, stype, stoken.tindex, stype)
						Code ($$ld, $$regro, sdatax, dbase.tindex, doffset, dtype, "", $$rmk$+"355")
						Code ($$st, $$roreg, sdata, dbase.tindex, doffset, dtype, "", $$rmk$+"356")
						Move (stoken.tindex, stype, sdatax, stype)
		END SELECT
	ELSE
		Code ($$push, $$imm, dlength, 0, 0, $$XLONG, "", $$rmk$+"357")
		Code ($$lea, $$regro, dbase.tindex, dbase.tindex, soffset, stype, "", $$rmk$+"358")
		Code ($$push, $$reg, dbase.tindex, 0, 0, $$XLONG, "", $$rmk$+"359")
		Move (dbase.tindex, $$XLONG, dtoken.tindex, $$XLONG)
		Code ($$push, $$reg, dbase.tindex, 0, 0, $$XLONG, "", $$rmk$+"360")
		Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxSwapMemory"+$$ftrail$+"24", $$rmk$+"362")
	END IF
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
dataAddrDataAddr:
	Topax2(@sbase, @dbaser)
	IF (stype < $$STRING) THEN
		SELECT CASE dtype
			CASE $$GIANT
						Code ($$lea, $$regro, $$R26, sbase, soffset, stype, "", $$rmk$+"363")
						Code ($$lea, $$regro, $$R27, dbaser, doffset, dtype, "", $$rmk$+"364")
						Code ($$ld, $$regro, $$RA0, $$R26, 0, stype, "", $$rmk$+"365")
						Code ($$ld, $$regro, $$RA1, $$R27, 0, dtype, "", $$rmk$+"366")
						Code ($$st, $$roreg, $$RA0, $$R27, 0, dtype, "", $$rmk$+"367")
						Code ($$st, $$roreg, $$RA1, $$R26, 0, stype, "", $$rmk$+"368")
			CASE ELSE
						Code ($$ld, $$regro, sbase+1, sbase, soffset, stype, "", $$rmk$+"369")
						Code ($$ld, $$regro, dbaser+1, dbaser, doffset, dtype, "", $$rmk$+"370")
						Code ($$st, $$roreg, sbase+1, dbaser, doffset, dtype, "", $$rmk$+"371")
						Code ($$st, $$roreg, dbaser+1, sbase, soffset, stype, "", $$rmk$+"372")
		END SELECT
	ELSE
		IF (dlength != slength) THEN XcowlErr (12004466): GOTO eeeTypeMismatch
		Code ($$push, $$imm, dlength, 0, 0, $$XLONG, "", $$rmk$+"373")
		Code ($$lea, $$regro, sbase, sbase, soffset, $$XLONG, "", $$rmk$+"374")
		Code ($$push, $$reg, sbase, 0, 0, $$XLONG, "", $$rmk$+"375")
		Code ($$lea, $$regro, dbaser, dbaser, doffset, $$XLONG, "", $$rmk$+"376")
		Code ($$push, $$reg, dbaser, 0, 0, $$XLONG, "", $$rmk$+"377")
		Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxSwapMemory"+$$ftrail$+"24", $$rmk$+"379")
	END IF
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	token.tproto = termToken.tproto
	token.tindex = termToken.tindex
	RETURN
'
'
' *****  TYPE  *****  DECLARE USER-DEFINED TYPES
'
p_type:
	IF typeNumber THEN typeNumber = 0: XcowlErr (12004483): GOTO eeeCompiler
	NextToken (@typeToken)
	typeKind = typeToken.tp.kind
	typeNumber = typeToken.tindex
	IF typeAlias[typeNumber] THEN typeNumber = 0: XcowlErr (12004487): GOTO eeeDupType
	typeAlias[typeNumber] = typeNumber
	IF (typeKind != $$KIND_TYPES) THEN XcowlErr (12004489): GOTO eeeSyntax
	IFZ typeNumber THEN XcowlErr (12004490): GOTO eeeCompiler
	IFF TokenMatch(typeToken, typeToken[typeNumber]) THEN XcowlErr (12004491): GOTO eeeCompiler
	NextToken (@token)
'
' *****  ALIAS TYPENAME SYNTAX  *****   TYPE typeName = typeName  (single line)
'
	IF TokenMatch (@token, @#T_EQ) THEN
		NextToken (@token)
		SELECT CASE token.tp.kind
			CASE $$KIND_TYPES        : atype = TypenameToken (@token)
			CASE $$KIND_STATE_INTRIN : atype = TypenameToken (@token)
			CASE ELSE                : atype = 0
		END SELECT
		typeAlias[typeNumber] = atype
		typeAlign[typeNumber] = typeAlign[atype]
		typeNumber = 0
		IFZ atype THEN XcowlErr (12004506): GOTO eeeUndefined
		IFZ typeAlias[atype] THEN XcowlErr (12004507): GOTO eeeUndefined
		token.tproto = $$TP_STARTS
		token.tindex = $$TI_ZERO
		RETURN
	END IF
	inTYPE = $$TRUE
'
' *****  TYPE DECLARATION SYNTAX  *****  (TYPE typeName...  END TYPE block)
'
	typeThisAddr = 0
	typeNextAddr = 0
	typeMaxAlign = 0
	typeMaxSize = 0
	eleCount = 0
	uEle = 3
	DIM tsymbol$[uEle]
	DIM ttoken[uEle]
	DIM tsize[uEle]
	DIM taddr[uEle]
	DIM ttype[uEle]
	DIM atype[uEle,]
	DIM tval[uEle]
	DIM tptr[uEle]
	DIM tss[uEle]
	DIM tub[uEle]
	got_type = $$TRUE
	IF got_declare THEN XcowlErr (12004533): tokenPtr = 1: GOTO eeeTooLate
	RETURN
'
'
' *****  TYPE ELEMENT DECLARATIONS  *****
' *****  UNION ELEMENT DECLARATIONS  *****
'
p_intype:
	IF TokenMatch (@token, @#T_UNION) THEN
		IFZ inTYPE THEN XcowlErr (12004542): GOTO eeeSyntax
		IF inUNION THEN XcowlErr (12004543): GOTO eeeNest
		eleCountUNION = eleCount
		addrUNION = typeNextAddr
		inUNION = $$TRUE
		token = #T_STARTS
		RETURN
	END IF
	IF TokenMatch (@token, @#T_END) THEN GOTO p_end_type
	eleStringSize = 0
	eleArrayUBound = 0
	fixedString = $$FALSE
	IF TokenMatch (@token, @#T_STRING) THEN           ' Fixed strings:  STRING*23  .s
		PeekToken (@testToken)
		IFF TokenMatch (@testToken, @#T_MUL) THEN XcowlErr (12004556): GOTO eeeSyntax
		NextToken (@testToken)                                    ' point to *
		IF elePtr THEN XcowlErr (12004558): GOTO eeeSyntax     ' pointer to fixed string: invalid
		NextToken (@testToken)
		tt = testToken.tindex
		SELECT CASE testToken.tp.kind
			CASE $$KIND_LITERALS : eleSize = XLONG (tab_sym$[tt])
			CASE $$KIND_SYSCONS  : eleSize = XLONG (r_addr$[tt])
			CASE ELSE            : XcowlErr (12004564): GOTO eeeSyntax
		END SELECT
		IFZ eleSize THEN XcowlErr (12004566): GOTO eeeComponent
		eleStringSize = eleSize
		fixedString = $$TRUE
	END IF
	eleToken = token                        ' pass the type token
	eleType = TypenameToken (@eleToken)     ' type; next token
	IFZ eleType THEN XcowlErr (12004572): GOTO eeeSyntax
'
	dataPtr = tokenPtr
	IF arg[] THEN DIM arg[]
	IF (eleType = $$FUNCADDR) THEN
		GetFuncaddrInfo (@eleToken, @eleElements, @arg[], @dataPtr)
		IF (eleToken.tp.kind = $$KIND_ARRAY_SYMBOLS) THEN
			IFZ eleElements THEN tokenPtr = dataPtr + 1: XcowlErr (12004579): GOTO eeeNeedSubscript
			eleArrayUBound = eleElements - 1
			eleSize = eleElements * 4
			eleAlign = 4
		ELSE
			eleArrayUBound = 0
			eleSize = 4
			eleAlign = 4
		END IF
		GOSUB CheckElement
	ELSE
		GOSUB CheckElement
		SELECT CASE TRUE
			CASE TokenMatch (@typeType, @#T_PACKED): eleAlign = 1
			CASE fixedString : eleAlign  = 1
			CASE ELSE        : eleAlign  = typeAlign[eleType]
		END SELECT
		IFF fixedString THEN eleSize = typeSize[eleType]
		IF (eleKind = $$KIND_ARRAY_SYMBOLS) THEN
			NextToken (@token)
			IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (12004599): GOTO eeeSyntax
			NextToken (@token)
			tt = token.tindex
			SELECT CASE token.tp.kind       ' literals may not be in r_addr yet
				CASE $$KIND_LITERALS : arrayDim = XLONG (tab_sym$[tt])
				CASE $$KIND_SYSCONS  : arrayDim = XLONG (r_addr$[tt])
				CASE ELSE            : XcowlErr (12004605): GOTO eeeComponent
			END SELECT
			NextToken (@token)
			IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (12004608): GOTO eeeSyntax    ' 1-D arrays for now
			eleSize = eleSize * (arrayDim + 1)
			eleArrayUBound = arrayDim
		END IF
	END IF
	IFZ eleSize THEN XcowlErr (12004613): GOTO eeeCompiler
	IFZ eleAlign THEN XcowlErr (12004614): GOTO eeeCompiler
	IF (eleAlign > typeMaxAlign) THEN typeMaxAlign = eleAlign
	SELECT CASE TRUE
		CASE inUNION : typeThisAddr = (addrUNION + eleAlign - 1) AND -eleAlign
										IF ((typeThisAddr + eleSize) > typeNextAddr) THEN typeNextAddr = typeThisAddr + eleSize
		CASE inTYPE  : typeThisAddr = (typeNextAddr + eleAlign - 1) AND -eleAlign
										typeNextAddr = typeThisAddr + eleSize
		CASE ELSE    : XcowlErr (12004621): GOTO eeeCompiler
	END SELECT
	IF (eleCount > uEle) THEN
'   PRINT "CheckState(4624):uEle", uEle
		uEle = uEle + 4
		REDIM tsymbol$[uEle]
		REDIM ttoken[uEle]
		REDIM tsize[uEle]
		REDIM taddr[uEle]
		REDIM ttype[uEle]
		REDIM atype[uEle,]
		REDIM tval[uEle]
		REDIM tptr[uEle]
		REDIM tss[uEle]
		REDIM tub[uEle]
	END IF
	tsymbol$[eleCount] = eleName$
	ttoken[eleCount] = eleToken
	tsize[eleCount] = eleSize
	taddr[eleCount] = typeThisAddr
	ttype[eleCount] = eleType
	tval[eleCount] = 0
	tptr[eleCount] = elePtr
	tss[eleCount] = eleStringSize
	tub[eleCount] = eleArrayUBound
	ATTACH arg[] TO atype[eleCount, ]
' PRINT eleCount;; eleName$;; HEX$(eleToken,8);; eleSize;; typeThisAddr;; typeNextAddr;; eleType;; elePtr;; eleStringSize;; eleArrayUBound
	INC eleCount
	NextToken (@token)
	IFF TokenMatch (@token, @#T_STARTS) THEN XcowlErr (12004650): GOTO eeeSyntax
	token.tproto = $$TP_STARTS
	token.tindex = $$TI_ZERO
	RETURN
'
' *****  END TYPE  *****  END UNION  *****
'
p_end_type:
	IFZ typeNumber THEN XcowlErr (12004658): GOTO eeeSyntax
	NextToken (@token)
	IF inUNION THEN
		SELECT CASE TRUE
			CASE TokenMatch (@token, @#T_UNION): GOSUB FixUnion: token = #T_STARTS: RETURN
			CASE TokenMatch (@token, @#T_TYPE) : XcowlErr (12004663): GOTO eeeSyntax
			CASE ELSE  : XcowlErr (12004664): GOTO eeeSyntax
		END SELECT
		IFF TokenMatch (@token, @#T_UNION) THEN XcowlErr (12004666): GOTO eeeSyntax
		GOSUB FixUnion
		token = #T_STARTS
		RETURN
	ELSE
		IFF TokenMatch (@token, @typeType) THEN  'probably END TYPE for END PACKED
			typeType = #T_ZERO
			inUNION = $$FALSE
			inTYPE = $$FALSE
			typeNumber = 0
			uEle = 0
			XcowlErr (12004677): GOTO eeeSyntax
		END IF
	END IF
	ATTACH tsymbol$[] TO typeEleSymbol$[typeNumber, ]
	ATTACH ttoken[] TO typeEleToken[typeNumber, ]
	ATTACH tsize[] TO typeEleSize[typeNumber, ]
	ATTACH taddr[] TO typeEleAddr[typeNumber, ]
	ATTACH ttype[] TO typeEleType[typeNumber, ]
	ATTACH atype[] TO typeEleArg[typeNumber, ]
	ATTACH tval[] TO typeEleVal[typeNumber, ]
	ATTACH tptr[] TO typeElePtr[typeNumber, ]
	ATTACH tss[] TO typeEleStringSize[typeNumber, ]
	ATTACH tub[] TO typeEleUBound[typeNumber, ]
	typeEleCount[typeNumber] = eleCount
	IFF TokenMatch (@typeType, @#T_PACKED) THEN
		IF (typeMaxAlign <= 4) THEN
			typeMaxAlign = 4
			roundSize = 3
		ELSE
			typeMaxAlign = 8
			roundSize = 7
		END IF
		typeNextAddr = (typeNextAddr + roundSize) AND (NOT roundSize)
	END IF
	typeType = #T_ZERO
	typeAlign[typeNumber] = typeMaxAlign
	typeSize[typeNumber] = typeNextAddr
	inUNION = $$FALSE
	inTYPE = $$FALSE
	typeNumber = 0
	uEle = 0
	token = #T_STARTS
	RETURN
'
'
' When the end of a UNION ... END UNION block is reached,
' all the components in the UNION need to be fixed up to
' align with the most restrictive component.
'
' *****  FixUnion  *****
'
SUB FixUnion
	inUNION = $$FALSE
	align = 0
	addr = 0
	size = 0
'
	FOR e = eleCountUNION TO eleCount-1
		eName$ = tsymbol$[e]
'   eToken = ttoken[e]
		eSize = tsize[e]
		eAddr = taddr[e]
		eType = ttype[e]
'   value = tval[e]
'   ePtr = tptr[e]
		sSize = tss[e]
		aUpper = tub[e]
		tAlign = typeAlign[eType]
		tSize = typeSize[eType]
'   PRINT eName$; eSize; eAddr; eType; sSize; aUpper; tAlign; tSize
		IF (eSize > size) THEN size = eSize
		IF (eAddr > addr) THEN addr = eAddr
	NEXT e
'
	FOR e = eleCountUNION TO eleCount-1
		taddr[e] = addr
	NEXT e
	typeNextAddr = addr + size
END SUB
'
SUB CheckElement
	eleKind = eleToken.tp.kind
	IF (eleKind != $$KIND_SYMBOLS) THEN
		IF (eleKind != $$KIND_ARRAY_SYMBOLS) THEN XcowlErr (12004750): GOTO eeeComponent
	END IF
	eleNumber = eleToken.tindex
	eleName$ = tab_sym$[eleNumber]
	IF (eleName${0} != '.') THEN XcowlErr (12004754): GOTO eeeSyntax   ' name must begin with .
	IF eleCount THEN
		i = 0
		DO WHILE (i < eleCount)
			IF (eleName$ = tsymbol$[i]) THEN
				tokenPtr  = dataPtr
				XcowlErr (12004760): GOTO eeeDupDefinition
			END IF
			INC i
		LOOP
	END IF
END SUB
'
'
' *****  WRITE *****
'
p_write:
	got_executable = $$TRUE
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (12004773): GOTO eeeSyntax        ' WRITE [ifile], var
	token = Eval (@result_type)
	IF XERROR THEN EXIT FUNCTION
	IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (12004776): GOTO eeeSyntax
	NextToken (@token)
	IFF TokenMatch (@token, @#T_COMMA) THEN XcowlErr (12004778): GOTO eeeSyntax
'
	IFF q_type_long[result_type] THEN XcowlErr (12004780): GOTO eeeTypeMismatch
	IFZ toes THEN XcowlErr (12004781): GOTO eeeSyntax
	symbol$ = ".filenumber"
	ftoken = AddSymbol (@symbol$, 0, $$KIND_VARIABLES, 0, $$XLONG, func_number)
	fnum = ftoken.tindex
	IFZ m_addr$[fnum] THEN AssignAddress (ftoken)
	IF XERROR THEN EXIT FUNCTION
	xx = Topax1 ()
	Move (ftoken.tindex, $$XLONG, xx, $$XLONG)
'
' WRITE the variables
'
	DO
		PeekToken (@wtoken)
		kind    = wtoken.tp.kind
		wt      = wtoken.tindex
		SELECT CASE kind
			CASE $$KIND_VARIABLES:  array = $$FALSE
			CASE $$KIND_ARRAYS:     array = $$TRUE
															NextToken (@token)
															NextToken (@token)
															IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (12004801): GOTO eeeCompiler
															PeekToken (@token)
															IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (12004803): GOTO eeeSyntax
			CASE ELSE:              NextToken (@token): XcowlErr (12004804): GOTO eeeKindMismatch
		END SELECT
		IFZ m_addr$[wt] THEN AssignAddress (wtoken)
		IF XERROR THEN EXIT FUNCTION
		wtype   = TheType (wtoken)
		IF (array OR (wtype < $$SCOMPLEX)) THEN
			IF (array OR (wtype = $$STRING)) THEN
				IF array THEN
					w$ = $$ulpc$+"_WriteArray"
				ELSE
					w$ = $$ulpc$+"_WriteString"
				END IF
				NextToken (@token)
				Code ($$sub, $$regimm, $$rsp, 64, 0, $$XLONG, "", $$rmk$+"380")
				Move ($$rax, $$XLONG, ftoken.tindex, $$XLONG)
				Code ($$st, $$roreg, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"381")
				Move ($$rax, $$XLONG, wtoken.tindex, $$XLONG) ' get file #
				Code ($$st, $$roreg, $$rax, $$rsp, 8, $$XLONG, "", $$rmk$+"382")
				Code ($$call, $$rel, 0, 0, 0, 0, w$, $$rmk$+"383")
				Code ($$add, $$regimm, $$rsp, 64, 0, $$XLONG, "", $$rmk$+"384")
			ELSE
				SELECT CASE wtype
					CASE $$SINGLE:  wtype = $$XLONG
					CASE $$DOUBLE:  wtype = $$GIANT
				END SELECT
				xsize   = typeSize[wtype]
				size$   = HEXX$(xsize, 4)
				NextToken (@token)
				wt      = token.tindex
				mReg    = m_reg[wt]
				mAddr   = m_addr[wt]
				Code ($$sub, $$regimm, $$rsp, 64, 0, $$XLONG, "", $$rmk$+"385")
				Move ($$rax, $$XLONG, ftoken.tindex, $$XLONG) ' get file #
				Code ($$st, $$roreg, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"386")
				IF mReg THEN
					Code ($$lea, $$regro, $$rax, mReg, mAddr, $$XLONG, "", $$rmk$+"387")
				ELSE
					Code ($$lea, $$regabs, $$rax, 0, mAddr, $$XLONG, m_addr$[wt], $$rmk$+"388")
				END IF
				Code ($$st, $$roreg, $$rax, $$rsp, 8, $$XLONG, "", $$rmk$+"389")
				Code ($$st, $$roimm, xsize, $$rsp, 16, $$XLONG, "", $$rmk$+"390")
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_Write", $$rmk$+"391")
				Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"392")
			END IF
		ELSE
			Code ($$sub, $$regimm, $$rsp, 64, 0, $$XLONG, "", $$rmk$+"393")
			Move ($$rax, $$XLONG, ftoken.tindex, $$XLONG) ' get file #
			Code ($$st, $$roreg, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"394")
			ctype   = wtype
			rreg    = $$FALSE
			NextToken (@tokTmp)
			Composite ($$GETDATAADDR, ctype, @tokTmp, @offset, @xsize)
			creg = tokTmp.tindex
			IF XERROR THEN EXIT FUNCTION
			IF toes THEN xx = Topax1 ()
			IFZ creg THEN XcowlErr (12004859): GOTO eeeCompiler
			Code ($$lea, $$regro, $$rax, creg, offset, $$XLONG, "", $$rmk$+"395")
			Code ($$st, $$roreg, $$rax, $$rsp, 8, $$XLONG, "", $$rmk$+"396")
			Code ($$st, $$roimm, xsize, $$rsp, 16, $$XLONG, "", $$rmk$+"397")
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_Write", $$rmk$+"398")
			Code ($$add, $$regimm, $$rsp, 64, 0, $$XLONG, "", $$rmk$+"399")
		END IF
		a0_type = 0
		NextToken (@token)
	LOOP WHILE TokenMatch (@token, @#T_COMMA)
	RETURN
'
'
'
' *****************************************
' *****  LOAD kindBeforeFunc[] ARRAY  *****
' *****************************************
'
SUB KindBeforeFunc
	DIM kindBeforeFunc[31]
	kindBeforeFunc[$$KIND_TYPES]        = GOADDRESS (b_types)         '0x10
	kindBeforeFunc[$$KIND_STARTS]       = GOADDRESS (b_starts)        '0x11
	kindBeforeFunc[$$KIND_SYSCONS]      = GOADDRESS (b_syscons)       '0x0C
	kindBeforeFunc[$$KIND_COMMENTS]     = GOADDRESS (b_comments)      '0x19
	kindBeforeFunc[$$KIND_CONSTANTS]    = GOADDRESS (b_constants)     '0x04
	kindBeforeFunc[$$KIND_STATEMENTS]   = GOADDRESS (b_statements)    '0x0D
	kindBeforeFunc[$$KIND_STATE_INTRIN] = GOADDRESS (b_statements)    '0x0F
	kindBeforeFunc[$$KIND_TERMINATORS]  = GOADDRESS (b_terminators)   '0x13
	IF kindBeforeFunc[0] THEN
		XERROR = ERROR_COMPILER
		PRINT "CheckState(4889):kindBeforeFunc[0] =", kindBeforeFunc[0]
	END IF
END SUB
'
SUB TypeBeforeFunc
	DIM typeBeforeFunc[255]
	typeBeforeFunc[#T_SBYTE.ti.ndex]    = GOADDRESS (p_types)
	typeBeforeFunc[#T_UBYTE.ti.ndex]    = GOADDRESS (p_types)
	typeBeforeFunc[#T_SSHORT.ti.ndex]   = GOADDRESS (p_types)
	typeBeforeFunc[#T_USHORT.ti.ndex]   = GOADDRESS (p_types)
	typeBeforeFunc[#T_SLONG.ti.ndex]    = GOADDRESS (p_types)
	typeBeforeFunc[#T_ULONG.ti.ndex]    = GOADDRESS (p_types)
	typeBeforeFunc[#T_XLONG.ti.ndex]    = GOADDRESS (p_types)
	typeBeforeFunc[#T_GOADDR.ti.ndex]   = GOADDRESS (p_types)
	typeBeforeFunc[#T_SUBADDR.ti.ndex]  = GOADDRESS (p_types)
	typeBeforeFunc[#T_FUNCADDR.ti.ndex] = GOADDRESS (p_types)
	typeBeforeFunc[#T_GIANT.ti.ndex]    = GOADDRESS (p_types)
	typeBeforeFunc[#T_SINGLE.ti.ndex]   = GOADDRESS (p_types)
	typeBeforeFunc[#T_DOUBLE.ti.ndex]   = GOADDRESS (p_types)
	typeBeforeFunc[#T_STRING.ti.ndex]   = GOADDRESS (p_types)
	IF typeBeforeFunc[0] THEN
		XERROR = ERROR_COMPILER
		PRINT "CheckState(4911):typeBeforeFunc[0] =", typeBeforeFunc[0]
	END IF
END SUB
'
SUB StateBeforeFunc
	DIM stateBeforeFunc[255]
	stateBeforeFunc[#T_ALL.ti.ndex]       = GOADDRESS (b_all)
	stateBeforeFunc[#T_CFUNCTION.ti.ndex] = GOADDRESS (b_cfunction)
	stateBeforeFunc[#T_DECLARE.ti.ndex]   = GOADDRESS (b_declare)
	stateBeforeFunc[#T_END.ti.ndex]       = GOADDRESS (b_end)
	stateBeforeFunc[#T_EXPORT.ti.ndex]    = GOADDRESS (b_export)
	stateBeforeFunc[#T_EXTERNAL.ti.ndex]  = GOADDRESS (b_external)
	stateBeforeFunc[#T_FUNCTION.ti.ndex]  = GOADDRESS (b_function)
	stateBeforeFunc[#T_IMPORT.ti.ndex]    = GOADDRESS (b_import)
	stateBeforeFunc[#T_INTERNAL.ti.ndex]  = GOADDRESS (b_internal)
	stateBeforeFunc[#T_LIBRARY.ti.ndex]   = GOADDRESS (b_library)
	stateBeforeFunc[#T_PACKED.ti.ndex]    = GOADDRESS (b_packed)
	stateBeforeFunc[#T_PROGRAM.ti.ndex]   = GOADDRESS (b_program)
	stateBeforeFunc[#T_SFUNCTION.ti.ndex] = GOADDRESS (b_sfunction)
	stateBeforeFunc[#T_SHARED.ti.ndex]    = GOADDRESS (b_shared)
	stateBeforeFunc[#T_TYPE.ti.ndex]      = GOADDRESS (b_type)
	stateBeforeFunc[#T_UNION.ti.ndex]     = GOADDRESS (b_union)
	stateBeforeFunc[#T_VERSION.ti.ndex]   = GOADDRESS (b_version)
	IF stateBeforeFunc[0] THEN
		XERROR = ERROR_COMPILER
		PRINT "CheckState(4936):stateBeforeFunc[0] =", stateBeforeFunc[0]
	END IF
END SUB
'
SUB KindAfterFunc
	DIM kindAfterFunc[31]
	kindAfterFunc[$$KIND_VARIABLES]    = GOADDRESS (a_variables)
	kindAfterFunc[$$KIND_ARRAYS]       = GOADDRESS (a_arrays)
	kindAfterFunc[$$KIND_CONSTANTS]    = GOADDRESS (a_constants)
	kindAfterFunc[$$KIND_FUNCTIONS]    = GOADDRESS (a_functions)
	kindAfterFunc[$$KIND_LABELS]       = GOADDRESS (a_labels)
	kindAfterFunc[$$KIND_STARTS]       = GOADDRESS (a_starts)
	kindAfterFunc[$$KIND_TYPES]        = GOADDRESS (a_types)
	kindAfterFunc[$$KIND_ADDR_OPS]     = GOADDRESS (a_addr_ops)
	kindAfterFunc[$$KIND_COMMENTS]     = GOADDRESS (a_comments)
	kindAfterFunc[$$KIND_WHITES]       = GOADDRESS (a_whites)
	kindAfterFunc[$$KIND_TERMINATORS]  = GOADDRESS (a_terminators)
	kindAfterFunc[$$KIND_CHARACTERS]   = GOADDRESS (a_characters)
	kindAfterFunc[$$KIND_STATEMENTS]   = GOADDRESS (a_statements)
	kindAfterFunc[$$KIND_INTRINSICS]   = GOADDRESS (a_intrinsics)
	kindAfterFunc[$$KIND_STATE_INTRIN] = GOADDRESS (a_state_intrin)
	IF kindAfterFunc[0] THEN
		XERROR = ERROR_COMPILER
		PRINT "CheckState(4959):kindAfterFunc[0] =", kindAfterFunc[0]
	END IF
END SUB
'
SUB StateAfterFunc
	DIM stateAfterFunc[255]
	stateAfterFunc[#T_ALL.ti.ndex]        = GOADDRESS (p_all)
	stateAfterFunc[#T_ATTACH.ti.ndex]     = GOADDRESS (p_attach)
	stateAfterFunc[#T_AUTO.ti.ndex]       = GOADDRESS (p_auto)
	stateAfterFunc[#T_AUTOX.ti.ndex]      = GOADDRESS (p_autox)
	stateAfterFunc[#T_CASE.ti.ndex]       = GOADDRESS (p_case)
	stateAfterFunc[#T_CFUNCTION.ti.ndex]  = GOADDRESS (p_cfunction)
	stateAfterFunc[#T_DEC.ti.ndex]        = GOADDRESS (p_dec)
	stateAfterFunc[#T_DECLARE.ti.ndex]    = GOADDRESS (p_declare_func)
	stateAfterFunc[#T_DIM.ti.ndex]        = GOADDRESS (p_dim)
	stateAfterFunc[#T_DO.ti.ndex]         = GOADDRESS (p_do)
	stateAfterFunc[#T_DOUBLE.ti.ndex]     = GOADDRESS (p_double)
	stateAfterFunc[#T_DOUBLEAT.ti.ndex]   = GOADDRESS (p_doubleat)
	stateAfterFunc[#T_ELSE.ti.ndex]       = GOADDRESS (p_else)
	stateAfterFunc[#T_END.ti.ndex]        = GOADDRESS (p_end)
	stateAfterFunc[#T_ENDIF.ti.ndex]      = GOADDRESS (p_endif)
	stateAfterFunc[#T_EXIT.ti.ndex]       = GOADDRESS (p_exit)
	stateAfterFunc[#T_EXTERNAL.ti.ndex]   = GOADDRESS (p_external)
	stateAfterFunc[#T_FOR.ti.ndex]        = GOADDRESS (p_for)
	stateAfterFunc[#T_FUNCADDR.ti.ndex]   = GOADDRESS (p_funcaddr)
	stateAfterFunc[#T_FUNCADDRAT.ti.ndex] = GOADDRESS (p_funcaddrat)
	stateAfterFunc[#T_FUNCTION.ti.ndex]   = GOADDRESS (p_function)
	stateAfterFunc[#T_GIANT.ti.ndex]      = GOADDRESS (p_giant)
	stateAfterFunc[#T_GIANTAT.ti.ndex]    = GOADDRESS (p_giantat)
	stateAfterFunc[#T_GOADDR.ti.ndex]     = GOADDRESS (p_goaddr)
	stateAfterFunc[#T_GOADDRAT.ti.ndex]   = GOADDRESS (p_goaddrat)
	stateAfterFunc[#T_GOSUB.ti.ndex]      = GOADDRESS (p_gosub)
	stateAfterFunc[#T_GOTO.ti.ndex]       = GOADDRESS (p_goto)
	stateAfterFunc[#T_IF.ti.ndex]         = GOADDRESS (p_if)
	stateAfterFunc[#T_IFF.ti.ndex]        = GOADDRESS (p_iff)
	stateAfterFunc[#T_IFT.ti.ndex]        = GOADDRESS (p_ift)
	stateAfterFunc[#T_IFZ.ti.ndex]        = GOADDRESS (p_ifz)
	stateAfterFunc[#T_INC.ti.ndex]        = GOADDRESS (p_inc)
	stateAfterFunc[#T_LOOP.ti.ndex]       = GOADDRESS (p_loop)
	stateAfterFunc[#T_NEXT.ti.ndex]       = GOADDRESS (p_next)
	stateAfterFunc[#T_PRINT.ti.ndex]      = GOADDRESS (p_print)
	stateAfterFunc[#T_READ.ti.ndex]       = GOADDRESS (p_read)
	stateAfterFunc[#T_REDIM.ti.ndex]      = GOADDRESS (p_redim)
	stateAfterFunc[#T_RETURN.ti.ndex]     = GOADDRESS (p_return)
	stateAfterFunc[#T_SBYTE.ti.ndex]      = GOADDRESS (p_sbyte)
	stateAfterFunc[#T_SBYTEAT.ti.ndex]    = GOADDRESS (p_sbyteat)
	stateAfterFunc[#T_SELECT.ti.ndex]     = GOADDRESS (p_select)
	stateAfterFunc[#T_SFUNCTION.ti.ndex]  = GOADDRESS (p_sfunction)
	stateAfterFunc[#T_SHARED.ti.ndex]     = GOADDRESS (p_shared)
	stateAfterFunc[#T_SINGLE.ti.ndex]     = GOADDRESS (p_single)
	stateAfterFunc[#T_SINGLEAT.ti.ndex]   = GOADDRESS (p_singleat)
	stateAfterFunc[#T_SLONG.ti.ndex]      = GOADDRESS (p_slong)
	stateAfterFunc[#T_SLONGAT.ti.ndex]    = GOADDRESS (p_slongat)
	stateAfterFunc[#T_SSHORT.ti.ndex]     = GOADDRESS (p_sshort)
	stateAfterFunc[#T_SSHORTAT.ti.ndex]   = GOADDRESS (p_sshortat)
	stateAfterFunc[#T_STATIC.ti.ndex]     = GOADDRESS (p_static)
	stateAfterFunc[#T_STOP.ti.ndex]       = GOADDRESS (p_stop)
	stateAfterFunc[#T_STRING.ti.ndex]     = GOADDRESS (p_string)
	stateAfterFunc[#T_SUB.ti.ndex]        = GOADDRESS (p_sub)
	stateAfterFunc[#T_SUBADDR.ti.ndex]    = GOADDRESS (p_subaddr)
	stateAfterFunc[#T_SUBADDRAT.ti.ndex]  = GOADDRESS (p_subaddrat)
	stateAfterFunc[#T_SWAP.ti.ndex]       = GOADDRESS (p_swap)
	stateAfterFunc[#T_UBYTE.ti.ndex]      = GOADDRESS (p_ubyte)
	stateAfterFunc[#T_UBYTEAT.ti.ndex]    = GOADDRESS (p_ubyteat)
	stateAfterFunc[#T_ULONG.ti.ndex]      = GOADDRESS (p_ulong)
	stateAfterFunc[#T_ULONGAT.ti.ndex]    = GOADDRESS (p_ulongat)
	stateAfterFunc[#T_USHORT.ti.ndex]     = GOADDRESS (p_ushort)
	stateAfterFunc[#T_USHORTAT.ti.ndex]   = GOADDRESS (p_ushortat)
	stateAfterFunc[#T_WRITE.ti.ndex]      = GOADDRESS (p_write)
	stateAfterFunc[#T_XLONG.ti.ndex]      = GOADDRESS (p_xlong)
	stateAfterFunc[#T_XLONGAT.ti.ndex]    = GOADDRESS (p_xlongat)
	IF stateAfterFunc[0] THEN
		XERROR = ERROR_COMPILER
		PRINT "CheckState(5032):stateAfterFunc[0] =", stateAfterFunc[0]
	END IF
END SUB
'
'
' ********************
' *****  ERRORS  *****
' ********************
'
eeeAfterElse:
	XERROR = ERROR_AFTER_ELSE
	EXIT FUNCTION
'
eeeBadCaseAll:
	XERROR = ERROR_BAD_CASE_ALL
	EXIT FUNCTION
eeeBadGosub:
	XERROR = ERROR_BAD_GOSUB
	EXIT FUNCTION
'
eeeBadGoto:
	XERROR = ERROR_BAD_GOTO
	EXIT FUNCTION
'
eeeBadSymbol:
	XERROR = ERROR_BAD_SYMBOL
	EXIT FUNCTION
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeComponent:
	XERROR = ERROR_COMPONENT
	EXIT FUNCTION
'
eeeCrossedFunctions:
	XERROR = ERROR_CROSSED_FUNCTIONS
	EXIT FUNCTION
'
eeeDeclare:
	XERROR = ERROR_DECLARE
	EXIT FUNCTION
'
eeeDeclareFuncs:
	XERROR = ERROR_DECLARE_FUNCS_FIRST
	EXIT FUNCTION
'
eeeDupDeclaration:
	XERROR = ERROR_DUP_DECLARATION
	EXIT FUNCTION
'
eeeDupDefinition:
	XERROR = ERROR_DUP_DEFINITION
	EXIT FUNCTION
'
eeeDupMismatch:
	XERROR = ERROR_DUP_MISMATCH
	EXIT FUNCTION
'
eeeDupType:
	XERROR = ERROR_DUP_TYPE
	EXIT FUNCTION
'
eeeElseInCaseAll:
	XERROR = ERROR_ELSE_IN_CASE_ALL
	EXIT FUNCTION
'
eeeEntryFunction:
	XERROR = ERROR_ENTRY_FUNCTION
	EXIT FUNCTION
'
eeeExpectAssignment:
	XERROR = ERROR_EXPECT_ASSIGNMENT
	EXIT FUNCTION
'
eeeExpressionStack:
	XERROR = ERROR_EXPRESSION_STACK
	EXIT FUNCTION
'
eeeInternalExternal:
	XERROR = ERROR_INTERNAL_EXTERNAL
	EXIT FUNCTION
'
eeeKindMismatch:
	XERROR = ERROR_KIND_MISMATCH
	EXIT FUNCTION
'
eeeNeedExcessComma:
	XERROR = ERROR_NEED_EXCESS_COMMA
	EXIT FUNCTION
'
eeeNeedSubscript:
	XERROR = ERROR_NEED_SUBSCRIPT
	EXIT FUNCTION
'
eeeNest:
	IFZ errNestLevel THEN errNestLevel = nestLevel
	nestToken = nestToken[errNestLevel]
	nestToken.tp.allo = 0
	SELECT CASE TRUE
		CASE TokenMatch (@nestToken, @#T_DO)    : XERROR = ERROR_NEST_DO
		CASE TokenMatch (@nestToken, @#T_FOR)   : XERROR = ERROR_NEST_FOR
		CASE TokenMatch (@nestToken, @#T_IF)    : XERROR = ERROR_NEST_IF
		CASE TokenMatch (@nestToken, @#T_SELECT): XERROR = ERROR_NEST_SELECT
		CASE TokenMatch (@nestToken, @#T_SUB)   : XERROR = ERROR_NEST_SUB
		CASE ELSE: XERROR = ERROR_NEST
	END SELECT
	errNestLevel = 0
	IF nestError THEN token = #T_STARTS: RETURN
	nestError = $$TRUE
	EXIT FUNCTION
'
eeeNodeDataMismatch:
	XERROR = ERROR_NODE_DATA_MISMATCH
	EXIT FUNCTION
'
eeeOutsideFunctions:
	XERROR = ERROR_OUTSIDE_FUNCTIONS
	EXIT FUNCTION
'
eeeOverflow:
	XERROR = ERROR_OVERFLOW
	EXIT FUNCTION
'
eeeProgramNotNamed:
	XERROR = ERROR_PROGRAM_NOT_NAMED
	EXIT FUNCTION
'
eeeScopeMismatch:
	XERROR = ERROR_SCOPE_MISMATCH
	EXIT FUNCTION
'
eeeSharename:
	XERROR = ERROR_SHARENAME
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooFewArgs:
	XERROR = ERROR_TOO_FEW_ARGS
	EXIT FUNCTION
'
eeeTooLate:
	XERROR = ERROR_TOO_LATE
	EXIT FUNCTION
'
eeeTooManyArgs:
	XERROR = ERROR_TOO_MANY_ARGS
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
'
eeeUndeclared:
	XERROR = ERROR_UNDECLARED
	EXIT FUNCTION
'
eeeUndefined:
	XERROR = ERROR_UNDEFINED
	EXIT FUNCTION
'
eeeUnimplemented:
	XERROR = ERROR_UNIMPLEMENTED
	EXIT FUNCTION
'
eeeWithinFunction:
	XERROR = ERROR_WITHIN_FUNCTION
	EXIT FUNCTION
END FUNCTION
'
'
' ################################
' #####  CloneArrayTOKEN ()  #####
' ################################
'
FUNCTION  CloneArrayTOKEN (TOKEN dest[], TOKEN source[])
'
	IFZ source[] THEN DIM dest[]: RETURN
	upper = UBOUND (source[])
	DIM dest[upper]
'
	FOR i = 0 TO upper
		dest[i] = source[i]
	NEXT i
'
END FUNCTION
'
'
' #####################
' #####  Code ()  #####
' #####################
'
FUNCTION  Code (opcode, mode, dreg, sreg$$, xreg, dataType, label$, remark$)
	EXTERNAL /xxx/  xpc, i486asm, i486bin
	SHARED  ofile
	SHARED  reg86$[],  reg86c$[],  typeSize[],  typeSize$[]
	SHARED  signhex64
	SHARED  XERROR, ERROR_COMPILER
	STATIC  smallStoreReg[], op$[],  fptr$[],  iptr$[]
	STATIC  XLONG amodeXlate[]  'translate "mode" to "amode"
	STATIC  XLONG twidModeXlate[] 'translate modes for bit-twiddle instructions
	STATIC  XLONG regcode[]   '3-bit register codes
	STATIC  XLONG scalef[]    '2-bit codes for scale factors (in s-i-b byte)
	STATIC  GOADDR  op[]
	STATIC  SUBADDR  mode[],  modex[]
	STATIC  GOADDR eamake[]   'GOADDRs to assemble mod-reg-rm bytes and s-i-b bytes;
														' one per "mode" ($$regreg, $$regr0, etc.)
	STATIC  GOADDR eamake4[]    'same as the GOADDRs in eamake[], except addressing modes
														' have an offset of 4 added to them and data-register numbers
														' are incremented (to access the most significant half
														' of a GIANT)
	STATIC  OPCODE86 op86[]   'data required to assemble an instruction:
														'1st dimension is "opcode" ($$add, $$adc, etc.)
														'2nd dimension is "amode" ($am_regea, $am_eareg, etc.)
	OPCODE86 op86             'element from op86[] for current instruction
	XLONG amode               'one of the $am_ constants: addressing-mode
														'category to which "mode" belongs
	XLONG mrm_mode            '"mode" field of mod-reg-rm byte
	XLONG mrm_reg             '"reg" field of mod-reg-rm byte
	XLONG mrm_rm              '"r/m" field of mod-reg-rm byte
'
	$am_regea = 0     'indexes into 2nd dimension of op86[]
	$am_eareg = 1     'each $am_ constant corresponds to one opcode of
	$am_ea = 2        ' one instruction.  (most instructions on the 80x86
	$am_rel = 3       ' have a different opcode for each addressing mode)
	$am_none = 4
	$am_eaimm = 5
	$am_max = 5
	$modemax = 32
'
'
'
	IFZ op[] THEN GOSUB Init
'
	sreg = sreg$$
	addr = xreg
	omode = mode
	dregx = dreg + 1
	sregx = sreg + 1
	xregx = xreg + 1
	addrx = addr + 4
	immByte = $$FALSE
	IFZ addr THEN
		SELECT CASE mode
			CASE $$ro:      mode = $$r0
			CASE $$regro:   mode = $$regr0
			CASE $$roreg:   mode = $$r0reg
			CASE $$roimm:   mode = $$r0imm
			CASE $$imm:     IF ((dreg >= -128) AND (dreg <= 127)) THEN immByte = $$TRUE
		END SELECT
	END IF
	SELECT CASE TRUE
		CASE i486bin: GOSUB EmitBin
		CASE i486asm: GOSUB EmitAsm
	END SELECT
	RETURN
'
SUB EmitBin
'	IF (dataType >= $$SCOMPLEX) THEN dataType = $$XLONG   '*cw* 230219+ 230223-
	IF (dataType >= $$STRING) THEN dataType = $$XLONG   '*cw* 230223+
	SELECT CASE dataType
		CASE $$SBYTE
					SELECT CASE opcode
						CASE $$ld:  opcode = $$movsx
						CASE $$st:  IFZ smallStoreReg[dreg] THEN XcowlErr (140076): GOTO eeeCompiler
												dreg = dreg - 8   ' make byte reg
					END SELECT
		CASE $$UBYTE
					SELECT CASE opcode
						CASE $$ld:  opcode = $$movzx
						CASE $$st:  IFZ smallStoreReg[dreg] THEN XcowlErr (140082): GOTO eeeCompiler
												dreg = dreg - 8   ' make byte reg
					END SELECT
		CASE $$SSHORT
					SELECT CASE opcode
						CASE $$ld:  opcode = $$movsx
						CASE $$st:  IFZ smallStoreReg[dreg] THEN XcowlErr (140088): GOTO eeeCompiler
												dreg = dreg - 4   ' make short reg
					END SELECT
		CASE $$USHORT
					SELECT CASE opcode
						CASE $$ld:  opcode = $$movzx
						CASE $$st:  IFZ smallStoreReg[dreg] THEN XcowlErr (140094): GOTO eeeCompiler
												dreg = dreg - 4   ' make short reg
					END SELECT
		CASE $$SLONG
					SELECT CASE opcode
						CASE $$ld:  opcode = $$movslq
						CASE $$st:  IFZ smallStoreReg[dreg] THEN XcowlErr (1400100): GOTO eeeCompiler
					END SELECT
	END SELECT
	GOSUB EmitInstruction
END SUB
'
SUB EmitInstruction
	amode = amodeXlate[mode]
	op86 = op86[opcode, amode]
	dataSize = typeSize[dataType]
'
	GOTO @op86.optype
'
 IF ##XBDV THEN PRINT "Zero optype address for opcode", opcode, "\""op$[opcode]"\""
	XcowlErr (1400121): GOTO eeeCompiler
	EXIT SUB
'
'
' ***** "optype" labels: one for each class of opcodes that are assembled the same way *****
'
BNorm:          '"normal" instructions, if indeed there are such things on the 80x86
								'a "normal" instructions is treated as follows:
								'   the last byte of its opcode is decremented if its operand is byte-sized
								'   prefixed with 0x66 if operand is word-sized
								'   followed by ea, as generated by MakeEa
								'   "reg" field of mod-reg-rm is dreg
	IF plus4
		mrm_reg = regcode[dreg + 1]
	ELSE
		mrm_reg = regcode[dreg]
	END IF
BRegop_entry:
'
	IF (dataSize = 8) THEN
		IF (mrm_reg AND 8) THEN                      '*cw* 230821+
'			UBYTEAT(xpc) = 0x49                        '*cw* 230821+-
			UBYTEAT(xpc) = 0x4C                        '*cw* 230822+
			mrm_reg = CLR(mrm_reg,1,3)                 '*cw* 230821+
		ELSE                                         '*cw* 230821+
			UBYTEAT(xpc) = 0x48                        '*cw* 230821+
		END IF                                       '*cw* 230821+
		rexW = xpc                                   '*cw* 230821+
		INC xpc                                      '*cw* 230821+
	END IF
'
	IF (dataSize = 2) THEN
		UBYTEAT(xpc) = 0x66
		INC xpc
	END IF
	IF (op86.nbytes = 2) THEN
		UBYTEAT(xpc) = op86.byte1
		INC xpc
		opcodebyte = op86.byte2
	ELSE
		opcodebyte = op86.byte1
	END IF
	IF (dataSize = 1) THEN
		UBYTEAT(xpc) = opcodebyte - 1
	ELSE
		UBYTEAT(xpc) = opcodebyte
	END IF
	INC xpc
	GOTO MakeEa
'
BRegop:         'an instruction with part of its opcode in the "reg" field of the mod-reg-rm
								'identical to a BNorm except for the setting of the "reg" field
	mrm_reg = op86.param
	GOTO BRegop_entry
'
BWord:          'a word-only instruction (PUSH and POP)
								'identical to BRegop except byte-sized operands are illegal
	mrm_reg = op86.param
	IF (dataSize < 2) THEN GOTO BErr
	IF (mode = $$reg) THEN
		SELECT CASE opcode
			CASE $$push : opcodebyte = 0x50
			CASE $$pop  : opcodebyte = 0x58
			CASE ELSE   : GOTO BErr
		END SELECT
		mrm_reg = regcode[dreg]
		IF (mrm_reg AND 0x8) THEN
			UBYTEAT(xpc) = 0x41
			INC xpc
		END IF
		opcodebyte = opcodebyte OR (mrm_reg AND 0x7)
			UBYTEAT(xpc) = opcodebyte
			INC xpc
			EXIT SUB
	END IF
	GOTO BRegop_entry
'
BTwid:          'bit-twiddling instructions
								'identical to a BNorm except "xxxreg" addressing modes are changed
								'to just "xxx" and "reg" field is part of opcode and "imm"s
								'are changed to "imm8"
	mode = twidModeXlate[mode]
	mrm_reg = op86.param
	GOTO BRegop_entry
'
BLea:           'the LEA instruction and any others like it
								'identical to a BNorm except dataSize is ignored

'	IF (dataSize = 8) THEN          '*cw* 230306-
	  UBYTEAT(xpc) = 0x48
		rexW = xpc                    '*cw* 230821-+
		INC xpc
'	END IF                          '*cw* 230306-

	IF plus4
		mrm_reg = regcode[dreg + 1]
	ELSE
		mrm_reg = regcode[dreg]
	END IF
	IF (op86.nbytes = 2) THEN
		UBYTEAT(xpc) = op86.byte1
		INC xpc
		opcodebyte = op86.byte2
	ELSE
		opcodebyte = op86.byte1
	END IF
	UBYTEAT(xpc) = opcodebyte
	INC xpc
	GOTO MakeEa
'
BNone:          'instructions with no operands
								'just spit out opcode bytes, don't go to MakeEa, don't do nuffin'
	IF (dataSize = 8) THEN
	  UBYTEAT(xpc) = 0x48
		rexW = xpc                  '*cw* 230821-+
		INC xpc
	END IF
'
BNoneNoRexW:                    '*cw* 220704+
	IF (op86.nbytes = 1) THEN
		UBYTEAT(xpc) = op86.byte1
		INC xpc
	ELSE
		UBYTEAT(xpc) = op86.byte1
		UBYTEAT(xpc, 1) = op86.byte2
		xpc = xpc + 2
	END IF
	EXIT SUB
'
BRel:           'relative branches
								'instruction consists of opcode byte(s) followed by 32-bit displacement
	IF (op86.nbytes = 1) THEN
		UBYTEAT(xpc) = op86.byte1
		INC xpc
	ELSE
		UBYTEAT(xpc) = op86.byte1
		UBYTEAT(xpc, 1) = op86.byte2
		xpc = xpc + 2
	END IF
	CodeLabelDisp(label$)
	EXIT SUB
'
' instructions with 32-bit immediate operand only (except push imm8)
' instruction consists of opcode byte(s) followed by dreg or label$
'
BImm:
	IFZ label$ THEN
		IF immByte THEN
			IF (opcode = $$push) THEN
				UBYTEAT(xpc) = op86.byte1 OR 2      ' push immSBYTE
				INC xpc
				UBYTEAT(xpc) = dreg AND 0x00FF
				INC xpc
				EXIT SUB
			END IF
		END IF
	END IF
'
	IF (op86.nbytes = 1) THEN
		UBYTEAT(xpc) = op86.byte1
		INC xpc
	ELSE
		UBYTEAT(xpc) = op86.byte1
		UBYTEAT(xpc, 1) = op86.byte2
		xpc = xpc + 2
	END IF
	IF label$ THEN
		CodeLabelAbs(label$, 0)
	ELSE
		UBYTEAT(xpc)    = dreg AND 0xFF
		UBYTEAT(xpc, 1) = (dreg AND 0xFF00) >> 8
		UBYTEAT(xpc, 2) = (dreg AND 0xFF0000) >> 16
		UBYTEAT(xpc, 3) = (dreg AND 0xFF000000) >> 24
		xpc = xpc + 4
	END IF
	EXIT SUB
'
' the INT instruction
' special opcode for INT 3; otherwise single-byte immmediate operand
'
BInt:
	IF (dreg = 3) THEN
		UBYTEAT(xpc) = 0xCC
		INC xpc
		EXIT SUB
	ELSE
		UBYTEAT(xpc) = 0xCD
		UBYTEAT(xpc, 1) = dreg
		xpc = xpc + 2
		EXIT SUB
	END IF
'
BErr:
	PRINT "invalid instruction/addressing-mode combination", opcode, amode
	XcowlErr (1400311): GOTO eeeCompiler
'
BRetImm:
	UBYTEAT(xpc) = 0xC2       : INC xpc
	UBYTEAT(xpc) = dreg       : INC xpc
	UBYTEAT(xpc) = dreg >> 8  : INC xpc
	EXIT SUB
'
BMovx:          'MOVSX and MOVZX
								'identical to BNorm except:
								'   32-bit operand size is an error (not checked)
								'   no change in opcode for 16-bit operands
  UBYTEAT(xpc) = 0x48
	rexW = xpc                       '*cw* 230821-+
	INC xpc
	mrm_reg = regcode[dreg]
'
	IF (op86.nbytes = 2) THEN
		UBYTEAT(xpc) = op86.byte1
		INC xpc
		opcodebyte = op86.byte2
	ELSE
		opcodebyte = op86.byte1
	END IF
'
	IF (dataSize = 1) THEN
		UBYTEAT(xpc) = opcodebyte - 1
	ELSE
		UBYTEAT(xpc) = opcodebyte
	END IF
'
	INC xpc
	GOTO MakeEa
'
BImul:      'the IMUL instruction with regimm addressing mode
						'generates three-operand IMUL instruction with source and
						' destination registers the same
						'only legal dataSizes are 2, 4 and 8
	SELECT CASE dataSize
		CASE 2, 4                      '2 or 4 bytes is good
		CASE 8 :	UBYTEAT(xpc) = 0x48  '8 bytes needs 64-bit prefix
							INC xpc
		CASE ELSE : GOTO BErr
	END SELECT
'	IFZ (sreg >> 8 ) THEN                    '*cw* 230228-
	IFZ (sreg >> 7 ) THEN                    '*cw* 230228+
		UBYTEAT(xpc) = 0x6B   'byte extended
		dataSize = 1
	ELSE
		UBYTEAT(xpc) = 0x69   'word extended
		dataSize = 4
	END IF
	INC xpc
	mrm_reg = regcode[dreg]
	GOTO MakeEa
'
BFstsw:         'FSTSW AX
BFnstsw:        'FNSTSW AX       '*cw* 220701+
	UBYTEAT(xpc) = 0xDF
	UBYTEAT(xpc, 1) = 0xE0
	xpc = xpc + 2
	EXIT SUB
'
BFld:       'FLD: 32-bit and 64-bit memory operands only
						'does not check if dataSize is invalid
						'does not check if operand is a register
	mrm_reg = 0
BFst_entry:
BFstp_entry:
	IF (dataSize = 4) THEN
		UBYTEAT(xpc) = 0xD9
	ELSE  'else dataSize is assumed to be 8
		UBYTEAT(xpc) = 0xDD
	END IF
	INC xpc
	GOTO MakeEa
'
BFild:      'FILD: 16-bit, 32-bit, and 64-bit memory operands only
						'does not check if dataSize is invalid
						'does not check if operand is a register
	SELECT CASE dataSize
		CASE 2
			UBYTEAT(xpc) = 0xDF
			mrm_reg = 0
		CASE 4
			UBYTEAT(xpc) = 0xDB
			mrm_reg = 0
		CASE ELSE 'else dataSize is assumed to be 8
			UBYTEAT(xpc) = 0xDF
			mrm_reg = 5
	END SELECT
	INC xpc
	GOTO MakeEa
'
BFst:       'FST: 32-bit or 64-bit memory operands only
						'does not check if dataSize is invalid
						'does not check if operand is a register
	mrm_reg = 2
	GOTO BFst_entry
'
BFist:      'FIST: 16-bit and 32-bit memory operands only
						'does not check if dataSize is invalid
						'does not check if operand is a register
	mrm_reg = 2
	IF (dataSize = 2) THEN
		UBYTEAT(xpc) = 0xDF
	ELSE 'else dataSize is assumed to be 4
		UBYTEAT(xpc) = 0xDB
	END IF
	INC xpc
	GOTO MakeEa
'
BFistp:     'FISTP: 16-bit, 32-bit, and 64-bit memory operands only
						'does not check if dataSize is invalid
						'does not check if operand is a register
	SELECT CASE dataSize
		CASE 2
			UBYTEAT(xpc) = 0xDF
			mrm_reg = 3
		CASE 4
			UBYTEAT(xpc) = 0xDB
			mrm_reg = 3
		CASE ELSE 'else dataSize is assumed to be 8
			UBYTEAT(xpc) = 0xDF
			mrm_reg = 7
	END SELECT
	INC xpc
	GOTO MakeEa
'
BFstp:      'FSTP: 32-bit or 64-bit memory operands only
						'does not check if dataSize is invalid
						'does not check if operand is a register
	mrm_reg = 3
	GOTO BFstp_entry
'
' ***** MakeEa: assembles mod-reg-rm and s-i-b bytes, assuming mrm_reg has already
'               been set.  opcode byte(s) are assumed to already have been written.
'               also writes immediate operand, if any, following ea.
'
MakeEa:
'
	IF (mrm_reg AND 8) THEN    '*cw* 230821+
		temp = UBYTEAT(rexW)     '*cw* 230821+
		temp = temp OR 4         '*cw* 230821+
		UBYTEAT(rexW) = temp     '*cw* 230821+
		mrm_reg = mrm_reg AND 7  '*cw* 230821+
	END IF                     '*cw* 230821+
'
	mrm_reg = mrm_reg << 3
	IFZ plus4 THEN
		GOTO @eamake[mode]
	ELSE
		GOTO @eamake4[mode]
	END IF
	XcowlErr (1400452): GOTO eeeCompiler
'
EM_none:
	EXIT SUB
'
EM_abs:
EM_regabs:
EM_absreg:
	UBYTEAT(xpc) = mrm_reg OR 0b00000101
	INC xpc
	IFZ addr THEN
		CodeLabelAbs(label$, 0)
	ELSE
'   address relative to %rip
		UBYTEAT(xpc)    = (addr - (xpc+4) AND 0xFF)
		UBYTEAT(xpc, 1) = (addr - (xpc+4) AND 0xFF00) >> 8
		UBYTEAT(xpc, 2) = (addr - (xpc+4) AND 0xFF0000) >> 16
		UBYTEAT(xpc, 3) = (addr - (xpc+4) AND 0xFF000000) >> 24
		xpc = xpc + 4
'		CodeAbs8Byte (addr)	'*cw* 230304+- ***************************************
	END IF
	EXIT SUB
'
EM_rel:
	CodeLabelDisp(label$)
	EXIT SUB
'
EM_reg:
	UBYTEAT(xpc) = mrm_reg OR 0b11000000 OR regcode[dreg]
	INC xpc
	EXIT SUB
'
EM_imm:
	IF label$ THEN
		CodeLabelAbs(label$, 0)
		EXIT SUB
	ELSE
		immval = dreg
		GOSUB EmitImm
		EXIT SUB
	END IF
'
'
EM_r0:
EM_regr0:
EM_r0reg:
	SELECT CASE TRUE
		CASE sreg = $$rsp:
			UBYTEAT(xpc) = mrm_reg OR 0b100   'have to make a s-i-b for [rsp]
			UBYTEAT(xpc, 1) = 0x24
			xpc = xpc + 2
		CASE sreg = $$rbp                   'have to make [rbp+0x00] for [rbp]
			UBYTEAT(xpc) = mrm_reg OR 0b01000101
			UBYTEAT(xpc, 1) = 0x00
			xpc = xpc + 2
		CASE ELSE:
			UBYTEAT(xpc) = mrm_reg OR regcode[sreg]
			INC xpc
	END SELECT
	EXIT SUB
'
'
EM_ro:
EM_regro:
EM_roreg:
	IF ((addr >= -128) AND (addr < +127)) THEN shorty = $$TRUE ELSE shorty = $$FALSE
	IF (sreg = $$rsp) THEN                  'have to make a s-i-b byte for [rsp]
		IF shorty THEN
			UBYTEAT(xpc) = mrm_reg OR 0b01000100
		ELSE
			UBYTEAT(xpc) = mrm_reg OR 0b10000100
		END IF
		UBYTEAT(xpc, 1) = 0x24
		xpc = xpc + 2
	ELSE
		IF shorty THEN
			UBYTEAT(xpc) = mrm_reg OR regcode[sreg] OR 0b01000000
		ELSE
			UBYTEAT(xpc) = mrm_reg OR regcode[sreg] OR 0b10000000
		END IF
		INC xpc
	END IF
	UBYTEAT(xpc)  = addr AND 0xFF              : INC xpc
	IF shorty THEN EXIT SUB
	UBYTEAT(xpc)  = (addr AND 0xFF00) >> 8     : INC xpc
	UBYTEAT(xpc)  = (addr AND 0xFF0000) >> 16  : INC xpc
	UBYTEAT(xpc)  = (addr AND 0xFF000000) >> 24: INC xpc
	EXIT SUB
'
EM_rr:               'warning: this will generate incorrect code for [rbp+rsp] and [rsp+rbp]
EM_regrr:
EM_rrreg:
	UBYTEAT(xpc) = mrm_reg OR 0b100
	IF (addr = $$rsp) THEN
		SWAP addr, sreg
	END IF
	UBYTEAT(xpc, 1) = (regcode[addr] << 3) OR regcode[sreg]
	xpc = xpc + 2
	EXIT SUB
'
EM_rs:              'assumes that dataSize is valid: 1, 2, 4, or 8
										'assumes that scaled register is not rsp (should be a safe assumption)
EM_regrs:
EM_rsreg:
	IF (sreg = $$rbp) THEN
		UBYTEAT(xpc) = mrm_reg OR 0b01000100
		UBYTEAT(xpc, 1) = scalef[dataSize] OR 0b00000101 OR (regcode[xreg] << 3)
		UBYTEAT(xpc, 2) = 0
		xpc = xpc + 3
		EXIT SUB
	ELSE
		UBYTEAT(xpc) = mrm_reg OR 0b100
		UBYTEAT(xpc, 1) = scalef[dataSize] OR (regcode[xreg] << 3) OR regcode[sreg]
		xpc = xpc + 2
		EXIT SUB
	END IF
'
EM_regreg:          'ea is source operand
	UBYTEAT(xpc) = 0b11000000 OR mrm_reg OR regcode[sreg]
	INC xpc
	EXIT SUB
'
EM_regimm:
	dreg_num = regcode[dreg]                                 '*cw* 230820+
	temp1 = dreg_num >> 3                                    '*cw* 230820+
	IF temp1 THEN                                            '*cw* 230820+
		temp2 = UBYTEAT(rexW)                                  '*cw* 230820+
		temp2 = temp2 OR temp1                                 '*cw* 230820+
		UBYTEAT(rexW) = temp2                                  '*cw* 230820+
		dreg_num = dreg_num AND 7                              '*cw* 230820+
		UBYTEAT(xpc) = 0b11000000 OR mrm_reg OR dreg_num       '*cw* 230820+
	ELSE                                                     '*cw* 230820+
		UBYTEAT(xpc) = 0b11000000 OR mrm_reg OR regcode[dreg]
	END IF                                                   '*cw* 230820+
'
'	UBYTEAT(xpc) = 0b11000000 OR mrm_reg OR regcode[dreg]    '*cw* 230822-
'
	INC xpc
	IF sreg THEN
		immval = sreg
		GOSUB EmitImm
		EXIT SUB
	END IF
	IF label$ THEN
		CodeLabelAbs(label$, 0)
		EXIT SUB
	ELSE
		immval = 0
		GOSUB EmitImm
		EXIT SUB
	END IF
	EXIT SUB
'
' sreg contains "imm"
' addr contains "abs" - else check label$
' what if imm and abs are both labels ???
'
EM_absimm:
	UBYTEAT(xpc) = mrm_reg OR 0b00000101
	INC xpc
	IFZ addr THEN
		CodeLabelAbs(label$, 0)
	ELSE
		UBYTEAT(xpc)    = addr AND 0xFF
		UBYTEAT(xpc, 1) = (addr AND 0xFF00) >> 8
		UBYTEAT(xpc, 2) = (addr AND 0xFF0000) >> 16
		UBYTEAT(xpc, 3) = (addr AND 0xFF000000) >> 24
		xpc = xpc + 4
	END IF
	immval = sreg
	GOSUB EmitImm
	EXIT SUB
'
EM_r0imm:
	SELECT CASE TRUE
		CASE sreg = $$rsp:
			UBYTEAT(xpc) = mrm_reg OR 0b100   ' have to make a s-i-b for [rsp]
			UBYTEAT(xpc, 1) = 0x24
			xpc = xpc + 2
		CASE sreg = $$rbp                   ' have to make [rbp+0x00] for [rbp]
			UBYTEAT(xpc) = mrm_reg OR 0b01000101
			UBYTEAT(xpc, 1) = 0x00
			xpc = xpc + 2
		CASE ELSE
			UBYTEAT(xpc) = mrm_reg OR regcode[sreg]
			INC xpc
	END SELECT
	IF dreg THEN
		immval = dreg
		GOSUB EmitImm
		EXIT SUB
	END IF
	IF label$ THEN
		CodeLabelAbs(label$, 0)
		EXIT SUB
	ELSE
		immval = 0
		GOSUB EmitImm
		EXIT SUB
	END IF
	EXIT SUB
'
EM_roimm:         'dreg or label$ contains "imm"
	IF (sreg = $$rsp) THEN                  'have to make a s-i-b byte for [rsp]
		IF (addr < 128) AND (addr >= -128) AND (opcodebyte == 0xC7) THEN       '*cw* 230318+-
			rsp_small = $$TRUE                                                   '*cw* 230318+
			UBYTEAT(xpc) = mrm_reg OR 0b01000100                                 '*cw* 230318+
		ELSE                                                                   '*cw* 230318+
			UBYTEAT(xpc) = mrm_reg OR 0b10000100
		END IF                                                                 '*cw* 230318+
		UBYTEAT(xpc, 1) = 0x24
		xpc = xpc + 2
	ELSE
		UBYTEAT(xpc) = mrm_reg OR regcode[sreg] OR 0b10000000
		INC xpc
	END IF
	UBYTEAT(xpc)    = addr AND 0xFF
	IF rsp_small THEN                                                        '*cw* 230318+
		xpc = xpc + 1                                                          '*cw* 230318+
	ELSE                                                                     '*cw* 230318+
		UBYTEAT(xpc, 1) = (addr AND 0xFF00) >> 8
		UBYTEAT(xpc, 2) = (addr AND 0xFF0000) >> 16
		UBYTEAT(xpc, 3) = (addr AND 0xFF000000) >> 24
		xpc = xpc + 4
	END IF                                                                   '*cw* 230318+
	IF dreg THEN
		immval = dreg
		GOSUB EmitImm
		EXIT SUB
	END IF
	IF label$ THEN
		CodeLabelAbs(label$, 0)
		EXIT SUB
	ELSE
		immval = 0
		GOSUB EmitImm
		EXIT SUB
	END IF
	EXIT SUB
'
EM_rrimm:             'warning: this will generate incorrect code for [rbp+rsp] and [rsp+rbp]
											'dreg or label$ contains "imm"
	UBYTEAT(xpc) = mrm_reg OR 0b100
	IF (addr = $$rsp) THEN
		SWAP addr, sreg
	END IF
	UBYTEAT(xpc, 1) = regcode[addr] OR regcode[sreg]
	xpc = xpc + 2
	IF dreg THEN
		immval = dreg
		GOSUB EmitImm
		EXIT SUB
	END IF
	IF label$ THEN
		CodeLabelAbs(label$, 0)
		EXIT SUB
	ELSE
		immval = 0
		GOSUB EmitImm
		EXIT SUB
	END IF
	EXIT SUB
'
EM_rsimm:           'assumes that dataSize is valid: 1, 2, 4, or 8
										'assumes that scaled register is not rsp (should be a safe assumption)
										'dreg or label$ contains "imm"
	IF (sreg = $$rbp) THEN
		UBYTEAT(xpc) = mrm_reg OR 0b01000100
		UBYTEAT(xpc, 1) = scalef[dataSize] OR 0b00000101 OR (regcode[xreg] << 3)
		UBYTEAT(xpc, 2) = 0
		xpc = xpc + 3
	ELSE
		UBYTEAT(xpc) = mrm_reg OR 0b100
		UBYTEAT(xpc, 1) = scalef[dataSize] OR (regcode[xreg] << 3) OR regcode[sreg]
		xpc = xpc + 2
	END IF
	IF dreg THEN
		immval = dreg
		GOSUB EmitImm
		EXIT SUB
	END IF
	IF label$ THEN
		CodeLabelAbs(label$, 0)
		EXIT SUB
	ELSE
		immval = 0
		GOSUB EmitImm
		EXIT SUB
	END IF
	EXIT SUB
'
EM_regimm8:         'immediate operand is shift width: always one byte
	UBYTEAT(xpc) = 0b11000000 OR mrm_reg OR regcode[dreg]
	UBYTEAT(xpc, 1) = sreg
	xpc = xpc + 2
	EXIT SUB
'
EM_absimm8:         'sreg contains shift width
	UBYTEAT(xpc) = mrm_reg OR 0b00000101
	INC xpc
	CodeLabelAbs(label$, 0)
	UBYTEAT(xpc) = sreg
	INC xpc
	EXIT SUB
'
EM_r0imm8:          'dreg contains shift width
	SELECT CASE TRUE
		CASE sreg = $$rsp:
			UBYTEAT(xpc) = mrm_reg OR 0b100   'have to make a s-i-b for [rsp]
			UBYTEAT(xpc, 1) = 0x24
			xpc = xpc + 2
		CASE sreg = $$rbp                     'have to make [rbp+0x00] for [rbp]
			UBYTEAT(xpc) = mrm_reg OR 0b01000101
			UBYTEAT(xpc, 1) = 0x00
			xpc = xpc + 2
		CASE ELSE
			UBYTEAT(xpc) = mrm_reg OR regcode[sreg]
			INC xpc
	END SELECT
	UBYTEAT(xpc) = dreg
	INC xpc
	EXIT SUB
'
EM_roimm8:          'dreg contains shift width
	IF (sreg = $$rsp) THEN                  'have to make a s-i-b byte for [rsp]
		UBYTEAT(xpc) = mrm_reg OR 0b10000100
		UBYTEAT(xpc, 1) = 0x24
		xpc = xpc + 2
	ELSE
		UBYTEAT(xpc) = mrm_reg OR regcode[sreg] OR 0b10000000
		INC xpc
	END IF
	UBYTEAT(xpc)    = addr AND 0xFF
	UBYTEAT(xpc, 1) = (addr AND 0xFF00) >> 8
	UBYTEAT(xpc, 2) = (addr AND 0xFF0000) >> 16
	UBYTEAT(xpc, 3) = (addr AND 0xFF000000) >> 24
	UBYTEAT(xpc, 4) = dreg
	xpc = xpc + 5
	EXIT SUB
'
EM_rrimm8:            'warning: this will generate incorrect code for [rbp+rsp] and [rsp+rbp]
											'dreg contains shift width
	UBYTEAT(xpc) = mrm_reg OR 0b100
	IF (addr = $$rsp) THEN
		SWAP addr, sreg
	END IF
	UBYTEAT(xpc, 1) = regcode[addr] OR regcode[sreg]
	UBYTEAT(xpc, 2) = dreg
	xpc = xpc + 3
	EXIT SUB
'
EM_rsimm8:          ' assumes that dataSize is valid: 1, 2, 4, or 8
										' assumes that scaled register is not rsp (should be a safe assumption)
										' dreg contains shift width
	IF (sreg = $$rbp) THEN
		UBYTEAT(xpc) = mrm_reg OR 0b01000100
		UBYTEAT(xpc, 1) = scalef[dataSize] OR 0b00000101 OR (regcode[xreg] << 3)
		UBYTEAT(xpc, 2) = 0
		xpc = xpc + 3
	ELSE
		UBYTEAT(xpc) = mrm_reg OR 0b100
		UBYTEAT(xpc, 1) = scalef[dataSize] OR (regcode[xreg] << 3) OR regcode[sreg]
		xpc = xpc + 2
	END IF
	UBYTEAT(xpc) = dreg
	INC xpc
	EXIT SUB
'
EM4_none:
EM4_rel:
EM4_imm:
EM4_abs:
EM4_r0:
EM4_rr:
EM4_rs:
EM4_absimm:
EM4_r0imm:
EM4_roimm:
EM4_rrimm:
EM4_rsimm:
	GOTO BErr
'
'
EM4_reg:
	UBYTEAT(xpc) = mrm_reg OR 0b11000000 OR regcode[dreg+1]
	INC xpc
	EXIT SUB
'
'
EM4_regabs:
EM4_absreg:
	UBYTEAT(xpc) = mrm_reg OR 0b00000101
	INC xpc
	IFZ addr THEN XcowlErr (1400822): GOTO eeeCompiler
	addr = addr + 4
	UBYTEAT(xpc)    = addr AND 0xFF
	UBYTEAT(xpc, 1) = (addr AND 0xFF00) >> 8
	UBYTEAT(xpc, 2) = (addr AND 0xFF0000) >> 16
	UBYTEAT(xpc, 3) = (addr AND 0xFF000000) >> 24
	xpc = xpc + 4
	EXIT SUB
'
EM4_regr0:
EM4_r0reg:
	addr = 0
	'fall through
'
EM4_ro:
EM4_regro:
EM4_roreg:
	addr4 = addr + 4
	shorty = $$FALSE
	IF ((addr4 >= -128) AND (addr4 < +127)) THEN shorty = $$TRUE
	IF (sreg = $$rsp) THEN                  'have to make a s-i-b byte for [rsp]
		IF shorty THEN
			UBYTEAT(xpc) = mrm_reg OR 0b01000100
		ELSE
			UBYTEAT(xpc) = mrm_reg OR 0b10000100
		END IF
		UBYTEAT(xpc, 1) = 0x24
		xpc = xpc + 2
	ELSE
		IF shorty THEN
			UBYTEAT(xpc) = mrm_reg OR regcode[sreg] OR 0b01000000
		ELSE
			UBYTEAT(xpc) = mrm_reg OR regcode[sreg] OR 0b10000000
		END IF
		INC xpc
	END IF
	UBYTEAT(xpc)    = addr4 AND 0xFF             : INC xpc
	IF shorty THEN EXIT SUB
	UBYTEAT(xpc)  = (addr4 AND 0xFF00) >> 8      : INC xpc
	UBYTEAT(xpc)  = (addr4 AND 0xFF0000) >> 16   : INC xpc
	UBYTEAT(xpc)  = (addr4 AND 0xFF000000) >> 24 : INC xpc
	EXIT SUB
'
'
EM4_regrr:          'warning: this will generate incorrect code for [rbp+rsp] and [rsp+rbp]
EM4_rrreg:
	UBYTEAT(xpc) = mrm_reg OR 0b01000100
	IF (addr = $$rsp) THEN
		SWAP addr, sreg
	END IF
	UBYTEAT(xpc, 1) = (regcode[addr] << 3) OR regcode[sreg]
	UBYTEAT(xpc, 2) = 4
	xpc = xpc + 3
	EXIT SUB
'
										'assumes that dataSize is valid: 1, 2, 4, or 8
										'assumes that scaled register is not rsp (should be a safe assumption)
EM4_regrs:
EM4_rsreg:
	UBYTEAT(xpc) = mrm_reg OR 0b01000100
	UBYTEAT(xpc, 1) = scalef[dataSize] OR regcode[sreg] OR (regcode[xreg] << 3)
	UBYTEAT(xpc, 2) = 4
	xpc = xpc + 3
	EXIT SUB
'
EM4_regreg:         'ea is source operand
	UBYTEAT(xpc) = 0b11000000 OR mrm_reg OR regcode[sreg + 1]
	INC xpc
	EXIT SUB
'
EM4_regimm:
	UBYTEAT(xpc) = 0b11000000 OR mrm_reg OR regcode[dreg + 1]
	INC xpc
	IF label$ THEN
		CodeLabelAbs(label$, 0)
		EXIT SUB
	ELSE
		UBYTEAT(xpc)    = sreg AND 0xFF
		UBYTEAT(xpc, 1) = (sreg AND 0xFF00) >> 8
		UBYTEAT(xpc, 2) = (sreg AND 0xFF0000) >> 16
		UBYTEAT(xpc, 3) = (sreg AND 0xFF000000) >> 24
		xpc = xpc + 4
		EXIT SUB
	END IF
	EXIT SUB
END SUB
'
'
'
SUB EmitImm     'immval = number to emit
								'generates 1, 2, or 4 bytes, depending on dataSize
								'does not check if dataSize is valid
	SELECT CASE dataSize
		CASE 1:   UBYTEAT(xpc)    = immval AND 0xFF
							INC xpc
		CASE 2:   UBYTEAT(xpc)    = immval AND 0xFF
							UBYTEAT(xpc, 1) = (immval AND 0xFF00) >> 8
							xpc = xpc + 2
		CASE 4:   UBYTEAT(xpc)    = immval AND 0xFF
							UBYTEAT(xpc, 1) = (immval AND 0xFF00) >> 8
							UBYTEAT(xpc, 2) = (immval AND 0xFF0000) >> 16
							UBYTEAT(xpc, 3) = (immval AND 0xFF000000) >> 24
							xpc = xpc + 4
		CASE 8:   CodeAbs8Byte (immval)
	END SELECT
END SUB
'
SUB EmitAsm
' IF (opcode = $$lea) THEN
'   PRINT Deparse$ (">>>")
'   dataType = $$XLONG
' END IF
	op$ = op$[opcode]
	ptrType = dataType
	IF (dataType >= $$SCOMPLEX) THEN ptrType = $$XLONG
	IF (op${1} = 'f') THEN
'   ptr$ = fptr$[ptrType]         ' spasm
		ptr$ = ""                     ' gas ?
	ELSE
'   ptr$ = iptr$[ptrType]         ' spasm
		ptr$ = ""                     ' gas ?
	END IF
	SELECT CASE dataType
		CASE $$SBYTE
					SELECT CASE opcode
						CASE $$ld:  op$ = " movsbq  "     ' gas
'           CASE $$ld:  op$ = " movsx "       ' spasm
						CASE $$st:  IFZ smallStoreReg[dreg] THEN XcowlErr (1400949): GOTO eeeCompiler
												op$ = " movb  "       ' gas
												dreg = dreg - 12      ' make byte reg
						CASE $$inc   : op$ = " incb  "    ' gas
						CASE $$dec   : op$ = " decb  "    ' gas
					END SELECT
		CASE $$UBYTE
					SELECT CASE opcode
						CASE $$ld:  op$ = " movzbq  "     ' gas
'           CASE $$ld:  op$ = " movzx "       ' spasm
						CASE $$st:  IFZ smallStoreReg[dreg] THEN XcowlErr (1400959): GOTO eeeCompiler
												op$ = " movb  "       ' gas
												dreg = dreg - 12      ' make byte reg
						CASE $$add   : op$ = " addb  "    ' gas
						CASE $$sub   : op$ = " subb  "    ' gas
					END SELECT
		CASE $$SSHORT
					SELECT CASE opcode
'           CASE $$ld    : op$ = " movsx "     ' spasm
						CASE $$ld    : op$ = " movswq  "   ' gas
						CASE $$st    : IFZ smallStoreReg[dreg] THEN XcowlErr (1400969): GOTO eeeCompiler
														op$ = " movw  "     ' gas
														dreg = dreg - 8     ' make short reg
						CASE $$fild  : op$ = " fildw "     ' gas
						CASE $$fist  : op$ = " fistw "     ' gas
						CASE $$fistp : op$ = " fistpw  "   ' gas
						CASE $$inc   : op$ = " incw  "     ' gas
						CASE $$dec   : op$ = " decw  "     ' gas
					END SELECT
		CASE $$USHORT
					SELECT CASE opcode
						CASE $$ld    : op$ = " movzwq  "   ' gas
'           CASE $$ld    : op$ = " movzx "     ' spasm
						CASE $$st    : IFZ smallStoreReg[dreg] THEN XcowlErr (1400982): GOTO eeeCompiler
														op$ = " movw  "     ' gas
														dreg = dreg - 8     ' make short reg
						CASE $$fild  : op$ = " fildw "     ' gas
						CASE $$fist  : op$ = " fistw "     ' gas
						CASE $$fistp : op$ = " fistpw  "   ' gas
						CASE $$add   : op$ = " addw  "     ' gas
						CASE $$sub   : op$ = " subw  "     ' gas
					END SELECT
		CASE $$SLONG
					SELECT CASE opcode
						CASE $$ld    : op$ = " movslq  "
						CASE $$st    : IFZ smallStoreReg[dreg] THEN XcowlErr (1400994): GOTO eeeCompiler
														op$ = " movl  "     ' gas
														dreg = dreg - 4     ' make long reg
						CASE $$fild  : op$ = " fildl "     ' gas
						CASE $$fist  : op$ = " fistl "     ' gas
						CASE $$fistp : op$ = " fistpl  "   ' gas
					END SELECT
		CASE $$ULONG
					SELECT CASE opcode
						CASE $$ld    : op$ = " movl    " : dreg = dreg-4
						CASE $$st    : IF smallStoreReg[dreg] THEN
															op$ = " movl  "     ' gas
															dreg = dreg - 4     ' make long reg
														END IF
						CASE $$fild  : op$ = " fildl "     ' gas
						CASE $$fist  : op$ = " fistl "     ' gas
						CASE $$fistp : op$ = " fistpl  "   ' gas
					END SELECT
		CASE $$XLONG, $$GIANT
					SELECT CASE opcode
						CASE $$fild  : op$ = " fildll "    ' gas      *cw* 220704-+
						CASE $$fist  : op$ = " fistl "     ' gas
						CASE $$fistp : op$ = " fistpll  "  ' gas      *cw* 220704-+ not tested
					END SELECT
		CASE $$SINGLE                               ' new to gas
					SELECT CASE opcode
						CASE $$fld   : op$ = " flds  "     ' gas
						CASE $$fst   : op$ = " fsts  "     ' gas
						CASE $$fstp  : op$ = " fstps "     ' gas
					END SELECT
		CASE $$DOUBLE                               ' new to gas
					SELECT CASE opcode
						CASE $$fld   : op$ = " fldl  "     ' gas
						CASE $$fst   : op$ = " fstl  "     ' gas
						CASE $$fstp  : op$ = " fstpl "     ' gas
					END SELECT
	END SELECT
	GOSUB @mode[mode]
	IF (LEFT$(remark$, 3) != "###") THEN
		remark$ = "### " + remark$
	END IF
	IF remark$ THEN
		spaces = 27 - LEN(op$) - LEN(oper$)
		IF (spaces < 4) THEN
			tabs = 2
		ELSE
			tabs = spaces / 2
		END IF
		IFZ oper$ THEN
			EmitAsm (op$ + CHR$('\t',tabs) + remark$)
		ELSE
			EmitAsm (op$ + oper$ + CHR$('\t',tabs) + remark$)
		END IF
	ELSE
		PRINT[ofile], (op$ + oper$)
	END IF
END SUB
'
SUB None
	oper$ = ""                                          ' spasm and gas
END SUB
'
SUB Rel
	oper$ = label$                                      ' spasm and gas ?
END SUB
'
SUB Imm
	IF label$ THEN
'   oper$ = label$                                    ' spasm
		oper$ = "$" + label$                              ' gas
	ELSE
'   oper$ = STRING (dreg)                             ' spasm
		oper$ = "$" + SignHex$(dreg)                       ' gas
	END IF
END SUB
'
SUB Reg
	IF ((opcode == $$call) OR (opcode == $$jmp)) THEN
		oper$ = "*" + reg86$[dreg]                        ' gas ?
	ELSE
		oper$ = reg86$[dreg]                              ' spasm and gas ?
	END IF
END SUB
'
SUB Abso
' oper$ = ptr$ + "[" + label$ + "]"                   ' spasm
	oper$ = ptr$ + label$                               ' gas ?
END SUB
'
SUB R0
' oper$ = ptr$ + "[" + reg86$[sreg] + "]"             ' spasm
	oper$ = ptr$ + "(" + reg86$[sreg] + ")"             ' gas ?
END SUB
'
SUB Ro
' oper$ = ptr$ + "[" + reg86$[sreg] + SIGNED$ (addr) + "]"    ' spasm
	oper$ = ptr$ + SignHex$ (addr) + "(" + reg86$[sreg] + ")"    ' gas ?
END SUB
'
SUB Rr
' oper$ = ptr$ + "[" + reg86$[sreg] + " + " + reg86$[xreg] + "]"    ' spasm
	oper$ = ptr$ + "(" + reg86c$[sreg] + reg86$[xreg] + ",1)"         ' gas ?
END SUB
'
SUB Rs
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "]"  ' spasm
	oper$ = ptr$ + "(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")"            ' gas ?
END SUB
'
SUB RegReg
' oper$ = reg86c$[dreg] + reg86$[sreg]                        ' spasm
	oper$ = reg86c$[sreg] + reg86$[dreg]                        ' gas
END SUB
'
SUB RegImm
	IF label$ THEN
'   oper$ = reg86c$[dreg] + label$                            ' spasm
		oper$ = "$" + label$ + "," + reg86$[dreg]                 ' gas
	ELSE
'   oper$ = reg86c$[dreg] + STRING$ (sreg)                    ' spasm
		oper$ = "$" + SignHex$(sreg$$) + "," + reg86$[dreg]          ' gas ?
		IF signhex64 THEN
			IF (opcode == $$mov) THEN
				op$ = "movabsq "
			END IF
		END IF
	END IF
END SUB
'
SUB RegAbs
' oper$ = reg86c$[dreg] + ptr$ + "[" + label$ + "]"           ' spasm
	oper$ = label$ + "," + ptr$ + reg86$[dreg]                  ' gas ?
END SUB
'
SUB RegR0
' oper$ = reg86c$[dreg] + ptr$ + "[" + reg86$[sreg] + "]"     ' spasm
	oper$ = ptr$ + "(" + reg86$[sreg] + ")," + reg86$[dreg]     ' gas ?
END SUB
'
SUB RegRo
' oper$ = reg86c$[dreg] + ptr$ + "[" + reg86$[sreg] + SIGNED$ (addr) + "]"        ' spasm
	oper$ = ptr$ + SignHex$(addr) + "(" + reg86$[sreg] + ")," +  reg86$[dreg]        ' gas ?
END SUB
'
SUB RegRr
' oper$ = reg86c$[dreg] + ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "]"    ' spasm
	oper$ = ptr$ + "(" + reg86c$[sreg] + reg86$[xreg] + ",1)," + reg86$[dreg]     ' gas ?
END SUB
'
SUB RegRs
' oper$ = reg86c$[dreg] + ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "]"    ' spasm
	oper$ = ptr$ + "(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")," + reg86$[dreg]              ' gas ?
END SUB
'
SUB AbsReg
' oper$ = ptr$ + "[" + label$ + "]," + reg86$[dreg]                               ' spasm
	oper$ = reg86c$[dreg] + ptr$ + label$                                           ' gas ?
END SUB
'
SUB R0Reg
' oper$ = ptr$ + "[" + reg86$[sreg] + "]," + reg86$[dreg]                         ' spasm
	oper$ = reg86c$[dreg] + ptr$ + "(" + reg86$[sreg] + ")"                         ' gas ?
END SUB
'
SUB RoReg
' oper$ = ptr$ + "[" + reg86$[sreg] + SIGNED$(addr) + "]," + reg86$[dreg]         ' spasm
	oper$ = reg86c$[dreg] + ptr$ + SignHex$(addr) + "(" + reg86$[sreg] + ")"         ' gas ?
END SUB
'
SUB RrReg
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "]," + reg86$[dreg]    ' spasm
	oper$ = reg86c$[dreg] + ptr$ + "(" + reg86c$[sreg] + reg86$[xreg] + ",1)"       ' gas ?
END SUB
'
SUB RsReg
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "]," + reg86$[dreg]    ' spasm
	oper$ = reg86c$[dreg] + ptr$ + "(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")"              ' gas ?
END SUB
'
SUB AbsImm                                                ' what if "abs" and "imm" are labels ???
	IF label$ THEN
'   oper$ = ptr$ + "[" + label$ + "]," + STRING (sreg)                            ' spasm
		oper$ = "$" + SignHex$(sreg) + "," + ptr$ + label$                             ' gas ?
	ELSE
'   oper$ = ptr$ + "[" + label$ + "]," + STRING (sreg)                            ' spasm
		oper$ = "$" + SignHex$(sreg) + "," + ptr$ + label$                             ' gas ?
	END IF
END SUB
'
SUB R0Imm
	IF label$ THEN
'   oper$ = ptr$ + "[" + reg86$[sreg] + "]," + label$                             ' spasm
		oper$ = "$" + label$ + "," + ptr$ + "(" + reg86$[sreg] + ")"                  ' gas ?
	ELSE
'   oper$ = ptr$ + "[" + reg86$[sreg] + "]," + STRING (dreg)                      ' spasm
		oper$ = "$" + SignHex$(dreg) + "," + ptr$ + "(" + reg86$[sreg] + ")"           ' gas ?
	END IF
END SUB
'
SUB RoImm
	IF label$ THEN
'   oper$ = ptr$ + "[" + reg86$[sreg] + SIGNED$ (addr) + "]," + label$                      ' spasm
		oper$ = "$" + label$ + "," + ptr$ + SignHex$ (addr) + "(" + reg86$[sreg] + ")"           ' gas ?
	ELSE
'   oper$ = ptr$ + "[" + reg86$[sreg] + SIGNED$ (addr) + "]," + STRING (dreg)               ' spasm
		oper$ = "$" + SignHex$(dreg) + "," + ptr$ + SignHex$(addr) + "(" + reg86$[sreg] + ")"     ' gas ?
	END IF
END SUB
'
SUB RrImm
	IF label$ THEN
'   oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "]," + label$                  ' spasm
		oper$ = "$" + label$ + "," + ptr$ + "(" + reg86c$[sreg] + reg86$[xreg] + ",1)"          ' gas ?
	ELSE
'   oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "]," + STRING (dreg)           ' spasm
		oper$ = "$" + SignHex$(dreg) + "," + ptr$ + "(" + reg86c$[sreg] + reg86$[xreg] + ",1)"   ' gas ?
	END IF
END SUB
'
SUB RsImm
	IF label$ THEN
'   oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "]," + label$          ' spasm
		oper$ = "$" + label$ + "," + ptr$ + "(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")"         ' gas ?
	ELSE
'   oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "]," + STRING (dreg)   ' spasm
		oper$ = "$" + SignHex$(dreg) + "," + ptr$ + "(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")"  ' gas ?
	END IF
END SUB
'
'
'
SUB XNone
	XcowlErr (14001221): GOTO eeeCompiler
END SUB
'
SUB XRel
	XcowlErr (14001225): GOTO eeeCompiler
END SUB
'
SUB XImm
	XcowlErr (14001229): GOTO eeeCompiler
END SUB
'
SUB XReg
	oper$ = reg86$[dreg+1]                                                ' spasm and gas ?
END SUB
'
SUB XAbso
' oper$ = ptr$ + "[" + label$ + "+4]"                                   ' spasm
	oper$ = ptr$ + label$ + "+4"                                          ' gas ?
END SUB
'
SUB XR0
' oper$ = ptr$ + "[" + reg86$[sreg] + "+4]"                             ' spasm
	oper$ = ptr$ + "4(" + reg86$[sreg]                                    ' gas ?
END SUB
'
SUB XRo
' oper$ = ptr$ + "[" + reg86$[sreg] + SIGNED$ (addrx) + "]"             ' spasm
	oper$ = ptr$ + SignHex$(addrx) + "(" + reg86$[sreg] + ")"              ' gas ?
END SUB
'
SUB XRr
' oper$ = ptr$ + "[" + reg86$[sreg] + " + " + reg86$[xreg] + "+4]"      ' spasm
	oper$ = ptr$ + "(" + reg86c$[sreg] + + reg86c$[xreg] + "+4]"          ' gas ?
END SUB
'
SUB XRs
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "+4]"    ' spasm
	oper$ = ptr$ + "4(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")"             ' gas ?
END SUB
'
SUB XRegReg
' oper$ = reg86c$[dregx] + reg86$[sregx]                                ' spasm
	oper$ = reg86c$[sregx] + reg86$[dregx]                                ' gas ?
END SUB
'
SUB XRegImm
' oper$ = reg86c$[dregx] + "0"                                          ' spasm
	oper$ = "$0x0," + reg86$[dregx]                                         ' gas ?
END SUB
'
SUB XRegAbs
' oper$ = reg86c$[dregx] + ptr$ + "[" + label$ + "+4]"                  ' spasm
	oper$ = ptr$ + label$ + "+4," + reg86$[dregx]                         ' gas ?
END SUB
'
SUB XRegR0
' oper$ = reg86c$[dregx] + ptr$ + "[" + reg86$[sreg] + "+4]"            ' spasm
	oper$ = ptr$ + "4(" + reg86$[sreg] + ")," + reg86$[dregx] ' gas ?
END SUB
'
SUB XRegRo
' oper$ = reg86c$[dregx] + ptr$ + "[" + reg86$[sreg] + SIGNED$ (addrx) + "]"          ' spasm
	oper$ = ptr$ + SignHex$(addrx) + "(" + reg86$[sreg] + ")," + reg86$[dregx]           ' gas ?
END SUB
'
SUB XRegRr
' oper$ = reg86c$[dreg+1] + ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "+4]"    ' spasm
	oper$ = ptr$ + "4(" + reg86c$[sreg] + reg86$[xreg] + ")," + reg86$[dreg+1]          ' gas ?
END SUB
'
SUB XRegRs
' oper$ = reg86c$[dreg+1] + ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "+4]"    ' spasm
	oper$ = ptr$ + "4(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")," + reg86$[dreg+1] ' gas ?
END SUB
'
SUB XAbsReg
' oper$ = ptr$ + "[" + label$ + "+4]," + reg86$[dregx]                              ' spasm
	oper$ = reg86c$[dregx] + ptr$ + label$ + "+4"                                     ' gas ?
END SUB
'
SUB XR0Reg
' oper$ = ptr$ + "[" + reg86$[sreg] + "+4]," + reg86$[dregx]                        ' spasm
	oper$ = reg86c$[dregx] + ptr$ + "4(" + reg86$[sreg] + ")"                         ' gas ?
END SUB
'
SUB XRoReg
' oper$ = ptr$ + "[" + reg86$[sreg] + SIGNED$(addrx) + "]," + reg86$[dregx]         ' spasm
	oper$ = reg86c$[dregx] + ptr$ + SignHex$(addrx) + "(" + reg86$[sreg] + ")"         ' gas ?
END SUB
'
SUB XRrReg
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "+4]," + reg86$[dregx]   ' spasm
	oper$ = reg86c$[dregx] + ptr$ + "4(" + reg86c$[sreg] + reg86$[xreg] + ")"         ' gas ?
END SUB
'
SUB XRsReg
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[addr] + "*" + typeSize$[dataType] + "+4]," + reg86$[dreg+1]    ' spasm
	oper$ = reg86c$[dreg+1] + ptr$ + "4(" + reg86c$[sreg] + reg86c$[addr] + typeSize$[dataType] + ")"               ' gas ?
END SUB
'
SUB XAbsImm
' oper$ = ptr$ + "[" + label$ + "+4],0"                                 ' spasm
	oper$ = "$0x0," + ptr$ + label$ + "+4"                                  ' gas ?
END SUB
'
SUB XR0Imm
' oper$ = ptr$ + "[" + reg86$[sreg] + "+4],0"                           ' spasm
	oper$ = "$0x0," + ptr$ + "4(" + reg86$[sreg] + ")"                      ' gas ?
END SUB
'
SUB XRoImm
' oper$ = ptr$ + "[" + reg86$[sreg] + SIGNED$ (addrx) + "],0"           ' spasm
	oper$ = "$0x0," + ptr$ + SignHex$(addrx) + "(" + reg86$[sreg] + ")"      ' gas ?
END SUB
'
SUB XRrImm
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "+4],0"      ' spasm
	oper$ = "$0x0," + ptr$ + "4(" + reg86c$[sreg] + reg86$[xreg] + ",1)"    ' gas ?
END SUB
'
SUB XRsImm
' oper$ = ptr$ + "[" + reg86$[sreg] + "+" + reg86$[xreg] + "*" + typeSize$[dataType] + "+4],0"    ' spasm
	oper$ = "$0x0," + ptr$ + "4(" + reg86c$[sreg] + reg86c$[xreg] + typeSize$[dataType] + ")"         ' gas ?
END SUB
'
'
'
' *******************************
' *****  Initialize Arrays  *****
' *******************************
'
SUB Init
	DIM op[255],    op$[255]
	DIM mode[31],   modex[31]
	DIM iptr$[31],  fptr$[31]
	DIM smallStoreReg[31]
	DIM amodeXlate[$modemax], twidModeXlate[$modemax]
	DIM regcode[31]
	DIM eamake[31], eamake4[31]
	DIM scalef[8]
	DIM op86[$$zlast, $am_max]
'
	amodeXlate[$$none]   = $am_none
	amodeXlate[$$rel]    = $am_rel
	amodeXlate[$$imm]    = $am_rel
	amodeXlate[$$reg]    = $am_ea
	amodeXlate[$$abs]    = $am_ea
	amodeXlate[$$r0]     = $am_ea
	amodeXlate[$$ro]     = $am_ea
	amodeXlate[$$rr]     = $am_ea
	amodeXlate[$$rs]     = $am_ea
	amodeXlate[$$regreg] = $am_regea
	amodeXlate[$$regimm] = $am_eaimm
	amodeXlate[$$regabs] = $am_regea
	amodeXlate[$$regr0]  = $am_regea
	amodeXlate[$$regro]  = $am_regea
	amodeXlate[$$regrr]  = $am_regea
	amodeXlate[$$regrs]  = $am_regea
	amodeXlate[$$absreg] = $am_eareg
	amodeXlate[$$r0reg]  = $am_eareg
	amodeXlate[$$roreg]  = $am_eareg
	amodeXlate[$$rrreg]  = $am_eareg
	amodeXlate[$$rsreg]  = $am_eareg
	amodeXlate[$$absimm] = $am_eaimm
	amodeXlate[$$r0imm]  = $am_eaimm
	amodeXlate[$$roimm]  = $am_eaimm
	amodeXlate[$$rrimm]  = $am_eaimm
	amodeXlate[$$rsimm]  = $am_eaimm
'
	twidModeXlate[$$none]   = $$none
	twidModeXlate[$$rel]    = $$rel
	twidModeXlate[$$imm]    = $$imm
	twidModeXlate[$$reg]    = $$reg
	twidModeXlate[$$abs]    = $$abs
	twidModeXlate[$$r0]     = $$r0
	twidModeXlate[$$ro]     = $$ro
	twidModeXlate[$$rr]     = $$rr
	twidModeXlate[$$rs]     = $$rs
	twidModeXlate[$$regreg] = $$reg
	twidModeXlate[$$regimm] = $$regimm8
	twidModeXlate[$$regabs] = $$regabs
	twidModeXlate[$$regr0]  = $$regr0
	twidModeXlate[$$regro]  = $$regro
	twidModeXlate[$$regrr]  = $$regrr
	twidModeXlate[$$regrs]  = $$regrs
	twidModeXlate[$$absreg] = $$reg
	twidModeXlate[$$r0reg]  = $$reg
	twidModeXlate[$$roreg]  = $$reg
	twidModeXlate[$$rrreg]  = $$reg
	twidModeXlate[$$rsreg]  = $$reg
	twidModeXlate[$$absimm] = $$absimm8
	twidModeXlate[$$r0imm]  = $$r0imm8
	twidModeXlate[$$roimm]  = $$roimm8
	twidModeXlate[$$rrimm]  = $$rrimm8
	twidModeXlate[$$rsimm]  = $$rsimm8
'
	eamake[$$none]    = GOADDRESS(EM_none)
	eamake[$$abs]     = GOADDRESS(EM_abs)
	eamake[$$rel]     = GOADDRESS(EM_rel)
	eamake[$$reg]     = GOADDRESS(EM_reg)
	eamake[$$imm]     = GOADDRESS(EM_imm)
	eamake[$$r0]      = GOADDRESS(EM_r0)
	eamake[$$ro]      = GOADDRESS(EM_ro)
	eamake[$$rr]      = GOADDRESS(EM_rr)
	eamake[$$rs]      = GOADDRESS(EM_rs)
	eamake[$$regreg]  = GOADDRESS(EM_regreg)
	eamake[$$regimm]  = GOADDRESS(EM_regimm)
	eamake[$$regabs]  = GOADDRESS(EM_regabs)
	eamake[$$regr0]   = GOADDRESS(EM_regr0)
	eamake[$$regro]   = GOADDRESS(EM_regro)
	eamake[$$regrr]   = GOADDRESS(EM_regrr)
	eamake[$$regrs]   = GOADDRESS(EM_regrs)
	eamake[$$absreg]  = GOADDRESS(EM_absreg)
	eamake[$$r0reg]   = GOADDRESS(EM_r0reg)
	eamake[$$roreg]   = GOADDRESS(EM_roreg)
	eamake[$$rrreg]   = GOADDRESS(EM_rrreg)
	eamake[$$rsreg]   = GOADDRESS(EM_rsreg)
	eamake[$$absimm]  = GOADDRESS(EM_absimm)
	eamake[$$r0imm]   = GOADDRESS(EM_r0imm)
	eamake[$$roimm]   = GOADDRESS(EM_roimm)
	eamake[$$rrimm]   = GOADDRESS(EM_rrimm)
	eamake[$$rsimm]   = GOADDRESS(EM_rsimm)
	eamake[$$regimm8] = GOADDRESS(EM_regimm8)
	eamake[$$absimm8] = GOADDRESS(EM_absimm8)
	eamake[$$r0imm8]  = GOADDRESS(EM_r0imm8)
	eamake[$$roimm8]  = GOADDRESS(EM_roimm8)
	eamake[$$rrimm8]  = GOADDRESS(EM_rrimm8)
	eamake[$$rsimm8]  = GOADDRESS(EM_rsimm8)
'
	eamake4[$$none]   = GOADDRESS(EM4_none)
	eamake4[$$abs]    = GOADDRESS(EM4_abs)
	eamake4[$$rel]    = GOADDRESS(EM4_rel)
	eamake4[$$reg]    = GOADDRESS(EM4_reg)
	eamake4[$$imm]    = GOADDRESS(EM4_imm)
	eamake4[$$r0]     = GOADDRESS(EM4_r0)
	eamake4[$$ro]     = GOADDRESS(EM4_ro)
	eamake4[$$rr]     = GOADDRESS(EM4_rr)
	eamake4[$$rs]     = GOADDRESS(EM4_rs)
	eamake4[$$regreg] = GOADDRESS(EM4_regreg)
	eamake4[$$regimm] = GOADDRESS(EM4_regimm)
	eamake4[$$regabs] = GOADDRESS(EM4_regabs)
	eamake4[$$regr0]  = GOADDRESS(EM4_regr0)
	eamake4[$$regro]  = GOADDRESS(EM4_regro)
	eamake4[$$regrr]  = GOADDRESS(EM4_regrr)
	eamake4[$$regrs]  = GOADDRESS(EM4_regrs)
	eamake4[$$absreg] = GOADDRESS(EM4_absreg)
	eamake4[$$r0reg]  = GOADDRESS(EM4_r0reg)
	eamake4[$$roreg]  = GOADDRESS(EM4_roreg)
	eamake4[$$rrreg]  = GOADDRESS(EM4_rrreg)
	eamake4[$$rsreg]  = GOADDRESS(EM4_rsreg)
	eamake4[$$absimm] = GOADDRESS(EM4_absimm)
	eamake4[$$r0imm]  = GOADDRESS(EM4_r0imm)
	eamake4[$$roimm]  = GOADDRESS(EM4_roimm)
	eamake4[$$rrimm]  = GOADDRESS(EM4_rrimm)
	eamake4[$$rsimm]  = GOADDRESS(EM4_rsimm)
'
'	regcode[ 1] = 4   'rsp
'	regcode[ 2] = 0   'al
'	regcode[ 3] = 2   'dl
'	regcode[ 4] = 3   'bl
'	regcode[ 5] = 1   'cl
'	regcode[ 6] = 0   'ax
'	regcode[ 7] = 2   'dx
'	regcode[ 8] = 3   'bx
'	regcode[ 9] = 1   'cx
'	regcode[10] = 0   'eax
'	regcode[11] = 2   'edx
'	regcode[12] = 3   'ebx
'	regcode[13] = 1   'ecx
'	regcode[26] = 6   'rsi
'	regcode[27] = 7   'rdi
'	regcode[28] = 1   'ecx
'	regcode[29] = 2   'edx
'	regcode[31] = 5   'rbp
'
	regcode[$$al]  = 0
	regcode[$$cl]  = 1
	regcode[$$dl]  = 2
	regcode[$$bl]  = 3
	regcode[$$ax]  = 0
	regcode[$$cx]  = 1
	regcode[$$dx]  = 2
	regcode[$$bx]  = 3
	regcode[$$eax] = 0
	regcode[$$ecx] = 1
	regcode[$$edx] = 2
	regcode[$$ebx] = 3
	regcode[$$rax] = 0
	regcode[$$rcx] = 1
	regcode[$$rdx] = 2
	regcode[$$rbx] = 3
	regcode[$$rsp] = 4
	regcode[$$rbp] = 5
	regcode[$$rsi] = 6
	regcode[$$rdi] = 7
	regcode[$$r8]  = 8
	regcode[$$r9]  = 9

'
	scalef[1] = 0
	scalef[2] = 1 << 6
	scalef[3] = 1 << 6    ' bogus value: should never be accessed
	scalef[4] = 2 << 6
	scalef[5] = 1 << 6    ' bogus value: should never be accessed
	scalef[6] = 1 << 6    ' bogus value: should never be accessed
	scalef[7] = 1 << 6    ' bogus value: should never be accessed
	scalef[8] = 3 << 6
'
' the following are the spasm opcode strings - followed by Linux aka gas opcode strings
'
' op$[$$nop]          = " nop "
' op$[$$adc]          = " adc "
' op$[$$add]          = " add "
' op$[$$and]          = " and "
' op$[$$bsf]          = " bsf "
' op$[$$bsr]          = " bsr "
' op$[$$bt]           = " bt  "
' op$[$$btc]          = " btc "
' op$[$$btr]          = " btr "
' op$[$$bts]          = " bts "
' op$[$$call]         = " call  "
' op$[$$cbw]          = " cbw "
' op$[$$cdq]          = " cdq "
' op$[$$clc]          = " clc "
' op$[$$cld]          = " cld "
' op$[$$cmc]          = " cmc "
' op$[$$cmp]          = " cmp "
' op$[$$cmpsb]        = " cmpsb "
' op$[$$cmpsw]        = " cmpsw "
' op$[$$cmpsd]        = " cmpsd "
' op$[$$cwd]          = " cwd "
' op$[$$cwde]         = " cwde  "
' op$[$$dec]          = " dec "
' op$[$$div]          = " div "
' op$[$$f2xm1]        = " f2xm1 "
' op$[$$fabs]         = " fabs  "
' op$[$$fadd]         = " fadd  "
' op$[$$faddp]        = " faddp "
' op$[$$fchs]         = " fchs  "
' op$[$$fclex]        = " fclex "
' op$[$$fnclex]       = " fnclex  "
' op$[$$fcom]         = " fcom  "
' op$[$$fcomp]        = " fcomp "
' op$[$$fcompp]       = " fcompp  "
' op$[$$fcos]         = " fcos  "
' op$[$$fdecstp]      = " fdecstp "
' op$[$$fdiv]         = " fdiv  "
' op$[$$fdivp]        = " fdivp "
' op$[$$fdivr]        = " fdivr "
' op$[$$fdivrp]       = " fdivrp  "
' op$[$$fild]         = " fild  "
' op$[$$fincstp]      = " fincstp "
' op$[$$fist]         = " fist  "
' op$[$$fistp]        = " fistp "
' op$[$$fld]          = " fld "
' op$[$$fldlg2]       = " fldlg2  "
' op$[$$fldln2]       = " fldln2  "
' op$[$$fldl2e]       = " fldl2e  "
' op$[$$fldl2t]       = " fldl2t  "
' op$[$$fldpi]        = " fldpi "
' op$[$$fldz]         = " fldz  "
' op$[$$fld1]         = " fld1  "
' op$[$$fmul]         = " fmul  "
' op$[$$fmulp]        = " fmulp "
' op$[$$fnop]         = " fnop  "
' op$[$$fpatan]       = " fpatan  "
' op$[$$fprem]        = " fprem "
' op$[$$fprem1]       = " fprem1  "
' op$[$$fptan]        = " fptan "
' op$[$$frndint]      = " frndint "
' op$[$$fscale]       = " fscale  "
' op$[$$fsin]         = " fsin  "
' op$[$$fsincos]      = " fsincos "
' op$[$$fsqrt]        = " fsqrt "
' op$[$$fst]          = " fst "
' op$[$$fstp]         = " fstp  "
' op$[$$fstsw]        = " fstsw "
' op$[$$fnstsw]       = " fnstsw  "
' op$[$$fsub]         = " fsub  "
' op$[$$fsubp]        = " fsubp "
' op$[$$fsubr]        = " fsubr "
' op$[$$fsubrp]       = " fsubrp  "
' op$[$$ftst]         = " ftst  "
' op$[$$fucom]        = " fucom "
' op$[$$fucomp]       = " fucomp  "
' op$[$$fucompp]      = " fucompp "
' op$[$$fxam]         = " fxam  "
' op$[$$fxch]         = " fxch  "
' op$[$$fxtract]      = " fxtract "
' op$[$$fyl2x]        = " fyl2x "
' op$[$$fyl2xp1]      = " fyl2xp1 "
' op$[$$f2xn1]        = " f2xn1 "
' op$[$$idiv]         = " idiv  "
' op$[$$imul]         = " imul  "
' op$[$$inc]          = " inc "
' op$[$$int]          = " int "
' op$[$$into]         = " into  "
' op$[$$ja]           = " ja  "
' op$[$$jae]          = " jae "
' op$[$$jb]           = " jb  "
' op$[$$jbe]          = " jbe "
' op$[$$jc]           = " jc  "
' op$[$$jcxz]         = " jcxz  "
' op$[$$jecxz]        = " jecxz "
' op$[$$je]           = " je  "
' op$[$$jg]           = " jg  "
' op$[$$jge]          = " jge "
' op$[$$jl]           = " jl  "
' op$[$$jle]          = " jle "
' op$[$$jna]          = " jna "
' op$[$$jnae]         = " jnae  "
' op$[$$jnb]          = " jnb "
' op$[$$jnbe]         = " jnbe  "
' op$[$$jnc]          = " jnc "
' op$[$$jne]          = " jne "
' op$[$$jng]          = " jng "
' op$[$$jnge]         = " jnge  "
' op$[$$jnl]          = " jnl "
' op$[$$jnle]         = " jnle  "
' op$[$$jno]          = " jno "
' op$[$$jnp]          = " jnp "
' op$[$$jns]          = " jns "
' op$[$$jnz]          = " jnz "
' op$[$$jo]           = " jo  "
' op$[$$jp]           = " jp  "
' op$[$$jpe]          = " jpe "
' op$[$$jpo]          = " jpo "
' op$[$$js]           = " js  "
' op$[$$jz]           = " jz  "
' op$[$$jmp]          = " jmp "
' op$[$$lahf]         = " lahf  "
' op$[$$ld]           = " mov "
' op$[$$lea]          = " lea "
' op$[$$lodsb]        = " lodsb "
' op$[$$lodsw]        = " lodsw "
' op$[$$lodsd]        = " lodsd "
' op$[$$loop]         = " loop  "
' op$[$$loopz]        = " loopz "
' op$[$$loopnz]       = " loopnz  "
' op$[$$mov]          = " mov "
' op$[$$movsb]        = " movsb "
' op$[$$movsw]        = " movsw "
' op$[$$movsd]        = " movsd "
' op$[$$mul]          = " mul "
' op$[$$neg]          = " neg "
' op$[$$nop]          = " nop "
' op$[$$not]          = " not "
' op$[$$or]           = " or  "
' op$[$$pop]          = " pop "
' op$[$$popad]        = " popad "
' op$[$$popfd]        = " popfd "
' op$[$$push]         = " push  "
' op$[$$pushad]       = " pushad  "
' op$[$$pushfd]       = " pushfd  "
' op$[$$rcl]          = " rcl "
' op$[$$rcr]          = " rcr "
' op$[$$rol]          = " rol "
' op$[$$ror]          = " ror "
' op$[$$rep]          = " rep "
' op$[$$repz]         = " repz  "
' op$[$$repnz]        = " repnz "
' op$[$$ret]          = " ret "
' op$[$$sahf]         = " sahf  "
' op$[$$sal]          = " sal "
' op$[$$sar]          = " sar "
' op$[$$sll]          = " sll "
' op$[$$slr]          = " slr "
' op$[$$sbb]          = " sbb "
' op$[$$scasb]        = " scasb "
' op$[$$scasw]        = " scasw "
' op$[$$scasd]        = " scasd "
' op$[$$shld]         = " shld  "
' op$[$$shrd]         = " shrd  "
' op$[$$st]           = " mov "
' op$[$$stc]          = " stc "
' op$[$$std]          = " std "
' op$[$$stosb]        = " stosb "
' op$[$$stosw]        = " stosw "
' op$[$$stosd]        = " stosd "
' op$[$$sub]          = " sub "
' op$[$$test]         = " test  "
' op$[$$xchg]         = " xchg  "
' op$[$$xor]          = " xor "
'
	op$[$$nop]          = " nop "       ' nop     =
	op$[$$adc]          = " adcq  "     ' adc
	op$[$$add]          = " addq  "     ' add
	op$[$$and]          = " andq  "     ' and
	op$[$$bsf]          = " bsfq  "     ' bsf       x
	op$[$$bsr]          = " bsrq  "     ' bsr
	op$[$$bt]           = " btq "       ' bt
	op$[$$btc]          = " btcq  "     ' btc       x
	op$[$$btr]          = " btrq  "     ' btr
	op$[$$bts]          = " btsq  "     ' bts
	op$[$$call]         = " call  "     ' call    = x
	op$[$$cbw]          = " cbtw  "     ' cbw       x   AT&T mnemonic
	op$[$$cdq]          = " cqto  "     ' cdq     =     AT&T mnemonic
	op$[$$clc]          = " clc "       ' clc     =
	op$[$$cld]          = " cld "       ' cld     =
	op$[$$cmc]          = " cmc "       ' cmc     =
	op$[$$cmp]          = " cmpq  "     ' cmp
	op$[$$cmpsb]        = " cmpsb "     ' cmpsb   =
	op$[$$cmpsw]        = " cmpsw "     ' cmpsw     x
	op$[$$cmpsd]        = " cmpsd "     ' cmpsd     x
	op$[$$cwd]          = " cwtd  "     ' cwd     = x   AT&T mnemonic
	op$[$$cwde]         = " cwtl  "     ' cwde    = x   AT&T mnemonic
	op$[$$dec]          = " decq  "     ' dec
	op$[$$div]          = " divq  "     ' div
	op$[$$f2xm1]        = " f2xm1 "     ' f2xm1     x
	op$[$$fabs]         = " fabs  "     ' fabs    =
	op$[$$fadd]         = " faddp "     ' fadd        !
	op$[$$faddp]        = " faddp "     ' faddp   =
	op$[$$fchs]         = " fchs  "     ' fchs    =
	op$[$$fclex]        = " fclex "     ' fclex   = x
	op$[$$fnclex]       = " fnclex  "   ' fnclex  =
	op$[$$fcom]         = " fcoms "     ' fcom
	op$[$$fcomp]        = " fcomp "     ' fcomp   =
	op$[$$fcompp]       = " fcompp  "   ' fcompp  =
	op$[$$fcos]         = " fcos  "     ' fcos    = x
	op$[$$fdecstp]      = " fdecstp "   ' fdecstp = x
	op$[$$fdiv]         = " fdivrp  "   ' fdivrp      !
	op$[$$fdivp]        = " fdivrp  "   ' fdivrp    x !
	op$[$$fdivr]        = " fdivp "     ' fdivp       !
	op$[$$fdivrp]       = " fdivp "     ' fdivp     x !
	op$[$$fild]         = " fild  "     ' fild    =   !
	op$[$$fincstp]      = " fincstp "   ' fincstp = x
' op$[$$fimul]        = " fimulq  "   ' fimul       !  !!! in unspas but not xnt.x !!!
	op$[$$fist]         = " fist  "     ' fist    =   !
	op$[$$fistp]        = " fistp "     ' fistp   =   !
	op$[$$fld]          = " fld "       ' fld     =   !
	op$[$$fldlg2]       = " fldlg2  "   ' fldlg2  = x
	op$[$$fldln2]       = " fldln2  "   ' fldln2  = x
	op$[$$fldl2e]       = " fldl2e  "   ' fldl2e  = x
	op$[$$fldl2t]       = " fldl2t  "   ' fldl2t  = x
	op$[$$fldpi]        = " fldpi "     ' fldpi   = x
	op$[$$fldz]         = " fldz  "     ' fldz    = x
	op$[$$fld1]         = " fld1  "     ' fld1    =
	op$[$$fmul]         = " fmulp "     ' fmul        !
	op$[$$fmulp]        = " fmulp "     ' fmulp   =
	op$[$$fnop]         = " fnop  "     ' fnop    =
	op$[$$fpatan]       = " fpatan  "   ' fpatan  = x
	op$[$$fprem]        = " fprem "     ' fprem   = x
	op$[$$fprem1]       = " fprem1  "   ' fprem1  = x
	op$[$$fptan]        = " fptan "     ' fptan   = x
	op$[$$frndint]      = " frndint "   ' frndint =
	op$[$$fscale]       = " fscale  "   ' fscale  = x
	op$[$$fsin]         = " fsin  "     ' fsin    = x
	op$[$$fsincos]      = " fsincos "   ' fsincos = x
	op$[$$fsqrt]        = " fsqrt "     ' fsqrt   = x
	op$[$$fst]          = " fst "       ' fst     =   !
	op$[$$fstp]         = " fstp  "     ' fstp    =   !
	op$[$$fstsw]        = " fstsw "     ' fstsw   =       !!! fas assembles as fnstsw
	op$[$$fnstsw]       = " fnstsw  "   ' fnstsw  =
	op$[$$fsub]         = " fsubrp  "   ' fsub        !
	op$[$$fsubp]        = " fsubrp  "   ' fsubp       !
	op$[$$fsubr]        = " fsubp "     ' fsubr       !
	op$[$$fsubrp]       = " fsubp "     ' fsubrp      !
	op$[$$ftst]         = " ftst  "     ' ftst    =
	op$[$$fucom]        = " fucom "     ' fucom   = x
	op$[$$fucomp]       = " fucomp  "   ' fucomp  = x
	op$[$$fucompp]      = " fucompp "   ' fucompp = x
' op$[$$fwait]        = " fwait "     ' fwait   =   !   !!! in unspas but not xnt.x !!!
	op$[$$fxam]         = " fxam  "     ' fxam    =
	op$[$$fxch]         = " fxch  "     ' fxch    = x
	op$[$$fxtract]      = " fxtract "   ' fxtract = x
	op$[$$fyl2x]        = " fyl2x "     ' fyl2x   = x
	op$[$$fyl2xp1]      = " fyl2xp1 "   ' fyl2xp1 = x
	op$[$$f2xn1]        = " f2xn1 "     ' f2xn1   = x
	op$[$$idiv]         = " idivq  "    ' idiv    =
	op$[$$imul]         = " imulq  "    ' imul    =
	op$[$$inc]          = " incq  "     ' inc
	op$[$$int]          = " int "       ' int     =
	op$[$$into]         = " int $4 "    ' into    =
	op$[$$ja]           = " ja  "       ' ja      = x
	op$[$$jae]          = " jae "       ' jae     = x
	op$[$$jb]           = " jb  "       ' jb      = x
	op$[$$jbe]          = " jbe "       ' jbe     = x
	op$[$$jc]           = " jc  "       ' jc      = x
	op$[$$jcxz]         = " jcxz  "     ' jcxz    = x
	op$[$$jecxz]        = " jecxz "     ' jecxz   = x
	op$[$$je]           = " je  "       ' je      = x
	op$[$$jg]           = " jg  "       ' jg      = x
	op$[$$jge]          = " jge "       ' jge     = x
	op$[$$jl]           = " jl  "       ' jl      = x
	op$[$$jle]          = " jle "       ' jle     = x
	op$[$$jna]          = " jna "       ' jna     = x
	op$[$$jnae]         = " jnae  "     ' jnae    = x
	op$[$$jnb]          = " jnb "       ' jnb     = x
	op$[$$jnbe]         = " jnbe  "     ' jnbe    = x
	op$[$$jnc]          = " jnc "       ' jnc     = x
	op$[$$jne]          = " jne "       ' jne     = x
	op$[$$jng]          = " jng "       ' jng     = x
	op$[$$jnge]         = " jnge  "     ' jnge    = x
	op$[$$jnl]          = " jnl "       ' jnl     = x
	op$[$$jnle]         = " jnle  "     ' jnle    = x
	op$[$$jno]          = " jno "       ' jno     = x
	op$[$$jnp]          = " jnp "       ' jnp     = x
	op$[$$jns]          = " jns "       ' jns     = x
	op$[$$jnz]          = " jnz "       ' jnz     = x
	op$[$$jo]           = " jo  "       ' jo      = x
	op$[$$jp]           = " jp  "       ' jp      = x
	op$[$$jpe]          = " jpe "       ' jpe     = x
	op$[$$jpo]          = " jpo "       ' jpo     = x
	op$[$$js]           = " js  "       ' js      = x
	op$[$$jz]           = " jz  "       ' jz      = x
	op$[$$jmp]          = " jmp "       ' jmp     = x
	op$[$$lahf]         = " lahf  "     ' lahf    =
	op$[$$ld]           = " movq  "     ' mov
	op$[$$lea]          = " leaq  "     ' lea
	op$[$$lodsb]        = " lodsb "     ' lodsb   = x
	op$[$$lodsw]        = " lodsw "     ' lodsw   = x
	op$[$$lodsd]        = " lodsd "     ' lodsd   = x
	op$[$$loop]         = " loop  "     ' loop    = x
	op$[$$loopz]        = " loopz "     ' loopz   = x
	op$[$$loopnz]       = " loopnz  "   ' loopnz  = x
	op$[$$mov]          = " movq  "     ' mov
	op$[$$movsb]        = " movsb "     ' movsb   =
	op$[$$movsw]        = " movsw "     ' movsw   =
	op$[$$movsd]        = " movsl "     ' movsd
	op$[$$movslq]       = " movslq "    ' movslq
	op$[$$mul]          = " mulq  "     ' mul
	op$[$$neg]          = " negq  "     ' neg
	op$[$$nop]          = " nop "       ' nop     =
	op$[$$not]          = " notq  "     ' not
	op$[$$or]           = " orq "       ' or
	op$[$$pop]          = " popq  "     ' pop
	op$[$$popad]        = " popad "     ' popad   = x
	op$[$$popfd]        = " popfd "     ' popfd   = x
	op$[$$push]         = " pushq "     ' push
	op$[$$pushad]       = " pushad  "   ' pushad  = x
	op$[$$pushfd]       = " pushfd  "   ' pushfd  = x
	op$[$$rcl]          = " rclq  "     ' rcl       x
	op$[$$rcr]          = " rcrq  "     ' rcr       x
	op$[$$rol]          = " rolq  "     ' rol       x
	op$[$$ror]          = " rorq  "     ' ror       x
	op$[$$rep]          = " rep "       ' rep     = x
	op$[$$repz]         = " repz  "     ' repz    = x
	op$[$$repnz]        = " repnz "     ' repnz   = x
	op$[$$ret]          = " ret "       ' ret     = x
	op$[$$sahf]         = " sahf  "     ' sahf    =
	op$[$$sal]          = " salq  "     ' sal
	op$[$$sar]          = " sarq  "     ' sar
	op$[$$sll]          = " shlq  "     ' sll
	op$[$$slr]          = " shrq  "     ' slr
	op$[$$sbb]          = " sbbq  "     ' sbb
	op$[$$scasb]        = " scasb "     ' scasb   =
	op$[$$scasw]        = " scasw "     ' scasw   = x
	op$[$$scasd]        = " scasd "     ' scasd   = x
	op$[$$shld]         = " shldq "     ' shld
	op$[$$shrd]         = " shrdq "     ' shrd
	op$[$$st]           = " movq  "     ' mov
	op$[$$stc]          = " stc "       ' stc     = x
	op$[$$std]          = " std "       ' std     = x
	op$[$$stosb]        = " stosb "     ' stosb   =
	op$[$$stosw]        = " stosw "     ' stosw   =
	op$[$$stosd]        = " stosl "     ' stosd
	op$[$$stosq]        = " stosq "     ' stosq
	op$[$$sub]          = " subq  "     ' sub
	op$[$$test]         = " testq "     ' test
	op$[$$xchg]         = " xchgq "     ' xchg
' op$[$$xlat]         = " xlat  "     ' xlatb       !   !!! in unspas but not xnt.x !!!
	op$[$$xor]          = " xorq  "     ' xor
'
	mode[$$none]                = SUBADDRESS (None)
	mode[$$abs]                 = SUBADDRESS (Abso)
	mode[$$rel]                 = SUBADDRESS (Rel)
	mode[$$reg]                 = SUBADDRESS (Reg)
	mode[$$imm]                 = SUBADDRESS (Imm)
	mode[$$r0]                  = SUBADDRESS (R0)
	mode[$$ro]                  = SUBADDRESS (Ro)
	mode[$$rr]                  = SUBADDRESS (Rr)
	mode[$$rs]                  = SUBADDRESS (Rs)
	mode[$$regreg]              = SUBADDRESS (RegReg)
	mode[$$regimm]              = SUBADDRESS (RegImm)
	mode[$$regabs]              = SUBADDRESS (RegAbs)
	mode[$$regr0]               = SUBADDRESS (RegR0)
	mode[$$regro]               = SUBADDRESS (RegRo)
	mode[$$regrr]               = SUBADDRESS (RegRr)
	mode[$$regrs]               = SUBADDRESS (RegRs)
	mode[$$absreg]              = SUBADDRESS (AbsReg)
	mode[$$r0reg]               = SUBADDRESS (R0Reg)
	mode[$$roreg]               = SUBADDRESS (RoReg)
	mode[$$rrreg]               = SUBADDRESS (RrReg)
	mode[$$rsreg]               = SUBADDRESS (RsReg)
	mode[$$absimm]              = SUBADDRESS (AbsImm)
	mode[$$r0imm]               = SUBADDRESS (R0Imm)
	mode[$$roimm]               = SUBADDRESS (RoImm)
	mode[$$rrimm]               = SUBADDRESS (RrImm)
	mode[$$rsimm]               = SUBADDRESS (RsImm)
'
	modex[$$none]               = SUBADDRESS (XNone)
	modex[$$abs]                = SUBADDRESS (XAbso)
	modex[$$rel]                = SUBADDRESS (XRel)
	modex[$$reg]                = SUBADDRESS (XReg)
	modex[$$imm]                = SUBADDRESS (XImm)
	modex[$$r0]                 = SUBADDRESS (XR0)
	modex[$$ro]                 = SUBADDRESS (XRo)
	modex[$$rr]                 = SUBADDRESS (XRr)
	modex[$$rs]                 = SUBADDRESS (XRs)
	modex[$$regreg]             = SUBADDRESS (XRegReg)
	modex[$$regimm]             = SUBADDRESS (XRegImm)
	modex[$$regabs]             = SUBADDRESS (XRegAbs)
	modex[$$regr0]              = SUBADDRESS (XRegR0)
	modex[$$regro]              = SUBADDRESS (XRegRo)
	modex[$$regrr]              = SUBADDRESS (XRegRr)
	modex[$$regrs]              = SUBADDRESS (XRegRs)
	modex[$$absreg]             = SUBADDRESS (XAbsReg)
	modex[$$r0reg]              = SUBADDRESS (XR0Reg)
	modex[$$roreg]              = SUBADDRESS (XRoReg)
	modex[$$rrreg]              = SUBADDRESS (XRrReg)
	modex[$$rsreg]              = SUBADDRESS (XRsReg)
	modex[$$absimm]             = SUBADDRESS (XAbsImm)
	modex[$$r0imm]              = SUBADDRESS (XR0Imm)
	modex[$$roimm]              = SUBADDRESS (XRoImm)
	modex[$$rrimm]              = SUBADDRESS (XRrImm)
	modex[$$rsimm]              = SUBADDRESS (XRsImm)
'
	iptr$[$$ZERO]               = ""
	iptr$[$$VOID]               = ""
	iptr$[$$SBYTE]              = "byte ptr "
	iptr$[$$UBYTE]              = "byte ptr "
	iptr$[$$SSHORT]             = "word ptr "
	iptr$[$$USHORT]             = "word ptr "
	iptr$[$$SLONG]              = ""
	iptr$[$$ULONG]              = ""
	iptr$[$$XLONG]              = ""
	iptr$[$$GOADDR]             = ""
	iptr$[$$SUBADDR]            = ""
	iptr$[$$FUNCADDR]           = ""
	iptr$[$$GIANT]              = ""
	iptr$[$$SINGLE]             = "dword ptr "
	iptr$[$$DOUBLE]             = "qword ptr "
	fptr$[$$ZERO]               = ""
	fptr$[$$VOID]               = ""
	fptr$[$$SBYTE]              = "byte ptr "
	fptr$[$$UBYTE]              = "byte ptr "
	fptr$[$$SSHORT]             = "word ptr "
	fptr$[$$USHORT]             = "word ptr "
	fptr$[$$SLONG]              = ""
	fptr$[$$ULONG]              = ""
	fptr$[$$XLONG]              = ""
	fptr$[$$GOADDR]             = ""
	fptr$[$$SUBADDR]            = ""
	fptr$[$$FUNCADDR]           = ""
	fptr$[$$GIANT]              = "qword ptr "
	fptr$[$$SINGLE]             = "dword ptr "
	fptr$[$$DOUBLE]             = "qword ptr "
'
	smallStoreReg[$$al]   = $$TRUE
	smallStoreReg[$$dl]   = $$TRUE
	smallStoreReg[$$bl]   = $$TRUE
	smallStoreReg[$$cl]   = $$TRUE
	smallStoreReg[$$ax]   = $$TRUE
	smallStoreReg[$$dx]   = $$TRUE
	smallStoreReg[$$bx]   = $$TRUE
	smallStoreReg[$$cx]   = $$TRUE
	smallStoreReg[$$eax]  = $$TRUE
	smallStoreReg[$$edx]  = $$TRUE
	smallStoreReg[$$ebx]  = $$TRUE
	smallStoreReg[$$ecx]  = $$TRUE
	smallStoreReg[$$rax]  = $$TRUE
	smallStoreReg[$$rdx]  = $$TRUE
	smallStoreReg[$$rbx]  = $$TRUE
	smallStoreReg[$$ecx]  = $$TRUE
'
	op86[$$adc, $am_regea].nbytes   = 1
	op86[$$adc, $am_regea].byte1    = 0x13
	op86[$$adc, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$adc, $am_eareg].nbytes   = 1
	op86[$$adc, $am_eareg].byte1    = 0x11
	op86[$$adc, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$adc, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$adc, $am_eaimm].nbytes   = 1
	op86[$$adc, $am_eaimm].byte1    = 0x81
	op86[$$adc, $am_eaimm].param    = 2
	op86[$$adc, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$adc, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$adc, $am_none].optype    = GOADDRESS(BErr)
	op86[$$add, $am_regea].nbytes   = 1
	op86[$$add, $am_regea].byte1    = 0x03
	op86[$$add, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$add, $am_eareg].nbytes   = 1
	op86[$$add, $am_eareg].byte1    = 0x01
	op86[$$add, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$add, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$add, $am_eaimm].nbytes   = 1
	op86[$$add, $am_eaimm].byte1    = 0x81
	op86[$$add, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$add, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$add, $am_none].optype    = GOADDRESS(BErr)
	op86[$$and, $am_regea].nbytes   = 1
	op86[$$and, $am_regea].byte1    = 0x23
	op86[$$and, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$and, $am_eareg].nbytes   = 1
	op86[$$and, $am_eareg].byte1    = 0x21
	op86[$$and, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$and, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$and, $am_eaimm].nbytes   = 1
	op86[$$and, $am_eaimm].byte1    = 0x81
	op86[$$and, $am_eaimm].param    = 4
	op86[$$and, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$and, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$and, $am_none].optype    = GOADDRESS(BErr)
	op86[$$cmp, $am_regea].nbytes   = 1
	op86[$$cmp, $am_regea].byte1    = 0x3B
	op86[$$cmp, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$cmp, $am_eareg].nbytes   = 1
	op86[$$cmp, $am_eareg].byte1    = 0x39
	op86[$$cmp, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$cmp, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$cmp, $am_eaimm].nbytes   = 1
	op86[$$cmp, $am_eaimm].byte1    = 0x81
	op86[$$cmp, $am_eaimm].param    = 7
	op86[$$cmp, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$cmp, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$cmp, $am_none].optype    = GOADDRESS(BErr)
	op86[$$or, $am_regea].nbytes    = 1
	op86[$$or, $am_regea].byte1     = 0x0B
	op86[$$or, $am_regea].optype    = GOADDRESS(BNorm)
	op86[$$or, $am_eareg].nbytes    = 1
	op86[$$or, $am_eareg].byte1     = 0x09
	op86[$$or, $am_eareg].optype    = GOADDRESS(BNorm)
	op86[$$or, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$or, $am_eaimm].nbytes    = 1
	op86[$$or, $am_eaimm].byte1     = 0x81
	op86[$$or, $am_eaimm].param     = 1
	op86[$$or, $am_eaimm].optype    = GOADDRESS(BRegop)
	op86[$$or, $am_rel].optype      = GOADDRESS(BErr)
	op86[$$or, $am_none].optype     = GOADDRESS(BErr)
	op86[$$sbb, $am_regea].nbytes   = 1
	op86[$$sbb, $am_regea].byte1    = 0x1B
	op86[$$sbb, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$sbb, $am_eareg].nbytes   = 1
	op86[$$sbb, $am_eareg].byte1    = 0x19
	op86[$$sbb, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$sbb, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$sbb, $am_eaimm].nbytes   = 1
	op86[$$sbb, $am_eaimm].byte1    = 0x81
	op86[$$sbb, $am_eaimm].param    = 3
	op86[$$sbb, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$sbb, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$sbb, $am_none].optype    = GOADDRESS(BErr)
	op86[$$sub, $am_regea].nbytes   = 1
	op86[$$sub, $am_regea].byte1    = 0x2B
	op86[$$sub, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$sub, $am_eareg].nbytes   = 1
	op86[$$sub, $am_eareg].byte1    = 0x29
	op86[$$sub, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$sub, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$sub, $am_eaimm].nbytes   = 1
	op86[$$sub, $am_eaimm].byte1    = 0x81
	op86[$$sub, $am_eaimm].param    = 5
	op86[$$sub, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$sub, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$sub, $am_none].optype    = GOADDRESS(BErr)
	op86[$$xor, $am_regea].nbytes   = 1
	op86[$$xor, $am_regea].byte1    = 0x33
	op86[$$xor, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$xor, $am_eareg].nbytes   = 1
	op86[$$xor, $am_eareg].byte1    = 0x31
	op86[$$xor, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$xor, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$xor, $am_eaimm].nbytes   = 1
	op86[$$xor, $am_eaimm].byte1    = 0x81
	op86[$$xor, $am_eaimm].param    = 6
	op86[$$xor, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$xor, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$xor, $am_none].optype    = GOADDRESS(BErr)
	op86[$$mov, $am_regea].nbytes   = 1
	op86[$$mov, $am_regea].byte1    = 0x8B
	op86[$$mov, $am_regea].optype   = GOADDRESS(BNorm)
	op86[$$mov, $am_eareg].nbytes   = 1
	op86[$$mov, $am_eareg].byte1    = 0x89
	op86[$$mov, $am_eareg].optype   = GOADDRESS(BNorm)
	op86[$$mov, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$mov, $am_eaimm].nbytes   = 1
	op86[$$mov, $am_eaimm].byte1    = 0xC7
	op86[$$mov, $am_eaimm].optype   = GOADDRESS(BRegop)
	op86[$$mov, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$mov, $am_none].optype    = GOADDRESS(BErr)
	op86[$$ld, $am_regea].nbytes    = 1
	op86[$$ld, $am_regea].byte1     = 0x8B
	op86[$$ld, $am_regea].optype    = GOADDRESS(BNorm)
	op86[$$ld, $am_eareg].nbytes    = 1
	op86[$$ld, $am_eareg].byte1     = 0x89
	op86[$$ld, $am_eareg].optype    = GOADDRESS(BNorm)
	op86[$$ld, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$ld, $am_eaimm].nbytes    = 1
	op86[$$ld, $am_eaimm].byte1     = 0xC7
	op86[$$ld, $am_eaimm].optype    = GOADDRESS(BRegop)
	op86[$$ld, $am_rel].optype      = GOADDRESS(BErr)
	op86[$$ld, $am_none].optype     = GOADDRESS(BErr)
	op86[$$st, $am_regea].nbytes    = 1
	op86[$$st, $am_regea].byte1     = 0x8B
	op86[$$st, $am_regea].optype    = GOADDRESS(BNorm)
	op86[$$st, $am_eareg].nbytes    = 1
	op86[$$st, $am_eareg].byte1     = 0x89
	op86[$$st, $am_eareg].optype    = GOADDRESS(BNorm)
	op86[$$st, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$st, $am_eaimm].nbytes    = 1
	op86[$$st, $am_eaimm].byte1     = 0xC7
	op86[$$st, $am_eaimm].optype    = GOADDRESS(BRegop)
	op86[$$st, $am_rel].optype      = GOADDRESS(BErr)
	op86[$$st, $am_none].optype     = GOADDRESS(BErr)
	op86[$$test, $am_regea].nbytes  = 1
	op86[$$test, $am_regea].byte1   = 0x85
	op86[$$test, $am_regea].optype  = GOADDRESS(BNorm)
	op86[$$test, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$test, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$test, $am_eaimm].nbytes  = 1
	op86[$$test, $am_eaimm].byte1   = 0xF7
	op86[$$test, $am_eaimm].optype  = GOADDRESS(BRegop)
	op86[$$test, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$test, $am_none].optype   = GOADDRESS(BErr)
	op86[$$imul, $am_regea].nbytes  = 2
	op86[$$imul, $am_regea].byte1   = 0x0F
	op86[$$imul, $am_regea].byte2   = 0xAF
	op86[$$imul, $am_regea].optype  = GOADDRESS(BNorm)
	op86[$$imul, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$imul, $am_ea].nbytes     = 1
	op86[$$imul, $am_ea].byte1      = 0xF7
	op86[$$imul, $am_ea].param      = 5
	op86[$$imul, $am_ea].optype     = GOADDRESS(BRegop)
	op86[$$imul, $am_eaimm].nbytes  = 1
	op86[$$imul, $am_eaimm].byte1   = 0x69
	op86[$$imul, $am_eaimm].optype  = GOADDRESS(BImul)
	op86[$$imul, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$imul, $am_none].optype   = GOADDRESS(BErr)
	op86[$$idiv, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$idiv, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$idiv, $am_ea].nbytes     = 1
	op86[$$idiv, $am_ea].byte1      = 0xF7
	op86[$$idiv, $am_ea].param      = 7
	op86[$$idiv, $am_ea].optype     = GOADDRESS(BRegop)
	op86[$$idiv, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$idiv, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$idiv, $am_none].optype   = GOADDRESS(BErr)
	op86[$$div, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$div, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$div, $am_ea].nbytes      = 1
	op86[$$div, $am_ea].byte1       = 0xF7
	op86[$$div, $am_ea].param       = 6
	op86[$$div, $am_ea].optype      = GOADDRESS(BRegop)
	op86[$$div, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$div, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$div, $am_none].optype    = GOADDRESS(BErr)
	op86[$$mul, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$mul, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$mul, $am_ea].nbytes      = 1
	op86[$$mul, $am_ea].byte1       = 0xF7
	op86[$$mul, $am_ea].param       = 4
	op86[$$mul, $am_ea].optype      = GOADDRESS(BRegop)
	op86[$$mul, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$mul, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$mul, $am_none].optype    = GOADDRESS(BErr)
	op86[$$not, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$not, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$not, $am_ea].nbytes      = 1
	op86[$$not, $am_ea].byte1       = 0xF7
	op86[$$not, $am_ea].param       = 2
	op86[$$not, $am_ea].optype      = GOADDRESS(BRegop)
	op86[$$not, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$not, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$not, $am_none].optype    = GOADDRESS(BErr)
	op86[$$neg, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$neg, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$neg, $am_ea].nbytes      = 1
	op86[$$neg, $am_ea].byte1       = 0xF7
	op86[$$neg, $am_ea].param       = 3
	op86[$$neg, $am_ea].optype      = GOADDRESS(BRegop)
	op86[$$neg, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$neg, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$neg, $am_none].optype    = GOADDRESS(BErr)
	op86[$$movsx, $am_regea].nbytes = 2
	op86[$$movsx, $am_regea].byte1  = 0x0F
	op86[$$movsx, $am_regea].byte2  = 0xBF
	op86[$$movsx, $am_regea].optype = GOADDRESS(BMovx)
	op86[$$movsx, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$movsx, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$movsx, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$movsx, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$movsx, $am_none].optype  = GOADDRESS(BErr)
	op86[$$movzx, $am_regea].nbytes = 2
	op86[$$movzx, $am_regea].byte1  = 0x0F
	op86[$$movzx, $am_regea].byte2  = 0xB7
	op86[$$movzx, $am_regea].optype = GOADDRESS(BMovx)
	op86[$$movzx, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$movzx, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$movzx, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$movzx, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$movzx, $am_none].optype  = GOADDRESS(BErr)
	op86[$$movslq, $am_regea].nbytes = 1
	op86[$$movslq, $am_regea].byte1  = 0x63
	op86[$$movslq, $am_regea].optype = GOADDRESS(BMovx)
	op86[$$movslq, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$movslq, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$movslq, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$movslq, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$movslq, $am_none].optype  = GOADDRESS(BErr)
	op86[$$fstsw, $am_regea].optype = GOADDRESS(BErr)
	op86[$$fstsw, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$fstsw, $am_ea].nbytes    = 2
	op86[$$fstsw, $am_ea].byte1     = 0xDF
	op86[$$fstsw, $am_ea].byte2     = 0xE0
	op86[$$fstsw, $am_ea].optype    = GOADDRESS(BFstsw)
	op86[$$fstsw, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$fstsw, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$fstsw, $am_none].optype  = GOADDRESS(BErr)
	op86[$$fnstsw, $am_regea].optype = GOADDRESS(BErr)     '*cw* 220701+
	op86[$$fnstsw, $am_eareg].optype = GOADDRESS(BErr)     '*cw* 220701+
	op86[$$fnstsw, $am_ea].nbytes    = 2                   '*cw* 220701+
	op86[$$fnstsw, $am_ea].byte1     = 0xDF                '*cw* 220701+
	op86[$$fnstsw, $am_ea].byte2     = 0xE0                '*cw* 220701+
	op86[$$fnstsw, $am_ea].optype    = GOADDRESS(BFnstsw)  '*cw* 220701+
	op86[$$fnstsw, $am_eaimm].optype = GOADDRESS(BErr)     '*cw* 220701+
	op86[$$fnstsw, $am_rel].optype   = GOADDRESS(BErr)     '*cw* 220701+
	op86[$$fnstsw, $am_none].optype  = GOADDRESS(BErr)     '*cw* 220701+
	op86[$$fld, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fld, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fld, $am_ea].optype      = GOADDRESS(BFld)
	op86[$$fld, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fld, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fld, $am_none].optype    = GOADDRESS(BErr)
	op86[$$fild, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$fild, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$fild, $am_ea].optype     = GOADDRESS(BFild)
	op86[$$fild, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$fild, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$fild, $am_none].optype   = GOADDRESS(BErr)
	op86[$$fst, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fst, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fst, $am_ea].optype      = GOADDRESS(BFst)
	op86[$$fst, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fst, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fst, $am_none].optype    = GOADDRESS(BErr)
	op86[$$fist, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$fist, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$fist, $am_ea].optype     = GOADDRESS(BFist)
	op86[$$fist, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$fist, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$fist, $am_none].optype   = GOADDRESS(BErr)
	op86[$$fstp, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$fstp, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$fstp, $am_ea].optype     = GOADDRESS(BFstp)
	op86[$$fstp, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$fstp, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$fstp, $am_none].optype   = GOADDRESS(BErr)
	op86[$$fistp, $am_regea].optype = GOADDRESS(BErr)
	op86[$$fistp, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$fistp, $am_ea].optype    = GOADDRESS(BFistp)
	op86[$$fistp, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$fistp, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$fistp, $am_none].optype  = GOADDRESS(BErr)
	op86[$$push, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$push, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$push, $am_ea].nbytes     = 1
	op86[$$push, $am_ea].byte1      = 0xFF
	op86[$$push, $am_ea].param      = 6
	op86[$$push, $am_ea].optype     = GOADDRESS(BWord)
	op86[$$push, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$push, $am_rel].nbytes    = 1
	op86[$$push, $am_rel].byte1     = 0x68
	op86[$$push, $am_rel].optype    = GOADDRESS(BImm)
	op86[$$push, $am_none].optype   = GOADDRESS(BErr)
	op86[$$pop, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$pop, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$pop, $am_ea].nbytes      = 1
	op86[$$pop, $am_ea].byte1       = 0x8F
	op86[$$pop, $am_ea].optype      = GOADDRESS(BWord)
	op86[$$pop, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$pop, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$pop, $am_none].optype    = GOADDRESS(BErr)
	op86[$$inc, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$inc, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$inc, $am_ea].nbytes      = 1
	op86[$$inc, $am_ea].byte1       = 0xFF
	op86[$$inc, $am_ea].optype      = GOADDRESS(BRegop)
	op86[$$inc, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$inc, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$inc, $am_none].optype    = GOADDRESS(BErr)
	op86[$$dec, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$dec, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$dec, $am_ea].nbytes      = 1
	op86[$$dec, $am_ea].byte1       = 0xFF
	op86[$$dec, $am_ea].param       = 1
	op86[$$dec, $am_ea].optype      = GOADDRESS(BRegop)
	op86[$$dec, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$dec, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$dec, $am_none].optype    = GOADDRESS(BErr)
	op86[$$xchg, $am_regea].nbytes  = 1
	op86[$$xchg, $am_regea].byte1   = 0x87
	op86[$$xchg, $am_regea].optype  = GOADDRESS(BNorm)
	op86[$$xchg, $am_eareg].nbytes  = 1
	op86[$$xchg, $am_eareg].byte1   = 0x87
	op86[$$xchg, $am_eareg].optype  = GOADDRESS(BNorm)
	op86[$$xchg, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$xchg, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$xchg, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$xchg, $am_none].optype   = GOADDRESS(BErr)
	op86[$$lea, $am_regea].nbytes   = 1
	op86[$$lea, $am_regea].byte1    = 0x8D
	op86[$$lea, $am_regea].optype   = GOADDRESS(BLea)
	op86[$$lea, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$lea, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$lea, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$lea, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$lea, $am_none].optype    = GOADDRESS(BErr)
	op86[$$jmp, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$jmp, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$jmp, $am_ea].nbytes      = 1
	op86[$$jmp, $am_ea].byte1       = 0xFF
	op86[$$jmp, $am_ea].param       = 4
	op86[$$jmp, $am_ea].optype      = GOADDRESS(BRegop)
	op86[$$jmp, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$jmp, $am_rel].nbytes     = 1
	op86[$$jmp, $am_rel].byte1      = 0xE9
	op86[$$jmp, $am_rel].optype     = GOADDRESS(BRel)
	op86[$$jmp, $am_none].optype    = GOADDRESS(BErr)
	op86[$$call, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$call, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$call, $am_ea].nbytes     = 1
	op86[$$call, $am_ea].byte1      = 0xFF
	op86[$$call, $am_ea].param      = 2
	op86[$$call, $am_ea].optype     = GOADDRESS(BRegop)
	op86[$$call, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$call, $am_rel].nbytes    = 1
	op86[$$call, $am_rel].byte1     = 0xE8
	op86[$$call, $am_rel].optype    = GOADDRESS(BRel)
	op86[$$call, $am_none].optype   = GOADDRESS(BErr)
	op86[$$rol, $am_regea].nbytes   = 1
	op86[$$rol, $am_regea].byte1    = 0xD3
	op86[$$rol, $am_regea].optype   = GOADDRESS(BTwid)
	op86[$$rol, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$rol, $am_ea].nbytes      = 1
	op86[$$rol, $am_ea].byte1       = 0xD3
	op86[$$rol, $am_ea].optype      = GOADDRESS(BTwid)
	op86[$$rol, $am_eaimm].nbytes   = 1
	op86[$$rol, $am_eaimm].byte1    = 0xC1
	op86[$$rol, $am_eaimm].optype   = GOADDRESS(BTwid)
	op86[$$rol, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$rol, $am_none].optype    = GOADDRESS(BErr)
	op86[$$ror, $am_regea].nbytes   = 1
	op86[$$ror, $am_regea].byte1    = 0xD3
	op86[$$ror, $am_regea].param    = 1
	op86[$$ror, $am_regea].optype   = GOADDRESS(BTwid)
	op86[$$ror, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$ror, $am_ea].nbytes      = 1
	op86[$$ror, $am_ea].byte1       = 0xD3
	op86[$$ror, $am_ea].param       = 1
	op86[$$ror, $am_ea].optype      = GOADDRESS(BTwid)
	op86[$$ror, $am_eaimm].nbytes   = 1
	op86[$$ror, $am_eaimm].byte1    = 0xC1
	op86[$$ror, $am_eaimm].param    = 1
	op86[$$ror, $am_eaimm].optype   = GOADDRESS(BTwid)
	op86[$$ror, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$ror, $am_none].optype    = GOADDRESS(BErr)
	op86[$$rcl, $am_regea].nbytes   = 1
	op86[$$rcl, $am_regea].byte1    = 0xD3
	op86[$$rcl, $am_regea].param    = 2
	op86[$$rcl, $am_regea].optype   = GOADDRESS(BTwid)
	op86[$$rcl, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$rcl, $am_ea].nbytes      = 1
	op86[$$rcl, $am_ea].byte1       = 0xD3
	op86[$$rcl, $am_ea].param       = 2
	op86[$$rcl, $am_ea].optype      = GOADDRESS(BTwid)
	op86[$$rcl, $am_eaimm].nbytes   = 1
	op86[$$rcl, $am_eaimm].byte1    = 0xC1
	op86[$$rcl, $am_eaimm].param    = 2
	op86[$$rcl, $am_eaimm].optype   = GOADDRESS(BTwid)
	op86[$$rcl, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$rcl, $am_none].optype    = GOADDRESS(BErr)
	op86[$$rcr, $am_regea].nbytes   = 1
	op86[$$rcr, $am_regea].byte1    = 0xD3
	op86[$$rcr, $am_regea].param    = 3
	op86[$$rcr, $am_regea].optype   = GOADDRESS(BTwid)
	op86[$$rcr, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$rcr, $am_ea].nbytes      = 1
	op86[$$rcr, $am_ea].byte1       = 0xD3
	op86[$$rcr, $am_ea].param       = 3
	op86[$$rcr, $am_ea].optype      = GOADDRESS(BTwid)
	op86[$$rcr, $am_eaimm].nbytes   = 1
	op86[$$rcr, $am_eaimm].byte1    = 0xC1
	op86[$$rcr, $am_eaimm].param    = 3
	op86[$$rcr, $am_eaimm].optype   = GOADDRESS(BTwid)
	op86[$$rcr, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$rcr, $am_none].optype    = GOADDRESS(BErr)
	op86[$$sll, $am_regea].nbytes   = 1
	op86[$$sll, $am_regea].byte1    = 0xD3
	op86[$$sll, $am_regea].param    = 4
	op86[$$sll, $am_regea].optype   = GOADDRESS(BTwid)
	op86[$$sll, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$sll, $am_ea].nbytes      = 1
	op86[$$sll, $am_ea].byte1       = 0xD3
	op86[$$sll, $am_ea].param       = 4
	op86[$$sll, $am_ea].optype      = GOADDRESS(BTwid)
	op86[$$sll, $am_eaimm].nbytes   = 1
	op86[$$sll, $am_eaimm].byte1    = 0xC1
	op86[$$sll, $am_eaimm].param    = 4
	op86[$$sll, $am_eaimm].optype   = GOADDRESS(BTwid)
	op86[$$sll, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$sll, $am_none].optype    = GOADDRESS(BErr)
	op86[$$slr, $am_regea].nbytes   = 1
	op86[$$slr, $am_regea].byte1    = 0xD3
	op86[$$slr, $am_regea].param    = 5
	op86[$$slr, $am_regea].optype   = GOADDRESS(BTwid)
	op86[$$slr, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$slr, $am_ea].nbytes      = 1
	op86[$$slr, $am_ea].byte1       = 0xD3
	op86[$$slr, $am_ea].param       = 5
	op86[$$slr, $am_ea].optype      = GOADDRESS(BTwid)
	op86[$$slr, $am_eaimm].nbytes   = 1
	op86[$$slr, $am_eaimm].byte1    = 0xC1
	op86[$$slr, $am_eaimm].param    = 5
	op86[$$slr, $am_eaimm].optype   = GOADDRESS(BTwid)
	op86[$$slr, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$slr, $am_none].optype    = GOADDRESS(BErr)
	op86[$$sar, $am_regea].nbytes   = 1
	op86[$$sar, $am_regea].byte1    = 0xD3
	op86[$$sar, $am_regea].param    = 7
	op86[$$sar, $am_regea].optype   = GOADDRESS(BTwid)
	op86[$$sar, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$sar, $am_ea].nbytes      = 1
	op86[$$sar, $am_ea].byte1       = 0xD3
	op86[$$sar, $am_ea].param       = 7
	op86[$$sar, $am_ea].optype      = GOADDRESS(BTwid)
	op86[$$sar, $am_eaimm].nbytes   = 1
	op86[$$sar, $am_eaimm].byte1    = 0xC1
	op86[$$sar, $am_eaimm].param    = 7
	op86[$$sar, $am_eaimm].optype   = GOADDRESS(BTwid)
	op86[$$sar, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$sar, $am_none].optype    = GOADDRESS(BErr)
	op86[$$rep, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$rep, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$rep, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$rep, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$rep, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$rep, $am_none].nbytes    = 1
	op86[$$rep, $am_none].byte1     = 0xF3
	op86[$$rep, $am_none].optype    = GOADDRESS(BNone)
	op86[$$repz, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$repz, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$repz, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$repz, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$repz, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$repz, $am_none].nbytes   = 1
	op86[$$repz, $am_none].byte1    = 0xF3
	op86[$$repz, $am_none].optype   = GOADDRESS(BNone)
	op86[$$repnz, $am_regea].optype = GOADDRESS(BErr)
	op86[$$repnz, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$repnz, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$repnz, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$repnz, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$repnz, $am_none].nbytes  = 1
	op86[$$repnz, $am_none].byte1   = 0xF2
	op86[$$repnz, $am_none].optype  = GOADDRESS(BNone)
	op86[$$stosb, $am_regea].optype = GOADDRESS(BErr)
	op86[$$stosb, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$stosb, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$stosb, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$stosb, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$stosb, $am_none].nbytes  = 1
	op86[$$stosb, $am_none].byte1   = 0xAA
	op86[$$stosb, $am_none].optype  = GOADDRESS(BNone)
	op86[$$stosw, $am_regea].optype = GOADDRESS(BErr)
	op86[$$stosw, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$stosw, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$stosw, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$stosw, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$stosw, $am_none].nbytes  = 2
	op86[$$stosw, $am_none].byte1   = 0x66
	op86[$$stosw, $am_none].byte2   = 0xAB
	op86[$$stosw, $am_none].optype  = GOADDRESS(BNone)
	op86[$$stosd, $am_regea].optype = GOADDRESS(BErr)
	op86[$$stosd, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$stosd, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$stosd, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$stosd, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$stosd, $am_none].nbytes  = 1
	op86[$$stosd, $am_none].byte1   = 0xAB
	op86[$$stosd, $am_none].optype  = GOADDRESS(BNone)
	op86[$$sahf, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$sahf, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$sahf, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$sahf, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$sahf, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$sahf, $am_none].nbytes   = 1
	op86[$$sahf, $am_none].byte1    = 0x9E
	op86[$$sahf, $am_none].optype   = GOADDRESS(BNone)
	op86[$$cdq, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$cdq, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$cdq, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$cdq, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$cdq, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$cdq, $am_none].nbytes    = 1
	op86[$$cdq, $am_none].byte1     = 0x99
	op86[$$cdq, $am_none].optype    = GOADDRESS(BNone)
	op86[$$cld, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$cld, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$cld, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$cld, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$cld, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$cld, $am_none].nbytes    = 1
	op86[$$cld, $am_none].byte1     = 0xFC
	op86[$$cld, $am_none].optype    = GOADDRESS(BNone)
	op86[$$std, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$std, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$std, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$std, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$std, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$std, $am_none].nbytes    = 1
	op86[$$std, $am_none].byte1     = 0xFD
	op86[$$std, $am_none].optype    = GOADDRESS(BNone)
	op86[$$clc, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$clc, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$clc, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$clc, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$clc, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$clc, $am_none].nbytes    = 1
	op86[$$clc, $am_none].byte1     = 0xF8
	op86[$$clc, $am_none].optype    = GOADDRESS(BNone)
	op86[$$stc, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$stc, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$stc, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$stc, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$stc, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$stc, $am_none].nbytes    = 1
	op86[$$stc, $am_none].byte1     = 0xF9
	op86[$$stc, $am_none].optype    = GOADDRESS(BNone)
	op86[$$cmc, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$cmc, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$cmc, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$cmc, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$cmc, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$cmc, $am_none].nbytes    = 1
	op86[$$cmc, $am_none].byte1     = 0xF5
	op86[$$cmc, $am_none].optype    = GOADDRESS(BNone)
	op86[$$ret, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$ret, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$ret, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$ret, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$ret, $am_rel].optype     = GOADDRESS(BRetImm)
	op86[$$ret, $am_none].nbytes    = 1
	op86[$$ret, $am_none].byte1     = 0xC3
	op86[$$ret, $am_none].optype    = GOADDRESS(BNone)
	op86[$$into, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$into, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$into, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$into, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$into, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$into, $am_none].nbytes   = 1
	op86[$$into, $am_none].byte1    = 0xCE
	op86[$$into, $am_none].optype   = GOADDRESS(BNone)
	op86[$$int, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$int, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$int, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$int, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$int, $am_rel].optype     = GOADDRESS(BInt)
	op86[$$int, $am_none].optype    = GOADDRESS(BErr)
	op86[$$fcompp, $am_regea].optype = GOADDRESS(BErr)
	op86[$$fcompp, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$fcompp, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$fcompp, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$fcompp, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$fcompp, $am_none].nbytes  = 2
	op86[$$fcompp, $am_none].byte1   = 0xDE
	op86[$$fcompp, $am_none].byte2   = 0xD9
'	op86[$$fcompp, $am_none].optype  = GOADDRESS(BNone)        '*cw* 220704-
	op86[$$fcompp, $am_none].optype  = GOADDRESS(BNoneNoRexW)  '*cw* 220704+
	op86[$$fchs, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fchs, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fchs, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fchs, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fchs, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fchs, $am_none].nbytes    = 2
	op86[$$fchs, $am_none].byte1     = 0xD9
	op86[$$fchs, $am_none].byte2     = 0xE0
	op86[$$fchs, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fabs, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fabs, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fabs, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fabs, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fabs, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fabs, $am_none].nbytes    = 2
	op86[$$fabs, $am_none].byte1     = 0xD9
	op86[$$fabs, $am_none].byte2     = 0xE1
	op86[$$fabs, $am_none].optype    = GOADDRESS(BNone)
	op86[$$ftst, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$ftst, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$ftst, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$ftst, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$ftst, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$ftst, $am_none].nbytes    = 2
	op86[$$ftst, $am_none].byte1     = 0xD9
	op86[$$ftst, $am_none].byte2     = 0xE4
	op86[$$ftst, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fxam, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fxam, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fxam, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fxam, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fxam, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fxam, $am_none].nbytes    = 2
	op86[$$fxam, $am_none].byte1     = 0xD9
	op86[$$fxam, $am_none].byte2     = 0xE5
	op86[$$fxam, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fld1, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fld1, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fld1, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fld1, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fld1, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fld1, $am_none].nbytes    = 2
	op86[$$fld1, $am_none].byte1     = 0xD9
	op86[$$fld1, $am_none].byte2     = 0xE8
	op86[$$fld1, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fldpi, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$fldpi, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$fldpi, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$fldpi, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$fldpi, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$fldpi, $am_none].nbytes   = 2
	op86[$$fldpi, $am_none].byte1    = 0xD9
	op86[$$fldpi, $am_none].byte2    = 0xEB
	op86[$$fldpi, $am_none].optype   = GOADDRESS(BNone)
	op86[$$fldz, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fldz, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fldz, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fldz, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fldz, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fldz, $am_none].nbytes    = 2
	op86[$$fldz, $am_none].byte1     = 0xD9
	op86[$$fldz, $am_none].byte2     = 0xEE
	op86[$$fldz, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fadd, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fadd, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fadd, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fadd, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fadd, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fadd, $am_none].nbytes    = 2
	op86[$$fadd, $am_none].byte1     = 0xDE
	op86[$$fadd, $am_none].byte2     = 0xC1
	op86[$$fadd, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fmul, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fmul, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fmul, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fmul, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fmul, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fmul, $am_none].nbytes    = 2
	op86[$$fmul, $am_none].byte1     = 0xDE
	op86[$$fmul, $am_none].byte2     = 0xC9
	op86[$$fmul, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fsub, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fsub, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fsub, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fsub, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fsub, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fsub, $am_none].nbytes    = 2
	op86[$$fsub, $am_none].byte1     = 0xDE
	op86[$$fsub, $am_none].byte2     = 0xE9
	op86[$$fsub, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fsubr, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$fsubr, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$fsubr, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$fsubr, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$fsubr, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$fsubr, $am_none].nbytes   = 2
	op86[$$fsubr, $am_none].byte1    = 0xDE
	op86[$$fsubr, $am_none].byte2    = 0xE1
	op86[$$fsubr, $am_none].optype   = GOADDRESS(BNone)
	op86[$$fdiv, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fdiv, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fdiv, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fdiv, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fdiv, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fdiv, $am_none].nbytes    = 2
	op86[$$fdiv, $am_none].byte1     = 0xDE
	op86[$$fdiv, $am_none].byte2     = 0xF9
	op86[$$fdiv, $am_none].optype    = GOADDRESS(BNone)
	op86[$$fdivr, $am_regea].optype  = GOADDRESS(BErr)
	op86[$$fdivr, $am_eareg].optype  = GOADDRESS(BErr)
	op86[$$fdivr, $am_ea].optype     = GOADDRESS(BErr)
	op86[$$fdivr, $am_eaimm].optype  = GOADDRESS(BErr)
	op86[$$fdivr, $am_rel].optype    = GOADDRESS(BErr)
	op86[$$fdivr, $am_none].nbytes   = 2
	op86[$$fdivr, $am_none].byte1    = 0xDE
	op86[$$fdivr, $am_none].byte2    = 0xF1
	op86[$$fdivr, $am_none].optype   = GOADDRESS(BNone)
	op86[$$fxch, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$fxch, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$fxch, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$fxch, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$fxch, $am_rel].optype     = GOADDRESS(BErr)
	op86[$$fxch, $am_none].nbytes    = 2
	op86[$$fxch, $am_none].byte1     = 0xD9
	op86[$$fxch, $am_none].byte2     = 0xC9
	op86[$$fxch, $am_none].optype    = GOADDRESS(BNone)
	op86[$$ja, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$ja, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$ja, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$ja, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$ja, $am_rel].nbytes       = 2
	op86[$$ja, $am_rel].byte1        = 0x0F
	op86[$$ja, $am_rel].byte2        = 0x87
	op86[$$ja, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$ja, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jae, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jae, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jae, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jae, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jae, $am_rel].nbytes      = 2
	op86[$$jae, $am_rel].byte1       = 0x0F
	op86[$$jae, $am_rel].byte2       = 0x83
	op86[$$jae, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jae, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jb, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$jb, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$jb, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$jb, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$jb, $am_rel].nbytes       = 2
	op86[$$jb, $am_rel].byte1        = 0x0F
	op86[$$jb, $am_rel].byte2        = 0x82
	op86[$$jb, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$jb, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jbe, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jbe, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jbe, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jbe, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jbe, $am_rel].nbytes      = 2
	op86[$$jbe, $am_rel].byte1       = 0x0F
	op86[$$jbe, $am_rel].byte2       = 0x86
	op86[$$jbe, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jbe, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jc, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$jc, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$jc, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$jc, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$jc, $am_rel].nbytes       = 2
	op86[$$jc, $am_rel].byte1        = 0x0F
	op86[$$jc, $am_rel].byte2        = 0x82
	op86[$$jc, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$jc, $am_none].optype      = GOADDRESS(BErr)
	op86[$$je, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$je, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$je, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$je, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$je, $am_rel].nbytes       = 2
	op86[$$je, $am_rel].byte1        = 0x0F
	op86[$$je, $am_rel].byte2        = 0x84
	op86[$$je, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$je, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jg, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$jg, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$jg, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$jg, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$jg, $am_rel].nbytes       = 2
	op86[$$jg, $am_rel].byte1        = 0x0F
	op86[$$jg, $am_rel].byte2        = 0x8F
	op86[$$jg, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$jg, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jge, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jge, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jge, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jge, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jge, $am_rel].nbytes      = 2
	op86[$$jge, $am_rel].byte1       = 0x0F
	op86[$$jge, $am_rel].byte2       = 0x8D
	op86[$$jge, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jge, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jl, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$jl, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$jl, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$jl, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$jl, $am_rel].nbytes       = 2
	op86[$$jl, $am_rel].byte1        = 0x0F
	op86[$$jl, $am_rel].byte2        = 0x8C
	op86[$$jl, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$jl, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jle, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jle, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jle, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jle, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jle, $am_rel].nbytes      = 2
	op86[$$jle, $am_rel].byte1       = 0x0F
	op86[$$jle, $am_rel].byte2       = 0x8E
	op86[$$jle, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jle, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jna, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jna, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jna, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jna, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jna, $am_rel].nbytes      = 2
	op86[$$jna, $am_rel].byte1       = 0x0F
	op86[$$jna, $am_rel].byte2       = 0x86
	op86[$$jna, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jna, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jnae, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$jnae, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$jnae, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$jnae, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$jnae, $am_rel].nbytes     = 2
	op86[$$jnae, $am_rel].byte1      = 0x0F
	op86[$$jnae, $am_rel].byte2      = 0x82
	op86[$$jnae, $am_rel].optype     = GOADDRESS(BRel)
	op86[$$jnae, $am_none].optype    = GOADDRESS(BErr)
	op86[$$jnb, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jnb, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jnb, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jnb, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jnb, $am_rel].nbytes      = 2
	op86[$$jnb, $am_rel].byte1       = 0x0F
	op86[$$jnb, $am_rel].byte2       = 0x83
	op86[$$jnb, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jnb, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jnbe, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$jnbe, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$jnbe, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$jnbe, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$jnbe, $am_rel].nbytes     = 2
	op86[$$jnbe, $am_rel].byte1      = 0x0F
	op86[$$jnbe, $am_rel].byte2      = 0x87
	op86[$$jnbe, $am_rel].optype     = GOADDRESS(BRel)
	op86[$$jnbe, $am_none].optype    = GOADDRESS(BErr)
	op86[$$jnc, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jnc, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jnc, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jnc, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jnc, $am_rel].nbytes      = 2
	op86[$$jnc, $am_rel].byte1       = 0x0F
	op86[$$jnc, $am_rel].byte2       = 0x83
	op86[$$jnc, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jnc, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jne, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jne, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jne, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jne, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jne, $am_rel].nbytes      = 2
	op86[$$jne, $am_rel].byte1       = 0x0F
	op86[$$jne, $am_rel].byte2       = 0x85
	op86[$$jne, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jne, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jng, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jng, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jng, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jng, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jng, $am_rel].nbytes      = 2
	op86[$$jng, $am_rel].byte1       = 0x0F
	op86[$$jng, $am_rel].byte2       = 0x8E
	op86[$$jng, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jng, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jnge, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$jnge, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$jnge, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$jnge, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$jnge, $am_rel].nbytes     = 2
	op86[$$jnge, $am_rel].byte1      = 0x0F
	op86[$$jnge, $am_rel].byte2      = 0x8C
	op86[$$jnge, $am_rel].optype     = GOADDRESS(BRel)
	op86[$$jnge, $am_none].optype    = GOADDRESS(BErr)
	op86[$$jnl, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jnl, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jnl, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jnl, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jnl, $am_rel].nbytes      = 2
	op86[$$jnl, $am_rel].byte1       = 0x0F
	op86[$$jnl, $am_rel].byte2       = 0x8D
	op86[$$jnl, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jnl, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jnle, $am_regea].optype   = GOADDRESS(BErr)
	op86[$$jnle, $am_eareg].optype   = GOADDRESS(BErr)
	op86[$$jnle, $am_ea].optype      = GOADDRESS(BErr)
	op86[$$jnle, $am_eaimm].optype   = GOADDRESS(BErr)
	op86[$$jnle, $am_rel].nbytes     = 2
	op86[$$jnle, $am_rel].byte1      = 0x0F
	op86[$$jnle, $am_rel].byte2      = 0x8F
	op86[$$jnle, $am_rel].optype     = GOADDRESS(BRel)
	op86[$$jnle, $am_none].optype    = GOADDRESS(BErr)
	op86[$$jno, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jno, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jno, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jno, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jno, $am_rel].nbytes      = 2
	op86[$$jno, $am_rel].byte1       = 0x0F
	op86[$$jno, $am_rel].byte2       = 0x81
	op86[$$jno, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jno, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jnp, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jnp, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jnp, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jnp, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jnp, $am_rel].nbytes      = 2
	op86[$$jnp, $am_rel].byte1       = 0x0F
	op86[$$jnp, $am_rel].byte2       = 0x8B
	op86[$$jnp, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jnp, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jns, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jns, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jns, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jns, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jns, $am_rel].nbytes      = 2
	op86[$$jns, $am_rel].byte1       = 0x0F
	op86[$$jns, $am_rel].byte2       = 0x89
	op86[$$jns, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jns, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jnz, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jnz, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jnz, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jnz, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jnz, $am_rel].nbytes      = 2
	op86[$$jnz, $am_rel].byte1       = 0x0F
	op86[$$jnz, $am_rel].byte2       = 0x85
	op86[$$jnz, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jnz, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jo, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$jo, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$jo, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$jo, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$jo, $am_rel].nbytes       = 2
	op86[$$jo, $am_rel].byte1        = 0x0F
	op86[$$jo, $am_rel].byte2        = 0x80
	op86[$$jo, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$jo, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jp, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$jp, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$jp, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$jp, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$jp, $am_rel].nbytes       = 2
	op86[$$jp, $am_rel].byte1        = 0x0F
	op86[$$jp, $am_rel].byte2        = 0x8A
	op86[$$jp, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$jp, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jpe, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jpe, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jpe, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jpe, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jpe, $am_rel].nbytes      = 2
	op86[$$jpe, $am_rel].byte1       = 0x0F
	op86[$$jpe, $am_rel].byte2       = 0x8A
	op86[$$jpe, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jpe, $am_none].optype     = GOADDRESS(BErr)
	op86[$$jpo, $am_regea].optype    = GOADDRESS(BErr)
	op86[$$jpo, $am_eareg].optype    = GOADDRESS(BErr)
	op86[$$jpo, $am_ea].optype       = GOADDRESS(BErr)
	op86[$$jpo, $am_eaimm].optype    = GOADDRESS(BErr)
	op86[$$jpo, $am_rel].nbytes      = 2
	op86[$$jpo, $am_rel].byte1       = 0x0F
	op86[$$jpo, $am_rel].byte2       = 0x8B
	op86[$$jpo, $am_rel].optype      = GOADDRESS(BRel)
	op86[$$jpo, $am_none].optype     = GOADDRESS(BErr)
	op86[$$js, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$js, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$js, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$js, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$js, $am_rel].nbytes       = 2
	op86[$$js, $am_rel].byte1        = 0x0F
	op86[$$js, $am_rel].byte2        = 0x88
	op86[$$js, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$js, $am_none].optype      = GOADDRESS(BErr)
	op86[$$jz, $am_regea].optype     = GOADDRESS(BErr)
	op86[$$jz, $am_eareg].optype     = GOADDRESS(BErr)
	op86[$$jz, $am_ea].optype        = GOADDRESS(BErr)
	op86[$$jz, $am_eaimm].optype     = GOADDRESS(BErr)
	op86[$$jz, $am_rel].nbytes       = 2
	op86[$$jz, $am_rel].byte1        = 0x0F
	op86[$$jz, $am_rel].byte2        = 0x84
	op86[$$jz, $am_rel].optype       = GOADDRESS(BRel)
	op86[$$jz, $am_none].optype      = GOADDRESS(BErr)
'
	op86[$$stosq, $am_regea].optype = GOADDRESS(BErr)
	op86[$$stosq, $am_eareg].optype = GOADDRESS(BErr)
	op86[$$stosq, $am_ea].optype    = GOADDRESS(BErr)
	op86[$$stosq, $am_eaimm].optype = GOADDRESS(BErr)
	op86[$$stosq, $am_rel].optype   = GOADDRESS(BErr)
	op86[$$stosq, $am_none].nbytes  = 2
	op86[$$stosq, $am_none].byte1   = 0x48            'rexW
	op86[$$stosq, $am_none].byte2   = 0xAB
	op86[$$stosq, $am_none].optype  = GOADDRESS(BNone)
'
'	FOR cw1 = 0 TO $$zlast
'		FOR cw2 = 0 TO $am_max
'			PRINT cw1, cw2, "-", op86[cw1, cw2].nbytes,   ' number of bytes in opcode
'			PRINT HEX$(op86[cw1, cw2].byte1,2),    ' first byte
'			PRINT HEX$(op86[cw1, cw2].byte2,2),    ' second byte
'			PRINT HEX$(op86[cw1, cw2].param,2),    ' special (usually "reg" from mod-reg-rm) for assembling
'			PRINT HEX$(op86[cw1, cw2].optype)   ' address in Code() to assemble opcode of this type
'		NEXT cw2
'	NEXT cw1
'
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
'
' ############################
' #####  CodeAbs8Byte()  #####  emits a absolute value eight bytes 210813-+
' ############################
'
' If the opcode as a move and value is more than 32-bits,
' the opcode is modified from two byte (ie 0xC7C0) to one byte (0xB8)
' and the 64-bit value is added
' If not a move (or add sub etc), a 32-bit value as added.
'
FUNCTION  CodeAbs8Byte (immvalue)
	EXTERNAL /xxx/  xpc
'
	IF (UBYTEAT(xpc-2) = 0xC7) THEN  'move immediate 32 or 64 bits to register
		minlong = -2147483647
		maxlong = 2147483647
		IF ((immvalue > maxlong) OR (immvalue < minlong)) THEN  'immvalue more than 32 bits
			bite = UBYTEAT(xpc-1)
			IF (bite >= 0xC0) THEN
				bite = (bite AND 0x7) OR 0xB8
				UBYTEAT(xpc-2) = bite
			END IF
			DEC xpc
			XLONGAT(xpc) = immvalue     ' 64 bit move immediate
			xpc = xpc + 8
		ELSE
			ULONGAT(xpc) = immvalue     ' 32 bit move immediate
			xpc = xpc + 4
		END IF
	ELSE
		ULONGAT(xpc) = immvalue     ' 32 bit immediate
		xpc = xpc + 4
	END IF
'
END FUNCTION
'
'
'
' ############################
' #####  CodeLabelAbs()  #####  emits a absolute value of a label (eight bytes)
' ############################
'
'
FUNCTION  CodeLabelAbs (label$, offset)
	EXTERNAL /xxx/  xpc
	XLONG addr
'
	IF (UBYTEAT(xpc-2) = 0xC7) THEN
		bite = UBYTEAT(xpc-1)
		IF (bite >= 0xC0) THEN
			bite = (bite AND 0x7) OR 0xB8
			UBYTEAT(xpc-2) = bite
		END IF
		DEC xpc
	END IF
'
	addr = Value (label$, $$VALUEABS) + offset
	IF #cw THEN PRINT "CodeLabelAbs(23)", HEXX$(addr)
''	XLONGAT(xpc) = addr
''	xpc = xpc + 8
'	ULONGAT(xpc) = addr  '*cw* 230724-
	XLONGAT(xpc) = addr  '*cw* 230724+
'	xpc = xpc + 4
	xpc = xpc + 8

END FUNCTION
'
'
'
' #############################  emits a displacement to a label
' #####  CodeLabelDisp()  #####  relative to the byte after the
' #############################  four-byte displacement
'
FUNCTION  CodeLabelDisp (label$)
	EXTERNAL /xxx/  xpc
	XLONG addr
'
	addr = Value (label$, $$VALUEDISP)
	IF addr THEN addr = addr - (xpc + 4)
'	PRINT "CodeLabelDisp(13)", label$, HEXX$(addr), HEXX$(xpc)
	UBYTEAT(xpc) = addr AND 0xFF
	UBYTEAT(xpc, 1) = (addr AND 0xFF00) >> 8
	UBYTEAT(xpc, 2) = (addr AND 0xFF0000) >> 16
	UBYTEAT(xpc, 3) = (addr AND 0xFF000000) >> 24
	xpc = xpc + 4
END FUNCTION
'
'
' ########################
' #####  Compile ()  #####
' ########################
'
FUNCTION  Compile ()
	EXTERNAL /xxx/  i486bin,  i486asm,  xpc
	EXTERNAL /xxx/  checkBounds,  library,  errorCount
	TOKEN   tok[]
	SHARED  XERROR,  ERROR_TOO_LATE
	SHARED  pass0source,  pass0tokens,  pass1source,  pass1tokens
	SHARED  end_program,  got_declare
	SHARED  rawLength,  rawline$
	SHARED  toes,  toms,  a0,  a0_type,  a1,  a1_type,  oos
	SHARED  entryCheckBounds
	SHARED  UBYTE  oos[]
	SHARED  UBYTE  charsetPath[]
	SHARED  abort
	STATIC  xxpc
'
	abort = $$FALSE
'
	XstGetCommandLineArguments (@argc, @argv$[])
'
	IF (argc > 1) THEN
		FOR i = 1 TO argc - 1
			file$ = TRIM$(argv$[i])
			IFZ file$ THEN EXIT FOR
			IF (file${0} != '-') THEN EXIT FOR
			file$ = ""
		NEXT i
	END IF
'
'
'
' *****  if there's a <file$> then compile it
'
compileFile:
	IF file$ THEN
		IF (argc > 2) THEN
			IF (TRIM$(argv$[2]) == "-lib") THEN
				library = $$TRUE
			END IF
			IF ##WHOMASK THEN                         'xbdv
				IF ##XBDV THEN                          'xbdv
					IF (TRIM$(argv$[2]) == "-c") THEN     'xbdv
						checkBounds = $$TRUE                'xbdv
						entryCheckBounds = $$TRUE           'xbdv
					END IF                                'xbdv
				END IF                                  'xbdv
			END IF                                    'xbdv
		END IF
		CompileFile (@file$)
		RETURN
	END IF
'
'
' *****  compile user-typed input  *****
'
	PRINT "\n#####  .file  #####\n"
'
	DO
		DO
			rawline$ = TRIM$(INLINE$(""))
			rawLength = LEN(rawline$)
		LOOP UNTIL (rawLength)
'
		SELECT CASE rawLength
			CASE 1:     switch = rawline${0}
									GOSUB CompileSwitch
			CASE ELSE:  IF (rawline${0} = '.') THEN EXIT DO
									GOSUB CompileTypedLine
		END SELECT
		IF end_program THEN RETURN
	LOOP
'
'
' *****  ".filename"
'
compileDotFile:
	dash = INSTR(rawline$,"-")
	IF dash THEN
		switch$ = TRIM$(MID$(rawline$,dash+1))
		rawline$ = TRIM$(LEFT$(rawline$,dash-1))
		upper = UBOUND (switch$)
		FOR i = 0 TO upper
			s = switch${i}
			IF (((s >= 'A') AND (s <= 'Z')) OR ((s >= 'a') AND (s <= 'z'))) THEN
				switch = s
				GOSUB CompileSwitch
			END IF
		NEXT i
	END IF
	file$ = TRIM$(MID$(rawline$, 2))
	upper = UBOUND (file$)
	FOR i = 0 TO upper
		char = file${i}
		IFZ charsetPath[char] THEN EXIT FOR
	NEXT i
	IF (i <= upper) THEN file$ = LEFT$(file$, i)
	GOTO compileFile
'
'
'
' *****  Only one character was typed on the line
'
SUB CompileSwitch
	SELECT CASE switch
		CASE 'a': i486asm = $$TRUE: i486bin = $$FALSE: PRINT "i486asm"
		CASE 'b': xpc = ##UCODE
							IFZ xpc THEN
								PRINT "i486bin unavailable: ##UCODE = 0"
							ELSE
								PRINT "i486bin at ##UCODE = "; HEX$(##UCODE,8)
								i486bin = $$TRUE: i486asm = $$FALSE
							END IF
							xxpc = xpc
		CASE 'B': i486bin = $$TRUE: i486asm = $$FALSE
							xpc = ##DATAZ - 0x1000
							PRINT "i486bin at ##DATAZ - 0x1000: !!! VERY DANGEROUS !!!"
							xxpc = xpc
		CASE 'C': checkBounds = $$FALSE:  PRINT "bounds checking off"
							entryCheckBounds = $$FALSE
		CASE 'c': checkBounds = $$TRUE:   PRINT "bounds checking on"
							entryCheckBounds = $$TRUE
		CASE 'l': IF got_declare THEN XcowlErr (1800127): GOTO eeeTooLate
							library = $$TRUE:       PRINT "compile as function library"
		CASE 'L': IF got_declare THEN XcowlErr (1800129): GOTO eeeTooLate
							library = $$FALSE:      PRINT "compile as application"
		CASE 'q': RETURN ($$TRUE)
		CASE 'x': PRINT XxxDisassemble64$ (xxpc, xpc - xxpc)
		CASE 'S': pass0source = $$TRUE
		CASE 's': pass0source = $$FALSE
		CASE 'T': pass0tokens = $$TRUE
		CASE 't': pass0tokens = $$FALSE
		CASE 'U': pass1source = $$TRUE
		CASE 'u': pass1source = $$FALSE
		CASE 'V': pass1tokens = $$TRUE
		CASE 'v': pass1tokens = $$FALSE
		CASE '.': rawline$    = "DECLARE FUNCTION a (XLONG, XLONG)"
							rawLength   = LEN (rawline$)
							GOSUB CompileTypedLine
							rawline$    = "FUNCTION a (y, z)"
							rawLength   = LEN (rawline$)
							GOSUB CompileTypedLine
	END SELECT
END SUB
'
'
'
SUB CompileTypedLine
	xxpc = xpc
	ParseLine (@tok[])
	IF pass0source THEN PRINT Deparse$ ("")
	IF pass0tokens THEN PrintTokens ()
	#immediatemode = $$TRUE
	CheckOneLine()
	#immediatemode = $$FALSE
	IF XERROR THEN
		IF PrintError (XERROR) THEN EXIT FUNCTION
	END IF
	IF (toes OR toms OR a0 OR a0_type OR a1 OR a1_type OR oos OR oos[0]) THEN
		PRINT Deparse$ (">>> ")
		PRINT "exp stk error:  "; toes; toms; a0; a0_type; a1; a1_type; oos; oos[0]
		a0 = 0: a1 = 0: toes = 0: toms = 0: a0_type = 0: a1_type = 0: oos = 0: oos[0] = 0
	END IF
	PRINT
END SUB
'
eeeTooLate:
	XERROR = ERROR_TOO_LATE
	EXIT FUNCTION
END FUNCTION
'
'
' ############################
' #####  CompileFile ()  #####
' ############################
'
FUNCTION  CompileFile (file$)
	EXTERNAL /xxx/  i486asm,  i486bin,  library
	TOKEN   tok[], tokoid[]
	SHARED  TOKEN tokens[]
	SHARED  ofile,  rawline$,  rawLength, end_program
	SHARED  tokenCount,  lineNumber,  func_number
	SHARED  export
	SHARED  tokenPtr
	SHARED  programName$,  asmFile$
	SHARED  XERROR,  ERROR_COMPILER
'
	ofile = 0
	export = 0
	asmFile$ = ""
	##ERROR = $$FALSE
'
' find source file
'
	XstDecomposePathname (@file$, @path$, @parent$, @filename$, @programName$, @extent$)
	IF (extent$ != ".x") THEN filename$ = programName$ + ".x": extent$ = ".x"
	GetSubPath ("app", @programName$, @path$[])
	XstFindFile (@file$, @path$[], @xfile$, @attr)
	IF xfile$ THEN XxxSetProgramName (@xfile$)
'
' open source file
'
	fileNum = OPEN (xfile$, $$RD)
	IF (fileNum <= 0) THEN
		PRINT "error: can't open "; xfile$; ": "; ERROR$(##ERROR);;;; "terminating..."
		RETURN
	END IF
'
' read source file
'
	fileSize = LOF (fileNum)          ' fileSize = # of bytes in file$
	IFZ fileSize THEN RETURN          ' nothing in source file
	source$ = NULL$ (fileSize)        ' source$ = size of program
	READ [fileNum], source$           ' source$ = entire program
	CLOSE (fileNum)                   ' close source file
'
' Source program is in source$
' Now convert it to tokens
'
	upperLine = fileSize >> 3         ' 1/8 size of source$
	DIM tokoid[upperLine, ]           ' Create array for source$ program tokens
	sourceLine = 0
	off = 0
'
'	PRINT "\n#####  "; xfile$;
	PRINT "\n###  "; filename$,, path$
	IF library THEN PRINT "     -lib";
	PRINT "  #####"
' IF ##XBDV THEN PRINT "*****  PASS 0  *****"
'
	DO
		INC sourceLine
		IFZ (sourceLine AND 0x3F) THEN XgrProcessMessages (-2)
		rawline$ = XstNextLine$ (@source$, @off, @done)
		IF ##WHOMASK THEN                                                     '*cw* for testing only
			IF (sourceLine == #traceStart) THEN                                 '*cw* for testing only
'				##TRACE = #traceStart                                             '*cw* for testing only
				log = #traceStart                                                 '*cw* for testing only
				PRINT sourceLine, rawline$                                        '*cw* for testing only
'				STOP                                                              '*cw* for testing only
			ELSE                                                                '*cw* for testing only
				log = $$FALSE                                                     '*cw* for testing only
			END IF                                                              '*cw* for testing only
		END IF                                                                '*cw* for testing only
		rawLength = LEN (rawline$)
		ParseLine (@tok[])
		IF tok[] THEN
			u = UBOUND (tok[])
			tok[u] = #T_STARTS
			IFZ ##WHOMASK THEN                                                  '*cw* for testing only
				IF log THEN                                                       '*cw* for testing only
					FOR cw = 0 TO u                                                 '*cw* for testing only
						PRINT HEX$(tok[cw].tproto,8); "."; HEX$(tok[cw].tindex,8)     '*cw* for testing only
					NEXT cw                                                         '*cw* for testing only
				END IF                                                            '*cw* for testing only
			END IF                                                              '*cw* for testing only
			ATTACH tok[] TO tokoid[sourceLine, ]
		END IF
		IF (sourceLine >= upperLine) THEN
			upperLine = upperLine + (upperLine >> 2)
			REDIM tokoid[upperLine, ]
		END IF
	LOOP UNTIL done
	source$ = ""
	DEC sourceLine
' IF ##XBDV THEN PRINT "*****  PASS 1  *****"
'
' Create assembly language output file
'
	##ERROR = $$FALSE
	IF i486asm THEN
		XxxCreateCompileFiles ()
		IF (##ERROR OR (ofile <= 0)) THEN PRINT "CompileFile(): error: (Could not open .s file)": XcowlErr (1900103): GOTO eeeCompiler
	END IF
'
	func_number = 0
	FOR lineNumber = 1 TO sourceLine
		IFZ (lineNumber AND 0x3F) THEN XgrProcessMessages (-2)
		ATTACH tokoid[lineNumber, ] TO tok[]
		IFZ tok[] THEN XcowlErr (1900110): GOTO eeeCompiler
		tokenCount = tok[0].ti.ndex
		FOR i = 0 TO tokenCount
			tokens[i].tproto = tok[i].tproto
			tokens[i].tindex = tok[i].tindex
		NEXT i
		tokenPtr = 0
		holdCount = tokenCount
		ATTACH tok[] TO tokoid[lineNumber, ]
		CheckOneLine ()
		IF XERROR THEN
			IF PrintError (XERROR) THEN RETURN
		END IF
		IF end_program THEN RETURN
	NEXT lineNumber
'
' If program doesn't have an END PROGRAM then fake one (necessary)
'
	IFZ end_program THEN
		tokens[0].tproto  = $$TP_STARTS
		tokens[0].ti.ndex = 2
		tokens[1]         = #T_END
		tokens[2]         = #T_PROGRAM
		tokens[3].tproto  = $$TP_STARTS
		tokenCount  = 2
		CheckOneLine ()
	END IF
	IF (ofile > 2) THEN CLOSE (ofile)
	ofile = 0
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  Component ()  #####
' ##########################
'
' returns element address (not data)
'
' varToken  = composite variable token
'           = 0 once variable loaded into accumulator
' regBase   = the accumulator holding the current base pointer
' offset    = holds a compiler internal byte offset
'
FUNCTION  Component (command, TOKEN varToken, regBase, offset, theType, TOKEN token, length)
	TOKEN   subToken, old_op, new_data, oldToken
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc,  checkBounds
	SHARED  TOKEN typeEleToken[]
	SHARED  typeEleCount[],                   typeEleAddr[]
	SHARED  typeEleType[],  typeEleSize[]
	SHARED  typeElePtr[],  typeEleStringSize[],  typeEleUBound[]
	SHARED  typeSize[]
	SHARED  tab_sym$[],  r_addr[],  r_addr$[],  q_type_long[]
	SHARED  dim_array,  tokenPtr
	SHARED  toes,  a0,  a0_type,  a1,  a1_type,  labelNumber
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_COMPONENT,  ERROR_OVERFLOW
	SHARED  ERROR_SYNTAX,  ERROR_TYPE_MISMATCH
	SHARED  preType,  componentNumber
	SHARED UBYTE  shiftMulti[]
'
	inType  = theType
	preType = theType
	typeEleCount = typeEleCount[inType]
	found = $$FALSE
	i = 0
'
	DO WHILE (i < typeEleCount)
		subToken = typeEleToken[inType, i]
		IF TokenMatch (@subToken, @token) THEN
			componentNumber = i
			found = $$TRUE
			EXIT DO
		END IF
		INC i
	LOOP
	IFZ found THEN XcowlErr (200045): GOTO eeeComponent
'
	haveData = $$FALSE            ' OUTDATED...used with ptrs
	theType = typeEleType[inType, i]
	offset = offset + typeEleAddr[inType, i]          ' offset to this element
	ptrs = typeElePtr[inType, i]                      ' is this a pointer?
	lastElement = LastElement (token, @lastPlace, @excessComma)
	IF XERROR THEN EXIT FUNCTION
'
' Get the component length (.a[] gives the size of the entire 1D array)
'
	SELECT CASE TRUE
		CASE (token.tp.kind = $$KIND_ARRAY_SYMBOLS)
			oldTokenPtr = tokenPtr
			oldToken = token
			NextToken (@token)
			IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (200061): GOTO eeeComponent
			NextToken (@token)
			IF TokenMatch (@token, @#T_RBRAK) THEN
				IFF lastElement THEN XcowlErr (200064): GOTO eeeSyntax
				length = typeEleSize[inType, i]     ' Get length of entire array
				RETURN                              ' offset unchanged (point to [0])
			ELSE
				tokenPtr = oldTokenPtr
				token = oldToken
				IF (theType = $$STRING) THEN
					length = typeEleStringSize[inType, i]
				ELSE
					length = typeSize[theType]
				END IF
			END IF
		CASE ELSE
			IF (theType = $$STRING) THEN
				length = typeEleStringSize[inType, i]
			ELSE
				length = typeSize[theType]
			END IF
	END SELECT
'
	IFZ ptrs THEN
		IF lastElement THEN                     ' HANDLE valid only for pointers
			IF (command = $$GETHANDLE) THEN XcowlErr (200086): GOTO eeeSyntax
		END IF
	ELSE
'   IF (offset > 65535) THEN XcowlErr (200089): XcowlErr (190088): GOTO eeeOverflow
		IF lastElement THEN
			IF (command = $$GETHANDLE) THEN
				theType = $$XLONG
				tokenPtr = lastPlace                  ' point to end of last composite
				RETURN                                ' offset points to handle
			END IF
		END IF
'
		IF TokenMatch (@varToken, @#T_ZERO) THEN  ' base is in an accumulator already
			sreg = regBase
		ELSE
			regBase = OpenAccForType ($$XLONG)      ' open regBase accumulator
			nn = varToken.tindex
			sreg = r_addr[nn]
			IFZ sreg THEN                           ' data is in memory
				Move (regBase, $$XLONG, nn, $$XLONG)  ' move data into acc
				sreg = regBase
			END IF
			varToken = #T_ZERO
		END IF
'
'   BOUNDS CHECKING:  blow up if contents of sreg = 0
'     (Add when including pointers...)
'
		Code ($$ld, $$regro, regBase, sreg, offset, $$XLONG, "", $$rmk$+"402")
		offset = 0
'
'   BOUNDS CHECKING:  blow up if contents of regBase = 0
'     (Add when including pointers...)
'
		i = 2
		DO UNTIL (i > ptrs)
			Code ($$ld, $$regr0, regBase, regBase, 0, $$XLONG, "", $$rmk$+"403")
			INC i
		LOOP
	END IF
	IF (token.tp.kind != $$KIND_ARRAY_SYMBOLS) THEN RETURN  ' element not array
'
' Array:
'
	IF ptrs THEN                            ' points to std array
		IF dim_array THEN XcowlErr (2000131): GOTO eeeSyntax     ' Can't dim internal composite array
		new_data.tproto = $$TP_ARRAYS         ' Kludge up ARRAYS token
		new_data.tindex = regBase             ' Kludge up ARRAYS token
		IF lastElement THEN                   ' Tested above
			SELECT CASE command                 ' HANDLE returns above
				CASE $$GETADDR, $$GETDATAADDR
						old_op = #T_ADDR_OP
						old_prec = $$PREC_ADDR_OP
				CASE ELSE
						old_op = #T_ZERO
						old_prec = 0
'                                         ' haveData outdated...ptrs only
						haveData = $$TRUE             ' ExpressArray returns data
			END SELECT
		ELSE
			IF excessComma THEN XcowlErr (2000146): GOTO eeeSyntax
			old_op = #T_ZERO
			old_prec = 0
		END IF
		accArray = 'v'
		ExpressArray (old_op, old_prec, @new_data, @new_type, accArray, 0, theType, 0)
		IF XERROR THEN EXIT FUNCTION
		IF lastElement THEN
			IF (command = $$GETDATAADDR) THEN           ' returns composite type
				IF excessComma THEN theType = new_type    '   unless excessComma
			ELSE
				theType = new_type
			END IF
		ELSE
			IF (new_type < $$SCOMPLEX) THEN XcowlErr (2000160): GOTO eeeSyntax
		END IF
		regBase = Top ()                              ' new regBase is toes
		IFF TokenMatch (@new_data, @#T_ZERO) THEN     ' null array
			IF (new_data.tindex != regBase) THEN XcowlErr (2000164): GOTO eeeCompiler
		END IF
		RETURN
	END IF
'
' imbedded array
'
	IF (theType = $$STRING) THEN
		aSize = typeEleStringSize[inType, i]
	ELSE
		aSize = typeSize[theType]       ' size of element in array (aligned)
	END IF
' IF (aSize > 65535) THEN XcowlErr (2000176): GOTO eeeOverflow
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (2000178): GOTO eeeComponent
	arrayUBound = typeEleUBound[inType, i]
'
' fixedArray [expression]
'
	token = #T_ZERO
	new_data = #T_ZERO
	new_type = 0
	Expresso (0, @token, 0, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	IFF q_type_long[new_type] THEN XcowlErr (2000188): GOTO eeeTypeMismatch
	IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (2000189): GOTO eeeComponent
	IFF TokenMatch (@new_data, @#T_ZERO) THEN  ' simple token (regBase same)
		GOSUB CheckForLiteral
		IF gotLiteral THEN RETURN
		nn = new_data.tindex
		regTemp = r_addr[nn]
		IF regTemp THEN                       ' value is in a register
			regIndex = regTemp
			regOffset = $$rsi
		ELSE                                  ' value in memory
			Move ($$rsi, $$XLONG, nn, $$XLONG)
			regIndex = $$rsi
			regOffset = regIndex
		END IF
	ELSE
		IFF TokenMatch (@varToken, @#T_ZERO) THEN    ' base not in acc yet
			regIndex = Top ()                     ' expression in acc
		ELSE
			IF (toes <= 1) THEN XcowlErr (2000207): GOTO eeeSyntax   ' expression and base in acc
			Topaccs (@regIndex, @regBase)
		END IF
		regOffset = regIndex
	END IF
'
	IF TokenMatch (@varToken, @#T_ZERO) THEN  ' base is in an accumulator already
		sreg = regBase
	ELSE
		regBase = OpenAccForType ($$XLONG)    ' open regBase accumulator
		nn = varToken.tindex
		regTemp = r_addr[nn]
		IF regTemp THEN                           ' data is in a register
			sreg = regTemp
		ELSE
			Move (regBase, $$XLONG, nn, $$XLONG)  ' move data into acc
			sreg = regBase
		END IF
		varToken = #T_ZERO
	END IF
'
	IFF TokenMatch (@new_data, @#T_ZERO) THEN  ' simple, no expression on stack
		newRegBase = regBase        ' use old regBase
	ELSE                          ' remove expression from stack
'		newRegBase = $$eax          ' combine TOS + TOS-1 into r10       '*cw* 230214-
		newRegBase = $$rax          ' combine TOS + TOS-1 into r10       '*cw* 230214+
		DEC toes                    ' Free r12
		a1 = 0
		a1_type = 0
		a0 = toes
		a0_type = $$XLONG
	END IF
'
' Bounds Check
'
	IF checkBounds THEN
		INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
		Code ($$mov, $$regimm, $$rcx, arrayUBound, 0, $$XLONG, "", $$rmk$+"404")
		Code ($$cmp, $$regreg, $$rcx, regIndex, 0, $$XLONG, "", $$rmk$+"405")
		Code ($$jge, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"406")
		Code ($$mov, $$regreg, $$rcx, sreg, 0, $$XLONG, "", $$rmk$+"407")
		Code ($$xor, $$regreg, regIndex, regIndex, 0, $$XLONG, "", $$rmk$+"408")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_OutOfBounds", $$rmk$+"409")
		EmitLabel (@d1$)
	END IF
'
	IF (aSize = 1) THEN
		regOffset = regIndex                    ' skipit:  multiplier is 1
	ELSE
		IF (regOffset != regIndex) THEN
			Code ($$mov, $$regreg, regOffset, regIndex, 0, $$XLONG, "", $$rmk$+"410")
		END IF
		IF (aSize <= 1024) THEN ashift = shiftMulti[aSize]
		IF ashift THEN
			Code ($$sll, $$regimm, regOffset, ashift, 0, $$XLONG, "", $$rmk$+"411")
		ELSE
			Code ($$imul, $$regimm, regOffset, aSize, 0, $$XLONG, "", $$rmk$+"412")
		END IF
	END IF
'
	Code ($$lea, $$regrr, newRegBase, sreg, regOffset, $$XLONG, "", $$rmk$+"413")
	regBase = newRegBase      ' updated base pointer
	RETURN
'
SUB CheckForLiteral
	gotLiteral = $$FALSE
	SELECT CASE new_data.tp.kind
		CASE $$KIND_LITERALS
			tt = new_data.tindex
			arrayIndex = XLONG (tab_sym$[tt])   ' literals may not be in r_addr yet
			IF (arrayIndex > arrayUBound) THEN
				XcowlErr (2000277): GOTO eeeOverflow
			END IF
			offset = offset + arrayIndex * aSize
			gotLiteral = $$TRUE
		CASE $$KIND_CONSTANTS, $$KIND_SYSCONS
			tt = new_data.tindex
			arrayIndex = XLONG (r_addr$[tt])
			IF (arrayIndex > arrayUBound) THEN
				XcowlErr (2000285): GOTO eeeOverflow
			END IF
			offset = offset + arrayIndex * aSize
			gotLiteral = $$TRUE
	END SELECT
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeComponent:
	XERROR = ERROR_COMPONENT
	EXIT FUNCTION
'
eeeOverflow:
	XERROR = ERROR_OVERFLOW
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  Composite ()  #####
' ##########################
'
' *****  INPUT  *****       *****  RETURN VALUES  *****
'
' command = $$GETADDR:      command   = # of items stacked  (in RAx)
'                           theType   = XLONG
'                           theReg    = token or reg containing base address
'                           theOffset = offset from base address to data
' command = $$GETHANDLE:    command   = # of items stacked  (in RAx)
'                           theType   = XLONG
'                           theReg    = token or reg containing base addr
'                           theOffset = offset from base address to array handle
' command = $$GETDATAADDR:  command   = # of items stacked  (in RAx)
'                           theType   = type of final component
'                           theReg    = token or reg containing base addr
'                           theOffset = offset from base address to data
' command = $$GETDATA:      command   = # of items stacked  (in RAx)
'                           theType   = type of final component
'                           theReg    = reg containing data (addr if composite)
'                           theOffset = 0
'
' Notes:
'   subComposite == a composite expression including sub-element references
'   varComposite == a composite variable/array without sub-element references
'
'   Destination:  GETADDR invalid for varComposites/subComposites
'                 GETHANDLE invalid for varComposites
'                 GETHANDLE valid only for pointer sub-elements (to allow
'                     assigning address to pointer)
'   Source:       (Composite() not called for source addr_ops on varComposites)
'                 GETADDR valid for subComposites
'                 GETHANDLE valid for pointer sub-elements in subComposites
'
'   NOTE:  error generated if theOffset > 65535
'
FUNCTION  Composite (command, theType, TOKEN theReg, theOffset, theLength)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   check, new_data, new_op, varToken
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  ERROR_OVERFLOW,  ERROR_SYNTAX
	SHARED  r_addr[],  typeSize[]
	SHARED  a0_type, a1_type
	SHARED  oos,  dim_array
	SHARED  preType
	SHARED UBYTE oos[]
'
	theLength   = 0
	IFF TokenMatch (@theReg, @#T_ZERO) THEN
		varToken  = theReg
		theType   = TheType (theReg)
		inType    = theType
		top       = $$FALSE
	ELSE
		top       = Top ()
		IFZ top THEN XcowlErr (210059): GOTO eeeCompiler
		IFZ theType THEN XcowlErr (210060): GOTO eeeCompiler
		varToken.tp.kind = $$KIND_VARIABLES
		varToken.tp.type = theType
		varToken.tindex = top
		inType = theType
	END IF
	theOffset = 0
	PeekToken (@check)
'
	IF (varToken.tp.kind = $$KIND_ARRAYS) THEN
		IF dim_array THEN XcowlErr (210070): GOTO eeeSyntax
		new_data  = varToken
		new_type  = theType
		accArray  = $$FALSE
		node      = $$FALSE
'
' new_op and new_prec added below
'
		SELECT CASE command
			CASE $$GETHANDLE:   new_op = #T_HANDLE_OP:  new_prec = $$PREC_ADDR_OP
			CASE $$GETADDR:     new_op = #T_ADDR_OP:    new_prec = $$PREC_ADDR_OP
			CASE $$GETDATAADDR: new_op = #T_ADDR_OP:    new_prec = $$PREC_ADDR_OP
			CASE $$GETDATA:     new_op = #T_ZERO:       new_prec = 0
		END SELECT
'
		ExpressArray (@new_op, @new_prec, @new_data, @new_type, accArray, @node, theType, 0)
		IF XERROR THEN EXIT FUNCTION
		IF node THEN
			command   = 1
			preType   = 0
			theType   = $$XLONG
'     theReg    = Top ()
			theReg.tindex   = Top ()
			theOffset = 0
			theLength = 0
			RETURN
		END IF
		new_type  = theType
		PeekToken (@check)
		checkKind = check.tp.kind
		SELECT CASE checkKind
			CASE $$KIND_SYMBOLS, $$KIND_ARRAY_SYMBOLS   ' subComposite
				IFF TokenMatch (@new_data, @#T_ZERO) THEN XcowlErr (2100102): GOTO eeeSyntax ' null array invalid
				regBase   = Top ()                        ' new regBase is toes
				varToken  = #T_ZERO
			CASE ELSE                                   ' varComposite
				SELECT CASE command
					CASE $$GETADDR, $$GETHANDLE:  XcowlErr (2100107): GOTO eeeSyntax
				END SELECT
				IF TokenMatch (@new_data, @#T_ZERO) THEN  ' not null array
					regBase   = Top ()                      ' new regBase is toes
					varToken  = #T_ZERO
				END IF
		END SELECT
	END IF
	preType = theType
'
com_process:
	theLength = typeSize[theType]
	DO
		checkKind = check.tp.kind
		SELECT CASE checkKind
			CASE $$KIND_SYMBOLS, $$KIND_ARRAY_SYMBOLS
					NextToken (@check)
					component   = $$TRUE
					preType     = theType
					Component (command, @varToken, @regBase, @theOffset, @theType, check, @theLength)
					IF XERROR THEN EXIT FUNCTION
					PeekToken (@check)
			CASE ELSE
					component   = $$FALSE
		END SELECT
	LOOP WHILE (component)
' IF (theOffset > 65535) THEN XcowlErr (2100133): GOTO eeeOverflow
'
' Make sure base address is in a register
'   Note:  haveData can only be true with pointers...
'
	IF TokenMatch (@varToken, @#T_ZERO) THEN      ' base moved to regBase register (ptr or [x])
		theReg.tindex = regBase                     ' theReg = base & destination
		SELECT CASE command                         ' address or data ???
			CASE $$GETDATA                            ' data requested
				command = 1                             ' one thing stacked
				IF haveData THEN                        '
					IFZ theLength THEN theLength = typeSize[theType]  ' ??? xx2m ???
					RETURN                                ' ExpressArray got data
				END IF
			CASE ELSE                                 ' address requested
				command = 1                             ' one thing stacked
				IFZ theLength THEN theLength = typeSize[theType]    ' ??? xx2m ???
				RETURN                                  ' address requested
		END SELECT
	ELSE                          ' base still in varToken (simple offset)
		uu = varToken.tindex                      ' token # or reg #
		regBase = r_addr[uu]                        ' regBase = base address reg
		IF regBase THEN
			SELECT CASE command                       ' address or data ???
				CASE $$GETDATA                          ' data requested
					IF top THEN
						theReg.tindex = top               ' already stacked
					ELSE
						theReg.tindex = OpenAccForType (theType)  ' theReg = destination
					END IF
					command = 1                           ' one thing stacked
					IF haveData THEN RETURN               ' ExpressArray got data
				CASE ELSE                               ' address requested
					theReg.tindex = regBase             ' theReg = base address
					IFZ theLength THEN theLength = typeSize[theType]  ' ??? xx2m ???
					command = 0                           ' nothing stacked
					RETURN                                ' theOffset
			END SELECT
		ELSE                                        ' base address not in reg
			theReg.tindex = OpenAccForType ($$XLONG)        ' theReg = destination
			Move (theReg.tindex, $$XLONG, varToken.tindex, $$XLONG)
			SELECT CASE command                       ' address of data ???
				CASE $$GETDATA                          ' data requested
					command = 1                           ' one thing stacked
					regBase = theReg.tindex             ' regBase = base address
					IF haveData THEN                      '
						IFZ theLength THEN theLength = typeSize[theType]  ' ??? xx2m ???
						RETURN                              ' ExpressArray got data
					END IF                                '
				CASE ELSE                               ' address requested
					command = 1                           ' one thing stacked
					IFZ theLength THEN theLength = typeSize[theType]  ' ??? xx2m ???
					RETURN
			END SELECT
		END IF
	END IF
'
'
' *******************************
' *****  WANT DATA ELEMENT  *****
' *******************************
'
' regBase   = base address register
' theOffset = offset from base address to data
' theReg    = register to contain data
' theType   = data type of the component (simple or composite)
'
'
' *****  SIMPLE TYPE  *****  copy fixed string into native string
'
	IF (theType < $$SCOMPLEX) THEN
		IF (theType = $$STRING) THEN
			Code ($$lea, $$regro, theReg.tindex, regBase, theOffset, $$XLONG, "", $$rmk$+"414")
			Code ($$mov, $$regreg, $$rsi, theReg.tindex, 0, $$XLONG, "", $$rmk$+"415")
			Code ($$mov, $$regimm, $$rdi, theLength, 0, $$XLONG, "", $$rmk$+"416")
'     Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_ByteMakeCopy", $$rmk$+"417")
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_CompositeStringToString", $$rmk$+"418")
			Code ($$mov, $$regreg, theReg.tindex, $$rsi, 0, $$XLONG, "", $$rmk$+"419")
			INC oos
			oos[oos] = 's'
		ELSE
			IF ((theType = $$SINGLE) OR (theType = $$DOUBLE)) THEN
				Code ($$fld, $$ro, theReg.tindex, regBase, theOffset, theType, "", $$rmk$+"420")
			ELSE
				Code ($$ld, $$regro, theReg.tindex, regBase, theOffset, theType, "", $$rmk$+"421")
			END IF
		END IF
		IF (theType < $$SLONG) THEN theType = $$SLONG
		SELECT CASE theReg.tindex
			CASE $$RA0 : a0_type = theType
			CASE $$RA1 : a1_type = theType
			CASE ELSE  : XcowlErr (2100224): GOTO eeeCompiler
		END SELECT
		theOffset = 0
		RETURN
	END IF
'
' *****  COMPOSITE TYPE  *****
'
	IF (theReg.tindex = regBase) THEN
		IFZ theOffset THEN RETURN
	END IF
	Code ($$lea, $$regro, theReg.tindex, regBase, theOffset, $$XLONG, "", $$rmk$+"422")
	theOffset = 0
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeOverflow:
	XERROR = ERROR_OVERFLOW
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
END FUNCTION
'
'
' #####################
' #####  Conv ()  #####
' #####################
'
FUNCTION  Conv (destin, to_type, source, from_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_TYPE_MISMATCH
	SHARED  ERROR_VOID
	SHARED  a0_type,  a1_type,  labelNumber
	STATIC GOADDR  convToType[]
	STATIC GOADDR  convToType2[]
	STATIC GOADDR  convToType3[]
	STATIC GOADDR  convToType4[]
	STATIC GOADDR  convToType5[]
	STATIC GOADDR  convToType6[]
	STATIC GOADDR  convToType7[]
	STATIC GOADDR  convToType8[]
	STATIC GOADDR  convToType9[]
	STATIC GOADDR  convToTypea[]
	STATIC GOADDR  convToTypeb[]
	STATIC GOADDR  convToTypec[]
	STATIC GOADDR  convToTyped[]
	STATIC GOADDR  convToTypee[]
	STATIC GOADDR  convToTypes[]
'
	IFZ convToType[] THEN
		GOSUB LoadConvToType
		GOSUB LoadConvToType2
		GOSUB LoadConvToType3
		GOSUB LoadConvToType4
		GOSUB LoadConvToType5
		GOSUB LoadConvToType6
		GOSUB LoadConvToType7
		GOSUB LoadConvToType8
		GOSUB LoadConvToType9
		GOSUB LoadConvToTypea
		GOSUB LoadConvToTypeb
		GOSUB LoadConvToTypec
		GOSUB LoadConvToTyped
		GOSUB LoadConvToTypee
		GOSUB LoadConvToTypes
	END IF
'
	tt = to_type
	ft = from_type
	IF (ft < $$SLONG) THEN ft = $$SLONG
	IFZ tt THEN tt = ft
	d_reg   = Reg (destin)
	d_regx  = d_reg + 1
	IFZ d_reg THEN XcowlErr (220052): GOTO eeeCompiler
	IF (d_reg = $$RA0) THEN a0_type = tt
	IF (d_reg = $$RA1) THEN a1_type = tt
'
	s_reg   = Reg (source)
	s_regx  = s_reg + 1
	IFZ s_reg THEN XcowlErr (220058): GOTO eeeCompiler
	IF (tt = ft) THEN
		IF (d_reg = s_reg) THEN RETURN
		Move (d_reg, tt, source, ft)
		EXIT FUNCTION
	END IF
	IF ((tt >= $$SCOMPLEX) OR (ft >= $$SCOMPLEX)) THEN XcowlErr (220064): GOTO eeeTypeMismatch
'
	IF Literal (s_reg) THEN
		IF ((ft = $$DOUBLE) OR (ft = $$GIANT)) THEN
			IF ((tt != $$DOUBLE) AND (tt != $$GIANT)) THEN
				Move ($$rsi, ft, source, ft)
				s_reg   = $$rsi
				s_regx  = $$rdi
			ELSE
				Move (d_reg, ft, source, ft)
				s_reg   = d_reg
				s_regx  = d_regx
				s_reg$  = d_reg$
				s_regx$ = d_regx$
			END IF
		ELSE
			Move (d_reg, ft, source, ft)
			s_reg   = d_reg
			s_regx  = d_regx
			s_reg$  = d_reg$
			s_regx$ = d_regx$
		END IF
	END IF
'
' *****  Dispatch to routine to convert to type "tt"  *****
'
	GOTO @convToType[tt]
	PRINT "conv3"
	XcowlErr (220092): GOTO eeeCompiler
'
'
' **************************************************************
' *****  Emit code to convert from type "ft" to type "tt"  *****
' **************************************************************
'
' ********************************
' *****  to SBYTE from "tt"  *****
' ********************************
'
tt2:
	GOTO @convToType2[ft]
	PRINT "conv4"
	XcowlErr (2200106): GOTO eeeCompiler
'
'
' *****  to SBYTE from SLONG  *****
'
tt2ft6:
tt2ft8:
tt2fte:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$mov, $$regreg, $$rsi, s_reg, 0, $$XLONG, "", $$rmk$+"423")
	Code ($$sar, $$regimm, $$rsi, 7, 0, $$XLONG, "", $$rmk$+"424")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"425")
	Code ($$not, $$reg, $$rsi, 0, 0, $$XLONG, "", $$rmk$+"426")
	Code ($$or, $$regreg, $$rsi, $$rsi, 0, $$XLONG, "", $$rmk$+"426A")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"427")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"428")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to SBYTE from ULONG  *****
'
tt2ft7:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$mov, $$regreg, $$rsi, s_reg, 0, $$XLONG, "", $$rmk$+"429")
	Code ($$sar, $$regimm, $$rsi, 7, 0, $$XLONG, "", $$rmk$+"430")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"431")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"432")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to SBYTE from SINGLE  *****
'
tt2ftc:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"433")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"434")
	ft = $$SLONG
	s_reg = d_reg
	GOTO tt2ft6
'
' *****  to SBYTE from DOUBLE  *****
'
tt2ftd:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"435")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"436")
	ft = $$SLONG
	s_reg = d_reg
	GOTO tt2ft6
'
'
' ********************************
' *****  to UBYTE from "tt"  *****
' ********************************
'
tt3:
	GOTO @convToType3[ft]
	PRINT "conv5"
	XcowlErr (2200164): GOTO eeeCompiler
'
' *****  to UBYTE from SLONG
' *****  to UBYTE from ULONG
'
tt3ft6:
tt3ft7:
tt3ft8:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$mov, $$regreg, $$rsi, s_reg, 0, $$XLONG, "", $$rmk$+"437")
	Code ($$sar, $$regimm, $$rsi, 8, 0, $$XLONG, "", $$rmk$+"438")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"439")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"440")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to UBYTE from SINGLE  *****
'
tt3ftc:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"441")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"442")
	ft    = $$SLONG
	s_reg = d_reg
	GOTO tt3ft6
'
' *****  to UBYTE from DOUBLE  *****
'
tt3ftd:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"443")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"444")
	ft    = $$SLONG
	s_reg = d_reg
	GOTO tt3ft6
'
' *****  to UBYTE from GIANT  *****
'
tt3fte:
	GOSUB cv_giant_to_slong
	ft = $$SLONG
	s_reg  = d_reg
	s_reg$ = d_reg$
	GOTO tt3ft6
'
'
' *********************************
' *****  to SSHORT from "tt"  *****
' *********************************
'
tt4:
	GOTO @convToType4[ft]
	PRINT "conv6"
	XcowlErr (2200216): GOTO eeeCompiler
'
tt4ft6:
tt4ft8:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$mov, $$regreg, $$rsi, s_reg, 0, $$XLONG, "", $$rmk$+"445")
	Code ($$sar, $$regimm, $$rsi, 15, 0, $$XLONG, "", $$rmk$+"446")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"447")
	Code ($$not, $$reg, $$rsi, 0, 0, $$XLONG, "", $$rmk$+"448")
	Code ($$or, $$regreg, $$rsi, $$rsi, 0, $$XLONG, "", $$rmk$+"426A")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"449")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"450")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to SSHORT from ULONG  *****
'
tt4ft7:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$mov, $$regreg, $$rsi, s_reg, 0, $$XLONG, "", $$rmk$+"451")
	Code ($$sar, $$regimm, $$rsi, 15, 0, $$XLONG, "", $$rmk$+"452")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"453")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"454")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to SSHORT from SINGLE  *****
'
tt4ftc:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"455")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"456")
	ft = $$SLONG
	s_reg = d_reg
	GOTO tt4
'
' *****  to SSHORT from DOUBLE  *****
'
tt4ftd:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"457")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"458")
	ft = $$SLONG
	s_reg = d_reg
	GOTO tt4
'
' *****  to SSHORT from GIANT  *****
'
tt4fte:
	GOSUB cv_giant_to_slong
	ft = $$SLONG
	s_reg  = d_reg
	GOTO tt4
'
'
' *********************************
' *****  to USHORT from "tt"  *****
' *********************************
'
tt5:
	GOTO @convToType5[ft]
	PRINT "conv7"
	XcowlErr (2200278): GOTO eeeCompiler
'
' *****  to USHORT from SLONG  *****
' *****  to USHORT from ULONG  *****
' *****  to USHORT from XLONG  *****
'
tt5ft6:
tt5ft7:
tt5ft8:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$mov, $$regreg, $$rsi, s_reg, 0, $$XLONG, "", $$rmk$+"459")
	Code ($$sar, $$regimm, $$rsi, 16, 0, $$XLONG, "", $$rmk$+"460")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"461")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"462")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
'
' *****  to USHORT from SINGLE  *****
'
tt5ftc:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"463")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"464")
	ft = $$SLONG
	s_reg = d_reg
	GOTO tt5
'
' *****  to USHORT from DOUBLE  *****
'
tt5ftd:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"465")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"466")
	ft = $$SLONG
	s_reg = d_reg
	GOTO tt5
'
' *****  to USHORT from GIANT  *****
'
tt5fte:
	GOSUB cv_giant_to_slong
	ft = $$SLONG
	s_reg  = d_reg
	GOTO tt5
'
'
' ********************************
' *****  to SLONG from "tt"  *****
' ********************************
'
tt6:
	GOTO @convToType6[ft]
	PRINT "conv8"
	XcowlErr (2200331): GOTO eeeCompiler
'
' *****  to SLONG from SLONG  *****
'
tt6ft6:
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to SLONG from ULONG  *****
'
tt6ft7:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$or, $$regreg, s_reg, s_reg, 0, $$XLONG, "", $$rmk$+"467")
	Code ($$jns, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"468")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"469")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to SLONG from XLONG  *****
'
tt6ft8:
	Move(d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to SLONG from SINGLE  *****
'
tt6ftc:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"470")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"471")
	RETURN
'
' *****  to SLONG from DOUBLE  *****
'
tt6ftd:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"472")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"473")
	RETURN
'
' *****  to SLONG from GIANT  *****
'
tt6fte:
	GOSUB cv_giant_to_slong
	RETURN
'
'
' ********************************
' *****  to ULONG from "tt"  *****
' ********************************
'
tt7:
	GOTO @convToType7[ft]
	PRINT "conv9"
	XcowlErr (2200384): GOTO eeeCompiler
'
' *****  to ULONG from SLONG  *****
'
tt7ft6:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$or, $$regreg, s_reg, s_reg, 0, $$XLONG, "", $$rmk$+"474")
	Code ($$jns, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"475")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"476")
	EmitLabel (@d1$)
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to ULONG from ULONG  *****
' *****  to ULONG from XLONG  *****
'
tt7ft7:
tt7ft8:
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to ULONG from SINGLE  *****
'
tt7ftc:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"477")
	Code ($$or, $$regreg, d_reg, d_reg, 0, $$XLONG, "", $$rmk$+"479")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"480")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"481")
	EmitLabel (@d1$)
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"482")
	RETURN
'
' *****  to ULONG from DOUBLE  *****
'
tt7ftd:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"483")
	Code ($$or, $$regreg, d_reg, d_reg, 0, $$XLONG, "", $$rmk$+"485")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"486")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"487")
	EmitLabel (@d1$)
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"488")
	RETURN
'
' *****  to ULONG from GIANT  *****
'
tt7fte:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$mov, $$regreg, d_regx, s_reg, 0, $$XLONG, "", $$rmk$+"489")
	Code ($$sar, $$regimm, d_regx, 32, 0, $$XLONG, "", $$rmk$+"490")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"491")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"492")
	EmitLabel (@d1$)
	RETURN
'
'
' ********************************
' *****  to XLONG from "tt"  *****
' ********************************
'
tt8:
	GOTO @convToType8[ft]
	XcowlErr (2200447): GOTO eeeCompiler
'
' *****  to XLONG from SLONG  *****
' *****  to XLONG from ULONG  *****
' *****  to XLONG from XLONG  *****
' *****  to XLONG from GOADDR  *****
' *****  to XLONG from SUBADDR  *****
' *****  to XLONG from FUNCADDR  *****
'
tt8ft6:
tt8ft7:
tt8ft8:
tt8ft9:
tt8fta:
tt8ftb:
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to XLONG from SINGLE  *****
'
tt8ftc:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"493")
'	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"494")  '*cw* 230220-
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$SLONG, "", $$rmk$+"494")  '*cw* 230220+
	RETURN
'
' *****  to XLONG from DOUBLE  *****
'
tt8ftd:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"495")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"496")
	RETURN
'
' *****  to XLONG from GIANT  *****
'
tt8fte:
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
'
' *********************************
' *****  to GOADDR from "tt"  *****
' *********************************
'
tt9:
	GOTO @convToType9[ft]
	PRINT "conv11"
	XcowlErr (2200493): GOTO eeeCompiler
'
' *****  to GOADDR from XLONG  *****
'
tt9ft8:
	Move (d_reg, tt, s_reg, tt)
	RETURN
'
' *****  to GOADDR from GOADDR  *****
'
tt9ft9:
	Move (d_reg, tt, s_reg, tt)
	RETURN
'
'
' **********************************
' *****  to SUBADDR from "tt"  *****
' **********************************
'
tta:
	GOTO @convToTypea[ft]
	PRINT "conv12"
	XcowlErr (2200515): GOTO eeeCompiler
'
' *****  to SUBADDR from XLONG  *****
'
ttaft8:
	Move (d_reg, tt, s_reg, tt)
	RETURN
'
' *****  to SUBADDR from SUBADDR  *****
'
ttafta:
	Move (d_reg, tt, s_reg, tt)
	RETURN
'
'
' ***********************************
' *****  to FUNCADDR from "tt"  *****
' ***********************************
'
ttb:
	GOTO @convToTypeb[ft]
	PRINT "conv13"
	XcowlErr (2200537): GOTO eeeCompiler
'
' *****  to FUNCADDR from XLONG  *****
'
ttbft8:
	Move (d_reg, tt, s_reg, tt)
	RETURN
'
' *****  to FUNCADDR from FUNCADDR  *****
'
ttbftb:
	Move (d_reg, tt, s_reg, tt)
	RETURN
'
'
' *********************************
' *****  to SINGLE from "tt"  *****
' *********************************
'
ttc:
	GOTO @convToTypec[ft]
	PRINT "conv14"
	XcowlErr (2200559): GOTO eeeCompiler
'
' *****  to SINGLE from SLONG  *****
' *****  to SINGLE from XLONG  *****
'
ttcft6:
ttcft8:
	Code ($$st, $$roreg, s_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"497")
	Code ($$fild, $$ro, 0, $$rbp, -8, $$SLONG, "", $$rmk$+"498")
	RETURN
'
' *****  to SINGLE from ULONG  *****
'
ttcft7:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$st, $$roreg, s_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"499")
	Code ($$fild, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"501")
	EmitLabel (@d1$)
	RETURN
'
' *****  to SINGLE from SINGLE  *****
'
ttcftc:
	Move (d_reg, tt, s_reg, tt)
	RETURN
'
' *****  to SINGLE from DOUBLE  *****
'
ttcftd:
	RETURN
'
' *****  to SINGLE from GIANT  *****
'
ttcfte:
	Code ($$st, $$roreg, s_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"502")
	Code ($$fild, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"504")
	RETURN
'
'
' *********************************
' *****  to DOUBLE from "tt"  *****
' *********************************
'
ttd:
	GOTO @convToTyped[ft]
	PRINT "conv15"
	XcowlErr (2200605): GOTO eeeCompiler
'
' *****  to DOUBLE from SLONG  *****
' *****  to DOUBLE from XLONG  *****
'
ttdft6:
ttdft8:
	Code ($$st, $$roreg, s_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"505")
	Code ($$fild, $$ro, 0, $$rbp, -8, $$XLONG, "", $$rmk$+"506")
	RETURN
'
' *****  to DOUBLE from ULONG  *****
'
ttdft7:
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$st, $$roreg, s_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"508")
	Code ($$fild, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"509")
	EmitLabel (@d1$)
	RETURN
'
' *****  to DOUBLE from SINGLE  *****
'
ttdftc:
	RETURN
'
' *****  to DOUBLE from DOUBLE  *****
'
ttdftd:
	RETURN
'
' *****  to DOUBLE from GIANT  *****
'
ttdfte:
	Code ($$st, $$roreg, s_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"510")
	Code ($$fild, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"512")
	RETURN
'
'
' ********************************
' *****  to GIANT from "tt"  *****
' ********************************
'
tte:
	GOTO @convToTypee[ft]
	PRINT "conv16"
	XcowlErr (2200650): GOTO eeeCompiler
'
' *****  to GIANT from SLONG  *****
' *****  to GIANT from XLONG  *****
'
tteft6:
tteft8:
	Move (d_reg, ft, s_reg, ft)
	RETURN
'
' *****  to GIANT from ULONG  *****
'
tteft7:
	IF (d_reg != s_reg) THEN Code ($$mov, $$regreg, d_reg, s_reg, 0, $$XLONG, "", $$rmk$+"516")
	Code ($$xor, $$regreg, d_regx, d_regx, 0, $$XLONG, "", $$rmk$+"517")
	RETURN
'
' *****  to GIANT from SINGLE  *****
'
tteftc:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"518")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"519")
	RETURN
'
' *****  to GIANT from DOUBLE  *****
'
tteftd:
	Code ($$fistp, $$ro, 0, $$rbp, -8, $$GIANT, "", $$rmk$+"521")
	Code ($$ld, $$regro, d_reg, $$rbp, -8, $$XLONG, "", $$rmk$+"522")
	RETURN
'
' *****  to GIANT from GIANT  *****
'
ttefte:
	IF (d_reg != s_reg) THEN Move (d_reg, $$GIANT, s_reg, $$GIANT)
	RETURN
'
'
' *********************************
' *****  to STRING from "tt"  *****
' *********************************
'
tts:
	GOTO @convToTypes[ft]
	PRINT "conv17"
	XcowlErr (2200695): GOTO eeeCompiler
'
ttsfts:
	Move (d_reg, $$STRING, s_reg, $$STRING)
	RETURN
'
'
' *****************************************
' *****  TYPE CONVERSION SUBROUTINES  *****
' *****************************************
'
' *****  GIANT  to  SLONG  *****  subroutine used by several other conversions
'
SUB  cv_giant_to_slong
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	INC labelNumber: d2$ = $$ulpc$ + HEX$(labelNumber, 4)
	IF (d_reg != s_reg) THEN Code ($$mov, $$regreg, d_reg, s_reg, 0, $$XLONG, "", $$rmk$+"524")
	Code ($$or, $$regreg, s_reg, s_reg, 0, $$XLONG, "", $$rmk$+"525")
	Code ($$jns, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"526")
	Code ($$not, $$reg, s_regx, 0, 0, $$XLONG, "", $$rmk$+"527")
	EmitLabel (@d1$)
	Code ($$or, $$regreg, s_regx, s_regx, 0, $$XLONG, "", $$rmk$+"528")
	Code ($$jz, $$rel, 0, 0, 0, 0, @d2$, $$rmk$+"529")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"530")
	EmitLabel (@d2$)
END SUB
'
'
'
' *****************************************************
' *****  Load conversion from/to dispatch arrays  *****
' *****************************************************
'
SUB LoadConvToType
	DIM convToType[31]
	convToType[ $$VOID     ] = GOADDRESS (eeeVoid)
	convToType[ $$SBYTE    ] = GOADDRESS (tt2)
	convToType[ $$UBYTE    ] = GOADDRESS (tt3)
	convToType[ $$SSHORT   ] = GOADDRESS (tt4)
	convToType[ $$USHORT   ] = GOADDRESS (tt5)
	convToType[ $$SLONG    ] = GOADDRESS (tt6)
	convToType[ $$ULONG    ] = GOADDRESS (tt7)
	convToType[ $$XLONG    ] = GOADDRESS (tt8)
	convToType[ $$GOADDR   ] = GOADDRESS (tt9)
	convToType[ $$SUBADDR  ] = GOADDRESS (tta)
	convToType[ $$FUNCADDR ] = GOADDRESS (ttb)
	convToType[ $$SINGLE   ] = GOADDRESS (ttc)
	convToType[ $$DOUBLE   ] = GOADDRESS (ttd)
	convToType[ $$GIANT    ] = GOADDRESS (tte)
	convToType[ $$STRING   ] = GOADDRESS (tts)
END SUB
'
SUB LoadConvToType2
	DIM convToType2[31]
	convToType2[ $$VOID     ] = GOADDRESS (eeeVoid)
	convToType2[ $$SLONG    ] = GOADDRESS (tt2ft6)
	convToType2[ $$ULONG    ] = GOADDRESS (tt2ft7)
	convToType2[ $$XLONG    ] = GOADDRESS (tt2ft8)
	convToType2[ $$GOADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToType2[ $$SUBADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToType2[ $$FUNCADDR ] = GOADDRESS (eeeTypeMismatch)
	convToType2[ $$SINGLE   ] = GOADDRESS (tt2ftc)
	convToType2[ $$DOUBLE   ] = GOADDRESS (tt2ftd)
	convToType2[ $$GIANT    ] = GOADDRESS (tt2fte)
	convToType2[ $$STRING   ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToType3
	DIM convToType3[31]
	convToType3[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToType3[ $$SLONG     ] = GOADDRESS (tt3ft6)
	convToType3[ $$ULONG     ] = GOADDRESS (tt3ft7)
	convToType3[ $$XLONG     ] = GOADDRESS (tt3ft8)
	convToType3[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToType3[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToType3[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToType3[ $$SINGLE    ] = GOADDRESS (tt3ftc)
	convToType3[ $$DOUBLE    ] = GOADDRESS (tt3ftd)
	convToType3[ $$GIANT     ] = GOADDRESS (tt3fte)
	convToType3[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToType4
	DIM convToType4[31]
	convToType4[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToType4[ $$SLONG     ] = GOADDRESS (tt4ft6)
	convToType4[ $$ULONG     ] = GOADDRESS (tt4ft7)
	convToType4[ $$XLONG     ] = GOADDRESS (tt4ft8)
	convToType4[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToType4[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToType4[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToType4[ $$SINGLE    ] = GOADDRESS (tt4ftc)
	convToType4[ $$DOUBLE    ] = GOADDRESS (tt4ftd)
	convToType4[ $$GIANT     ] = GOADDRESS (tt4fte)
	convToType4[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToType5
	DIM convToType5[31]
	convToType5[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToType5[ $$SLONG     ] = GOADDRESS (tt5ft6)
	convToType5[ $$ULONG     ] = GOADDRESS (tt5ft7)
	convToType5[ $$XLONG     ] = GOADDRESS (tt5ft8)
	convToType5[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToType5[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToType5[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToType5[ $$SINGLE    ] = GOADDRESS (tt5ftc)
	convToType5[ $$DOUBLE    ] = GOADDRESS (tt5ftd)
	convToType5[ $$GIANT     ] = GOADDRESS (tt5fte)
	convToType5[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToType6
	DIM convToType6[31]
	convToType6[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToType6[ $$SLONG     ] = GOADDRESS (tt6ft6)
	convToType6[ $$ULONG     ] = GOADDRESS (tt6ft7)
	convToType6[ $$XLONG     ] = GOADDRESS (tt6ft8)
	convToType6[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToType6[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToType6[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToType6[ $$SINGLE    ] = GOADDRESS (tt6ftc)
	convToType6[ $$DOUBLE    ] = GOADDRESS (tt6ftd)
	convToType6[ $$GIANT     ] = GOADDRESS (tt6fte)
	convToType6[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToType7
	DIM convToType7[31]
	convToType7[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToType7[ $$SLONG     ] = GOADDRESS (tt7ft6)
	convToType7[ $$ULONG     ] = GOADDRESS (tt7ft7)
	convToType7[ $$XLONG     ] = GOADDRESS (tt7ft8)
	convToType7[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToType7[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToType7[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToType7[ $$SINGLE    ] = GOADDRESS (tt7ftc)
	convToType7[ $$DOUBLE    ] = GOADDRESS (tt7ftd)
	convToType7[ $$GIANT     ] = GOADDRESS (tt7fte)
	convToType7[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToType8
	DIM convToType8[31]
	convToType8[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToType8[ $$SLONG     ] = GOADDRESS (tt8ft6)
	convToType8[ $$ULONG     ] = GOADDRESS (tt8ft7)
	convToType8[ $$XLONG     ] = GOADDRESS (tt8ft8)
	convToType8[ $$GOADDR    ] = GOADDRESS (tt8ft9)
	convToType8[ $$SUBADDR   ] = GOADDRESS (tt8fta)
	convToType8[ $$FUNCADDR  ] = GOADDRESS (tt8ftb)
	convToType8[ $$SINGLE    ] = GOADDRESS (tt8ftc)
	convToType8[ $$DOUBLE    ] = GOADDRESS (tt8ftd)
	convToType8[ $$GIANT     ] = GOADDRESS (tt8fte)
	convToType8[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)

'	convToTypec[ $$VOID      ] = GOADDRESS (eeeVoid)
'	convToTypec[ $$SLONG     ] = GOADDRESS (ttcft6)
'	convToTypec[ $$ULONG     ] = GOADDRESS (ttcft7)
'	convToTypec[ $$XLONG     ] = GOADDRESS (ttcft8)
'	convToTypec[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
'	convToTypec[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
'	convToTypec[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
'	convToTypec[ $$SINGLE    ] = GOADDRESS (ttcftc)
'	convToTypec[ $$DOUBLE    ] = GOADDRESS (ttcftd)
'	convToTypec[ $$GIANT     ] = GOADDRESS (ttcfte)
'	convToTypec[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToType9
	DIM convToType9[31]
	convToType9[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToType9[ $$SLONG     ] = GOADDRESS (eeeTypeMismatch)
	convToType9[ $$ULONG     ] = GOADDRESS (eeeTypeMismatch)
	convToType9[ $$XLONG     ] = GOADDRESS (tt9ft8)
	convToType9[ $$GOADDR    ] = GOADDRESS (tt9ft9)
	convToType9[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToType9[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToType9[ $$SINGLE    ] = GOADDRESS (eeeTypeMismatch)
	convToType9[ $$DOUBLE    ] = GOADDRESS (eeeTypeMismatch)
	convToType9[ $$GIANT     ] = GOADDRESS (eeeTypeMismatch)
	convToType9[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToTypea
	DIM convToTypea[31]
	convToTypea[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToTypea[ $$SLONG     ] = GOADDRESS (eeeTypeMismatch)
	convToTypea[ $$ULONG     ] = GOADDRESS (eeeTypeMismatch)
	convToTypea[ $$XLONG     ] = GOADDRESS (ttaft8)
	convToTypea[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToTypea[ $$SUBADDR   ] = GOADDRESS (ttafta)
	convToTypea[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToTypea[ $$SINGLE    ] = GOADDRESS (eeeTypeMismatch)
	convToTypea[ $$DOUBLE    ] = GOADDRESS (eeeTypeMismatch)
	convToTypea[ $$GIANT     ] = GOADDRESS (eeeTypeMismatch)
	convToTypea[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToTypeb
	DIM convToTypeb[31]
	convToTypeb[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToTypeb[ $$SLONG     ] = GOADDRESS (eeeTypeMismatch)
	convToTypeb[ $$ULONG     ] = GOADDRESS (eeeTypeMismatch)
	convToTypeb[ $$XLONG     ] = GOADDRESS (ttbft8)
	convToTypeb[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToTypeb[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToTypeb[ $$FUNCADDR  ] = GOADDRESS (ttbftb)
	convToTypeb[ $$SINGLE    ] = GOADDRESS (eeeTypeMismatch)
	convToTypeb[ $$DOUBLE    ] = GOADDRESS (eeeTypeMismatch)
	convToTypeb[ $$GIANT     ] = GOADDRESS (eeeTypeMismatch)
	convToTypeb[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToTypec
	DIM convToTypec[31]
	convToTypec[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToTypec[ $$SLONG     ] = GOADDRESS (ttcft6)
	convToTypec[ $$ULONG     ] = GOADDRESS (ttcft7)
	convToTypec[ $$XLONG     ] = GOADDRESS (ttcft8)
	convToTypec[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToTypec[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToTypec[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToTypec[ $$SINGLE    ] = GOADDRESS (ttcftc)
	convToTypec[ $$DOUBLE    ] = GOADDRESS (ttcftd)
	convToTypec[ $$GIANT     ] = GOADDRESS (ttcfte)
	convToTypec[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToTyped
	DIM convToTyped[31]
	convToTyped[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToTyped[ $$SLONG     ] = GOADDRESS (ttdft6)
	convToTyped[ $$ULONG     ] = GOADDRESS (ttdft7)
	convToTyped[ $$XLONG     ] = GOADDRESS (ttdft8)
	convToTyped[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToTyped[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToTyped[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToTyped[ $$SINGLE    ] = GOADDRESS (ttdftc)
	convToTyped[ $$DOUBLE    ] = GOADDRESS (ttdftd)
	convToTyped[ $$GIANT     ] = GOADDRESS (ttdfte)
	convToTyped[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToTypee
	DIM convToTypee[31]
	convToTypee[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToTypee[ $$SLONG     ] = GOADDRESS (tteft6)
	convToTypee[ $$ULONG     ] = GOADDRESS (tteft7)
	convToTypee[ $$XLONG     ] = GOADDRESS (tteft8)
	convToTypee[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToTypee[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToTypee[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToTypee[ $$SINGLE    ] = GOADDRESS (tteftc)
	convToTypee[ $$DOUBLE    ] = GOADDRESS (tteftd)
	convToTypee[ $$GIANT     ] = GOADDRESS (ttefte)
	convToTypee[ $$STRING    ] = GOADDRESS (eeeTypeMismatch)
END SUB
'
SUB LoadConvToTypes
	DIM convToTypes[31]
	convToTypes[ $$VOID      ] = GOADDRESS (eeeVoid)
	convToTypes[ $$SLONG     ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$ULONG     ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$XLONG     ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$GOADDR    ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$SUBADDR   ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$FUNCADDR  ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$SINGLE    ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$DOUBLE    ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$GIANT     ] = GOADDRESS (eeeTypeMismatch)
	convToTypes[ $$STRING    ] = GOADDRESS (ttsfts)
END SUB
'
'
'
'  *******************************
'  *****  CONVERSION ERRORS  *****
'  *******************************
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
'
eeeVoid:
	XERROR = ERROR_VOID
	EXIT FUNCTION
END FUNCTION
'
'
' ###########################
' #####  Deallocate ()  #####
' ###########################
'
FUNCTION  Deallocate (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
'
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  m_addr[]
'
	IFZ m_addr[token.tindex] THEN RETURN
	otype = TheType (token)
	kind  = token.tp.kind
	SELECT CASE kind
		CASE $$KIND_VARIABLES, $$KIND_CONSTANTS
			Move ($$rdi, otype, token.tindex, otype)
			Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"531")
			Code ($$xor, $$regreg, $$rdx, $$rdx, 0, $$XLONG, "", $$rmk$+"532")
			Move (token.tindex, $$XLONG, $$rdx, $$XLONG)
		CASE $$KIND_ARRAYS
			Move ($$rdi, $$XLONG, token.tindex, $$XLONG)
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_FreeArray", $$rmk$+"533")
			Code ($$xor, $$regreg, $$rdx, $$rdx, 0, $$XLONG, "", $$rmk$+"534")
			Move (token.tindex, $$XLONG, $$rdx, $$XLONG)
		CASE ELSE
			PRINT "dd1"
			XcowlErr (230029): GOTO eeeCompiler
	END SELECT
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #########################
' #####  Deparse$ ()  #####
' #########################
'
' charpos[] = character position of tokens, 0 offset
'
FUNCTION  Deparse$ (prefix$)
	TOKEN   token
	SHARED  TOKEN  tokens[]
	SHARED  charpos[]
	SHARED  funcSymbol$[],  tab_lab$[],  tab_sym$[],  tab_sys$[]
	SHARED  typeSymbol$[]
	SHARED  tokenCount,  tokenPtr
	STATIC SUBADDR  kindDeparse[]
'
	IFZ kindDeparse[] THEN GOSUB LoadKindDeparse
'
	tokenPtr    = -1
	charpos[0]  = 0
	deparsed$   = prefix$
	DO WHILE (tokenPtr < tokenCount)
		INC tokenPtr
		token.tproto = tokens[tokenPtr].tproto
		token.tindex = tokens[tokenPtr].tindex
		tt      = token.tindex
		kind    = token.tp.kind
		spaces  = token.tp.stsp
		IF (spaces > 0) THEN
			whiteChar = 32      ' spaces
		ELSE
			whiteChar = 9       ' tabs
			spaces = -spaces
		END IF
		GOSUB @kindDeparse[kind]        ' dispatch deparse based on kind of token
		IF (tokenPtr < 255) THEN charpos[tokenPtr + 1] = LEN(deparsed$)
	LOOP
	IF (tokenPtr < 254) THEN charpos[tokenPtr + 2] = 0
	RETURN (deparsed$)
'
'
' ****************************************************************
' *****  Subroutines to deparse different "kinds" of tokens  *****
' ****************************************************************
'
' *****  SystemSymbols  *****
'
SUB SystemSymbols
	deparsed$ = deparsed$ + tab_sys$[tt] + CHR$ (whiteChar, spaces)
END SUB
'
' *****  UserSymbols  *****
'
SUB UserSymbols
	deparsed$ = deparsed$ + tab_sym$[tt] + CHR$ (whiteChar, spaces)
END SUB
'
' *****  FunctionSymbols  *****  $$KIND_FUNCTIONS
'
SUB FunctionSymbols
	deparsed$ = deparsed$ + funcSymbol$[tt] + CHR$ (whiteChar, spaces)
END SUB
'
' *****  UserLabels  *****
'
SUB UserLabels
	s$ = MID$ (tab_lab$[tt], 4)
	suffix = RINSTR (s$, $$ulpc$)                   ' unspas
	s$ = LEFT$ (s$, suffix - 1)
	IF (tokenPtr = 1) THEN s$ = s$ + ":"
	deparsed$ = deparsed$ + s$ + CHR$ (whiteChar, spaces)
END SUB
'
' *****  SystemStarts  *****   $$KIND_STARTS
'
SUB SystemStarts
	errorIndex = token.ti.errno                             ' errno is BYTE1
	IF errorIndex THEN
		deparsed$ = deparsed$ + RIGHT$ ("000" + STRING(errorIndex), 3)
	END IF
	SELECT CASE token.ti.bpexe
		CASE $$BPEXECLR:
		CASE $$BP      : deparsed$ = deparsed$ + ":"
		CASE $$EXE     : deparsed$ = deparsed$ + ">"
		CASE $$BPEXE   : deparsed$ = deparsed$ + ">:"
		CASE ELSE      : PRINT "Deparse$(88):Invalid .bpexe"
	END SELECT
'
	IF spaces THEN
		deparsed$ = deparsed$ + CHR$ (whiteChar, spaces)
	END IF
END SUB
'
' *****  SystemWhites  *****  $$KIND_WHITES
'
SUB SystemWhites
	IF spaces THEN
		deparsed$ = deparsed$ + CHR$ (whiteChar, spaces)
	END IF
END SUB
'
' *****  SystemComments  *****  $$KIND_COMMENTS
'
SUB SystemComments
	count = token.tp.type
	IF (count = 255) THEN
		INC tokenPtr
		count = tokens[tokenPtr].tindex
	END IF
	deparsed$ = deparsed$ + "'"
	pw$ = NULL$(8)
	pa = &pw$
	x = 0
	DO WHILE (x < count)
		INC tokenPtr
		ULONGAT(pa) = tokens[tokenPtr].tindex
		ULONGAT(pa+4) = tokens[tokenPtr].tproto
		deparsed$ = deparsed$ + pw$
		XLONGAT(pa) = 0
		x = x + 8
	LOOP
	deparsed$ = RTRIM$(deparsed$)
END SUB
'
' *****  UserTypes  *****
'
SUB UserTypes
	deparsed$ = deparsed$ + typeSymbol$[tt] + CHR$ (whiteChar, spaces)
END SUB
'
' *****  BogusToken  *****
'
SUB BogusToken
	PRINT "*****  DEPARSE$:  BOGUS TOKEN  *****"
END SUB
'
' *****  LoadKindDeparse  *****
'
SUB LoadKindDeparse
'
	stspType = TYPE(token.tp.stsp)
	IF (stspType <> $$SBYTE) THEN
		PRINT "TAKS.stsp is not defined as a signed byte"
		XcowlErr (2400145)
	END IF
'
	DIM kindDeparse[31]
	FOR i = 0 TO 31
		kindDeparse[i] = SUBADDRESS (BogusToken)
	NEXT
	kindDeparse[ $$KIND_TERMINATORS   ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_STATE_INTRIN  ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_STATEMENTS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_INTRINSICS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_SEPARATORS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_CHARACTERS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_BINARY_OPS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_UNARY_OPS     ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_ADDR_OPS      ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_LPARENS       ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_RPARENS       ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_SYMBOLS       ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_ARRAY_SYMBOLS ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_VARIABLES     ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_ARRAYS        ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_LITERALS      ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_CONSTANTS     ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_CHARCONS      ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_SYSCONS       ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_LABELS        ] = SUBADDRESS (UserLabels)
	kindDeparse[ $$KIND_TYPES         ] = SUBADDRESS (UserTypes)
	kindDeparse[ $$KIND_STARTS        ] = SUBADDRESS (SystemStarts)
	kindDeparse[ $$KIND_WHITES        ] = SUBADDRESS (SystemWhites)
	kindDeparse[ $$KIND_COMMENTS      ] = SUBADDRESS (SystemComments)
	kindDeparse[ $$KIND_FUNCTIONS     ] = SUBADDRESS (FunctionSymbols)
END SUB
END FUNCTION
'
'
' ########################
' #####  EmitAsm ()  #####
' ########################
'
FUNCTION  EmitAsm (line$)
	EXTERNAL /xxx/  i486asm, i486bin
	SHARED  ofile
'
' #emitasm = 0  ' flush buffer
' #emitasm = 1  ' buffer assembly
' #emitasm = 2  ' emit this now - leave buffer intact
'
	IF i486asm THEN
		emitasm = #emitasm
		IF #immediatemode THEN emitasm = 2
		SELECT CASE emitasm
			CASE 0 : GOSUB FlushBuffer
			CASE 1 : GOSUB BufferAssembly
			CASE 2 : PRINT[ofile], line$
		END SELECT
		IF ##WHOMASK && ##TRACE THEN PRINT line$
	END IF
	RETURN
'
'
' *****  FlushBuffer  *****
'
SUB FlushBuffer
	IF #asm$[] THEN
		IF (#asmnext > 0) THEN
			FOR line = 0 TO #asmnext-1
				PRINT[ofile], #asm$[line]
			NEXT line
		END IF
	END IF
'
	PRINT[ofile], line$
'
	#asmupper = -1
	#asmnext = 0
	DIM #asm$[]
END SUB
'
'
' *****  BufferAssembly  *****
'
SUB BufferAssembly
	IFZ #asm$[] THEN
		#asmnext = 0
		#asmupper = 4095
		DIM #asm$[#asmupper]
	END IF
'
	IF (#asmnext > #asmupper) THEN
		#asmupper = #asmupper + 4096
		REDIM #asm$[#asmupper]
	END IF
'
	#asm$[#asmnext] = line$
	INC #asmnext
END SUB
END FUNCTION
'
'
' #########################
' #####  EmitData ()  #####
' #########################
'
FUNCTION  EmitData ()
	EXTERNAL /xxx/  i486asm, i486bin
'
	IF i486asm THEN
		EmitAsm (".data")
	END IF
END FUNCTION
'
'
' ##################################
' #####  EmitFunctionLabel ()  #####
' ##################################
'
FUNCTION  EmitFunctionLabel (label$)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   token
	SHARED  labaddr[]
	SHARED  XERROR,  ERROR_DUP_LABEL
'
	token = AddLabel (@label$, $$KIND_LABELS, 0, $$XNEW)
	IF XERROR THEN EXIT FUNCTION
	SELECT CASE TRUE
		CASE i486bin : IF XERROR THEN EXIT FUNCTION
										tt = token.tindex
										qpc = labaddr[tt]
										IF qpc THEN XcowlErr (270019): GOTO eeeDupLabel
										labaddr[tt] = xpc
		CASE i486asm : ' PRINT[ofile], label$ + ":"
										EmitAsm (label$ + ":")
	END SELECT
	RETURN
'
eeeDupLabel:
	PRINT "Duplicate Label = "; label$
	XERROR = ERROR_DUP_LABEL
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  EmitLabel ()  #####
' ##########################
'
FUNCTION  EmitLabel (label$)
	EXTERNAL /xxx/  i486bin,  i486asm,  xpc
	TOKEN   token
	SHARED  labaddr[]
	SHARED  XERROR,  ERROR_DUP_LABEL
'
	token = AddLabel (@label$, $$KIND_LABELS, 0, $$XADD)
	IF XERROR THEN EXIT FUNCTION
	SELECT CASE TRUE
		CASE i486bin : IF XERROR THEN EXIT FUNCTION
										tt = token.tindex
										qpc = labaddr[tt]
										IF qpc THEN XcowlErr (280019): GOTO eeeDupLabel
										labaddr[tt] = xpc
		CASE i486asm : ' PRINT[ofile], label$ + ":"
										EmitAsm (label$ + ":")
	END SELECT
	RETURN
'
eeeDupLabel:
	PRINT "Duplicate Label = "; label$
	XERROR = ERROR_DUP_LABEL
	EXIT FUNCTION
END FUNCTION
'
'
' #########################
' #####  EmitLine ()  #####
' #########################
'
' Put address of line number in line address array and emit a line number
' symbol into the source text.
'
FUNCTION  EmitLine (lnum)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc,  library
	SHARED  xit,  XERROR
	STATIC  linefile    'DEBUG
'
	SELECT CASE TRUE
		CASE i486bin:   ' GOSUB EmitLineBin     'DEBUG
		CASE i486asm:     GOSUB EmitLineAsm
	END SELECT
	RETURN
'
SUB EmitLineAsm
	SELECT CASE TRUE
		CASE xit     : label$ = "aaaa" + STRING$ (lnum)
		CASE library : label$ = "llll" + STRING$ (lnum)
		CASE ELSE    : label$ = "xxxx" + STRING$ (lnum)
	END SELECT
'
	IF label$ THEN
		EmitAsm (label$ + ":")
		EmitAsm (".globl  " + label$)
	END IF
END SUB
'
SUB EmitLineBin                                           ' DEBUG
	IFZ linefile THEN                                       ' DEBUG
		linefile = OPEN ("lines", $$WRNEW)                    ' DEBUG
		PRINT "linefile = " linefile "    XERROR = " XERROR   ' DEBUG
	END IF                                                  ' DEBUG
	PRINT[linefile], lnum; ": "; HEXX$(xpc, 8)              ' DEBUG
END SUB                                                   ' DEBUG
END FUNCTION
'
'
' #############################
' #####  EmitLocation ()  #####
' #############################
'
FUNCTION  EmitLocation ()
SHARED programName$
SHARED lineNumber
SHARED func_number
STATIC fileEmitted
'
 RETURN                                     'only run this function when using gdb debug program
	IFZ ##XBDV THEN RETURN
	IFZ func_number THEN RETURN
'
	XstGetEnvironmentVariable ("zzz", @value$)
	IF (value$ == "7") THEN RETURN
'
'
	SELECT CASE programName$
		CASE "xst" : fileNumber$ = "1"
		CASE "xgr" : fileNumber$ = "2"
		CASE "xui" : fileNumber$ = "3"
		CASE "xit" : fileNumber$ = "4"
		CASE "xcol": fileNumber$ = "5"
		CASE ELSE  : fileNumber$ = ""
	END SELECT
	IFZ fileNumber$ THEN RETURN
'
	IFZ fileEmitted THEN
		s1$ = ".file 1 \"xst.x\""
		s2$ = ".file 2 \"xgr.x\""
		s3$ = ".file 3 \"xui.x\""
		s4$ = ".file 4 \"xit.x\""
		s5$ = ".file 5 \"xcol.x\""
'
		fileNumber = XLONG(fileNumber$)
		EmitNull (s1$)
		IF (fileNumber >= 2) THEN EmitNull (s2$)
		IF (fileNumber >= 3) THEN EmitNull (s3$)
		IF (fileNumber >= 4) THEN EmitNull (s4$)
		IF (fileNumber >= 5) THEN EmitNull (s5$)
		PRINT "EmitLocation()", programName$, fileNumber$
		fileEmitted = $$TRUE
	END IF
'
	IF fileEmitted THEN
		IF $$linux THEN
			s$ = ".loc " + fileNumber$ + STR$(lineNumber)  'linux
		ELSE
			s$ = ".ln " + STR$(lineNumber)                 'win32
		END IF
		EmitNull (s$)
	END IF
'
END FUNCTION
'
'
' #########################
' #####  EmitNull ()  #####
' #########################
'
FUNCTION  EmitNull (nullAsm$)
	EXTERNAL /xxx/  i486bin, i486asm
'
	IF i486asm THEN
		EmitAsm (@nullAsm$)
	END IF
END FUNCTION
'
'
' ###########################
' #####  EmitString ()  #####
' ###########################
'
FUNCTION  EmitString (theLabel$, theString$)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED  xit
'
	IF (INSTR(theString$, "\\")) THEN
		theString$ = XstBackStringToBinString$ (@theString$)
	END IF
'
	SELECT CASE TRUE
		CASE i486bin
			xpc = (xpc + 32) & 0xFFFFFFFFFFFFFFF0  '*cw* 230302-+
			litlen = LEN(theString$)
			litall = (litlen + 32) & 0xFFFFFFFFFFFFFFF0  '*cw* 230302-+
			litpad = litall - litlen
			litall$ = theString$ + NULL$(litpad)
			aaa = &litall$
			chunk = litall + 32
			XLONGAT(xpc) = chunk     : xpc = xpc + 8   ' size of chunk
			XLONGAT(xpc) = 0         : xpc = xpc + 8   ' unknown backlink
			XLONGAT(xpc) = litlen    : xpc = xpc + 8   ' length of string
			XLONGAT(xpc) = 0x80130001: xpc = xpc + 8   ' info word

			IFZ xit THEN EmitLabel (@theLabel$)
			i = 0
			DO WHILE i < litall
				XLONGAT(xpc) = XLONGAT(aaa)
				xpc = xpc + 4
				aaa = aaa + 4
				i = i + 4
			LOOP
		CASE i486asm                ' different in SCO vs Linux because of assembler differences
			litlen = LEN (theString$)
			asmString$ = BinStringToAsmString$ (@theString$)
			asmlen      = LEN (asmString$)
			pad         = ((litlen + 16) AND 0xFFFFFFFFFFFFFFF0) - litlen             '*cw* 230302-+
			chunk       = (litlen + 48) AND 0xFFFFFFFFFFFFFFF0                        '*cw* 230302-+
			e$          = ".quad  " + STRING (chunk) + ", 0, " + STRING (litlen)      ' gas ?
			EmitNull (e$ + ", 0x80130001")
			EmitLabel (@theLabel$)
'     IF (asmlen <= 128) THEN
'       EmitNull (".byte  \"" + asmString$ + "\"")                              ' spasm
				EmitNull (".string  \"" + asmString$ + "\"")                            ' gas ?
'     ELSE
'       offset = 1
'       DO
'         length = 32
'         IF (litlen < length) THEN length = litlen
'         piece$ = MID$ (theString$, offset, length)
'         asmString$ = BinStringToAsmString$ (@piece$)
'         EmitNull (".byte  \"" + asmString$ + "\"")                            ' spasm
'         EmitNull (".string  \"" + asmString$ + "\"")                          ' gas ?
'         litlen = litlen - length
'         offset = offset + length
'       LOOP WHILE litlen
'     END IF
'
' asshole Linux assembler puts a 0x00 after every ".string" string,
' which is a MAJOR pain in the butt.
'
' First of all it means you can't emit strings in several lines because
' the frigging 0x00 bytes get into the string and the last bytes in the
' strings are not included because the 0x00 bytes are part of the length.
' Second, the pad value is bad so it has to be adjusted below.
'
			DEC pad
			IF pad THEN EmitNull (".zero  " + STRING$(pad))
	END SELECT
END FUNCTION
'
'
' #########################
' #####  EmitText ()  #####
' #########################
'
FUNCTION  EmitText ()
	EXTERNAL /xxx/  i486bin, i486asm
'
	IF i486asm THEN
		EmitAsm (".text")
	END IF
END FUNCTION
'
'
' ##############################
' #####  EmitUserLabel ()  #####
' ##############################
'
' bin:  Put address of the label in labaddr[tt] where tt is the label
' token number.  The address is the current value of "xpc".  If labaddr[tt]
' has a value already, the label is a duplicate, which is an error.
'
' asm:  Emit user program (GOTO or GOSUB) label into ascii source .s file.
'
' EmitUserLabel() is for user labels, not internal labels (see EmitLabel()).
' User Labels are GOTO labels and GOSUB labels (also function() labels ???).
'
FUNCTION  EmitUserLabel (TOKEN labelToken)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED  labaddr[],  tab_lab$[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_DUP_LABEL
'
	SELECT CASE TRUE
		CASE i486bin: ltype = labelToken.tp.type
									SELECT CASE ltype
										CASE $$GOADDR, $$SUBADDR
										CASE ELSE: XcowlErr (340025): GOTO eeeCompiler
									END SELECT
									tt    = labelToken.tindex
									qpc   = labaddr[tt]
									IF qpc THEN XcowlErr (340029): GOTO eeeDupLabel
									labaddr[tt] = xpc
		CASE i486asm: ltype = labelToken.tp.type
									tt    = labelToken.tindex
									qpc   = labaddr[tt]
									IF qpc THEN XcowlErr (340034): GOTO eeeDupLabel
									labaddr[tt]   = $$TRUE
									tt$   = tab_lab$[tt]
									SELECT CASE ltype
										CASE $$GOADDR, $$SUBADDR : ' PRINT[ofile], tt$ + ":"
																								EmitAsm (tt$ + ":")
										CASE ELSE                : XcowlErr (340040): GOTO eeeCompiler
									END SELECT
	END SELECT
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeDupLabel:
	PRINT "Duplicate Label = "; a$
	XERROR = ERROR_DUP_LABEL
	EXIT FUNCTION
END FUNCTION
'
'
' #####################
' #####  Eval ()  #####
' #####################
'
FUNCTION  TOKEN Eval (result_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   new_op, new_data
	SHARED  ERROR_COMPILER,  XERROR
	SHARED  a0,  a0_type,  a1,  a1_type,  oos,  toes
	SHARED UBYTE oos[]
'
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	nn = new_data.tindex
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		INC toes
		SELECT CASE TRUE
			CASE (a0 = 0):  dd$ = "a0": a0 = toes: tr = $$RA0
			CASE (a1 = 0):  dd$ = "a1": a1 = toes: tr = $$RA1
			CASE (a1 > a0)
				Push ($$RA0, a0_type)
				dd$ = "a0": tr = $$RA0
				a0 = toes: a0_type = new_type
			CASE (a1 < a0)
				Push ($$RA1, a1_type)
				dd$ = "a1": tr = $$RA1
				a1 = toes: a1_type = new_type
			CASE ELSE: XcowlErr (350033): GOTO eeeCompiler
		END SELECT
		Move (tr, new_type, nn, new_type)
	ELSE
		SELECT CASE toes
			CASE a0:  dd$ = "a0"
			CASE a1:  dd$ = "a1"
		END SELECT
	END IF
	IF ((new_type = $$STRING) AND (oos[oos] = 'v')) THEN
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone." + dd$, $$rmk$+"535")
		oos[oos] = 'v'
	END IF
	result_type = new_type
	RETURN (new_op)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ########################
' #####  EvalArg ()  #####
' ########################
'
FUNCTION  TOKEN EvalArg (argNum, result_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   new_op, new_data
	SHARED  ERROR_COMPILER,  XERROR
	SHARED  a0,  a0_type,  a1,  a1_type,  oos,  toes
	SHARED UBYTE oos[]
'
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	nn = new_data.tindex
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		IF argNum THEN
'
			SELECT CASE argNum
				CASE 1    : tr = $$rdi
				CASE 2    : tr = $$rsi
				CASE 3    : tr = $$rdx
				CASE 4    : tr = $$rcx
				CASE 5    : tr = $$r8
				CASE 6    : tr = $$r9
				CASE ELSE : tr = 0           'push onto stack
			END SELECT
			Move (tr, new_type, nn, new_type)
'
		ELSE
			INC toes
			SELECT CASE TRUE
				CASE (a0 = 0):  dd$ = "a0": a0 = toes: tr = $$RA0
				CASE (a1 = 0):  dd$ = "a1": a1 = toes: tr = $$RA1
				CASE (a1 > a0)
					Push ($$RA0, a0_type)
					dd$ = "a0": tr = $$RA0
					a0 = toes: a0_type = new_type
				CASE (a1 < a0)
					Push ($$RA1, a1_type)
					dd$ = "a1": tr = $$RA1
					a1 = toes: a1_type = new_type
				CASE ELSE: XcowlErr (360047): GOTO eeeCompiler
			END SELECT
			Move (tr, new_type, nn, new_type)
		END IF

	ELSE
		SELECT CASE toes
			CASE a0:  dd$ = "a0"
			CASE a1:  dd$ = "a1"
		END SELECT
	END IF
	IF ((new_type = $$STRING) AND (oos[oos] = 'v')) THEN
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone." + dd$, $$rmk$+"535")
		oos[oos] = 'v'
	END IF
	result_type = new_type
	RETURN (new_op)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #############################
' #####  ExpressArray ()  #####
' #############################
'
FUNCTION  ExpressArray (TOKEN old_op, old_prec, TOKEN new_data, new_type, accArray, excess, theType, sourceReg)
	EXTERNAL /xxx/  i486asm,  i486bin,  checkBounds,  xpc
	TOKEN   token, atoken
	TOKEN   check, new_op, trash
	SHARED  TOKEN  falseToken
	SHARED  m_addr[],  m_addr$[],  m_reg[]
	SHARED  r_addr[],  r_addr$[]
	SHARED  typeSize[]
	SHARED  ERROR_COMPILER,  ERROR_REGADDR,  ERROR_SYNTAX
	SHARED  ERROR_TOO_MANY_ARGS,  ERROR_TYPE_MISMATCH
	SHARED  XERROR
	SHARED  a0,  a0_type,  a1,  a1_type
	SHARED  dim_array
	SHARED  redim_array
	SHARED  labelNumber
	SHARED  oos
	SHARED  toes,  tokenPtr,  elementType
	SHARED UBYTE  oos[],  shiftMulti[]
	STATIC  opcode[],  opcode$[]
'
'
' *****  define local constants  *****
'
	$ld           = 0
	$st           = 1
	$addrOp       = 2
	$handleOp     = 3
	$immediate    = 0
	$scaled       = 1
	$unscaled     = 2
	$lowestDim    = 0
	$higherDim    = 1
	$excessComma  = 2
	$addr         = 2
	$handle       = 3
	$imm          = 0    ' immediate
	$sca          = 1    ' scaled
	$uns          = 2    ' unscaled
	$lo           = 0
	$hi           = 1
	$ex           = 2
	$ro           = 6
	$rr           = 7
	$rs           = 8
	$regr0        = 12
	$regro        = 13
	$regrr        = 14
	$regrs        = 15
	$r0reg        = 17
	$roreg        = 18
	$rrreg        = 19
	$rsreg        = 20
'
	IFZ opcode[] THEN GOSUB InitArrays
'
	token = new_data
	hd    = token.tindex
	IF (hd > $$CONNUM) THEN
		IFZ m_addr$[hd] THEN AssignAddress (token)
		IF XERROR THEN EXIT FUNCTION
	END IF
'
	args        = 0
	kind        = token.tp.kind
	atoken      = token
	SELECT CASE kind
		CASE $$KIND_ARRAYS
					IF theType THEN
						aType     = theType
					ELSE
						aType     = TheType (token)
					END IF
					chkType     = aType
					xsize       = typeSize[aType]
					composite   = $$FALSE
					braceString = $$FALSE
					NextToken (@token)
					IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (370084): GOTO eeeSyntax
		CASE $$KIND_VARIABLES     ' a${n} style access (byte from string)
					IF (new_type  != $$STRING) THEN XcowlErr (370086): GOTO eeeCompiler
					aType     = $$UBYTE
					chkType   = $$STRING
					atoken    = token
					atoken.tp.kind = $$KIND_ARRAYS
					atoken.tp.type = $$UBYTE
					xsize     = 1
					NextToken (@token)
					IFF TokenMatch (@token, @#T_LBRACE) THEN XcowlErr (370094): GOTO eeeSyntax
					compositeType = $$FALSE
					braceString   = $$TRUE
					IF dim_array THEN XcowlErr (370097): GOTO eeeSyntax
		CASE ELSE
					PRINT "expressArrayKind"
					XcowlErr (3700100): GOTO eeeCompiler
	END SELECT
	IF (aType >= $$SCOMPLEX) THEN
		compositeType = $$TRUE
		eType         = $$COMPOSITE
	ELSE
		eType         = aType
	END IF
	excessComma       = $$FALSE
	IF dim_array THEN GOTO e_dim_array ELSE GOTO e_get_array
'
'
' *****************************
' *****  DIMENSION ARRAY  *****
' *****************************
'
e_dim_array:
	Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"536")
e_dim_array_loop:
	INC args
	temp_dim = dim_array: dim_array = $$FALSE
	new_op = Eval (@new_type)
	dim_array = temp_dim
	IF XERROR THEN EXIT FUNCTION
	SELECT CASE toes
		CASE 0:     Move ($$rdi, $$XLONG, hd, $$XLONG)
								Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_FreeArray", $$rmk$+"537")
								Move (atoken.tindex, $$XLONG, falseToken.tindex, $$XLONG)
								Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"539")
								RETURN ($$TRUE)
		CASE a0:    Conv ($$RA0, $$XLONG, $$RA0, new_type)
								sreg = $$RA0
		CASE a1:    Conv ($$RA1, $$XLONG, $$RA1, new_type)
								sreg = $$RA1
		CASE ELSE:  XcowlErr (3700134): GOTO eeeSyntax
	END SELECT
	Code ($$st, $$roreg, sreg, $$rsp, (32+8*(args-1)), $$XLONG, "", $$rmk$+"540")
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	IF TokenMatch (@new_op, @#T_COMMA) THEN
		PeekToken (@check)
		IFF TokenMatch (@check, @#T_RBRAK) THEN GOTO e_dim_array_loop   ' get next subscript
		NextToken (@new_op)
		excessComma = $$TRUE
	END IF
	IFF TokenMatch (@new_op, @#T_RBRAK) THEN XcowlErr (3700144): GOTO eeeSyntax
	IF (args > 8) THEN XcowlErr (3700145): GOTO eeeTooManyArgs
'
	IF excessComma THEN
		info  = 0x6000 OR aType         ' "higher dimension" bit = 1  (TRUE)
		xsize = typeSize[$$XLONG]       ' xsize = 4  (size of XLONG)
	ELSE
		info  = 0x4000 OR aType         ' "higher dimension" bit = 0  (FALSE)
	END IF
'
	IF redim_array THEN
		routine$ = $$ulpc$+"_RedimArray"
	ELSE
		routine$ = $$ulpc$+"_DimArray"
	END IF
	Move ($$rdi, $$XLONG, atoken.tindex, $$XLONG)                     'array address
	Code ($$st, $$roreg, $$rdi, $$rsp, 0, $$XLONG, "", $$rmk$+"541")
	Code ($$st, $$roimm, args, $$rsp, 8, $$XLONG, "", $$rmk$+"542")
	Code ($$st, $$roimm, (info << 16) + xsize, $$rsp, 16, $$XLONG, "", $$rmk$+"543")
	Code ($$st, $$roimm, 0, $$rsp, 24, $$XLONG, "", $$rmk$+"544")
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"545")
	Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"546")
	Move (hd, $$XLONG, $$R14, $$XLONG)
'
dimend:
	excess  = excessComma
	RETURN ($$TRUE)           ' done
'
'
' ******************************************
' *****  GET ARRAY ELEMENT OR ADDRESS  *****
' ******************************************
'
e_get_array:
	IF excess THEN
		SELECT CASE TRUE
			CASE (aType < $$SLONG):   aType = $$XLONG: xsize = 4
			CASE (aType = $$GIANT):   aType = $$XLONG: xsize = 4
			CASE (aType = $$DOUBLE):  aType = $$XLONG: xsize = 4
		END SELECT
	END IF
	SELECT CASE r_addr[hd]
		CASE 0, $$RA0, $$RA1: regarray = $$FALSE
		CASE ELSE:            regarray = $$TRUE
	END SELECT
	old_op_kind = old_op.tp.kind
	stringType  = $$FALSE
	IF (aType = $$STRING) THEN stringType = $$TRUE
	SELECT CASE TRUE
		CASE TokenMatch (@old_op, @#T_ADDR_OP):  actionKind  = $addrOp:   oldKindAddrOp = $$TRUE
		CASE TokenMatch (@old_op, @#T_HANDLE_OP): actionKind = $handleOp: oldKindAddrOp = $$TRUE
		CASE TokenMatch (@old_op, @#T_STORE_OP):  actionKind = $st:       oldKindAddrOp = $$FALSE
																								IF stringType THEN    oldKindAddrOp = $$TRUE
																								IF compositeType THEN oldKindAddrOp = $$TRUE
		CASE ELSE: actionKind = $ld: oldKindAddrOp = $$FALSE
	END SELECT
	PeekToken (@check)
	IF braceString THEN
		IF TokenMatch (@check, @#T_RBRACE) THEN XcowlErr (3700202): GOTO eeeSyntax   ' a${} not yet allowed
		GOTO not_null_array
	ELSE
		IFF TokenMatch (@check, @#T_RBRAK) THEN GOTO not_null_array
	END IF
'
a_null_array:
	null_array = $$TRUE
	NextToken (@trash)
	SELECT CASE actionKind
		CASE $addrOp:     old_op = #T_ZERO: old_prec = 0:   GOTO addr_null_array
		CASE $handleOp:                               GOTO handle_null_array
		CASE $st:                                     XcowlErr (3700214): GOTO eeeSyntax
		CASE ELSE:                                    GOTO null_array
	END SELECT
'
null_array:
addr_null_array:
	new_data  = atoken
	new_data.tp.kind  = $$KIND_VARIABLES
	new_type  = $$XLONG
	excess    = $$FALSE
	RETURN ($$FALSE)                ' GOTO express_op
'
' *****  &&array[]  *****
'
handle_null_array:
	IF r_addr[hd] THEN DEC tokenPtr: XcowlErr (3700229): GOTO eeeRegAddr
	tacc = OpenAccForType ($$XLONG)
	m$   = m_addr$[hd]
	mReg  = m_reg[hd]
	mAddr = m_addr[hd]
	IF mReg THEN
		Code ($$lea, $$regro, tacc, mReg, mAddr, $$XLONG, "", $$rmk$+"547")
	ELSE
		Code ($$mov, $$regimm, tacc, mAddr, 0, $$XLONG, m$, $$rmk$+"548")
	END IF
	new_data  = #T_ZERO
	new_type  = $$XLONG
	excess    = $$FALSE
	RETURN ($$FALSE)                ' GOTO express_op
'
'
' **************************************************
' *****  PROCESS ARRAY ARGUMENTS (subscripts)  *****
' **************************************************
'
not_null_array:
	doneArgs = $$FALSE
	DO
		test = 0: new_prec = 0: new_type = 0
		new_data  = #T_ZERO
		new_op = #T_ZERO
		Expresso (@test, @new_op, @new_prec, @new_data, @new_type)
		IF XERROR THEN EXIT FUNCTION
		IF (new_type > $$XLONG) THEN DEC tokenPtr: XcowlErr (3700257): GOTO eeeTypeMismatch
		new_type        = $$XLONG
		stackString     = $$FALSE
		fakeExcessComma = $$FALSE
'   aType           = eType
		SELECT CASE TRUE
			CASE TokenMatch (@new_op, @#T_RBRAK)
						esize = xsize
						doneArgs = $$TRUE
						dimensionKind = $lowestDim
						IF (aType = $$STRING) THEN
							IF (actionKind = $ld) THEN INC oos: oos[oos] = 'v'
							IF excess THEN
								fakeExcessComma = $$TRUE
								dimensionKind = $excessComma
								excessComma = $$TRUE
								aType = $$XLONG
							END IF
						END IF
						IF braceString THEN XcowlErr (3700276): GOTO eeeSyntax
			CASE TokenMatch (@new_op, @#T_RBRACE)
						esize = 1
						doneArgs = $$TRUE
						dimensionKind = $lowestDim
						IFZ braceString THEN XcowlErr (3700281): GOTO eeeSyntax
						IF (accArray = 's') THEN stackString = $$TRUE
			CASE TokenMatch (@new_op, @#T_COMMA):
						IF braceString THEN XcowlErr (3700284): GOTO eeeSyntax   ' a${n,...} (later!)
						PeekToken (@check)
						IF TokenMatch (@check, @#T_RBRAK) THEN
							doneArgs          = $$TRUE
							dimensionKind     = $excessComma
							NextToken (@new_op)
							excessComma       = $$TRUE
							aType             = $$XLONG
						ELSE
							doneArgs          = $$FALSE
							dimensionKind     = $higherDim
						END IF
						esize               = 8
			CASE ELSE
						XcowlErr (3700298): GOTO eeeSyntax
		END SELECT
'
' new_data is a variable or literal or constant (not evaluated expression)
'
		IFF TokenMatch (@new_data, @#T_ZERO) THEN
			nn = new_data.tindex
'
' array is in a register and this is leftmost dimension
'
			IF regarray THEN
				acc   = OpenAccForType ($$XLONG)
				dreg  = acc
				rr    = r_addr[nn]
				SELECT CASE TRUE
					CASE (rr AND (rr < $$IMM16))
						arsub       = r_addr[nn]
						araddr      = r_addr[hd]
						elementKind = $scaled
						IF (eSize = 1) THEN elementKind = $unscaled
						IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
					CASE (rr AND (rr <= $$CONNUM))
						element     = XLONG (r_addr$[nn])
						offset      = element * esize
						IF (offset <= 65535) THEN
							offset$     = STRING(offset)
							arsub       = offset
							araddr      = r_addr[hd]
							element$    = STRING(element)
							elementKind = $immediate
						ELSE
							Move (dreg, new_type, new_data.tindex, new_type)
							arsub       = dreg
							araddr      = r_addr[hd]
							elementKind = $scaled
							IF (esize = 1) THEN elementKind = $unscaled
							IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
						END IF
					CASE ELSE
						Move (acc, new_type, new_data.tindex, new_type)
						arsub       = dreg
						araddr      = r_addr[hd]
						elementKind = $scaled
						IF (esize = 1) THEN elementKind = $unscaled
						IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
				END SELECT
			ELSE
'
' array is not in a register, or not leftmost dimension
'
				IF (args OR accArray) THEN
					acc     = Top()
					dreg    = acc
					araddr  = dreg
					rr      = r_addr[nn]
					SELECT CASE TRUE
						CASE (rr AND (rr < $$IMM16))
							arsub       = r_addr[nn]
							elementKind = $scaled
							IF (esize = 1) THEN elementKind = $unscaled
							IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
						CASE (rr AND (rr <= $$CONNUM))
							element     = XLONG (r_addr$[nn])
							offset      = element * esize
							IF (offset <= 65535) THEN
								offset$     = STRING(offset)
								arsub       = offset
								element$    = STRING(element)
								elementKind = $immediate
							ELSE
								Move (acc + 1, new_type, nn, new_type)
								arsub       = acc + 1
								elementKind = $scaled
								IF (esize = 1) THEN elementKind = $unscaled
								IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
							END IF
						CASE ELSE
							Move (acc + 1, new_type, nn, new_type)
							arsub       = acc + 1
							elementKind = $scaled
							IF (esize = 1) THEN elementKind = $unscaled
							IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
					END SELECT
				ELSE
					acc   = OpenAccForType ($$XLONG)
					dreg  = acc
					rr    = r_addr[nn]
					SELECT CASE TRUE
						CASE (rr AND (rr < $$IMM16))
							Move (acc + 1, $$XLONG, atoken.tindex, $$XLONG)
							araddr      = acc + 1
							arsub       = r_addr[nn]
							elementKind = $scaled
							IF (esize = 1) THEN elementKind = $unscaled
							IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
						CASE (rr AND (rr <= $$CONNUM))
							element     = XLONG (r_addr$[nn])
							offset      = element * esize
							IF (offset <= 65535) THEN
								Move (acc + 1, $$XLONG, atoken.tindex, $$XLONG)
								araddr      = acc + 1
								offset$     = STRING(offset)
								arsub       = offset
								element$    = STRING(element)
								elementKind = $immediate
							ELSE
								Move (acc, new_type, new_data.tindex, new_type)
								Move (acc + 1, $$XLONG, atoken.tindex, $$XLONG)
								araddr      = acc + 1
								arsub       = dreg
								elementKind = $scaled
								IF (esize = 1) THEN elementKind = $unscaled
								IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
							END IF
						CASE ELSE
							Move (acc, new_type, new_data.tindex, new_type)
							Move (acc + 1, $$XLONG, atoken.tindex, $$XLONG)
							araddr        = acc + 1
							arsub         = dreg
							elementKind   = $scaled
							IF (esize = 1) THEN elementKind = $unscaled
							IF (compositeType AND (dimensionKind = lowestDim)) THEN GOSUB AccessComposite
					END SELECT
				END IF
			END IF
		ELSE
'
' new_data is result of expression evaluation, not variable, literal, constant
'
			acc   = Top()
			dreg  = acc
			arsub = dreg
			IF regarray THEN
				araddr      = r_addr[hd]
				elementKind = $scaled
				IF (esize = 1) THEN elementKind = $unscaled
				IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
			ELSE
				IF (args OR accArray) THEN
					SELECT CASE acc
						CASE $$RA0: IFZ a1 THEN Pop ($$RA1, $$XLONG)
												araddr  = $$RA1
						CASE $$RA1: IFZ a0 THEN Pop ($$RA0, $$XLONG)
												araddr  = $$RA0
						CASE ELSE: XcowlErr (3700442): GOTO eeeCompiler
					END SELECT
					DEC toes
					dreg        = $$RA0
					elementKind = $scaled
					IF (esize = 1) THEN elementKind = $unscaled
					a1 = 0: a1_type = 0: a0 = toes: a0_type = $$XLONG
					IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
				ELSE
					araddr = acc + 1
					elementKind = $scaled
					IF (esize = 1) THEN elementKind = $unscaled
					Move (acc + 1, $$XLONG, atoken.tindex, $$XLONG)
					IF (compositeType AND (dimensionKind = $lowestDim)) THEN GOSUB AccessComposite
				END IF
			END IF
		END IF
'
' if bounds checking is enabled, emit bounds checking code
'
		IF checkBounds THEN
			IF (dimensionKind != $lowestDim) THEN
				needHigherDim = $$TRUE
			ELSE
				needHigherDim = $$FALSE
			END IF
			IF fakeExcessComma THEN needHigherDim = NOT needHigherDim
			IFZ needHigherDim THEN
				INC labelNumber: d00$ = $$ulpc$ + HEX$(labelNumber, 4)
			END IF
			INC labelNumber: d0$ = $$ulpc$ + HEX$(labelNumber, 4)
			INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
			INC labelNumber: d2$ = $$ulpc$ + HEX$(labelNumber, 4)
			INC labelNumber: d3$ = $$ulpc$ + HEX$(labelNumber, 4)
			Code ($$or, $$regreg, araddr, araddr, 0, $$XLONG, "", $$rmk$+"549")
			Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"550")
			Code ($$ld, $$regro, $$rsi, araddr, -16, $$XLONG, "", $$rmk$+"551")
			Code ($$ld, $$regro, $$rdi, araddr, -8, $$XLONG, "", $$rmk$+"552")
			IF needHigherDim THEN
				Code ($$test, $$regimm, $$rdi, (1 << 29), 0, $$XLONG, "", $$rmk$+"553")
				Code ($$jnz, $$rel, 0, 0, 0, 0, d0$, $$rmk$+"554")
				Code ($$mov, $$regreg, dreg, araddr, 0, $$XLONG, "", $$rmk$+"556")
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_UnexpectedLowestDim", $$rmk$+"557")
				Code ($$jmp, $$rel, 0, 0, 0, 0, d3$, $$rmk$+"558")
				EmitLabel (@d0$)
			ELSE
				Code ($$test, $$regimm, $$rdi, (1 << 29), 0, $$XLONG, "", $$rmk$+"559")
				Code ($$jz, $$rel, 0, 0, 0, 0, d00$, $$rmk$+"561")
				Code ($$mov, $$regreg, dreg, araddr, 0, $$XLONG, "", $$rmk$+"563")
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_UnexpectedHigherDim", $$rmk$+"564")
				Code ($$jmp, $$rel, 0, 0, 0, 0, d3$, $$rmk$+"565")
				EmitLabel (@d00$)
				IF (chkType <= $$DCOMPLEX) THEN
					Code ($$cmp, $$roimm, chkType, araddr, -6, $$UBYTE, "", $$rmk$+"566")
					Code ($$jz, $$rel, 0, 0, 0, 0, d0$, $$rmk$+"567")
					Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_ArrayInvalidType", $$rmk$+"568")
					EmitLabel (@d0$)
				END IF
			END IF
			IFZ braceString THEN
				Code ($$dec, $$reg, $$rsi, 0, 0, $$XLONG, "", $$rmk$+"569")
			END IF
			SELECT CASE elementKind
				CASE $imm
							Code ($$cmp, $$regimm, $$rsi, element, 0, $$XLONG, "", $$rmk$+"570")
				CASE $sca
							Code ($$cmp, $$regreg, $$rsi, arsub, 0, $$XLONG, "", $$rmk$+"571")
				CASE $uns
							Code ($$and, $$regimm, $$rdi, 0xFFFF, 0, $$XLONG, "", $$rmk$+"572")
							Code ($$imul, $$regreg, $$rsi, $$rdi, 0, $$XLONG, "", $$rmk$+"573")
							Code ($$cmp, $$regreg, $$rsi, arsub, 0, $$XLONG, "", $$rmk$+"574")
			END SELECT
			Code ($$jae, $$rel, 0, 0, 0, 0, d2$, $$rmk$+"575")
			EmitLabel (@d1$)
			Code ($$mov, $$regreg, dreg, araddr, 0, $$XLONG, "", $$rmk$+"577")
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_OutOfBounds", $$rmk$+"578")
			Code ($$jmp, $$rel, 0, 0, 0, 0, d3$, $$rmk$+"579")
			EmitLabel (@d2$)
		END IF
'
		IF stackString THEN
			Code ($$mov, $$regreg, $$rdi, araddr, 0, $$XLONG, "", $$rmk$+"580")
		END IF
		code  = opcode[dimensionKind, elementKind, actionKind, eType]
		mode  = code AND 0x00FF
		code  = code {$$WORD1}
		IFZ code THEN XcowlErr (3700528): GOTO eeeSyntax
		IF dimensionKind THEN xType = $$XLONG ELSE xType = eType          '*cw* 230305-+
'		xType = $$XLONG                                                   '*cw* 230305+-
		Code (code, mode, dreg, araddr, arsub, xType, "", $$rmk$+"581")
		IF checkBounds THEN EmitLabel (@d3$)
		regarray = $$FALSE
		INC args
	LOOP UNTIL (doneArgs)
'
'
' *****  DONE processing subscripts  *****
'
	IF stackString THEN
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"582")
	END IF
	IF accArray THEN DEC oos
	acc = Top()
	elementType = aType
	IF (aType < $$SLONG) THEN aType = $$SLONG
	IF oldKindAddrOp THEN aType = $$XLONG
	SELECT CASE acc
		CASE $$RA0 : a0_type = aType
		CASE $$RA1 : a1_type = aType
		CASE ELSE  : XcowlErr (3700550): GOTO eeeCompiler
	END SELECT
	excess      = excessComma
	new_type    = aType
	new_data    = #T_ZERO
	RETURN ($$FALSE)
'
' *****  Access Composite Element in Array  *****
'
SUB AccessComposite
	IF (esize <= 1024) THEN eshift = shiftMulti[esize]
	IF eshift THEN
		Code ($$sll, $$regimm, arsub, eshift, 0, $$XLONG, "", $$rmk$+"583")
	ELSE
		Code ($$imul, $$regimm, arsub, esize, 0, $$XLONG, "", $$rmk$+"584")
	END IF
	elementKind = $unscaled
END SUB
'
'
'
' ****************************
' *****  SUB InitArrays  *****
' ****************************
'
SUB InitArrays
	DIM opcode[2, 2, 3, 31]
	DIM opcode$[2, 2, 3, 31]
'
'
' ****************************************
' ****************************************
' *****  dimensionKind = $lowestDim  *****
' ****************************************
' ****************************************
'
' ***********************
' *****  immediate  *****  (offset = element * size)
' ***********************
'
	opcode[$lo, $imm, $ld, $$SBYTE]       = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$UBYTE]       = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$SSHORT]      = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$USHORT]      = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$SLONG]       = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$ULONG]       = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$XLONG]       = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$GOADDR]      = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$SUBADDR]     = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$FUNCADDR]    = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$GIANT]       = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$SINGLE]      = $$ufld + $ro
	opcode[$lo, $imm, $ld, $$DOUBLE]      = $$ufld + $ro
	opcode[$lo, $imm, $ld, $$STRING]      = $$uld  + $regro
	opcode[$lo, $imm, $ld, $$COMPOSITE]   = $$ulda + $regro
'
	opcode[$lo, $imm, $st, $$SBYTE]       = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$UBYTE]       = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$SSHORT]      = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$USHORT]      = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$SLONG]       = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$ULONG]       = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$XLONG]       = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$GOADDR]      = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$SUBADDR]     = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$FUNCADDR]    = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$GIANT]       = $$ust   + $roreg
	opcode[$lo, $imm, $st, $$SINGLE]      = $$ufstp + $ro
	opcode[$lo, $imm, $st, $$DOUBLE]      = $$ufstp + $ro
	opcode[$lo, $imm, $st, $$STRING]      = $$ust  + $roreg
	opcode[$lo, $imm, $st, $$COMPOSITE]   = $$ulda + $regro
'
	opcode[$lo, $imm, $addr, $$SBYTE]     = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$UBYTE]     = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$SSHORT]    = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$USHORT]    = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$SLONG]     = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$ULONG]     = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$XLONG]     = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$GOADDR]    = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$SUBADDR]   = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$FUNCADDR]  = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$GIANT]     = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$SINGLE]    = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$DOUBLE]    = $$ulda + $regro
	opcode[$lo, $imm, $addr, $$STRING]    = $$uld  + $regro
	opcode[$lo, $imm, $addr, $$COMPOSITE] = $$ulda + $regro
'
	opcode[$lo, $imm, $handle, $$STRING]  = $$ulda + $regro
'
'
' ********************
' *****  scaled  *****  (size = 1, 2, 4, 8 bytes)
' ********************
'
	opcode[$lo, $sca, $ld, $$SBYTE]       = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$UBYTE]       = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$SSHORT]      = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$USHORT]      = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$SLONG]       = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$ULONG]       = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$XLONG]       = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$GOADDR]      = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$SUBADDR]     = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$FUNCADDR]    = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$GIANT]       = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$SINGLE]      = $$ufld + $rs
	opcode[$lo, $sca, $ld, $$DOUBLE]      = $$ufld + $rs
	opcode[$lo, $sca, $ld, $$STRING]      = $$uld + $regrs
	opcode[$lo, $sca, $ld, $$COMPOSITE]   = $$uld + $regrs
'
	opcode[$lo, $sca, $st, $$SBYTE]       = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$UBYTE]       = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$SSHORT]      = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$USHORT]      = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$SLONG]       = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$ULONG]       = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$XLONG]       = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$GOADDR]      = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$SUBADDR]     = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$FUNCADDR]    = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$GIANT]       = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$SINGLE]      = $$ufstp + $rs
	opcode[$lo, $sca, $st, $$DOUBLE]      = $$ufstp + $rs
	opcode[$lo, $sca, $st, $$STRING]      = $$ust   + $rsreg
	opcode[$lo, $sca, $st, $$COMPOSITE]   = $$ulda + $regrs
'
	opcode[$lo, $sca, $addr, $$SBYTE]     = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$UBYTE]     = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$SSHORT]    = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$USHORT]    = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$SLONG]     = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$ULONG]     = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$XLONG]     = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$GOADDR]    = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$SUBADDR]   = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$FUNCADDR]  = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$GIANT]     = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$SINGLE]    = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$DOUBLE]    = $$ulda + $regrs
	opcode[$lo, $sca, $addr, $$STRING]    = $$uld + $regrs
	opcode[$lo, $sca, $addr, $$COMPOSITE] = $$ulda + $regrs
'
	opcode[$lo, $sca, $handle, $$STRING]  = $$ulda + $regrs
'
'
' **********************
' *****  unscaled  *****  (size not 1, 2, 4, 8 bytes)  *****
' **********************
'
	opcode[$lo, $uns, $ld, $$SBYTE]       = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$UBYTE]       = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$SSHORT]      = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$USHORT]      = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$SLONG]       = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$ULONG]       = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$XLONG]       = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$GOADDR]      = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$SUBADDR]     = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$FUNCADDR]    = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$GIANT]       = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$SINGLE]      = $$ufld + $rr
	opcode[$lo, $uns, $ld, $$DOUBLE]      = $$ufld + $rr
	opcode[$lo, $uns, $ld, $$STRING]      = $$uld  + $regrr
	opcode[$lo, $uns, $ld, $$COMPOSITE]   = $$ulda + $regrr
'
	opcode[$lo, $uns, $st, $$SBYTE]       = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$UBYTE]       = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$SSHORT]      = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$USHORT]      = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$SLONG]       = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$ULONG]       = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$XLONG]       = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$GOADDR]      = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$SUBADDR]     = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$FUNCADDR]    = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$GIANT]       = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$SINGLE]      = $$ufstp + $rr
	opcode[$lo, $uns, $st, $$DOUBLE]      = $$ufstp + $rr
	opcode[$lo, $uns, $st, $$STRING]      = $$ust   + $rrreg
	opcode[$lo, $uns, $st, $$COMPOSITE]   = $$ulda  + $regrr
'
	opcode[$lo, $uns, $addr, $$SBYTE]     = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$UBYTE]     = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$SSHORT]    = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$USHORT]    = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$SLONG]     = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$ULONG]     = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$XLONG]     = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$GOADDR]    = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$SUBADDR]   = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$FUNCADDR]  = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$GIANT]     = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$SINGLE]    = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$DOUBLE]    = $$ulda + $regrr
	opcode[$lo, $uns, $addr, $$STRING]    = $$uld  + $regrr
	opcode[$lo, $uns, $addr, $$COMPOSITE] = $$ulda + $regrr
'
	opcode[$lo, $uns, $handle, $$STRING]  = $$ulda + $regrr
'
'
' ****************************************
' ****************************************
' *****  dimensionKind = $higherDim  *****
' ****************************************
' ****************************************
'
' ***********************
' *****  immediate  *****  (offset = ele * size)
' ***********************
'
	opcode[$hi, $imm, $ld, $$SBYTE]       = $$uld + $regro
	opcode[$hi, $imm, $ld, $$UBYTE]       = $$uld + $regro
	opcode[$hi, $imm, $ld, $$SSHORT]      = $$uld + $regro
	opcode[$hi, $imm, $ld, $$USHORT]      = $$uld + $regro
	opcode[$hi, $imm, $ld, $$SLONG]       = $$uld + $regro
	opcode[$hi, $imm, $ld, $$ULONG]       = $$uld + $regro
	opcode[$hi, $imm, $ld, $$XLONG]       = $$uld + $regro
	opcode[$hi, $imm, $ld, $$GOADDR]      = $$uld + $regro
	opcode[$hi, $imm, $ld, $$SUBADDR]     = $$uld + $regro
	opcode[$hi, $imm, $ld, $$FUNCADDR]    = $$uld + $regro
	opcode[$hi, $imm, $ld, $$GIANT]       = $$uld + $regro
	opcode[$hi, $imm, $ld, $$SINGLE]      = $$uld + $regro
	opcode[$hi, $imm, $ld, $$DOUBLE]      = $$uld + $regro
	opcode[$hi, $imm, $ld, $$STRING]      = $$uld + $regro
	opcode[$hi, $imm, $ld, $$COMPOSITE]   = $$uld + $regro
'
	opcode[$hi, $imm, $st, $$SBYTE]       = $$uld + $regro
	opcode[$hi, $imm, $st, $$UBYTE]       = $$uld + $regro
	opcode[$hi, $imm, $st, $$SSHORT]      = $$uld + $regro
	opcode[$hi, $imm, $st, $$USHORT]      = $$uld + $regro
	opcode[$hi, $imm, $st, $$SLONG]       = $$uld + $regro
	opcode[$hi, $imm, $st, $$ULONG]       = $$uld + $regro
	opcode[$hi, $imm, $st, $$XLONG]       = $$uld + $regro
	opcode[$hi, $imm, $st, $$GOADDR]      = $$uld + $regro
	opcode[$hi, $imm, $st, $$SUBADDR]     = $$uld + $regro
	opcode[$hi, $imm, $st, $$FUNCADDR]    = $$uld + $regro
	opcode[$hi, $imm, $st, $$GIANT]       = $$uld + $regro
	opcode[$hi, $imm, $st, $$SINGLE]      = $$uld + $regro
	opcode[$hi, $imm, $st, $$DOUBLE]      = $$uld + $regro
	opcode[$hi, $imm, $st, $$STRING]      = $$uld + $regro
	opcode[$hi, $imm, $st, $$COMPOSITE]   = $$uld + $regro
'
	opcode[$hi, $imm, $addr, $$SBYTE]     = $$uld + $regro
	opcode[$hi, $imm, $addr, $$UBYTE]     = $$uld + $regro
	opcode[$hi, $imm, $addr, $$SSHORT]    = $$uld + $regro
	opcode[$hi, $imm, $addr, $$USHORT]    = $$uld + $regro
	opcode[$hi, $imm, $addr, $$SLONG]     = $$uld + $regro
	opcode[$hi, $imm, $addr, $$ULONG]     = $$uld + $regro
	opcode[$hi, $imm, $addr, $$XLONG]     = $$uld + $regro
	opcode[$hi, $imm, $addr, $$GOADDR]    = $$uld + $regro
	opcode[$hi, $imm, $addr, $$SUBADDR]   = $$uld + $regro
	opcode[$hi, $imm, $addr, $$FUNCADDR]  = $$uld + $regro
	opcode[$hi, $imm, $addr, $$GIANT]     = $$uld + $regro
	opcode[$hi, $imm, $addr, $$SINGLE]    = $$uld + $regro
	opcode[$hi, $imm, $addr, $$DOUBLE]    = $$uld + $regro
	opcode[$hi, $imm, $addr, $$STRING]    = $$uld + $regro
	opcode[$hi, $imm, $addr, $$COMPOSITE] = $$uld + $regro
'
	opcode[$hi, $imm, $handle, $$STRING]   = $$uld + $regro
'
'
' ********************
' *****  scaled  *****  (size = 1, 2, 4, 8 bytes)
' ********************
'
	opcode[$hi, $sca, $ld, $$SBYTE]       = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$UBYTE]       = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$SSHORT]      = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$USHORT]      = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$SLONG]       = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$ULONG]       = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$XLONG]       = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$GOADDR]      = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$SUBADDR]     = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$FUNCADDR]    = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$GIANT]       = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$SINGLE]      = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$DOUBLE]      = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$STRING]      = $$uld + $regrs
	opcode[$hi, $sca, $ld, $$COMPOSITE]   = $$uld + $regrs
'
	opcode[$hi, $sca, $st, $$SBYTE]       = $$uld + $regrs
	opcode[$hi, $sca, $st, $$UBYTE]       = $$uld + $regrs
	opcode[$hi, $sca, $st, $$SSHORT]      = $$uld + $regrs
	opcode[$hi, $sca, $st, $$USHORT]      = $$uld + $regrs
	opcode[$hi, $sca, $st, $$SLONG]       = $$uld + $regrs
	opcode[$hi, $sca, $st, $$ULONG]       = $$uld + $regrs
	opcode[$hi, $sca, $st, $$XLONG]       = $$uld + $regrs
	opcode[$hi, $sca, $st, $$GOADDR]      = $$uld + $regrs
	opcode[$hi, $sca, $st, $$SUBADDR]     = $$uld + $regrs
	opcode[$hi, $sca, $st, $$FUNCADDR]    = $$uld + $regrs
	opcode[$hi, $sca, $st, $$GIANT]       = $$uld + $regrs
	opcode[$hi, $sca, $st, $$SINGLE]      = $$uld + $regrs
	opcode[$hi, $sca, $st, $$DOUBLE]      = $$uld + $regrs
	opcode[$hi, $sca, $st, $$STRING]      = $$uld + $regrs
	opcode[$hi, $sca, $st, $$COMPOSITE]   = $$uld + $regrs
'
	opcode[$hi, $sca, $addr, $$SBYTE]     = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$UBYTE]     = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$SSHORT]    = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$USHORT]    = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$SLONG]     = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$ULONG]     = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$XLONG]     = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$GOADDR]    = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$SUBADDR]   = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$FUNCADDR]  = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$GIANT]     = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$SINGLE]    = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$DOUBLE]    = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$STRING]    = $$uld + $regrs
	opcode[$hi, $sca, $addr, $$COMPOSITE] = $$uld + $regrs
'
	opcode[$hi, $sca, $handle, $$STRING]    = $$uld + $regrs
'
'
' **********************
' *****  unscaled  *****  (size not 1, 2, 4, 8 bytes)  *****
' **********************
'
	opcode[$hi, $uns, $ld, $$SBYTE]       = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$UBYTE]       = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$SSHORT]      = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$USHORT]      = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$SLONG]       = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$ULONG]       = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$XLONG]       = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$GOADDR]      = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$SUBADDR]     = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$FUNCADDR]    = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$GIANT]       = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$SINGLE]      = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$DOUBLE]      = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$STRING]      = $$uld + $regrr
	opcode[$hi, $uns, $ld, $$COMPOSITE]   = $$uld + $regrr
'
	opcode[$hi, $uns, $st, $$SBYTE]       = $$uld + $regrr
	opcode[$hi, $uns, $st, $$UBYTE]       = $$uld + $regrr
	opcode[$hi, $uns, $st, $$SSHORT]      = $$uld + $regrr
	opcode[$hi, $uns, $st, $$USHORT]      = $$uld + $regrr
	opcode[$hi, $uns, $st, $$SLONG]       = $$uld + $regrr
	opcode[$hi, $uns, $st, $$ULONG]       = $$uld + $regrr
	opcode[$hi, $uns, $st, $$XLONG]       = $$uld + $regrr
	opcode[$hi, $uns, $st, $$GOADDR]      = $$uld + $regrr
	opcode[$hi, $uns, $st, $$SUBADDR]     = $$uld + $regrr
	opcode[$hi, $uns, $st, $$FUNCADDR]    = $$uld + $regrr
	opcode[$hi, $uns, $st, $$GIANT]       = $$uld + $regrr
	opcode[$hi, $uns, $st, $$SINGLE]      = $$uld + $regrr
	opcode[$hi, $uns, $st, $$DOUBLE]      = $$uld + $regrr
	opcode[$hi, $uns, $st, $$STRING]      = $$uld + $regrr
	opcode[$hi, $uns, $st, $$COMPOSITE]   = $$uld + $regrr
'
	opcode[$hi, $uns, $addr, $$SBYTE]     = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$UBYTE]     = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$SSHORT]    = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$USHORT]    = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$SLONG]     = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$ULONG]     = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$XLONG]     = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$GOADDR]    = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$SUBADDR]   = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$FUNCADDR]  = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$GIANT]     = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$SINGLE]    = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$DOUBLE]    = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$STRING]    = $$uld + $regrr
	opcode[$hi, $uns, $addr, $$COMPOSITE] = $$uld + $regrr
'
	opcode[$hi, $uns, $handle, $$STRING]   = $$uld + $regrr
'
'
' ******************************************
' ******************************************
' *****  dimensionKind = $excessComma  *****
' ******************************************
' ******************************************
'
' ***********************
' *****  immediate  *****  (offset = ele * size)
' ***********************
'
	opcode[$ex, $imm, $ld, $$SBYTE]       = $$uld + $regro
	opcode[$ex, $imm, $ld, $$UBYTE]       = $$uld + $regro
	opcode[$ex, $imm, $ld, $$SSHORT]      = $$uld + $regro
	opcode[$ex, $imm, $ld, $$USHORT]      = $$uld + $regro
	opcode[$ex, $imm, $ld, $$SLONG]       = $$uld + $regro
	opcode[$ex, $imm, $ld, $$ULONG]       = $$uld + $regro
	opcode[$ex, $imm, $ld, $$XLONG]       = $$uld + $regro
	opcode[$ex, $imm, $ld, $$GOADDR]      = $$uld + $regro
	opcode[$ex, $imm, $ld, $$SUBADDR]     = $$uld + $regro
	opcode[$ex, $imm, $ld, $$FUNCADDR]    = $$uld + $regro
	opcode[$ex, $imm, $ld, $$GIANT]       = $$uld + $regro
	opcode[$ex, $imm, $ld, $$SINGLE]      = $$uld + $regro
	opcode[$ex, $imm, $ld, $$DOUBLE]      = $$uld + $regro
	opcode[$ex, $imm, $ld, $$STRING]      = $$uld + $regro
	opcode[$ex, $imm, $ld, $$COMPOSITE]   = $$uld + $regro
'
	opcode[$ex, $imm, $st, $$SBYTE]       = $$ust + $roreg
	opcode[$ex, $imm, $st, $$UBYTE]       = $$ust + $roreg
	opcode[$ex, $imm, $st, $$SSHORT]      = $$ust + $roreg
	opcode[$ex, $imm, $st, $$USHORT]      = $$ust + $roreg
	opcode[$ex, $imm, $st, $$SLONG]       = $$ust + $roreg
	opcode[$ex, $imm, $st, $$ULONG]       = $$ust + $roreg
	opcode[$ex, $imm, $st, $$XLONG]       = $$ust + $roreg
	opcode[$ex, $imm, $st, $$GOADDR]      = $$ust + $roreg
	opcode[$ex, $imm, $st, $$SUBADDR]     = $$ust + $roreg
	opcode[$ex, $imm, $st, $$FUNCADDR]    = $$ust + $roreg
	opcode[$ex, $imm, $st, $$GIANT]       = $$ust + $roreg
	opcode[$ex, $imm, $st, $$SINGLE]      = $$ust + $roreg
	opcode[$ex, $imm, $st, $$DOUBLE]      = $$ust + $roreg
	opcode[$ex, $imm, $st, $$STRING]      = $$ust + $roreg
	opcode[$ex, $imm, $st, $$COMPOSITE]   = $$ust + $roreg
'
	opcode[$ex, $imm, $addr, $$SBYTE]     = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$UBYTE]     = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$SSHORT]    = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$USHORT]    = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$SLONG]     = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$ULONG]     = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$XLONG]     = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$GOADDR]    = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$SUBADDR]   = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$FUNCADDR]  = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$GIANT]     = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$SINGLE]    = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$DOUBLE]    = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$STRING]    = $$ulda + $regro
	opcode[$ex, $imm, $addr, $$COMPOSITE] = $$ulda + $regro
'
'
' ********************
' *****  scaled  *****  (size = 1, 2, 4, 8 bytes)
' ********************
'
	opcode[$ex, $sca, $ld, $$SBYTE]       = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$UBYTE]       = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$SSHORT]      = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$USHORT]      = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$SLONG]       = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$ULONG]       = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$XLONG]       = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$GOADDR]      = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$SUBADDR]     = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$FUNCADDR]    = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$GIANT]       = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$SINGLE]      = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$DOUBLE]      = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$STRING]      = $$uld + $regrs
	opcode[$ex, $sca, $ld, $$COMPOSITE]   = $$uld + $regrs
'
	opcode[$ex, $sca, $st, $$SBYTE]       = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$UBYTE]       = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$SSHORT]      = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$USHORT]      = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$SLONG]       = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$ULONG]       = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$XLONG]       = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$GOADDR]      = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$SUBADDR]     = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$FUNCADDR]    = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$GIANT]       = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$SINGLE]      = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$DOUBLE]      = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$STRING]      = $$ust + $rsreg
	opcode[$ex, $sca, $st, $$COMPOSITE]   = $$ust  + $rsreg
'
	opcode[$ex, $sca, $addr, $$SBYTE]     = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$UBYTE]     = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$SSHORT]    = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$USHORT]    = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$SLONG]     = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$ULONG]     = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$XLONG]     = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$GOADDR]    = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$SUBADDR]   = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$FUNCADDR]  = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$GIANT]     = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$SINGLE]    = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$DOUBLE]    = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$STRING]    = $$ulda + $regrs
	opcode[$ex, $sca, $addr, $$COMPOSITE] = $$ulda + $regrs
'
'
' **********************
' *****  unscaled  *****  (size not 1, 2, 4, 8 bytes)  *****
' **********************
'
	opcode[$ex, $uns, $ld, $$SBYTE]       = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$UBYTE]       = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$SSHORT]      = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$USHORT]      = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$SLONG]       = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$ULONG]       = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$XLONG]       = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$GOADDR]      = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$SUBADDR]     = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$FUNCADDR]    = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$GIANT]       = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$SINGLE]      = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$DOUBLE]      = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$STRING]      = $$uld + $regrr
	opcode[$ex, $uns, $ld, $$COMPOSITE]   = $$uld + $regrr
'
	opcode[$ex, $uns, $st, $$SBYTE]       = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$UBYTE]       = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$SSHORT]      = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$USHORT]      = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$SLONG]       = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$ULONG]       = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$XLONG]       = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$GOADDR]      = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$SUBADDR]     = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$FUNCADDR]    = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$GIANT]       = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$SINGLE]      = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$DOUBLE]      = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$STRING]      = $$ust + $rrreg
	opcode[$ex, $uns, $st, $$COMPOSITE]   = $$ust + $rrreg
'
	opcode[$ex, $uns, $addr, $$SBYTE]     = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$UBYTE]     = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$SSHORT]    = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$USHORT]    = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$SLONG]     = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$ULONG]     = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$XLONG]     = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$GOADDR]    = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$SUBADDR]   = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$FUNCADDR]  = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$GIANT]     = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$SINGLE]    = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$DOUBLE]    = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$STRING]    = $$ulda + $regrr
	opcode[$ex, $uns, $addr, $$COMPOSITE] = $$ulda + $regrr
END SUB
'
'
' ********************
' *****  ERRORS  *****
' ********************
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeRegAddr:
	XERROR = ERROR_REGADDR
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooManyArgs:
	XERROR = ERROR_TOO_MANY_ARGS
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' #########################
' #####  Expresso ()  #####
' #########################
'
FUNCTION  Expresso (old_test, TOKEN old_op, old_prec, TOKEN old_data, old_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  checkBounds,  library,  xpc
	TOKEN   token, check, new_op, new_data, varToken, openBrace, hold_token
	TOKEN   argToken, tokenTmp, atoken, funcToken, ttoken, ctoken
	TOKEN   hold_func
	TOKEN   rctoken
	TOKEN   funcaddrToken
	TOKEN   tokenTemp[]
	TOKEN   parArg[]
	TOKEN   argArg[]
	TOKEN   componentToken
	TOKEN   getToken
	SHARED  TOKEN programToken
	SHARED  TOKEN versionToken
	SHARED  TOKEN funcArg[]
	SHARED  TOKEN funcToken[]
	SHARED  TOKEN tabArg[]
	SHARED  TOKEN tab_sym[]
	SHARED  TOKEN typeEleArg[]
	SHARED  TOKEN typeEleToken[]

	SHARED  SSHORT typeConvert[]
	SHARED  typeEleCount[],  typeEleSize[]
	SHARED  typeEleType[]
	SHARED  typeEleStringSize[],  typeEleUBound[]
	SHARED  m_reg[],  m_addr[]
	SHARED  SLONG cop[]
	SHARED  funcLabel$[]
	SHARED  funcScope[],  funcKind[],  funcArgSize[]
	SHARED  tabType[]
	SHARED  q_type_int[]
	SHARED  m_addr$[],  q_type_long[],  q_type_long_or_addr[],  r_addr[],  r_addr$[]
	SHARED  tab_sym$[],  tab_lab$[]
	SHARED  typeSize[],  typeName$[]
	SHARED  XERROR
	SHARED  ERROR_BITSPEC,  ERROR_BYREF,  ERROR_BYVAL,  ERROR_COMPILER
	SHARED  ERROR_COMPONENT,  ERROR_KIND_MISMATCH,  ERROR_LITERAL
	SHARED  ERROR_NEED_EXCESS_COMMA,  ERROR_OVERFLOW,  ERROR_REGADDR
	SHARED  ERROR_SYNTAX,  ERROR_TOO_FEW_ARGS,  ERROR_TOO_MANY_ARGS
	SHARED  ERROR_TYPE_MISMATCH,  ERROR_UNDECLARED,  ERROR_UNDEFINED
	SHARED  ERROR_UNIMPLEMENTED
	SHARED  a0,  a0_type,  a1,  a1_type,  toes,  tokenPtr
	SHARED  got_expression,  inPrint,  funcaddrFuncNumber
	SHARED  oos,  dim_array,  func_number
	SHARED  excessComma
	SHARED  preType,  componentNumber
	SHARED  labelNumber,  compositeArg
	SHARED  UBYTE  oos[]
	SHARED  rsp_mod                                          '*cw* 230730+
	STATIC  TOKEN argToken[]
	STATIC  GOADDR opKind[]
	STATIC  GOADDR dataKind[]
	STATIC  GOADDR intrinToken[]
	STATIC  GOADDR firstIntrinToken[]
	STATIC  SBYTE inlineToken[]
	AUTOX  FUNCARG  farg[]
	AUTOX  FUNCARG  farg
	AUTOX  UBYTE  argReg[]
	AUTOX  UBYTE  orgReg[]
'
	IFZ argToken[] THEN GOSUB InitArrays
'
	got_expression = $$FALSE
	args      = 0
	DO
		NextToken (@token)
		kind    = token.tp.kind
	LOOP WHILE TokenMatch (@token, @#T_ADD)                 ' skip unary pluses
'
' ***********************************
' *****  EXPECTING DATA OBJECT  *****
' ***********************************
'
	GOTO @dataKind[kind]    ' dispatch routine based upon kind of token
	old_test = 0            ' unrecognized kinds aren't expression starters
	old_op   = token
	old_prec = 0
	old_data = #T_ZERO
	old_type = 0
	RETURN
'
'
' *****  Expecting data, got character  *****  @func() = invoke func()
'
express_character:
	IF TokenMatch (@token, @#T_ATSIGN) THEN GOTO express_function
	XcowlErr (380092): GOTO eeeSyntax
'
'
' *****  Expecting data object, got simple kind of data object  *****
'        (variable, constant, literal, syscon, charcons)
'
express_var:
	got_expression = $$TRUE
	new_data = token
	bitCheck = $$FALSE
	PeekToken (@check)
' new_type = TheType (token)                          '*****?????
	nn = token.tindex
	new_allo = token.tp.allo
'
	IFZ new_allo THEN
		symboloid$ = tab_sym$[nn]
		IF symboloid$ THEN
			IF (symboloid${0} == '#') THEN
				new_allo = $$SHARED
				IF (symboloid${1} == '#') THEN new_allo = $$EXTERNAL
			END IF
		END IF
	END IF
	new_type = token.tp.type
	IFZ new_type THEN new_type = tabType[nn]
	IFZ new_type THEN
		IF ((new_allo == $$SHARED) OR (new_allo == $$EXTERNAL)) THEN
			symboloid$ = tab_sym$[nn]
			IF (symboloid${0} == '#') THEN
				IFZ m_addr$[nn] THEN AssignAddress (token)
				new_type = TheType (token)
			END IF
		END IF
	END IF
'
	IFZ new_type THEN new_type = TheType (token)
'
' *****  COMPOSITE DATA TYPE  *****
'
' The following skips getting the data for the composite if
' it's followed by a kind = symbol token.  This really isn't
' a very good way to do it.  Change Composite () so there's
' a way to get data if it's not a stand-alone composite for
' which the token is the necessary result needed here.
'
' Note:   It is necessary to get the TOKEN only in such
'         cases, or places for intermediate SCOMPLEX and
'         DCOMPLEX don't get made up and expressions can
'         generate bogus code...
'
express_component:
	IF (new_type >= $$SCOMPLEX) THEN
		PeekToken (@check)
		ctest = check.tp.kind
		IF ((ctest = $$KIND_SYMBOLS) OR (ctest = $$KIND_ARRAY_SYMBOLS)) THEN
			Composite ($$GETDATA, @new_type, @new_data, 0, 0)
			IF XERROR THEN EXIT FUNCTION
			IF (new_type = $$STRING) THEN
				stackString = $$TRUE
				IFZ oos THEN XcowlErr (3800152): GOTO eeeCompiler
				accArray  = oos[oos]
				token.tindex = Top ()
				token.tp.kind = $$KIND_VARIABLES
				token.tp.type = $$STRING
				new_data  = #T_ZERO
			ELSE
				new_data  = #T_ZERO
				token     = #T_ZERO
				nn        = 0
			END IF
		END IF
		PeekToken (@check)
	END IF
'
	IF (TokenMatch (@check, @#T_LBRACE) OR TokenMatch (@check, @#T_LBRACES)) THEN
		SELECT CASE kind
			CASE $$KIND_VARIABLES, $$KIND_LITERALS, $$KIND_CONSTANTS, $$KIND_SYSCONS
			CASE ELSE:  XcowlErr (3800170): GOTO eeeSyntax
		END SELECT
		SELECT CASE new_type
			CASE $$STRING
						GOTO express_array            ' a${n} or a${n, m} form
			CASE ELSE
						IFF TokenMatch (@check, @#T_ZERO) THEN bitCheck = $$TRUE
		END SELECT
	END IF
'
	IF (new_type == $$STRING) THEN
		IFZ stackString THEN INC oos: oos[oos] = 'v'
	END IF
'
	orig_type = new_type                             '*cw* 230320+
	IF (new_type < $$SLONG) THEN new_type = $$SLONG  '*cw* 230306+
	IF (new_type < $$XLONG) THEN
		IF (kind != $$KIND_VARIABLES) THEN
			new_type = $$XLONG
		END IF
	ENDIF
'
	IF (kind = $$KIND_CONSTANTS) OR (kind = $$KIND_SYSCONS) THEN
		IFZ r_addr$[nn] THEN XcowlErr (3800191): GOTO eeeUndefined
	END IF
'
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		IFZ m_addr$[nn] THEN AssignAddress (token)
		IF XERROR THEN EXIT FUNCTION
	END IF
'
	IF bitCheck THEN
		IFF TokenMatch (@new_data, @#T_ZERO) THEN
			GOTO extract_bits_from_variable
		ELSE
			INC tokenPtr
			GOTO extract_bits_from_expression
		END IF
	END IF
'
'
' *************************************************
' *****  Got data, now expecting an operator  *****
' *************************************************
'
express_op:
	new_zip = $$FALSE                 ' new.zip TRUE if new.op is data kind
	NextToken (@token)                ' expecting operator
	kind = token.tp.kind              ' kind should be operator
'
	GOTO @opKind[kind]                ' dispatch based on kind.  Fall through on
	new_zip   = $$TRUE                '   data kinds and other non-binary-ops
	new_op    = token
	new_prec  = 0
	GOTO exo
'
express_op_rem:
	token = #T_STARTS                 ' got remark/comment token
	GOTO express_ops
'
express_op_lparen:
	IF (TokenMatch(@token, @#T_LBRACE) OR TokenMatch(@token, @#T_LBRACES)) THEN
		GOTO extract_bits_from_expression
	END IF
	old_test  = new_test
	old_op    = token                 ' got "(" when expecting an operator
	old_prec  = 0
	old_data  = new_data
	old_type  = new_type
	RETURN
'
express_op_component:
	IF (new_type < $$SCOMPLEX) THEN XcowlErr (3800240): GOTO eeeComponent
	DEC tokenPtr
	GOTO express_component
'
'
' ******************************************
' *****  Binary operator or separator  *****
' ******************************************
'
express_ops:
	new_op    = token
	new_prec  = new_op.tp.type AND 0xF
exo:
	IF XERROR THEN EXIT FUNCTION
	kind = new_op.tp.kind
'
' *****  new_prec > old_prec  *****
'
	IF (new_prec > old_prec) THEN
		IF new_test THEN GOSUB ExtractBit
		Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
		IF new_test AND (old_test != -1) THEN GOSUB ExtractBit
		IFZ new_type THEN                                                    'cw 150818+
			IF TokenMatch (@new_data, @#T_ZERO) THEN                           'cw 150818+
				IF TokenMatch (@new_op, @#T_STARTS) THEN                         'cw 150818+
					XcowlErr (3800265): GOTO eeeTooFewArgs                         'cw 150818+
				END IF                                                           'cw 150818+
			END IF                                                             'cw 150818+
		END IF                                                               'cw 150818+
		GOTO exo
	END IF
'
' *****  new_prec <= old_prec  *****
'
	IF (old_op.tp.kind = $$KIND_ADDR_OPS) THEN
		old_test = 0
		old_op   = new_op
		old_prec = new_prec
		old_data = #T_ZERO
		old_type = $$XLONG
		RETURN
	END IF
'
' old_table = ((old_op >> 20) AND 0x0F)       ' old.table = imbedded table #
' old_table = old_op.tp.allo                  ' old.table = imbedded table #
	old_table = old_op.tp.type >> 4             ' old.table = imbedded table #    ???????????
	IF new_zip THEN
		new_table = 0                             ' new.op = some kind of data
	ELSE
'   new_table = ((new_op >> 20) AND 0x0F)     ' xxx.table = 0 if xxx.op = () []
'   new_table = new_op.tp.allo                ' xxx.table = 0 if xxx.op = () []
		new_table = new_op.tp.type >> 4           ' xxx.table = 0 if xxx.op = () []  ??????????
	END IF
'
	IFZ (old_table OR new_table) THEN           ' matching parentheses
		old_test = new_test
		old_op   = new_op
		old_prec = new_prec
		old_data = new_data
		old_type = new_type
		RETURN
	END IF
'
' STRINGS and SCOMPLEX / DCOMPLEX arithmetic
'
	SELECT CASE old_type
		CASE $$STRING
					IF (new_type != $$STRING) THEN XcowlErr (3800307): GOTO eeeTypeMismatch
					SELECT CASE old_table
						CASE 2:     old_cop     = 0
												old_to_type = old_type  ' string compares:  a$ op b$
												new_to_type = new_type  ' op is =, <>, <, <=, etc...
												old_op_type = old_type
												result_type = $$XLONG
						CASE 5:     old_cop     = 0
												old_to_type = old_type  ' string concatenate:  a$ + b$
												new_to_type = new_type
												old_op_type = old_type
												result_type = old_type
						CASE ELSE:  XcowlErr (3800319): GOTO eeeTypeMismatch
					END SELECT
		CASE $$SCOMPLEX
					IF (new_type != $$SCOMPLEX) THEN XcowlErr (3800322): GOTO eeeTypeMismatch
					SELECT CASE old_table
						CASE 2, 4, 5, 8, 9, 10
						CASE ELSE: XcowlErr (3800325): GOTO eeeTypeMismatch
					END SELECT
					old_cop     = 0
					old_to_type = $$SCOMPLEX
					new_to_type = $$SCOMPLEX
					old_op_type = $$SCOMPLEX
					result_type = $$SCOMPLEX
					IF (old_table = 2) THEN result_type = $$XLONG
		CASE $$DCOMPLEX
					IF (new_type != $$DCOMPLEX) THEN XcowlErr (3800334): GOTO eeeTypeMismatch
					SELECT CASE old_table
						CASE 2, 4, 5, 8, 9, 10
						CASE ELSE: XcowlErr (3800337): GOTO eeeTypeMismatch
					END SELECT
					old_cop     = 0
					old_to_type = $$DCOMPLEX
					new_to_type = $$DCOMPLEX
					old_op_type = $$DCOMPLEX
					result_type = $$DCOMPLEX
					IF (old_table = 2) THEN result_type = $$XLONG
		CASE ELSE
					IF (new_type > $$DCOMPLEX) THEN XcowlErr (3800346): GOTO eeeTypeMismatch
					IF (old_type > $$DCOMPLEX) THEN XcowlErr (3800347): GOTO eeeTypeMismatch
					IF (old_table == ($$COP9 >> 4)) THEN
						SELECT CASE new_type
							CASE $$SINGLE: new_type = $$XLONG
							CASE $$DOUBLE: new_type = $$GIANT
							CASE $$STRING
								IFZ old_type THEN
									old_to_type = 0
									new_to_type = 0
									old_op_type = $$STRING
									old_op_type = $$XLONG
									result_type = $$XLONG
									EXIT SELECT 2
								END IF
						END SELECT
					END IF

					IF (old_table == ($$COP1 >> 4)) THEN
						SELECT CASE old_type
							CASE $$SINGLE: old_type = $$XLONG
							CASE $$DOUBLE: old_type = $$GIANT
						END SELECT

						SELECT CASE new_type
							CASE $$SINGLE: new_type = $$XLONG
							CASE $$DOUBLE: new_type = $$GIANT
							CASE $$STRING
								IFZ old_type THEN
									old_to_type = 0
									new_to_type = 0
									old_op_type = $$STRING
									old_op_type = $$XLONG
									result_type = $$XLONG
									EXIT SELECT 2
								END IF
						END SELECT
					END IF
					IF (old_table > UBOUND(cop[])) THEN XcowlErr (3800384): GOTO eeeTypeMismatch
					IF (old_type > UBOUND(cop[old_table,])) THEN XcowlErr (3800385): GOTO eeeTypeMismatch
					IF (new_type > UBOUND(cop[old_table, old_type, ])) THEN XcowlErr (3800386): GOTO eeeTypeMismatch
'
					old_cop = cop[old_table, old_type, new_type]
					old_to_type = old_cop {$$BYTE3}
					new_to_type = old_cop {$$BYTE2}
					old_op_type = old_cop {$$BYTE1}
					result_type = old_cop {$$BYTE0}
'					PRINT "Expresso(414)", HEX$(old_cop), HEX$(old_table), HEX$(old_type), HEX$(new_type)
'					PRINT "Expresso(415)", HEX$(new_to_type), HEX$(new_to_type), HEX$(old_op_type), HEX$(result_type)
'					PRINT "Expresso(416):&cop[]", HEX$(&cop[])
	END SELECT
	IF (old_cop < 0) THEN DEC tokenPtr: XcowlErr (3800397): GOTO eeeTypeMismatch
'
	st = old_type
	IF old_to_type THEN st = old_to_type
	xt = new_type
	IF new_to_type THEN xt = new_to_type
	ot = old_op_type
	rt = result_type
'
	oo = old_data.tindex
	nn = new_data.tindex
	ro = r_addr[oo]
	rn = r_addr[nn]
'
	SELECT CASE old_data.tp.kind
		CASE $$KIND_LITERALS, $$KIND_CONSTANTS:   ro = 0
		CASE $$KIND_CHARCONS, $$KIND_SYSCONS:     ro = 0
	END SELECT
'
	accx = 0                        ' accx = 3:  a1 full  . a0 full
	IF a0 THEN accx = accx + 1      ' accx = 2:  a1 full  . a0 empty
	IF a1 THEN accx = accx + 2      ' accx = 1:  a1 empty . a0 full
'                                 ' accx = 0:  a1 empty . a0 empty
'
'
'
	IF (old_type < $$SLONG) THEN old_type = $$SLONG
	IF (new_type < $$SLONG) THEN new_type = $$SLONG
	SELECT CASE old_type
		CASE $$SINGLE, $$DOUBLE:  oldFlop = $$TRUE
		CASE ELSE:                oldFlop = $$FALSE
	END SELECT
	SELECT CASE new_type
		CASE $$SINGLE, $$DOUBLE:  newFlop = $$TRUE
		CASE ELSE:                newFlop = $$FALSE
	END SELECT
' SVG 20010517 - simplified following lines
	newToFlop = (oldFlop AND !newFlop)
	oldToFlop = (newFlop AND !oldFlop)
'
	SELECT CASE ot
		CASE $$SINGLE, $$DOUBLE:  i486flop = $$TRUE
		CASE ELSE:                i486flop = $$FALSE
	END SELECT
'
'
'   *****  UNARY operators first  *****
'
	IF (rn AND (rn < $$IMM16)) THEN XcowlErr (3800445): GOTO eeeCompiler
	IF (old_op.tp.kind = $$KIND_UNARY_OPS) THEN
		IFF TokenMatch (@new_data, @#T_ZERO) THEN   ' UOP var
			IFZ rn THEN
				GOTO uop_var_mem      ' UOP var.mem
			ELSE
				GOTO uop_var_reg      ' UOP var.reg
			END IF
		ELSE
			IF a0 AND (a0 = toes) THEN
				GOTO uop_stk_reg_a0   ' UOP stk.reg.a0
			END IF
			IF a1 AND (a1 = toes) THEN
				GOTO uop_stk_reg_a1   ' UOP stk.reg.a1
			END IF
			GOTO uop_stk_mem        ' UOP stk.mem  (error)
		END IF
	END IF
'
'   *****  BINARY operators  *****
'
'   *****  var  OP  var  *****
'
	IF ro THEN XcowlErr (3800468): GOTO eeeCompiler
	IF rn THEN
		IF (rn < $$IMM16) THEN XcowlErr (3800470): GOTO eeeCompiler
		IF (rn > $$CONNUM) THEN XcowlErr (3800471): GOTO eeeCompiler
	END IF
	IFF TokenMatch (@old_data, @#T_ZERO) OR TokenMatch (@new_data, @#T_ZERO) THEN     ' var OP var
		IFZ rn THEN
			GOTO var_mem_op_var_mem           ' var.mem OP var.mem
		ELSE
			GOTO var_mem_op_var_reg           ' var.mem OP var.reg
		END IF
	END IF
'
'   *****  var  OP  stk  *****
'
	IF (NOT TokenMatch(@old_data, @#T_ZERO) AND TokenMatch(@new_data, @#T_ZERO)) THEN  ' var OP stk
		IFZ ro THEN
			IF a0 AND (a0 = toes) THEN
				GOTO var_mem_op_stk_reg_a0        ' var.mem OP stk.reg.a0
			END IF
			IF a1 AND (a1 = toes) THEN
				GOTO var_mem_op_stk_reg_a1        ' var.mem OP stk.reg.a1
			END IF
			GOTO var_mem_op_stk_mem             ' var.mem OP stk.mem  (error)
		END IF
	END IF
'
'   *****  stk  OP  var  *****
'
	IF TokenMatch(@old_data, @#T_ZERO) AND NOT TokenMatch(@new_data, @#T_ZERO) THEN ' stk OP var
		IFZ rn THEN
			IF a0 AND (a0 = toes) THEN
				GOTO stk_reg_a0_op_var_mem        ' stk.reg.a0 OP var.mem
			END IF
			IF a1 AND (a1 = toes) THEN
				GOTO stk_reg_a1_op_var_mem        ' stk.reg.a1 OP var.mem
			END IF
			GOTO stk_mem_op_var_mem             ' stk.mem OP var.mem  (error)
		ELSE
			IF a0 AND (a0 = toes) THEN
				GOTO stk_reg_a0_op_var_reg        ' stk.reg.a0 OP var.reg
			END IF
			IF a1 AND (a1 = toes) THEN
				GOTO stk_reg_a1_op_var_reg        ' stk.reg.a1 OP var.reg
			END IF
			GOTO stk_mem_op_var_reg             ' stk.mem OP var.reg (error)
		END IF
	END IF
'
'   *****  stk  OP  stk  *****
'
	IF TokenMatch(@old_data, @#T_ZERO) AND TokenMatch(@new_data, @#T_ZERO) THEN  ' stk OP stk
		IF a0 AND (a0 = toes) THEN
			IF a1 AND (a1 = toes - 1) THEN
				GOTO stk_reg_a1_op_stk_reg_a0     ' stk.reg.a0 OP stk.reg.a1
			ELSE
				GOTO stk_mem_op_stk_reg_a0        ' stk.mem OP stk.reg.a0
			END IF
		END IF
		IF a1 AND (a1 = toes) THEN
			IF a0 AND (a0 = toes - 1) THEN
				GOTO stk_reg_a0_op_stk_reg_a1     ' stk.reg.a1 OP stk.reg.a0
			ELSE
				GOTO stk_mem_op_stk_reg_a1        ' stk.mem OP stk.reg.a1
			END IF
		END IF
	END IF
	XcowlErr (3800535): GOTO eeeCompiler
'
' ***********************************************
' *****  THE ROUTINES JUMPED TO FROM ABOVE  *****
' ***********************************************
'
'
' *************************************
' *****  UNARY OPERATOR ROUTINES  *****
' *************************************
'
uop_var_mem:
	IF (accx = 3) THEN GOTO uvma
	IF (accx = 2) THEN GOTO uvmb
	IF (accx = 1) THEN GOTO uvmc
	IF (accx = 0) THEN GOTO uvmb
	XcowlErr (3800551): GOTO eeeCompiler
'
uvma:
	IF (a1 > a0) THEN GOTO uvm0
	IF (a1 < a0) THEN GOTO uvm1
	XcowlErr (3800556): GOTO eeeCompiler
'
uvm0:Push ($$RA0, a0_type)
uvmb:Move ($$RA0, new_type, nn, new_type)
				Conv ($$RA0, new_to_type, $$RA0, new_type)
				Uop ($$RA0, @old_op, $$RA0, rt, ot, xt)
				INC toes
				a0 = toes
				GOTO done
uvm1:Push ($$RA1, a1_type)
uvmc:Move ($$RA1, new_type, nn, new_type)
				Conv ($$RA1, new_to_type, $$RA1, new_type)
				Uop ($$RA1, @old_op, $$RA1, rt, ot, xt)
				INC toes
				a1 = toes: a1_type = rt
				GOTO done
'
'
'
uop_var_reg:
	IFZ new_to_type THEN GOTO uvrx
uvrn:
	IF (accx = 3) THEN GOTO uvrna
	IF (accx = 2) THEN GOTO uvrnb
	IF (accx = 1) THEN GOTO uvrnc
	IF (accx = 0) THEN GOTO uvrnb
	XcowlErr (3800582): GOTO eeeCompiler
uvrna:
	IF (a1 > a0) THEN GOTO uvrna0
	IF (a1 < a0) THEN GOTO uvrna1
	XcowlErr (3800586): GOTO eeeCompiler
uvrna0:Push ($$RA0, a0_type)
uvrnb:Conv ($$RA0, new_to_type, nn, new_type)
				Uop ($$RA0, @old_op, $$RA0, rt, ot, xt)
				INC toes
				a0 = toes
				a0_type = rt
				GOTO done
uvrna1:Push ($$RA1, a1_type)
uvrnc:Conv ($$RA1, new_to_type, nn, new_type)
				Uop ($$RA1, @old_op, $$RA1, rt, ot, xt)
				INC toes
				a1 = toes
				a1_type = rt
				GOTO done
uvrx:
	IF (accx = 3) THEN GOTO uvrxa
	IF (accx = 2) THEN GOTO uvrxb
	IF (accx = 1) THEN GOTO uvrxc
	IF (accx = 0) THEN GOTO uvrxb
	XcowlErr (3800606): GOTO eeeCompiler
uvrxa:
	IF (a1 > a0) THEN GOTO uvrxa0
	IF (a1 < a0) THEN GOTO uvrxa1
	XcowlErr (3800610): GOTO eeeCompiler
uvrxa0:Push ($$RA0, a0_type)
uvrxb:Move ($$RA0, xt, nn, xt)
				Uop ($$RA0, @old_op, $$RA0, rt, ot, xt)
				INC toes
				a0 = toes
				a0_type = rt
				GOTO done
uvrxa1:Push ($$RA1, a1_type)
uvrxc:Move ($$RA1, xt, nn, xt)
			Uop ($$RA1, @old_op, $$RA1, rt, ot, xt)
				INC toes
				a1 = toes
				a1_type = rt
				GOTO done
'
'
'
uop_stk_reg_a0:
				Conv ($$RA0, new_to_type, $$RA0, new_type)
				Uop ($$RA0, @old_op, $$RA0, rt, ot, xt)
				a0 = toes
				a0_type = rt
				GOTO done
'
'
'
uop_stk_reg_a1:
				Conv ($$RA1, new_to_type, $$RA1, new_type)
				Uop ($$RA1, @old_op, $$RA1, rt, ot, xt)
				a1 = toes
				a1_type = rt
				GOTO done
'
'
'
uop_stk_mem:
	XcowlErr (3800647): GOTO eeeCompiler
'
'
'
' ****************************************
' *****  BINARY  OPERATOR  ROUTINES  *****
' ****************************************
'
var_mem_op_var_mem:
	IF (accx = 3) THEN GOTO fc
	IF (accx = 2) THEN GOTO f8x
	IF (accx = 1) THEN GOTO f4x
	IF (accx = 0) THEN GOTO fcx
	XcowlErr (3800660): GOTO eeeCompiler
fc:
	IF (a1 > a0) THEN GOTO fca
	IF (a1 < a0) THEN GOTO fcb
	XcowlErr (3800664): GOTO eeeCompiler
fca:Push ($$RA0, a0_type)
f8x:Push ($$RA1, a1_type)
fcx:IF i486flop THEN
'       Move ($$RA0, old_type, oo, old_type)  ' xnt0l
				FloatLoad ($$RA0, oo, old_type)       ' xnt0l
			ELSE
				Move ($$RA0, old_type, oo, old_type)
				Conv ($$RA0, old_to_type, $$RA0, old_type)
			END IF
			IF i486flop THEN
'       Move ($$RA1, new_type, nn, new_type)  ' xnt0l
				FloatLoad ($$RA1, nn, new_type)       ' xnt0l
			ELSE
				Move ($$RA1, new_type, nn, new_type)
				Conv ($$RA1, new_to_type, $$RA1, new_type)
			END IF
			Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
			INC toes
			a1 = 0: a1_type = 0
			a0 = toes
			GOTO done
fcb:Push ($$RA1, a1_type)
f4x:Push ($$RA0, a0_type)
			GOTO fcx
'
'
'
var_mem_op_var_reg:
	IF (accx = 3) THEN GOTO ec
	IF (accx = 2) THEN GOTO e8
	IF (accx = 1) THEN GOTO e4
	IF (accx = 0) THEN GOTO e0
	XcowlErr (3800697): GOTO eeeCompiler
ec:IF (new_to_type OR (new_type = $$STRING)) THEN GOTO ecn ELSE GOTO ecx
e8:IF (new_to_type OR (new_type = $$STRING)) THEN GOTO e8n ELSE GOTO e8x
e4:IF (new_to_type OR (new_type = $$STRING)) THEN GOTO e4n ELSE GOTO e4x
e0:IF (new_to_type OR (new_type = $$STRING)) THEN GOTO ecnx ELSE GOTO e8x
ecn:
	IF (a1 > a0) THEN GOTO ecna
	IF (a1 < a0) THEN GOTO ecnb
	XcowlErr (3800705): GOTO eeeCompiler
ecna:Push ($$RA0, a0_type)
e8n:Push ($$RA1, a1_type)
ecnx:Move ($$RA0, old_type, oo, old_type)
			Conv ($$RA0, old_to_type, $$RA0, old_type)
			Conv ($$RA1, new_to_type, nn, new_type)
			Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
			INC toes
			a1 = 0: a1_type = 0
			a0 = toes
			GOTO done
ecnb:Push ($$RA1, a1_type)
e4n:Push ($$RA0, a0_type)
			GOTO ecnx
ecx:
	IF (a1 > a0) THEN GOTO ecxa
	IF (a1 < a0) THEN GOTO ecxb
	XcowlErr (3800722): GOTO eeeCompiler
ecxa:Push ($$RA0, a0_type)
e8x:Move ($$RA0, old_type, oo, old_type)
			Conv ($$RA0, old_to_type, $$RA0, old_type)
			Op ($$RA0, $$RA0, @old_op, nn, rt, st, ot, xt)
			INC toes
			a0 = toes
			a0_type = rt
			GOTO done
ecxb:Push ($$RA1, a1_type)
e4x:Move ($$RA1, old_type, oo, old_type)
			Conv ($$RA1, old_to_type, $$RA1, old_type)
			Op ($$RA1, $$RA1, @old_op, nn, rt, st, ot, xt)
			INC toes
			a1 = toes
			a1_type = rt
			GOTO done
'
'
'
'
'
'
var_mem_op_stk_reg_a0:
	IF (accx = 3) THEN GOTO cca
	IF (accx = 1) THEN GOTO c4
	XcowlErr (3800748): GOTO eeeCompiler
cca:Push ($$RA1, a1_type)
c4:IF i486flop THEN
				Conv ($$RA0, new_to_type, $$RA0, new_type)
'       Move ($$RA1, old_type, oo, old_type)  ' xnt0l
				FloatLoad ($$RA1, oo, old_type)       ' xnt0l
			ELSE
				Conv ($$RA0, new_to_type, $$RA0, new_type)
				Move ($$RA1, old_type, oo, old_type)
				Conv ($$RA1, old_to_type, $$RA1, old_type)
			END IF
			Op ($$RA0, $$RA1, @old_op, $$RA0, rt, st, ot, xt)
			a1 = 0: a1_type = 0
			a0 = toes
			GOTO done
'
'
'
var_mem_op_stk_reg_a1:
'       PRINT "var_mem_op_stk_reg_a1:  trouble ???"
				IF (accx == 3) THEN GOTO ccb
				IF (accx == 2) THEN GOTO c8
				XcowlErr (3800770): GOTO eeeCompiler
ccb:Push ($$RA0, a0_type)
c8:IF i486flop THEN
'       Move ($$RA0, old_type, oo, old_type)
				FloatLoad ($$RA0, oo, old_type)
				Conv ($$RA1, new_to_type, $$RA1, new_type)
' SVG 20010517 - correction for new_type not a float
				IF !newToFlop THEN
					Op ($$RA0, $$RA1, @old_op, $$RA0, rt, st, ot, xt)
				ELSE
					Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
				END IF
			ELSE
				Move ($$RA0, old_type, oo, old_type)
				Conv ($$RA0, old_to_type, $$RA0, old_type)
				Conv ($$RA1, new_to_type, $$RA1, new_type)
				Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
			END IF
			a1 = 0: a1_type = 0
			a0 = toes
			GOTO done
'
'
'
var_mem_op_stk_mem:
	XcowlErr (3800795): GOTO eeeCompiler
'
'
'
stk_reg_a0_op_var_mem:
	IF (accx = 3) THEN GOTO x3c0a
	IF (accx = 1) THEN GOTO x3c0b
	XcowlErr (3800802): GOTO eeeCompiler
x3c0a:Push ($$RA1, a1_type)
x3c0b:IF i486flop THEN
					Conv ($$RA0, old_to_type, $$RA0, old_type)
'         Move ($$RA1, new_type, nn, new_type)  ' xnt0l
					FloatLoad ($$RA1, nn, new_type)       ' xnt0l
				ELSE
				Move ($$RA1, new_type, nn, new_type)
					Conv ($$RA1, new_to_type, $$RA1, new_type)
					Conv ($$RA0, old_to_type, $$RA0, old_type)
				END IF
				Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
				a1 = 0: a1_type = 0
				a0 = toes
				GOTO done
'
'
stk_reg_a1_op_var_mem:
'       PRINT "stk_reg_a1_op_var_mem:  trouble ???"
				IF accx = 3 THEN GOTO x3c1a
				IF accx = 2 THEN GOTO x3c1b
				XcowlErr (3800823): GOTO eeeCompiler
x3c1a:Push ($$RA0, a0_type)
x3c1b:IF i486flop THEN
'         Move ($$RA0, new_type, nn, new_type)  ' xnt0l
					FloatLoad ($$RA0, nn, new_type)       ' xnt0l
				ELSE
				Move ($$RA0, new_type, nn, new_type)
					Conv ($$RA0, new_to_type, $$RA0, new_type)
				END IF
				Conv ($$RA1, old_to_type, $$RA1, old_type)
' SVG 20010517 - correction for case if old_type is a float
				IF oldFlop THEN
					Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
				ELSE
					Op ($$RA0, $$RA1, @old_op, $$RA0, rt, st, ot, xt)
				END IF
				a1 = 0: a1_type = 0
				a0 = toes
				GOTO done
'
'
'
stk_mem_op_var_mem:
	XcowlErr (3800846): GOTO eeeCompiler
'
'
'
stk_reg_a0_op_var_reg:
	cvcv = 0
	IF old_to_type THEN cvcv = cvcv + 2
	IF (new_to_type OR (new_type = $$STRING)) THEN cvcv = cvcv + 1
	IF (accx = 3) THEN GOTO x2ca
	IF (accx = 1) THEN GOTO x24a
	XcowlErr (3800856): GOTO eeeCompiler
x2ca:
	IF (cvcv = 3) THEN GOTO x2cona
	IF (cvcv = 2) THEN GOTO x2coxa
	IF (cvcv = 1) THEN GOTO x2cona
	IF (cvcv = 0) THEN GOTO x2cxxa
	XcowlErr (3800862): GOTO eeeCompiler
x24a:
	IF (cvcv = 3) THEN GOTO x24ona
	IF (cvcv = 2) THEN GOTO x2coxa
	IF (cvcv = 1) THEN GOTO x24ona
	IF (cvcv = 0) THEN GOTO x2cxxa
	XcowlErr (3800868): GOTO eeeCompiler
x2cona:Push ($$RA1, a1_type)
x24ona:Conv ($$RA1, new_to_type, nn, new_type)
				Conv ($$RA0, old_to_type, $$RA0, old_type)
				Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
				a1 = 0: a1_type = 0
				a0 = toes
				GOTO done
x2coxa:Conv ($$RA0, old_to_type, $$RA0, old_type)
x2cxxa:Op ($$RA0, $$RA0, @old_op, nn, rt, st, ot, xt)
				a0 = toes
				GOTO done
'
'
'
stk_reg_a1_op_var_reg:
	cvcv = 0
	IF old_to_type THEN cvcv = cvcv + 2
	IF (new_to_type OR (new_type = $$STRING)) THEN cvcv = cvcv + 1
	IF (accx = 3) THEN GOTO x2cb
	IF (accx = 2) THEN GOTO x28b
	XcowlErr (3800889): GOTO eeeCompiler
x2cb:
	IF (cvcv = 3) THEN GOTO x2conb
	IF (cvcv = 2) THEN GOTO x2coxb
	IF (cvcv = 1) THEN GOTO x2conb
	IF (cvcv = 0) THEN GOTO x2cxxb
	XcowlErr (3800895): GOTO eeeCompiler
x28b:
	IF (cvcv = 3) THEN GOTO x28onb
	IF (cvcv = 2) THEN GOTO x2coxb
	IF (cvcv = 1) THEN GOTO x28onb
	IF (cvcv = 0) THEN GOTO x2cxxb
	XcowlErr (3800901): GOTO eeeCompiler
x2conb:Push ($$RA0, a0_type)
x28onb:Conv ($$RA0, new_to_type, nn, new_type)
				Conv ($$RA1, old_to_type, $$RA1, old_type)
' SVG 20010517 - correction for case when old_type is a float
				IF newToFlop THEN
					Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
				ELSE
					Op ($$RA0, $$RA1, @old_op, $$RA0, rt, st, ot, xt)
				END IF
				a1 = 0: a1_type = 0
				a0 = toes
				GOTO done
x2coxb:Conv ($$RA1, old_to_type, $$RA1, old_type)
x2cxxb:Op ($$RA1, $$RA1, @old_op, nn, rt, st, ot, xt)
				a1 = toes: a1_type = rt
				GOTO done
'
'
'
stk_mem_op_var_reg:
	XcowlErr (3800922): GOTO eeeCompiler
'
'
'
stk_reg_a0_op_stk_reg_a1:
	Conv ($$RA0, old_to_type, $$RA0, old_type)
	Conv ($$RA1, new_to_type, $$RA1, new_type)
	IF oldToFlop THEN GOTO sr1osr0a               ' SVG 20010517
sr0osr1a:
	Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
	DEC toes
	a1 = 0: a1_type = 0
	a0 = toes
	GOTO done
'
'
'
stk_reg_a1_op_stk_reg_a0:
	Conv ($$RA1, old_to_type, $$RA1, old_type)
	Conv ($$RA0, new_to_type, $$RA0, new_type)
	IF oldFlop THEN GOTO sr0osr1a                 ' SVG 20010517
sr1osr0a:
	Op ($$RA0, $$RA1, @old_op, $$RA0, rt, st, ot, xt)
	DEC toes
	a1 = 0: a1_type = 0
	a0 = toes
	GOTO done
'
'
'
stk_mem_op_stk_reg_a0:
	IF (accx = 3) THEN XcowlErr (3800953): GOTO eeeCompiler
	IF (accx = 0) THEN XcowlErr (3800954): GOTO eeeCompiler
	Pop ($$RA1, old_type)
	Conv ($$RA1, old_to_type, $$RA1, old_type)
	Conv ($$RA0, new_to_type, $$RA0, new_type)
	IF oldFlop THEN GOTO smosr1a
smosr0a:
	Op ($$RA0, $$RA1, @old_op, $$RA0, rt, st, ot, xt)
	DEC toes
	a1 = 0: a1_type = 0
	a0 = toes
	GOTO done
'
'
stk_mem_op_stk_reg_a1:
	Pop ($$RA0, old_type)
	Conv ($$RA0, old_to_type, $$RA0, old_type)
	Conv ($$RA1, new_to_type, $$RA1, new_type)
	IF oldFlop THEN GOTO smosr0a
smosr1a:
	Op ($$RA0, $$RA0, @old_op, $$RA1, rt, st, ot, xt)
	DEC toes
	a1 = 0: a1_type = 0
	a0 = toes
	GOTO done
'
'
' *****  After code for unary and binary operators has been emitted  *****
' *****  if (old.op != 0), logical test op returned bit T/F, not XLONG T/F
'
done:
	old_test  = old_op.tindex
	old_op    = new_op
	old_prec  = new_prec
	old_data  = #T_ZERO
	old_type  = result_type
	RETURN
'
'
' ************************************************
' *****  Convert "bit T/F" into "XLONG T/F"  *****  ????  CAN THIS HAPPEN  ????
' ************************************************
'
SUB ExtractBit
	acc  = Top ()
	IFZ acc THEN XcowlErr (3800998): GOTO eeeCompiler
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	GOSUB ConvCondBitFalse
	Code ($$mov, $$regimm, acc, 0, 0, $$XLONG, "", $$rmk$+"585")
	Code (jmp486, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"586")
	Code ($$not, $$reg, acc, 0, 0, $$XLONG, "", $$rmk$+"587")
	EmitLabel (@d1$)
	new_test = 0
END SUB
'
'
' *****  ConvCondBitTrue  *****
'
' Sets jmp486$ to 80386 conditional jump mnemonic that corresponds to
' the 88000 condition bit in new_test being true.
'
SUB ConvCondBitTrue
	SELECT CASE new_test
		CASE 2:     jmp486 = $$je
		CASE 3:     jmp486 = $$jne
		CASE 4:     jmp486 = $$jg
		CASE 5:     jmp486 = $$jle
		CASE 6:     jmp486 = $$jl
		CASE 7:     jmp486 = $$jge
		CASE 8:     jmp486 = $$ja
		CASE 9:     jmp486 = $$jbe
		CASE 10:    jmp486 = $$jb
		CASE 11:    jmp486 = $$jae
		CASE ELSE:  jmp486 = -1
	END SELECT
END SUB
'
' *****  ConvCondBitFalse  *****
'
' Sets jmp486$ to 80386 conditional jump mnemonic that corresponds to
' the 88000 condition bit in new_test being false.
'
SUB ConvCondBitFalse
	SELECT CASE new_test
		CASE 2:     jmp486 = $$jne
		CASE 3:     jmp486 = $$je
		CASE 4:     jmp486 =  $$jle
		CASE 5:     jmp486 = $$jg
		CASE 6:     jmp486 = $$jge
		CASE 7:     jmp486 = $$jl
		CASE 8:     jmp486 = $$jbe
		CASE 9:     jmp486 = $$ja
		CASE 10:    jmp486 = $$jae
		CASE 11:    jmp486 = $$jb
		CASE ELSE:  jmp486 = -1
	END SELECT
END SUB
'
'
'
' *****  UNARY OPERATORS  *****
'
express_unary_op:
	IF (token.tp.type AND 0xF0 == $$COP9) THEN
		IF (old_op.tp.type AND 0xF0 == $$COP9) THEN
			XcowlErr (38001058): GOTO eeeSyntax
		END IF
	END IF
	new_op    = token
	new_prec  = new_op.tp.type AND 0xF
	new_data  = #T_ZERO
	new_type  = 0
	test      = 0
	Expresso (@test, @new_op, @new_prec, @new_data, @new_type)
	GOTO exo
'
'
'
' *****  ARRAYS  *****
'
express_array:
	got_expression = $$TRUE
	new_data = token
	nn = token.tindex
	new_allo = token.tp.allo
	IFZ new_allo THEN
		symboloid$ = tab_sym$[nn]
		IF symboloid$ THEN
			IF (symboloid${0} == '#') THEN
				new_allo = $$SHARED
				IF (symboloid${1} == '#') THEN new_allo = $$EXTERNAL
			END IF
		END IF
	END IF
	new_type = token.tp.type
	IFZ new_type THEN new_type = tabType[nn]
	IFZ new_type THEN
		IF ((new_allo == $$SHARED) OR (new_allo == $$EXTERNAL)) THEN
			symboloid$ = tab_sym$[nn]
			IF (symboloid${0} == '#') THEN
				IFZ m_addr$[nn] THEN AssignAddress (token)
				new_type = TheType (token)
			END IF
		END IF
	END IF
'
	IF (new_type >= $$SCOMPLEX) THEN                ' composite
		lastElement = LastElement (new_data, 0, 0)    ' Drop through if varComposite
		IF XERROR THEN EXIT FUNCTION
		IFF lastElement THEN                          ' composite + elements
			IF dim_array THEN XcowlErr (38001103): GOTO eeeComponent
			Composite ($$GETDATA, @new_type, @new_data, 0, 0)
			IF XERROR THEN EXIT FUNCTION
			new_op = #T_ZERO
			new_prec = 0
			new_data = #T_ZERO                                ' GETDATA stacks data
			GOTO express_op
		END IF
	END IF
'
	dimDone = ExpressArray (@old_op, @old_prec, @new_data, @new_type, accArray, @excess, 0, 0)
	IF excess THEN
		excessComma = excess
	END IF
	accArray    = $$FALSE
	IF XERROR THEN EXIT FUNCTION
	new_op = #T_ZERO
	new_prec    = 0
	IF dimDone THEN                       ' dimend return
		old_test  = 0
		NextToken (@old_op)
		old_prec  = 0
		old_data  = #T_ZERO
		old_type  = 0
		RETURN
	END IF
	GOTO express_op
'
'
' *******************************
' *****  EXTRACT BIT FIELD  *****
' *******************************
'
extract_bits_from_expression:
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		varToken  = new_data
		varType   = new_type
		bitVar    = $$TRUE
		GOTO extract_bits
	END IF
'
	IF (new_type != $$STRING) THEN
		acc       = Topax1 ()
		IFZ acc THEN XcowlErr (38001146): GOTO eeeCompiler
		Code ($$push, $$reg, acc, 0, 0, $$XLONG, "", $$rmk$+"588")
	END IF
	DEC tokenPtr
	varToken  = #T_ZERO
	varType   = new_type
	bitVar    = $$FALSE
	GOTO extract_bits
'
extract_bits_from_variable:
	got_expression = $$TRUE
	varToken  = token
	varType   = new_type
	bitVar    = $$TRUE
'
extract_bits:
	SELECT CASE varType
		CASE $$SINGLE, $$XLONG, $$ULONG, $$SLONG
		CASE $$USHORT, $$SSHORT, $$UBYTE, $$SBYTE
		CASE $$GIANT
		CASE $$STRING
			IF bitVar THEN
				DEC tokenPtr
				accArray = $$FALSE
			ELSE
				accArray = oos[oos]
			END IF
			token.tp.kind = $$KIND_VARIABLES
			token.tp.type = $$STRING
			token.tindex = varToken.tindex
			GOTO express_array
		CASE ELSE:  XcowlErr (38001177): GOTO eeeTypeMismatch
	END SELECT
	bitArgs = 0
	NextToken (@token)
	openBrace = token
'
' get width field (width-offset field if only one argument)
'
	new_op = Eval (@widthType)
	IF XERROR THEN EXIT FUNCTION
	IFZ q_type_long[widthType] THEN XcowlErr (38001187): GOTO eeeTypeMismatch
	INC bitArgs
'
' get offset field (if specified)
'
	SELECT CASE TRUE
		CASE TokenMatch (@new_op, @#T_RBRACE)
		CASE TokenMatch (@new_op, @#T_COMMA)
			new_op = Eval (@offsetType)
			IF XERROR THEN EXIT FUNCTION
			IFZ q_type_long[offsetType] THEN XcowlErr (38001197): GOTO eeeTypeMismatch
			IFF TokenMatch (@new_op, @#T_RBRACE) THEN XcowlErr (38001198): GOTO eeeSyntax
			INC bitArgs
		CASE ELSE
			XcowlErr (38001201): GOTO eeeSyntax
	END SELECT
	IF TokenMatch (@openBrace, @#T_LBRACES) THEN
		NextToken (@new_op)
		IFF TokenMatch (@new_op, @#T_RBRACE) THEN XcowlErr (38001205): GOTO eeeSyntax
	END IF
'
	IF (bitArgs < 2) THEN
		dacc = Top()
	ELSE
		Topaccs (@dacc, @daccx)
	END IF
	IF bitVar THEN
		Move ($$rsi, $$XLONG, varToken.tindex, $$XLONG)
	ELSE
		Code ($$pop, $$reg, $$rsi, 0, 0, $$XLONG, "", $$rmk$+"589")
	END IF
'
' get bitfield value in a register or immediate value
'
	SELECT CASE bitArgs
		CASE 1:     GOSUB OneBitArg
		CASE 2:     GOSUB TwoBitArgs
		CASE ELSE:  XcowlErr (38001224): GOTO eeeCompiler
	END SELECT
	new_type = $$XLONG
	new_op   = #T_ZERO
	new_data = #T_ZERO
	new_prec = 0
	GOTO express_op
'
'
'
SUB OneBitArg
	IF TokenMatch (@openBrace, @#T_LBRACE) THEN
		Code ($$mov, $$regreg, $$rcx, dacc, 0, $$XLONG, "", $$rmk$+"590")
		Code ($$slr, $$regreg, $$rsi, $$cl, 0, $$XLONG, "", $$rmk$+"591")
		Code ($$mov, $$regimm, $$rdi, -1, 0, $$XLONG, "", $$rmk$+"592")
		Code ($$slr, $$regimm, $$rcx, 6, 0, $$XLONG, "", $$rmk$+"593")
		Code ($$sll, $$regreg, $$rdi, $$cl, 0, $$XLONG, "", $$rmk$+"594")
		Code ($$not, $$reg, $$rdi, 0, 0, $$XLONG, "", $$rmk$+"595")
		Code ($$and, $$regreg, $$rsi, $$rdi, 0, $$XLONG, "", $$rmk$+"596")
		Code ($$mov, $$regreg, dacc, $$rsi, 0, $$XLONG, "", $$rmk$+"597")
	ELSE
		Code ($$mov, $$regreg, $$rdi, dacc, 0, $$XLONG, "", $$rmk$+"598")
		Code ($$mov, $$regreg, $$rcx, $$rdi, 0, $$XLONG, "", $$rmk$+"599")
		Code ($$slr, $$regimm, $$rcx, 6, 0, $$XLONG, "", $$rmk$+"600")
		Code ($$and, $$regimm, $$rdi, 63, 0, $$XLONG, "", $$rmk$+"601")
		Code ($$and, $$regimm, $$rcx, 63, 0, $$XLONG, "", $$rmk$+"602")
		Code ($$add, $$regreg, $$rcx, $$rdi, 0, $$XLONG, "", $$rmk$+"603")
		Code ($$neg, $$reg, $$rcx, 0, 0, $$XLONG, "", $$rmk$+"604")
		Code ($$add, $$regimm, $$rcx, 64, 0, $$XLONG, "", $$rmk$+"605")
		Code ($$sll, $$regreg, $$rsi, $$cl, 0, $$XLONG, "", $$rmk$+"606")
		Code ($$add, $$regreg, $$rcx, $$rdi, 0, $$XLONG, "", $$rmk$+"607")
		Code ($$sar, $$regreg, $$rsi, $$cl, 0, $$XLONG, "", $$rmk$+"608")
		Code ($$mov, $$regreg, dacc, $$rsi, 0, $$XLONG, "", $$rmk$+"609")
	END IF
END SUB
'
SUB TwoBitArgs
	IF TokenMatch (@openBrace, @#T_LBRACE) THEN
		Code ($$mov, $$regreg, $$rcx, dacc, 0, $$XLONG, "", $$rmk$+"610")
		Code ($$slr, $$regreg, $$rsi, $$cl, 0, $$XLONG, "", $$rmk$+"611")
		Code ($$mov, $$regimm, $$rdi, -1, 0, $$XLONG, "", $$rmk$+"612")
		Code ($$mov, $$regreg, $$rcx, daccx, 0, $$XLONG, "", $$rmk$+"613")
		Code ($$sll, $$regreg, $$rdi, $$cl, 0, $$XLONG, "", $$rmk$+"614")
		Code ($$not, $$reg, $$rdi, 0, 0, $$XLONG, "", $$rmk$+"615")
		Code ($$and, $$regreg, $$rsi, $$rdi, 0, $$XLONG, "", $$rmk$+"616")
		Code ($$mov, $$regreg, daccx, $$rsi, 0, $$XLONG, "", $$rmk$+"617")
	ELSE
		Code ($$mov, $$regreg, $$rcx, daccx, 0, $$XLONG, "", $$rmk$+"618")
		Code ($$mov, $$regreg, $$rdi, dacc, 0, $$XLONG, "", $$rmk$+"619")
		Code ($$add, $$regreg, $$rcx, $$rdi, 0, $$XLONG, "", $$rmk$+"620")
		Code ($$neg, $$reg, $$rcx, 0, 0, $$XLONG, "", $$rmk$+"621")
		Code ($$add, $$regimm, $$rcx, 64, 0, $$XLONG, "", $$rmk$+"622")
		Code ($$sll, $$regreg, $$rsi, $$cl, 0, $$XLONG, "", $$rmk$+"623")
		Code ($$add, $$regreg, $$rcx, $$rdi, 0, $$XLONG, "", $$rmk$+"624")
		Code ($$sar, $$regreg, $$rsi, $$cl, 0, $$XLONG, "", $$rmk$+"625")
		Code ($$mov, $$regreg, daccx, $$rsi, 0, $$XLONG, "", $$rmk$+"626")
	END IF
	Topax1 ()
END SUB
'
'
'
'
' *********************************
' *****  INTRINSIC FUNCTIONS  *****
' *********************************
'
express_intrinsic:
	args        = 0
	arg_pos$    = ""
	hold_token  = token
	ii          = token.ti.ndex
	hold_place  = tokenPtr
	hold_type   = token.tp.type
	return_type = hold_type
	inline      = inlineToken[ii]
	rtype$      = typeName$[return_type]
	max_args    = token.tp.allo
	IF (return_type < $$SLONG) THEN return_type = $$SLONG
'
'
' *****  Dispatch to intrinsics that need early processing  *****
'
	GOTO @firstIntrinToken[ii]
'
intrinsic_normal:
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38001311): GOTO eeeSyntax
	PeekToken (@check)
	IF TokenMatch (@check, @#T_RPAREN) THEN NextToken (@new_op): GOTO i_too_few_args
	firstpos  = tokenPtr
	argOff    = 0
	OpenBothAccs ()
'	IF TokenMatch (@hold_token, @#T_FORMAT_D) THEN                           '*cw* 230318-
'		frameSize = 24  ' 3 args 8 bytes each
'	ELSE
'		frameSize = 128
'	END IF
	SELECT CASE TRUE
		CASE TokenMatch (@hold_token, @#T_FORMAT_D): frameSize = 24  ' 3 args 8 bytes each
		CASE TokenMatch (@hold_token, @#T_GHIGH): frameSize = 0
		CASE TokenMatch (@hold_token, @#T_GLOW): frameSize = 0
		CASE TokenMatch (@hold_token, @#T_DMAKE): frameSize = 0
		CASE TokenMatch (@hold_token, @#T_GMAKE): frameSize = 0
		CASE TokenMatch (@hold_token, @#T_BITFIELD): frameSize = 0
		CASE ELSE: frameSize = 128
	END SELECT
	IF frameSize THEN                                                       '*cw* 230318+
		Code ($$sub, $$regimm, $$rsp, frameSize, 0, $$XLONG, "", $$rmk$+"627")
	END IF                                                                  '*cw* 230318+
'
	DO
		arg_pos$ = arg_pos$ + CHR$(tokenPtr + 1)
		new_test = 0: new_prec = 0: new_type = 0
		new_op = #T_ZERO
		new_data = #T_ZERO
		Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
		IF XERROR THEN EXIT FUNCTION
		INC args
		IF (new_type > $$STRING) THEN i_bad_arg = args: GOTO i_bad_type
		argOut  = $$FALSE
		ntype   = new_type
		IF (ntype < $$SLONG) THEN ntype = $$SLONG
		IF TokenMatch (@hold_token, @#T_FORMAT_D) THEN
			IF (args = 2) THEN
				Code ($$st, $$roimm, ntype, $$rsp, argOff, $$XLONG, "", $$rmk$+"628")
				argOff = argOff + 8
			END IF
		END IF
		IFF TokenMatch (@new_data, @#T_ZERO) THEN
			kind  = new_data.tp.kind
			IF ((kind = $$KIND_CONSTANTS) OR (kind = $$KIND_SYSCONS) OR (kind = $$KIND_LITERALS)) THEN
				IFZ inline THEN
					SELECT CASE ntype
						CASE $$DOUBLE:  argOut  = $$TRUE
														ntype = $$GIANT
														v#      = DOUBLE(r_addr$[new_data.tindex])
														hi      = DHIGH(v#)
														lo      = DLOW(v#)
														Code ($$st, $$roimm, lo, $$rsp, argOff, $$XLONG, "", $$rmk$+"629")
														Code ($$st, $$roimm, hi, $$rsp, argOff+4, $$XLONG, "", $$rmk$+"630")
						CASE $$SINGLE:  argOut  = $$TRUE
														ntype   = $$XLONG
														v       = XMAKE(SINGLE(r_addr$[new_data.tindex]))
														Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"631")
						CASE $$GIANT:   argOut  = $$TRUE
'														v$$     = GIANT(r_addr$[new_data.tindex])                            '*cw* 230318
'														hi      = GHIGH(v$$)                                                 '*cw* 230318
'														lo      = GLOW(v$$)                                                  '*cw* 230318
'														Code ($$st, $$roimm, lo, $$rsp, argOff, $$XLONG, "", $$rmk$+"632")   '*cw* 230318
'														Code ($$st, $$roimm, hi, $$rsp, argOff+4, $$XLONG, "", $$rmk$+"633") '*cw* 230318-
														v       = XLONG(r_addr$[new_data.tindex])                            '*cw* 230318+
														Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"632")    '*cw* 230318+
						CASE $$XLONG:   argOut  = $$TRUE
														v       = XLONG(r_addr$[new_data.tindex])
														Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"634")
						CASE $$ULONG:   argOut  = $$TRUE
														v       = ULONG(r_addr$[new_data.tindex])
														Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"635")
						CASE $$SLONG:   argOut  = $$TRUE
														v       = SLONG(r_addr$[new_data.tindex])
														Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"636")
						CASE ELSE:      acc     = OpenAccForType (ntype)
														Move (acc, ntype, new_data.tindex, ntype)
					END SELECT
				ELSE
					acc = OpenAccForType (ntype)
					SELECT CASE ntype
						CASE $$DOUBLE:  v#      = DOUBLE(r_addr$[new_data.tindex])
														hi      = DHIGH(v#)
														lo      = DLOW(v#)
														Code ($$ld, $$regimm, acc, lo, 0, $$XLONG, "", $$rmk$+"637")
														Code ($$ld, $$regimm, acc+1, hi, 0, $$XLONG, "", $$rmk$+"638")
						CASE $$SINGLE:  argOut  = $$TRUE
														ntype   = $$XLONG
														v       = XMAKE(SINGLE(r_addr$[new_data.tindex]))
														Code ($$ld, $$regimm, acc, v, 0, $$XLONG, "", $$rmk$+"639")
						CASE ELSE:      Move (acc, ntype, new_data.tindex, ntype)
					END SELECT
				END IF
			ELSE
				SELECT CASE ntype
					CASE $$SINGLE:  ntype = $$XLONG
					CASE $$DOUBLE:  ntype = $$GIANT
				END SELECT
				acc   = OpenAccForType (ntype)
				Move (acc, ntype, new_data.tindex, ntype)
			END IF
		ELSE
			acc   = Top ()
			SELECT CASE ntype
				CASE $$SINGLE:  Code ($$fstp, $$ro, 0, $$rsp, argOff, $$SINGLE, "", $$rmk$+"640")
												argOut  = $$TRUE
												ntype   = $$XLONG
												IF inline THEN
													Code ($$ld, $$regro, acc, $$rsp, argOff, $$XLONG, "", $$rmk$+"641")
												ELSE
													acc     = Topax1 ()
												END IF
				CASE $$DOUBLE:  Code ($$fstp, $$ro, 0, $$rsp, argOff, $$DOUBLE, "", $$rmk$+"642")
												argOut  = $$TRUE
												ntype   = $$GIANT
												IF inline THEN
													Code ($$ld, $$regro, acc, $$rsp, argOff, $$GIANT, "", $$rmk$+"643")
												ELSE
													acc     = Topax1 ()
												END IF
			END SELECT
		END IF
'
		IF (args > max_args) THEN DEC tokenPtr: XcowlErr (38001421): GOTO eeeTooManyArgs
		IFZ (inline OR argOut) THEN StackIt (ntype, acc, ntype, argOff)
		argOff = argOff + 8
		SELECT CASE args
			CASE 1   : at1 = new_type: nt1 = ntype
			CASE 2   : at2 = new_type: nt2 = ntype
			CASE 3   : at3 = new_type: nt3 = ntype
			CASE 4   : at4 = new_type: nt4 = ntype
			CASE ELSE: XcowlErr (38001429): GOTO eeeTooManyArgs
		END SELECT
	LOOP WHILE TokenMatch (@new_op, @#T_COMMA)
	IF TokenMatch (@new_op, @#T_RBRAK) AND TokenMatch (@hold_token, @#T_UBOUND) THEN NextToken (@new_op)
	IFF TokenMatch (@new_op, @#T_RPAREN) THEN XcowlErr (38001433): GOTO eeeSyntax
'
' got all the arguments
'
	arg_pos$ = arg_pos$ + CHR$(tokenPtr)
	IF (return_type = $$TYPE_INPUT) THEN return_type = at1
	IF inline THEN
		SELECT CASE args
			CASE 1: acc = Topax1 ()
							IF (acc != $$rax) THEN
								Code ($$mov, $$regreg, $$rax, acc, 0, nt1, "", $$rmk$+"644")
							END IF
			CASE 2: Topax2 (@acc2, @acc1)
							IF (acc1 != $$rax) THEN
								SELECT CASE nt1
									CASE $$SLONG, $$ULONG, $$XLONG
												Code ($$xchg, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"645")
									CASE $$GIANT
												Code ($$xchg, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"646")
												Code ($$xchg, $$regreg, $$rdx, $$rcx, 0, $$XLONG, "", $$rmk$+"647")
									CASE ELSE
												XcowlErr (38001454): GOTO eeeTypeMismatch
								END SELECT
							ELSE
								IF (acc2 != $$rbx) THEN XcowlErr (38001457): GOTO eeeCompiler
							END IF
		END SELECT
	END IF
	INC toes
	new_data  = #T_ZERO
	a0        = toes
	a0_type   = return_type
'
'
' *****  Dispatch to the intrinsic functions
'
igotm:
	GOTO @intrinToken[ii]     ' individual routines for intrinsics
	tokenPtr = hold_place       ' fall through on bad/unimplemented tokens
	XcowlErr (38001472): GOTO eeeUnimplemented
'
' ****************************************************************
' *****  typenameAT INTRINSICS  *****  DIRECT MEMORY ACCESS  *****
' ****************************************************************
'
' *****  SBYTEAT, UBYTEAT, SSHORTAT... DOUBLEAT  *****
'
i_atops:
	opcode = $$ld
	OpenBothAccs ()
	AtOps (hold_type, @opcode, @mode, @base, @offset, 0)
	IF XERROR THEN EXIT FUNCTION
	INC toes
	a0      = toes
	a0_type = return_type
	Code (opcode, mode, $$rax, base, offset, hold_type, "", $$rmk$+"648")
	new_type = return_type
	GOTO express_op
'
'
' ****************************************
' *****  TYPE CONVERSION INTRINSICS  *****
' ****************************************
'
' *****  SBYTE, UBYTE, SSHORT, USHORT... DOUBLE, GIANT  *****
'
i_types:
	IFF TokenMatch (@new_op, @#T_RPAREN) THEN XcowlErr (38001500): GOTO eeeSyntax
	new_type = hold_token.tp.type
	IF old_type THEN
		IF (old_type < $$XLONG) THEN
			IF (new_type <> old_type) THEN
				PRINT "Expresso(1548):type mismatch", old_type, new_type
				XcowlErr (38001506): GOTO eeeTypeMismatch
			END IF
		END IF
	END IF
	SELECT CASE TRUE
		CASE (new_type == at1)
					SELECT CASE TRUE
						CASE (new_type <= $$GIANT)
									Code ($$ld, $$regro, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"649")
						CASE (new_type == $$GIANT)
									Code ($$ld, $$regro, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"650")
									Code ($$ld, $$regro, $$rdx, $$rsp, 8, $$XLONG, "", $$rmk$+"651")
						CASE (new_type == $$SINGLE)
									Code ($$fld, $$ro, 0, $$rsp, 0, $$SINGLE, "", $$rmk$+"652")
						CASE (new_type == $$DOUBLE)
									Code ($$fld, $$ro, 0, $$rsp, 0, $$DOUBLE, "", $$rmk$+"653")
						CASE (new_type == $$STRING)
									Code ($$ld, $$regro, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"654")
									IF oos[oos] = 'v' THEN
										Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0", $$rmk$+"655")
									END IF
									oos[oos] = 's'
						CASE ELSE
									XcowlErr (38001529): GOTO eeeCompiler
					END SELECT
		CASE (new_type == $$STRING)
					SELECT CASE at1
						CASE $$SLONG, $$ULONG:  at1 = $$XLONG
					END SELECT
					Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_cv." + typeName$[at1] + ".to.string", $$rmk$+"656")
					INC oos
					oos[oos] = 's'
		CASE (at1 == $$STRING)
					Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_cv.string.to." + typeName$[new_type] + "." + CHR$(oos[oos]), $$rmk$+"657")
					DEC oos
		CASE ELSE
					SELECT CASE at1
						CASE $$SLONG : at1 = $$XLONG
					END SELECT
					Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_cv." + typeName$[at1] + ".to." + typeName$[new_type], $$rmk$+"658")
	END SELECT
	IF (new_type < $$SLONG) THEN new_type = $$SLONG
	GOTO intrinDone
'
'
' *****  CLOSE (x)  *****
'
i_close: routine$ = $$ulpc$+"_close":  GOTO ii_close
i_quit:  routine$ = $$ulpc$+"_quit":   GOTO ii_quit
i_eof:   routine$ = $$ulpc$+"_eof":    GOTO ii_eof
i_lof:   routine$ = $$ulpc$+"_lof":    GOTO ii_lof
i_pof:   routine$ = $$ulpc$+"_pof":    GOTO ii_pof
'
ii_close:
ii_quit:
ii_eof:
ii_lof:
ii_pof:
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IF sacc1 THEN tt1 = sacc1
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"659")
	new_data = #T_ZERO
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  OPEN (fileName$, mode)  *****
'
i_open:
	routine$ = $$ulpc$+"_open." + CHR$ (oos[oos])
	IF (args < 2) THEN GOTO i_too_few_args
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"660")
	new_data = #T_ZERO
	new_type = $$XLONG
	DEC oos
	GOTO intrinDone
	GOTO express_op
'
'
' *****  SEEK (file, pos)  *****
'
i_seek:
	IF (args < 2) THEN GOTO i_too_few_args
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_seek", $$rmk$+"661")
	new_data = #T_ZERO
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  SHELL (command$)  *****
'
i_shell:
	routine$ = $$ulpc$+"_shell." + CHR$ (oos[oos])
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"662")
	new_data = #T_ZERO
	new_type = $$XLONG
	DEC oos
	GOTO intrinDone
	GOTO express_op
'
'
' *****  INFILE$ (fileNumber)  *****
'
i_infile_d:
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_infile_d", $$rmk$+"663")
	INC oos
	oos[oos] = 's'
	new_data = #T_ZERO
	new_type = $$STRING
	GOTO intrinDone
	GOTO express_op
'
'
' *****  INLINE$ (prompt$)  *****
'
i_inline_d:
	routine$ = $$ulpc$+"_inline_d." + CHR$ (oos[oos])
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"664")
	new_data = #T_ZERO
	new_type = $$STRING
	oos[oos] = 's'
	GOTO intrinDone
	GOTO express_op
'
'
' ********************************************
' *****  NUMERIC = INTRINSIC (NUMERICS)  *****
' ********************************************
'
' *****  ABS (x)  *****
'
i_abs:
	IF (at1 > $$DOUBLE) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_abs." + typeName$[at1], $$rmk$+"665")
	new_type  = at1
	GOTO intrinDone
'
'
' *****  BITFIELD (x&, y&)  *****
'
i_bitfield:
	IF (args < 2) THEN GOTO i_too_few_args
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	Code ($$and, $$regimm, $$rax, 63, 0, $$XLONG, "", $$rmk$+"666")
	Code ($$sll, $$regimm, $$rax, 6, 0, $$XLONG, "", $$rmk$+"667")
	Code ($$and, $$regimm, $$rbx, 63, 0, $$XLONG, "", $$rmk$+"668")
	Code ($$or, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"669")
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  DHIGH (x#)  *****
'
i_dhigh:
	IF (at1 != $$DOUBLE) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$slr, $$regimm, $$rax, 32, 0, $$XLONG, "", $$rmk$+"670A")
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  DLOW (x#)  *****
'
i_dlow:
	IF (at1 != $$DOUBLE) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$sll, $$regimm, $$rax, 32, 0, $$XLONG, "", $$rmk$+"670B")
	Code ($$slr, $$regimm, $$rax, 32, 0, $$XLONG, "", $$rmk$+"670C")
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  DMAKE (x&, y&)  *****
'
i_dmake:
	IF (args < 2) THEN GOTO i_too_few_args
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	Code ($$st, $$roreg, $$rbx, $$rbp, -8, $$SLONG, "", $$rmk$+"671")
	Code ($$st, $$roreg, $$rax, $$rbp, -4, $$SLONG, "", $$rmk$+"672")
	Code ($$fld, $$ro, 0, $$rbp, -8, $$DOUBLE, "", $$rmk$+"673")
	new_type = $$DOUBLE
	GOTO intrinDone
	GOTO express_op
'
'
' *****  ERROR (e&)  *****  returns ##ERROR: IF (arg != -1) THEN ##ERROR = arg
'
i_error:
	IF (args < 1) THEN GOTO i_too_few_args
	IFZ q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_error", $$rmk$+"674")
	new_type = $$XLONG
	GOTO intrinDone
'
'
' *****  GHIGH (x$$)  *****
'
i_ghigh:
	IF (at1 != $$GIANT) THEN i_bad_arg = 1: GOTO i_bad_type
'	Code ($$mov, $$regreg, $$rax, $$rdx, 0, $$XLONG, "", $$rmk$+"675")  '*cw* 230318-
	Code ($$slr, $$regimm, $$rax, 32, 0, $$XLONG, "", $$rmk$+"675")  '*cw* 230318+
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  GLOW (x$$)  *****
'
i_glow:
	IF (at1 != $$GIANT) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$sll, $$regimm, $$rax, 32, 0, $$XLONG, "", $$rmk$+"675B")  '*cw* 230318+
	Code ($$slr, $$regimm, $$rax, 32, 0, $$XLONG, "", $$rmk$+"675C")  '*cw* 230318+
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  GMAKE (x&, y&)  *****
'
i_gmake:
	IF (args < 2) THEN GOTO i_too_few_args
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
'	Code ($$mov, $$regreg, $$rdx, $$rax, 0, $$XLONG, "", $$rmk$+"676")  '*cw* 230319-
'	Code ($$mov, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"677")  '*cw* 230319-
	Code ($$sll, $$regimm, $$rax, 32, 0, $$XLONG, "", $$rmk$+"676A")    '*cw* 230319+
	Code ($$sll, $$regimm, $$rbx, 32, 0, $$XLONG, "", $$rmk$+"676B")    '*cw* 230319+
	Code ($$slr, $$regimm, $$rbx, 32, 0, $$XLONG, "", $$rmk$+"676C")    '*cw* 230319+
	Code ($$or, $$regreg, $$rax, $$rbx, 0, $$XLONG,"", $$rmk$+"677")    '*cw* 230319+
	new_type  = $$GIANT
	GOTO intrinDone
	GOTO express_op
'
'
' *****  SMAKE (x&)  *****
'
i_smake:
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$st, $$roreg, $$rax, $$rbp, -8, $$XLONG, "", $$rmk$+"678")
	Code ($$fld, $$ro, 0, $$rbp, -8, $$SINGLE, "", $$rmk$+"679")
	new_type  = $$SINGLE
	GOTO intrinDone
	GOTO express_op
'
'
' *****  XMAKE (x!)  *****
'
i_xmake:
	IF (at1 != $$SINGLE) THEN i_bad_arg = 1: GOTO i_bad_type
	new_type  = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  HIGH0 (x&)  *****
' *****  HIGH1 (x&)  *****
'
i_high0: routine$ = $$ulpc$+"_high0": groutine$ = $$ulpc$+"_high0.giant": GOTO ii_high0
i_high1: routine$ = $$ulpc$+"_high1": groutine$ = $$ulpc$+"_high1.giant": GOTO ii_high1
'
ii_high0:
ii_high1:
	SELECT CASE TRUE
		CASE (q_type_long_or_addr[at1])
					Code ($$call, $$rel, 0, 0, 0, 0, @routine$, $$rmk$+"680")
		CASE (at1 = $$GIANT)
					Code ($$call, $$rel, 0, 0, 0, 0, @groutine$, $$rmk$+"681")
		CASE ELSE
					i_bad_arg = 1: GOTO i_bad_type
	END SELECT
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  LIBRARY (x)  *****
'
i_library:
	IFZ q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$xor, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"682")
	IF library THEN Code ($$not, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"683")
	new_type = $$XLONG
	GOTO intrinDone
'
'
' *****  MIN (x, y)  *****
' *****  MAX (x, y)  *****
'
i_min: routine$ = $$ulpc$+"_MIN." + typeName$[at1]: GOTO ii_minmax
i_max: routine$ = $$ulpc$+"_MAX." + typeName$[at1]: GOTO ii_minmax
'
ii_minmax:
	IF (args < 2) THEN GOTO i_too_few_args
	IF (at1 > $$DOUBLE) THEN i_bad_arg = 1:                 GOTO i_bad_type
	IF (at2 > $$DOUBLE) THEN i_bad_arg = 2:                 GOTO i_bad_type
	IF typeConvert[at1,at2]{{$$BYTE0}} THEN i_bad_arg = 2:  GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"684")
	new_type  = at1
	GOTO intrinDone
'
'
' *****  ROTATEL (x, y)  *****
'
i_rotatel:
	IF (args < 2) THEN GOTO i_too_few_args
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	Code ($$mov, $$regreg, $$rcx, $$rbx, 0, $$XLONG, "", $$rmk$+"685")
	Code ($$rol, $$regreg, $$rax, $$cl, 0, $$XLONG, "", $$rmk$+"686")
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  ROTATER (x, y)  *****
'
i_rotater:
	IF (args < 2) THEN GOTO i_too_few_args
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	Code ($$mov, $$regreg, $$rcx, $$rbx, 0, $$XLONG, "", $$rmk$+"687")
	Code ($$ror, $$regreg, $$rax, $$cl, 0, $$XLONG, "", $$rmk$+"688")
	new_type = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  CLR  (x&, y&, [z&])   1st arg may be LONG or SINGLE  *****
' *****  SET  (x&, y&, [z&])   1st arg may be LONG or SINGLE  *****
' *****  EXTS (x&, y&, [z&])   1st arg may be LONG or SINGLE  *****
' *****  EXTU (x&, y&, [z&])   1st arg may be LONG or SINGLE  *****
' *****  MAKE (x&, y&, [z&])   1st arg may be LONG or SINGLE  *****
'
i_clr:  iop$ = $$ulpc$+"_clr":  GOTO ii_clr
i_set:  iop$ = $$ulpc$+"_set":  GOTO ii_set
i_exts: iop$ = $$ulpc$+"_ext":  GOTO ii_exts
i_extu: iop$ = $$ulpc$+"_extu": GOTO ii_extu
i_make: iop$ = $$ulpc$+"_make": GOTO ii_make
'
ii_clr:
ii_set:
ii_exts:
ii_extu:
ii_make:
	IF (args < 2) THEN GOTO i_too_few_args
	IFF q_type_long[at1] THEN
		IF (at1 <> $$SINGLE) THEN i_bad_arg = 1: GOTO i_bad_type
	END IF
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	IF (args = 2) THEN
		Code ($$call, $$rel, 0, 0, 0, 0, iop$ + ".2arg", $$rmk$+"689")
	ELSE
		IFF q_type_long[at3] THEN i_bad_arg = 3: GOTO i_bad_type
		Code ($$call, $$rel, 0, 0, 0, 0, iop$ + ".3arg", $$rmk$+"690")
	END IF
	new_type = $$XLONG
	GOTO intrinDone
'
'
' *****  INT (x)  *****
' *****  FIX (x)  *****
'
i_int: routine$ = $$ulpc$+"_int.": GOTO ii_int
i_fix: routine$ = $$ulpc$+"_fix.": GOTO ii_fix
'
ii_int:
ii_fix:
	routine$ = routine$ + typeName$[at1]
	SELECT CASE at1
		CASE $$SINGLE, $$DOUBLE
				Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"691")
		CASE $$SLONG, $$ULONG, $$XLONG
				Code ($$ld, $$regro, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"692")
		CASE $$GIANT
				Code ($$ld, $$regro, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"693")
				Code ($$ld, $$regro, $$rdx, $$rsp, 8, $$XLONG, "", $$rmk$+"694")
		CASE ELSE
				i_bad_arg = 1: GOTO i_bad_type
	END SELECT
	new_type  = at1
	GOTO intrinDone
'
'
' *****  SGN (x)  *****
'
i_sgn:
	SELECT CASE at1
		CASE $$ULONG, $$USHORT, $$UBYTE
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					Code ($$or, $$regreg, $$rax, $$rax, 0, $$XLONG,"", $$rmk$+"695")
					Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"696")
					Code ($$mov, $$regimm, $$rax, 1, 0, $$XLONG,"", $$rmk$+"697")
					EmitLabel (@d1$)
		CASE $$SLONG, $$XLONG, $$GIANT, $$SSHORT, $$SBYTE
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					Code ($$or, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"698")
					Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"699")
					Code ($$sar, $$regimm, $$rax, 63, 0, $$XLONG, "", $$rmk$+"700")
					Code ($$or, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"701")
					EmitLabel (@d1$)
		CASE $$SINGLE
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					Code ($$mov, $$regreg, $$rsi, $$rax, 0, $$XLONG, "", $$rmk$+"707")
					Code ($$and, $$regimm, $$rax, 0x7FFFFFFF, 0, $$XLONG, "", $$rmk$+"708")
					Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"709")
					Code ($$mov, $$regreg, $$rax, $$rsi, 0, $$XLONG, "", $$rmk$+"710")
					Code ($$sar, $$regimm, $$rax, 63, 0, $$XLONG, "", $$rmk$+"711")
					Code ($$or, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"712")
					EmitLabel (@d1$)
		CASE $$DOUBLE
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					Code ($$mov, $$regreg, $$rsi, $$rdx, 0, $$XLONG, "", $$rmk$+"713")
					Code ($$and, $$regimm, $$rdx, 0x7FFFFFFF, 0, $$XLONG, "", $$rmk$+"714")
					Code ($$or, $$regreg, $$rax, $$rdx, 0, $$XLONG, "", $$rmk$+"715")
					Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"716")
					Code ($$mov, $$regreg, $$rax, $$rsi, 0, $$XLONG, "", $$rmk$+"717")
					Code ($$sar, $$regimm, $$rax, 63, 0, $$XLONG, "", $$rmk$+"718")
					Code ($$or, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"719")
					EmitLabel (@d1$)
		CASE ELSE
					i_bad_arg = 1: GOTO i_bad_type
	END SELECT
	new_type  = $$SLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  SIGN (x)  *****
'
i_sign:
	SELECT CASE at1
		CASE $$ULONG, $$USHORT, $$UBYTE
					Code ($$mov, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"720")
		CASE $$SLONG, $$XLONG, $$GIANT, $$SSHORT, $$SBYTE
					Code ($$sar, $$regimm, $$rax, 63, 0, $$XLONG, "", $$rmk$+"721")
					Code ($$or, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"722")
		CASE $$SINGLE
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					Code ($$mov, $$regreg, $$rsi, $$rax, 0, $$XLONG, "", $$rmk$+"726")
					Code ($$and, $$regimm, $$rax, 0x7FFFFFFF, 0, $$XLONG, "", $$rmk$+"727")
					Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"728")
					Code ($$mov, $$regreg, $$rax, $$rsi, 0, $$XLONG, "", $$rmk$+"729")
					Code ($$sar, $$regimm, $$rax, 63, 0, $$XLONG, "", $$rmk$+"730")
					EmitLabel (@d1$)
					Code ($$or, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"731")
		CASE $$DOUBLE                                      'All following code for 64-bit
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					Code ($$mov, $$regreg, $$rsi, $$rax, 0, $$XLONG, "", $$rmk$+"732")
					Code ($$sll, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"733A")
					Code ($$sar, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"733B")
					Code ($$or, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"734")
					Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"735")
					Code ($$mov, $$regreg, $$rax, $$rsi, 0, $$XLONG, "", $$rmk$+"736")
					Code ($$sar, $$regimm, $$rax, 63, 0, $$XLONG, "", $$rmk$+"737")
					EmitLabel (@d1$)
					Code ($$or, $$regimm, $$rax, 1, 0, $$XLONG, "", $$rmk$+"738")
		CASE ELSE
					i_bad_arg = 1: GOTO i_bad_type
	END SELECT
	new_type  = $$SLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  TAB (x)  *****
'
i_tab:
	IFZ inPrint THEN XcowlErr (38001978): GOTO eeeSyntax
	IFF q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$ld, $$regro, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"739")
	new_type  = $$XLONG
	GOTO intrinDone
'
'
' *********************************************
' *****  NUMERIC = INTRINSIC (STRING...)  *****
' *********************************************
'
'
' *****  ASC (x$, [i])  *****
'
i_asc:
	routine$ = $$ulpc$+"_asc."
	IF (at1 <> $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	IF (args = 1) THEN
		Code ($$mov, $$roimm, 1, $$rsp, 8, $$XLONG, "", $$rmk$+"740")
	ELSE
		IFZ q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	END IF
	dest$     = routine$ + CHR$ (oos[oos])
	Code ($$call, $$rel, 0, 0, 0, 0, dest$, $$rmk$+"741")
	DEC oos
	new_type  = $$XLONG
	GOTO intrinDone
'
'
' *****  LEN (x$)  *****
' *****  SIZE (x$)  *****
'
i_len:
i_size:
	acc     = Top ()
	stackedString = $$FALSE
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	IF (oos[oos] = 'v') THEN
		GOSUB GetSizeOrUpperFromHeader
	ELSE
		INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
		IF (acc != $$rax) THEN Code ($$mov, $$regreg, $$rax, acc, 0, $$XLONG, "", $$rmk$+"742")
		Code ($$or, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"743")
		Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"744")
		Code ($$mov, $$regreg, $$rdi, $$rax, 0, $$XLONG, "", $$rmk$+"745")
		Code ($$ld, $$regro, $$rax, $$rax, -16, $$XLONG, "", $$rmk$+"746")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"747")
		EmitLabel (@d1$)
	END IF
'
doneSize:
	DEC oos
	new_type  = $$XLONG
	GOTO intrinDone
	GOTO express_op
'
'
' *****  CSIZE (x$)  *****
'
i_csize:
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_csize." + CHR$ (oos[oos]), $$rmk$+"748")
	DEC oos
	new_type  = $$XLONG
	GOTO intrinDone
'
'
' *****  INCHR   (x$, y$ [,z])  *****   '
' *****  INSTR   (x$, y$ [,z])  *****   '
' *****  INCHRI  (x$, y$ [,z])  *****   ' case insensitive
' *****  INSTRI  (x$, y$ [,z])  *****   ' case insensitive
' *****  RINCHR  (x$, y$ [,z])  *****   ' reverse search
' *****  RINSTR  (x$, y$ [,z])  *****   ' reverse search
' *****  RINCHRI (x$, y$ [,z])  *****   ' reverse search, case insensitive
' *****  RINSTRI (x$, y$ [,z])  *****   ' reverse search, case insensitive
'
i_inchr:   routine$ = $$ulpc$+"_inchr.":   GOTO ii_inetc
i_instr:   routine$ = $$ulpc$+"_instr.":   GOTO ii_inetc
i_inchri:  routine$ = $$ulpc$+"_inchri.":  GOTO ii_inetc
i_instri:  routine$ = $$ulpc$+"_instri.":  GOTO ii_inetc
i_rinchr:  routine$ = $$ulpc$+"_rinchr.":  GOTO ii_inetc
i_rinstr:  routine$ = $$ulpc$+"_rinstr.":  GOTO ii_inetc
i_rinchri: routine$ = $$ulpc$+"_rinchri.": GOTO ii_inetc
i_rinstri: routine$ = $$ulpc$+"_rinstri.": GOTO ii_inetc
'
ii_inetc:
	IF (args < 2) THEN GOTO i_too_few_args
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	ab1 = at1{4,0}
	IF (at1 <> at2) THEN i_bad_arg = 2: GOTO i_bad_type
	IF (args = 2) THEN
		Code ($$st, $$roimm, 0, $$rsp, 16, $$XLONG, "", $$rmk$+"749")
	ELSE
		IFF q_type_long[at3] THEN i_bad_arg = 3: GOTO i_bad_type
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, routine$ + CHR$(oos[oos-1]) + CHR$(oos[oos]), $$rmk$+"750")
	oos = oos - 2
	new_type  = $$XLONG
	GOTO intrinDone
'
'
' ******************************************
' *****  STRING = INTRINSIC (NUMERIC)  *****
' ******************************************
'
'
' *****  ERROR$ (e)  *****  returns error string
'
i_error_d:
	IFZ q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_error.d", $$rmk$+"751")
	INC oos
	oos[oos] = 's'
	new_type = $$STRING
	GOTO intrinDone
'
'
' *****  VERSION$ (e)  *****  returns VERSION statement string
' *****  PROGRAM$ (e)  *****  returns PROGRAM statement string
'
i_version_d: getToken = versionToken: GOTO i_literal_string
i_program_d: getToken = programToken: GOTO i_literal_string
'
i_literal_string:
	IFZ q_type_long[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IFF TokenMatch (@getToken, @#T_ZERO) THEN
		Move ($$rax, $$XLONG, getToken.tindex, $$XLONG)
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0", $$rmk$+"752")
	ELSE
		Code ($$xor, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"753")
	END IF
	INC oos
	oos[oos] = 's'
	new_type = $$STRING
	GOTO intrinDone
'
'
' *****  NULL$ (x)  *****
' *****  SPACE$ (x)  *****
' *****  CSTRING$ (x)  *****
'
i_null_d:    routine$ = $$ulpc$+"_null.d":    GOTO ii_null_d
i_space_d:   routine$ = $$ulpc$+"_space.d":   GOTO ii_space_d
i_cstring_d: routine$ = $$ulpc$+"_cstring.d": GOTO ii_cstring_d
'
ii_null_d:
ii_space_d:
ii_cstring_d:
	SELECT CASE at1
		CASE $$SLONG, $$ULONG, $$XLONG
				Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"754")
		CASE ELSE
				i_bad_arg = 1: GOTO i_bad_type
	END SELECT
	INC oos
	oos[oos] = 's'
	new_type  = $$STRING
	GOTO intrinDone
'
'
' *****  BIN$  (x [,y])  *****
' *****  BINB$ (x [,y])  *****
' *****  HEX$  (x [,y])  *****
' *****  HEXX$ (x [,y])  *****
' *****  OCT$  (x [,y])  *****
' *****  OCTO$ (x [,y])  *****
'

i_bin_d:  routine$ = $$ulpc$+"_bin.d":  GOTO ii_bin_d
i_binb_d: routine$ = $$ulpc$+"_binb.d": GOTO ii_binb_d
i_hex_d:  routine$ = $$ulpc$+"_hex.d":  GOTO ii_hex_d
i_hexx_d: routine$ = $$ulpc$+"_hexx.d": GOTO ii_hexx_d
i_oct_d:  routine$ = $$ulpc$+"_oct.d":  GOTO ii_oct_d
i_octo_d: routine$ = $$ulpc$+"_octo.d": GOTO ii_octo_d
'
ii_bin_d:
ii_binb_d:
ii_hex_d:
ii_hexx_d:
ii_oct_d:
ii_octo_d:
	IFF q_type_long_or_addr[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IF (args = 1) THEN
		Code ($$mov, $$roimm, 0, $$rsp, argOff, $$XLONG, "", $$rmk$+"755")
	ELSE
		IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"756")
	INC oos
	oos[oos] = 's'
	new_type  = $$STRING
	GOTO intrinDone
'
'
' *****  CHR$ (x, [y])  *****
'
i_chr_d:
	IFZ q_type_int[at1] THEN i_bad_arg = 1: GOTO i_bad_type
	IF (args = 1) THEN
		Code ($$st, $$roimm, 1, $$rsp, 8, $$XLONG, "", $$rmk$+"757")
	ELSE
		IFZ q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_chr.d", $$rmk$+"758")
	INC oos
	oos[oos] = 's'
	new_type  = $$STRING
	GOTO intrinDone
'
'
' **************************
' *****  SIGNED$  (x)  *****
' *****  STRING$  (x)  *****
' *****  STRING   (x)  *****
' *****  STR$     (x)  *****
' **************************
'
i_signed_d:
	IF (at1 = $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	routine$ = $$ulpc$+"_signed.d." + typeName$[at1]
	GOTO istring
'
i_string_d:
i_string:
	IF (at1 = $$STRING) THEN GOTO i_string_string
	routine$ = $$ulpc$ + "_string." + typeName$[at1]
	GOTO istring
'
i_str_d:
	IF (at1 = $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	routine$ = $$ulpc$+"_str.d." + typeName$[at1]
	GOTO istring
'
istring:
	SELECT CASE at1
		CASE $$SBYTE, $$UBYTE, $$SSHORT, $$USHORT
		CASE $$SLONG, $$ULONG, $$XLONG
		CASE $$GIANT, $$SINGLE, $$DOUBLE
		CASE $$STRING
		CASE ELSE: i_bad_arg = 1: GOTO i_bad_type
	END SELECT
	IF (at1 = $$STRING) THEN DEC oos
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"759")
	INC oos
	oos[oos] = 's'
	new_type = $$STRING
	GOTO intrinDone
'
i_string_string:
	Code ($$mov, $$regro, $$rax, $$rsp, 0, $$XLONG, "", $$rmk$+"760")
	IF oos[oos] = 'v' THEN
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0", $$rmk$+"761")
		oos[oos] = 's'
	END IF
	new_type = $$STRING
	GOTO intrinDone
'
' ***************************************************
' *****  STRING = INTRINSIC (STRING [, XLONG])  *****
' ***************************************************
'
'
' ********************************************************
' *****  FORMAT$ (f$, argType, (arg$, arg$$, arg#))  *****
' ********************************************************
'
' last argument can be integer / float / string
'
i_format_d:
	IF (args < 2) THEN GOTO i_too_few_args
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxFormat$"+$$ftrail$+"24", $$rmk$+"765")
	IF (at2 = $$STRING) THEN
		IF (oos[oos] = 's') THEN
			Code ($$ld, $$regro, $$rdi, $$rsp, -8, $$XLONG, "", $$rmk$+"766")
			Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"767")
			oos[oos] = 0
			DEC oos
		END IF
	END IF
	IF (oos[oos] = 's') THEN
		Code ($$ld, $$regro, $$rdi, $$rsp, -24, $$XLONG, "", $$rmk$+"768")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"769")
	END IF
	oos[oos] = 's'
	new_type = $$STRING
	GOTO express_op
'
'
'
' *******************************
' *****  LJUST$ (x$, y)  ********
' *****  CJUST$ (x$, y)  ********
' *****  RJUST$ (x$, y)  ********
' *****  LCLIP$ (x$ [, y])  *****  Default argument value = 1
' *****  RCLIP$ (x$ [, y])  *****
' *****  LEFT$  (x$ [, y])  *****
' *****  RIGHT$ (x$ [, y])  *****
' *******************************
'
i_ljust_d: routine$ = $$ulpc$+"_ljust.d.": oa = $$FALSE: GOTO ii_ljust_d
i_cjust_d: routine$ = $$ulpc$+"_cjust.d.": oa = $$FALSE: GOTO ii_cjust_d
i_rjust_d: routine$ = $$ulpc$+"_rjust.d.": oa = $$FALSE: GOTO ii_rjust_d
i_lclip_d: routine$ = $$ulpc$+"_lclip.d.": oa = $$TRUE:  GOTO ii_lclip_d
i_rclip_d: routine$ = $$ulpc$+"_rclip.d.": oa = $$TRUE:  GOTO ii_rclip_d
i_left_d:  routine$ = $$ulpc$+"_left.d.":  oa = $$TRUE:  GOTO ii_left_d
i_right_d: routine$ = $$ulpc$+"_right.d.": oa = $$TRUE:  GOTO ii_right_d
'
ii_ljust_d:
ii_cjust_d:
ii_rjust_d:
ii_lclip_d:
ii_rclip_d:
ii_left_d:
ii_right_d:
	IF (args < 1) THEN GOTO i_too_few_args
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	IF (args = 1) THEN
		IFZ oa THEN GOTO i_too_few_args
		Code ($$st, $$roimm, 1, $$rsp, 8, $$XLONG, "", $$rmk$+"770")
	ELSE
		IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	END IF
	dest$ = routine$ + CHR$(oos[oos])
	Code ($$call, $$rel, 0, 0, 0, 0, dest$, $$rmk$+"771")
	oos[oos] = 's'
	new_type  = $$STRING
	GOTO intrinDone
'
'
' *******************************
' *****  MID$ (x$, y [,z])  *****  Default value of [,z] = infinity
' *******************************
'
i_mid_d:
	IF (args < 2) THEN GOTO i_too_few_args
	IF (args = 2) THEN at3 = $$XLONG
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	IFF q_type_long[at2] THEN i_bad_arg = 2: GOTO i_bad_type
	IFF q_type_long[at3] THEN i_bad_arg = 3: GOTO i_bad_type
	IF (args = 2) THEN Code ($$st, $$roimm, 0x7FFFFFFF, $$rsp, 16, $$XLONG, "", $$rmk$+"772")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_mid.d." + CHR$(oos[oos]), $$rmk$+"773")
	oos[oos]  = 's'
	new_type  = $$STRING
	GOTO intrinDone
'
'
' *************************************
' *****  STUFF$ (s$, i$, y [,z])  *****
' *************************************
'
i_stuff_d:
	IF (args < 3) THEN GOTO i_too_few_args
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	IF (at1 <> at2) THEN i_bad_arg = 2: GOTO i_bad_type
	IFF q_type_long[at3] THEN i_bad_arg = 3: GOTO i_bad_type
	IF (args = 3) THEN
		Code ($$st, $$roimm, -1, $$rsp, 24, $$XLONG,"", $$rmk$+"774")
	ELSE
		IFF q_type_long[at4] THEN i_bad_arg = 4: GOTO i_bad_type
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_stuff.d." + CHR$(oos[oos-1]) + CHR$(oos[oos]), $$rmk$+"775")
	DEC oos
	oos[oos]  = 's'
	new_type  = $$STRING
	GOTO intrinDone
'
'
' *****  TRIM$ (x$)  *****
' *****  LTRIM$ (x$)  *****
' *****  RTRIM$ (x$)  *****
' *****  LCASE$ (x$)  *****
' *****  UCASE$ (x$)  *****
' *****  CSIZE$ (x$)  *****
'
i_trim_d:  routine$ = $$ulpc$+"_trim.d.":  GOTO ii_trim_d
i_ltrim_d: routine$ = $$ulpc$+"_ltrim.d.": GOTO ii_ltrim_d
i_rtrim_d: routine$ = $$ulpc$+"_rtrim.d.": GOTO ii_rtrim_d
i_lcase_d: routine$ = $$ulpc$+"_lcase.d.": GOTO ii_lcase_d
i_ucase_d: routine$ = $$ulpc$+"_ucase.d.": GOTO ii_ucase_d
i_csize_d: routine$ = $$ulpc$+"_csize.d.": GOTO ii_csize_d
'
ii_ltrim_d:
ii_rtrim_d:
ii_trim_d:
ii_lcase_d:
ii_ucase_d:
ii_csize_d:
	IF (at1 != $$STRING) THEN i_bad_arg = 1: GOTO i_bad_type
	Code ($$call, $$rel, 0, 0, 0, 0, routine$ + CHR$(oos[oos]), $$rmk$+"776")
	oos[oos]  = 's'
	new_type  = $$STRING
	GOTO intrinDone
'
'
'
' ***************************************
' *****  NUMERIC = INTRINSIC (???)  *****
' ***************************************
'
'
' *****  SIZE (typeName)  *****              built-in or user-defined
' *****  SIZE (simpleVariable)  *****
' *****  SIZE (stringVariable)  *****
' *****  SIZE (compositeVariable)  *****
' *****  SIZE (compositeVariable.componentName...)  *****
' *****  SIZE (arrayName [dimension, dimension, ...])  *****
'
' *****  TYPE (typeName)  *****              built-in or user-defined
' *****  TYPE (simpleVariable)  *****
' *****  TYPE (stringVariable)  *****
' *****  TYPE (compositeVariable)  *****
' *****  TYPE (compositeVariable.componentName...)  *****
' *****  TYPE (arrayName [dimension, dimension, ...])  *****
'
i_lenof:
i_sizeof:
	getSize   = $$TRUE
	getType   = $$FALSE
	GOTO i_sizeof_typeof
'
i_typeof:
	getSize   = $$FALSE
	getType   = $$TRUE
	GOTO i_sizeof_typeof
'
i_sizeof_typeof:
	hold          = tokenPtr
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38002407): GOTO eeeSyntax
	holder        = tokenPtr
	NextToken (@argToken)
	kind          = argToken.tp.kind
	SELECT CASE kind
		CASE $$KIND_STATE_INTRIN
					SELECT CASE TRUE
						CASE TokenMatch (@argToken, @#T_DOUBLE):    varType = $$DOUBLE
						CASE TokenMatch (@argToken, @#T_FUNCADDR):  varType = $$FUNCADDR
						CASE TokenMatch (@argToken, @#T_GIANT):     varType = $$GIANT
						CASE TokenMatch (@argToken, @#T_GOADDR):    vartype = $$GOADDR
						CASE TokenMatch (@argToken, @#T_SBYTE):     varType = $$SBYTE
						CASE TokenMatch (@argToken, @#T_SINGLE):    varType = $$SINGLE
						CASE TokenMatch (@argToken, @#T_SLONG):     varType = $$SLONG
						CASE TokenMatch (@argToken, @#T_SSHORT):    varType = $$SSHORT
						CASE TokenMatch (@argToken, @#T_STRING):
									IF getSize THEN XcowlErr (38002423): GOTO eeeUndefined
									varType = $$STRING
									typeSize = 1
						CASE TokenMatch (@argToken, @#T_UBYTE):     varType = $$UBYTE
						CASE TokenMatch (@argToken, @#T_ULONG):     varType = $$ULONG
						CASE TokenMatch (@argToken, @#T_USHORT):    varType = $$USHORT
						CASE TokenMatch (@argToken, @#T_XLONG):     varType = $$XLONG
						CASE ELSE:    XcowlErr (38002430): GOTO eeeKindMismatch
					END SELECT
					GOSUB SizeofTypeofTypesAndVariables
		CASE $$KIND_TYPES
					varType = argToken.tindex
					GOSUB SizeofTypeofTypesAndVariables
		CASE $$KIND_VARIABLES
					aat = argToken.tindex
					IFZ m_addr$[aat] THEN AssignAddress (argToken)
					IF XERROR THEN EXIT FUNCTION
					varType = TheType (argToken)
					IF (varType = $$STRING) THEN
						PeekToken (@check)
						IF TokenMatch (@check, @#T_RPAREN) THEN
							dacc  = OpenAccForType ($$XLONG)
							IF getType THEN
								Code ($$mov, $$regimm, dacc, $$STRING, 0, $$XLONG, "", $$rmk$+"777")
							ELSE
								Move (dacc, $$XLONG, argToken.tindex, $$XLONG)
								GOSUB GetSizeOrUpperFromHeader
							END IF
							NextToken (@token)
							EXIT SELECT
						ELSE
							tokenPtr = hold
							GOTO intrinsic_normal
						END IF
					END IF
					GOSUB SizeofTypeofTypesAndVariables
		CASE $$KIND_ARRAYS
					aat = argToken.tindex
					IFZ m_addr$[aat] THEN AssignAddress (argToken)
					IF XERROR THEN EXIT FUNCTION
					varType = TheType (argToken)
					GOSUB SizeofTypeofArrays
		CASE $$KIND_INTRINSICS, $$KIND_LPARENS:
					tokenPtr = hold
					GOTO intrinsic_normal
		CASE ELSE
					XcowlErr (38002469): GOTO eeeKindMismatch
	END SELECT
	IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (38002471): GOTO eeeSyntax
	new_data  = #T_ZERO
	new_type  = $$XLONG
	GOTO express_op
'
SUB SizeofTypeofTypesAndVariables
	DO WHILE (varType >= $$SCOMPLEX)
		PeekToken (@check)
		inarray = $$FALSE
		SELECT CASE check.tp.kind
			CASE $$KIND_SYMBOLS
						IF array THEN XcowlErr (38002482): GOTO eeeSyntax
						array   = $$FALSE                           ' .component
						NextToken (@token)
			CASE $$KIND_ARRAY_SYMBOLS
						IF array THEN XcowlErr (38002486): GOTO eeeSyntax
						array   = $$TRUE                            ' .component[]
						NextToken (@token)
						NextToken (@tokenTmp)
						IFF TokenMatch (@tokenTmp, @#T_LBRAK) THEN XcowlErr (38002490): GOTO eeeSyntax
						NextToken (@tokenTmp)
						IF (tokenTmp.tp.kind = $$KIND_LITERALS) THEN
							NextToken (@tokenTmp)
							array   = $$FALSE                         ' .component[0]
							inarray = $$TRUE
						END IF
						IFF TokenMatch (@tokenTmp, @#T_RBRAK) THEN XcowlErr (38002497): GOTO eeeSyntax
			CASE ELSE:  EXIT DO
		END SELECT
		found     = $$FALSE
		component = 0
		DO
			componentToken  = typeEleToken[varType, component]
			IF TokenMatch (@token, @componentToken) THEN
				oldType = varType
				IF array THEN
					elements  = typeEleUBound[varType, component] + 1
				END IF
				varType   = typeEleType[varType, component]
				IF (varType = $$STRING) THEN
					IF inarray THEN
						typeSize = typeEleStringSize[oldType, component]
					ELSE
						typeSize = typeEleSize[oldType, component]
					END IF
				END IF
				found     = $$TRUE
				EXIT DO
			END IF
			INC component
		LOOP WHILE (component <= typeEleCount[varType])
		IFZ found THEN XcowlErr (38002522): GOTO eeeComponent
	LOOP
	IF (varType != $$STRING) THEN
		typeSize  = typeSize[varType]
		IF array THEN typeSize  = elements * typeSize
	END IF
	IF (typeSize <= 0) THEN XcowlErr (38002528): GOTO eeeCompiler
	SELECT CASE TRUE
		CASE getSize:   value = typeSize
		CASE getType:   value = varType
	END SELECT
	dacc          = OpenAccForType ($$XLONG)
	Code ($$mov, $$regimm, dacc, value, 0, $$XLONG, "", $$rmk$+"778")
	NextToken (@token)
END SUB
'
SUB SizeofTypeofArrays
	stringData  = $$FALSE
	arrayType   = TheType (argToken)
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (38002542): GOTO eeeSyntax
	NextToken (@token)
	IF TokenMatch (@token, @#T_RBRAK) THEN                      ' SIZE (a[])
		dacc      = OpenAccForType ($$XLONG)
		Move (dacc, $$XLONG, argToken.tindex, $$XLONG)
		NextToken (@token)
	ELSE
		tokenPtr  = holder
		new_type  = arrayType
		NextToken (@new_data)
		new_prec = 0: excess = 0
		new_op    = #T_ZERO
		IFF TokenMatch (@argToken, @new_data) THEN XcowlErr (38002554): GOTO eeeCompiler
		ExpressArray (@new_op, @new_prec, @new_data, @new_type, 0, @excess, 0, 0)
		IF XERROR THEN EXIT FUNCTION
		IFZ excess THEN
			IF (new_type != $$STRING) THEN XcowlErr (38002558): GOTO eeeNeedExcessComma
			stringData = $$TRUE
			DEC oos
		END IF
		NextToken (@token)
		dacc      = Top ()
		new_op    = token
	END IF
'
' Get # of elements out of header and multiply times size of array type
'
	SELECT CASE TRUE
		CASE getSize
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					IF stringData THEN
						Code ($$or, $$regreg, dacc, dacc, 0, $$XLONG, "", $$rmk$+"779")
						Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"780")
						Code ($$ld, $$regro, dacc, dacc, -16, $$XLONG, "", $$rmk$+"781")
					ELSE
						Code ($$or, $$regreg, dacc, dacc, 0, $$XLONG, "", $$rmk$+"782")
						Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"783")
						Code ($$ld, $$regro, $$rsi, dacc, -8, $$XLONG, "", $$rmk$+"784")
						Code ($$ld, $$regro, dacc, dacc, -16, $$XLONG, "", $$rmk$+"785")
						Code ($$and, $$regimm, $$rsi, 0x0000FFFF, 0, $$XLONG, "", $$rmk$+"786")
						Code ($$imul, $$regreg, dacc, $$rsi, 0, $$XLONG, "", $$rmk$+"787")
					END IF
					EmitLabel (@d1$)
		CASE getType
					INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
					Code ($$or, $$regreg, dacc, dacc, 0, $$XLONG, "", $$rmk$+"788")
					Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"789")
					Code ($$ld, $$regro, dacc, dacc, -6, $$UBYTE, "", $$rmk$+"790")
					EmitLabel (@d1$)
	END SELECT
END SUB
'
'
' *****  ISDATA (arrayName [dimension, dimension, ...])  *****
' *****  ISNODE (arrayName [dimension, dimension, ...])  *****
' *****  UBOUND (arrayName [])  *****
' *****  UBOUND (arrayName [dimension, dimension, ...])  *****
'
i_isdata:
	getData = $$TRUE
i_isnode:
	getDataOrNode = $$TRUE
i_ubound:
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38002606): GOTO eeeSyntax
	holder  = tokenPtr
	NextToken (@atoken)
	kind    = atoken.tp.kind
	SELECT CASE kind
		CASE $$KIND_ARRAYS, $$KIND_VARIABLES
		CASE ELSE: XcowlErr (38002612): GOTO eeeSyntax
	END SELECT
	IFZ m_addr$[atoken.tindex] THEN AssignAddress (atoken)
	IF XERROR THEN EXIT FUNCTION
	atype   = TheType (atoken)
	IF (kind = $$KIND_VARIABLES) THEN
		IF (atype != $$STRING) THEN XcowlErr (38002618): GOTO eeeKindMismatch
		dacc      = OpenAccForType ($$XLONG)
		Move (dacc, $$XLONG, atoken.tindex, $$XLONG)
		NextToken (@token)
		new_op  = token
	ELSE
		NextToken (@token)
		IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (38002625): GOTO eeeSyntax
		NextToken (@token)
		IF TokenMatch (@token, @#T_RBRAK) THEN                              ' UBOUND(a[]) case
			dacc      = OpenAccForType ($$XLONG)
			Move (dacc, $$XLONG, atoken.tindex, $$XLONG)
			NextToken (@token)
			IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (38002631): GOTO eeeSyntax
		ELSE
			excess    = 0
			tokenPtr  = holder
			new_type  = atype
			NextToken (@new_data)
			new_op    = #T_ZERO
			new_prec  = 0
			IFF TokenMatch (@atoken, @new_data) THEN XcowlErr (38002639): GOTO eeeCompiler
			ExpressArray (@new_op, @new_prec, @new_data, @new_type, 0, @excess, 0, 0)
			IF XERROR THEN EXIT FUNCTION
			IFZ excess THEN
				IF (new_type != $$STRING) THEN XcowlErr (38002643): GOTO eeeNeedExcessComma
				DEC oos
			END IF
			NextToken (@token)
			IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (38002647): GOTO eeeSyntax
			IF (arrayType = $$STRING) THEN DEC oos
			dacc      = Top ()
			new_op    = token
		END IF
	END IF
	IF getDataOrNode THEN
		GOSUB TestHigherLevel
		getData = $$FALSE
		getDataOrNode = $$FALSE
	ELSE
		GOSUB GetSizeOrUpperFromHeader
		Code ($$dec, $$reg, dacc, 0, 0, $$XLONG, "", $$rmk$+"792")
	END IF
	new_data  = #T_ZERO
	new_type  = $$XLONG
	GOTO express_op
'
' Get size/ubound from string/array header
'
SUB GetSizeOrUpperFromHeader
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$or, $$regreg, dacc, dacc, 0, $$XLONG, "", $$rmk$+"793")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"794")
	Code ($$ld, $$regro, dacc, dacc, -16, $$XLONG, "", $$rmk$+"795")
	EmitLabel (@d1$)
END SUB
'
' Test higher level bit
'
SUB TestHigherLevel
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	INC labelNumber: d2$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$or, $$regreg, dacc, dacc, 0, $$XLONG, "", $$rmk$+"797")
	Code ($$jz, $$rel, 0, 0, 0, 0, d2$, $$rmk$+"798")
	Code ($$test, $$roimm, (1 << 29), dacc, -8, $$XLONG, "", $$rmk$+"799")
	IF getData THEN
		Code ($$jnz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"800")
	ELSE
		Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"801")
	END IF
	Code ($$xor, $$regreg, dacc, dacc, 0, $$XLONG, "", $$rmk$+"802")
	Code ($$not, $$reg, dacc, 0, 0, $$XLONG, "", $$rmk$+"803")
	Code ($$jmp, $$rel, 0, 0, 0, 0, d2$, $$rmk$+"804")
	EmitLabel (@d1$)
	Code ($$xor, $$regreg, dacc, dacc, 0, $$XLONG, "", $$rmk$+"805")
	EmitLabel (@d2$)
END SUB
'
'
' *****  GOADDRESS (labelSymbol)  *****
'
i_goaddress:
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38002701): GOTO eeeSyntax
	NextToken (@token)
	kind  = token.tp.kind
	stype = token.tp.type
	IF (kind <> $$KIND_LABELS) THEN XcowlErr (38002705): GOTO eeeSyntax
	IF (stype <> $$GOADDR) THEN XcowlErr (38002706): GOTO eeeTypeMismatch
	dr  = OpenAccForType ($$GOADDR)
'
i_goaddr_of_reg:
	go_name$  = tab_lab$[token.tindex]
	Code ($$mov, $$regimm, dr, 0, 0, $$XLONG, go_name$, $$rmk$+"806")
	NextToken (@token)
	IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (38002713): GOTO eeeSyntax
	new_type  = $$GOADDR
	new_op    = token
	GOTO express_op
'
'
' *****  SUBADDRESS (SubName)  *****
'
i_subaddress:
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38002723): GOTO eeeSyntax
	NextToken (@token)
	kind  = token.tp.kind
	stype = token.tp.type
	IF (kind <> $$KIND_LABELS) THEN XcowlErr (38002727): GOTO eeeSyntax
	IF (stype <> $$SUBADDR) THEN XcowlErr (38002728): GOTO eeeTypeMismatch
	dr    = OpenAccForType ($$SUBADDR)
'
i_subaddr_of_reg:
	sub_name$ = tab_lab$[token.tindex]
	Code ($$mov, $$regimm, dr, 0, 0, $$XLONG, sub_name$, $$rmk$+"807")
	NextToken (@token)
	IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (38002735): GOTO eeeSyntax
	new_type  = $$SUBADDR
	new_op    = token
	GOTO express_op
'
'
' *****  FUNCADDRESS (FuncName())  *****
'
i_funcaddress:
	ifuncaddr = $$TRUE
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38002746): GOTO eeeSyntax
	NextToken (@token)
addrop_func:
	funcToken = token
	kind = token.tp.kind
	IF (kind <> $$KIND_FUNCTIONS) THEN XcowlErr (38002751): GOTO eeeSyntax
	dr        = OpenAccForType ($$FUNCADDR)
'
i_funcaddr_of_reg:
	funcaddrFuncNumber = funcToken.tindex
	funcaddrToken = funcToken[funcaddrFuncNumber]
	IFZ (funcaddrToken.tp.allo AND $$ALLO_DECLARED) THEN
		funcaddrToken = XxxUndeclaredFunction (funcaddrToken)
		IFZ (funcaddrToken.tp.allo AND $$ALLO_DECLARED) THEN XcowlErr (38002759): GOTO eeeUndeclared
	END IF
	funcaddrScope = funcScope[funcaddrFuncNumber]
	SELECT CASE funcaddrScope
		CASE $$FUNC_EXTERNAL, $$FUNC_DECLARE
					funcLabel$ = funcLabel$[funcaddrFuncNumber]
		CASE $$FUNC_INTERNAL
					funcLabel$ = "func" + HEX$(funcaddrFuncNumber)
		CASE ELSE
					XcowlErr (38002768): GOTO eeeCompiler
	END SELECT
	IF XERROR THEN EXIT FUNCTION
'	#cw = $$TRUE                                                          '*cw* 230724+ testing
	Code ($$mov, $$regimm, dr, 0, 0, $$XLONG, @funcLabel$, $$rmk$+"808")
'	#cw = $$FALSE                                                         '*cw* 230724+ testing
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38002773): GOTO eeeSyntax
	NextToken (@token)
	IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (38002775): GOTO eeeSyntax
	IF ifuncaddr THEN
		ifuncaddr = $$FALSE
		NextToken (@token)
		IFF TokenMatch (@token, @#T_RPAREN) THEN XcowlErr (38002779): GOTO eeeSyntax
	END IF
	new_data  = #T_ZERO
	new_type  = $$FUNCADDR
	new_op    = token
	GOTO express_op
'
'
' *****  INTRINSIC SUPPORT  *****
'
intrinDone:
'	Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"809")         '*cw* 230318-
	IF frameSize THEN                                                        '*cw* 230318+
		Code ($$add, $$regimm, $$rsp, frameSize, 0, $$XLONG, "", $$rmk$+"809") '*cw* 230318+
	END IF                                                                   '*cw* 230318+
	GOTO express_op
'
i_bad_type:
	tokenPtr = arg_pos${i_bad_arg-1}
	XcowlErr (38002795): GOTO eeeTypeMismatch
'
i_too_few_args:
	IF args THEN tokenPtr = arg_pos${args-1}
	XcowlErr (38002799): GOTO eeeTooFewArgs
'
'
'
' *****************************************
' *****  FUNCTIONS  *****  FUNCTIONS  *****
' *****************************************
'
express_function:
	args = 0
	argBytes = 0
	fkind = token.tp.kind
	hold_func_ptr = tokenPtr
'
	IF TokenMatch (@token, @#T_ATSIGN) THEN
		hfp       = hold_func_ptr
		NextToken (@token)
		vtype     = TheType (token)
		fkind     = token.tp.kind
		hold_func_ptr = tokenPtr
		SELECT CASE fkind
			CASE $$KIND_VARIABLES, $$KIND_ARRAYS
			CASE ELSE:  XcowlErr (38002821): GOTO eeeSyntax
		END SELECT
		tokenPtr  = hfp
		new_op    = Eval (@new_type)
		IF XERROR THEN EXIT FUNCTION
		INC labelNumber: fzip$ = $$ulpc$ + HEX$(labelNumber, 4)
		IF (new_type != $$FUNCADDR) THEN XcowlErr (38002827): GOTO eeeTypeMismatch
		IFF TokenMatch (@new_op, @#T_LPAREN) THEN XcowlErr (38002828): GOTO eeeSyntax
		DEC tokenPtr
		DIM tokenTemp[]
		IF (vtype = $$FUNCADDR) THEN    ' FUNCADDR variable/array
			fat     = token.tindex
			IFZ tabArg[fat, ] THEN XcowlErr (38002833): GOTO eeeCompiler
			ATTACH tabArg[fat, ] TO tokenTemp[]
			CloneArrayTOKEN (@parArg[], @tokenTemp[])
			ATTACH tokenTemp[] TO tabArg[fat, ]
		ELSE                            ' FUNCADDR .component
			ATTACH typeEleArg[preType, componentNumber, ] TO tokenTemp[]
			CloneArrayTOKEN (@parArg[], @tokenTemp[])
			ATTACH tokenTemp[] TO typeEleArg[preType, componentNumber, ]
		END IF
	END IF
'
	hold_func   = token
	func_num    = token.tindex
	SELECT CASE fkind
		CASE $$KIND_FUNCTIONS
					passError   = $$TRUE
					IF (funcScope[func_num] = $$FUNC_EXTERNAL) THEN
						IF (funcKind[func_num] = $$CFUNC) THEN passError = $$FALSE
					END IF
					IFZ funcArg[func_num, ] THEN
						token = XxxUndeclaredFunction (token)
						IFZ funcArg[func_num, ] THEN XcowlErr (38002854): GOTO eeeUndeclared
						hold_func = token
					END IF
					callKind = funcKind[func_num]
					ATTACH funcArg[func_num, ] TO tokenTemp[]
					CloneArrayTOKEN (@parArg[], @tokenTemp[])
					ATTACH tokenTemp[] TO funcArg[func_num, ]
					func_type   = parArg[0].tindex
					total_args  = parArg[0].tp.type
		CASE $$KIND_VARIABLES, $$KIND_ARRAYS
					func_type   = parArg[0].tindex
					total_args  = parArg[0].tp.type
'         callKind    = $$XFUNC                         ' xxxxxxxxxx
'         callKind    = parArg[0] >> 29                 ' xxxxxxxxxx
					callKind    = parArg[0].tp.stsp               ' xxxxxxxxxx
					IFZ callKind THEN callKind = $$XFUNC          ' xxxxxxxxxx
		CASE ELSE
					XcowlErr (38002871): GOTO eeeCompiler
	END SELECT
	DIM argArg[]
	CloneArrayTOKEN (@argArg[], @parArg[])
	IF (func_type AND (func_type < $$SLONG)) THEN func_type = $$XLONG
'
	DIM argReg[31]
	DIM orgReg[31]
	etc = $$FALSE
	rctoken = #T_ZERO
	IF (func_type >= $$SCOMPLEX) THEN
		rcname$ = ".compositeReturnAddr." + HEX$(compositeArg)
		INC compositeArg
		rctoken = AddSymbol (@rcname$, spaces, $$KIND_VARIABLES, $$AUTOX, 0, func_number)
		rctoken.tp.allo = $$AUTOX                                        'is this needed ??????????????????
		rcnum   = rctoken.tindex
		tab_sym[rcnum] = rctoken
		tabType[rcnum] = func_type
		IF m_addr[rcnum] THEN XcowlErr (38002889): GOTO eeeCompiler
		AssignAddress (rctoken)
		IF XERROR THEN EXIT FUNCTION
	END IF
'
'	cfunc = $$FALSE                           '*cw* 230807-
	hold_place = tokenPtr
	IF (fkind = $$KIND_FUNCTIONS) THEN
		IF (funcKind[func_num] = $$CFUNC) THEN
'			cfunc = $$TRUE                        '*cw* 230807-
			IF total_args THEN
				parArgs = parArg[0].tp.type
				IF (parArg[parArgs].tindex = $$ETC) THEN
					etc = $$TRUE
					DEC total_args
				END IF
			END IF
		END IF
		IFZ hold_func.tp.allo THEN
			hold_func = XxxUndeclaredFunction (hold_func)
			IFZ hold_func.tp.allo THEN XcowlErr (38002909): GOTO eeeUndeclared
			callKind = funcKind[func_num]
		END IF
	END IF
'
	NextToken (@token)
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38002915): GOTO eeeSyntax
'
' if FUNCADDR variable or array, test function address and skip if addr = 0
'
	SELECT CASE fkind
		CASE $$KIND_FUNCTIONS
					OpenBothAccs ()
		CASE $$KIND_VARIABLES, $$KIND_ARRAYS
					SELECT CASE TRUE
						CASE (a0 AND (a0 = toes))
									IF a1 THEN Push ($$RA1, a1_type)
						CASE (a1 AND (a1 = toes))
									IF a0 THEN Push ($$RA0, a0_type)
									Move ($$RA0, $$XLONG, $$RA1, $$XLONG)
									a1 = 0: a1_type = 0
						CASE ELSE
									XcowlErr (38002931): GOTO eeeCompiler
					END SELECT
					Code ($$xor, $$regreg, $$rdx, $$rdx, 0, $$XLONG,"", $$rmk$+"810")
					Code ($$or, $$regreg, $$rax, $$rax, 0, $$XLONG,"", $$rmk$+"811")
					Code ($$jz, $$rel, 0, 0, 0, 0, fzip$, $$rmk$+"812")
					Push ($$RA0, $$XLONG)
		CASE ELSE: XcowlErr (38002937): GOTO eeeCompiler
	END SELECT
'
' IF no arguments, skip argument processing
'
	PeekToken (@check)
	IF TokenMatch (@check, @#T_RPAREN) THEN
		NextToken (@token)
		noArgs  = $$TRUE
		new_op  = token
		GOTO PastArgs
	END IF
	noArgs    = $$FALSE
'
	IF TokenMatch (@old_op,@#T_ADDR_OP) THEN DEC tokenPtr: XcowlErr (38002951): GOTO eeeSyntax
	hold_rerun = tokenPtr
'
' ********************************
' *****  FUNCTION ARGUMENTS  *****
' ********************************
'
	args = 0
	argNum = 1
	refCount = 0
	argOffset = 0
	DIM farg[63]
	frame = $$FALSE
	skipit = $$FALSE
	fixArgs = $$FALSE
	IF (fkind = $$KIND_FUNCTIONS) THEN
		SELECT CASE callKind
			CASE $$XFUNC: argSize = funcArgSize[func_num]
			CASE $$SFUNC: IF $$linux THEN
											XcowlErr (38002970): GOTO eeeCompiler
										ELSE
											argSize = funcArgSize[func_num]
										END IF
			CASE $$CFUNC: argSize = funcArgSize[func_num]
			CASE ELSE: XcowlErr (38002975): GOTO eeeCompiler
		END SELECT
	ELSE
		IF (callKind = $$CFUNC) THEN          '*cw* 230731
			IF (total_args <= 6) THEN           '*cw* 230731
				argSize = 0                       '*cw* 230731
			ELSE                                '*cw* 230731
				argSize = (total_args - 6) * 8    '*cw* 230731
			END IF                              '*cw* 230731
		ELSE                                  '*cw* 230731
			argSize = total_args * 8
		END IF                                '*cw* 230731
	END IF
'
' create frame if necessary  -  CFUNCTIONs
'
' IF frame THEN Code ($$sub, $$regimm, $$rsp, argSize, 0, $$XLONG, "", $$rmk$+"813")
'
	DO
		PeekToken (@check)
		IF TokenMatch (check, @#T_ATSIGN) THEN  '  "" (BYREF) prefix on next argument ?
			INC refCount
			qref = $$TRUE
			NextToken (@token)       ' skip ""
		ELSE
			qref = $$FALSE
		END IF
'
		PeekToken (@ttoken)
		tkind     = ttoken.tp.kind
		ttype     = TheType (ttoken)
		tt        = ttoken.tindex
		refarray  = $$FALSE
		valarray  = $$FALSE
		stringLit = $$FALSE
		IF qref THEN
			IF (callKind == $$CFUNC) THEN XcowlErr (38003003): GOTO eeeByRef
			SELECT CASE tkind
				CASE $$KIND_VARIABLES
				CASE $$KIND_ARRAYS
							IFZ m_addr$[tt] THEN AssignAddress (ttoken)
							IF XERROR THEN EXIT FUNCTION
							NextToken (@token)
							NextToken (@token)
							IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (38003011): GOTO eeeSyntax
							NextToken (@token)
							IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (38003013): GOTO eeeSyntax
							refarray  = $$TRUE
							NextToken (@new_op)
							new_prec  = new_op.tp.type AND 0xF        '$$PREC
							new_data  = ttoken
							new_type  = TheType (ttoken)
							skipit    = $$TRUE
				CASE $$KIND_LITERALS, $$KIND_SYSCONS, $$KIND_CONSTANTS
							IF (ttype != $$STRING) THEN XcowlErr (38003021): GOTO eeeByRef
							stringLit = 0x20
				CASE ELSE
							XcowlErr (38003024): GOTO eeeByRef
			END SELECT
		ELSE
			SELECT CASE tkind
				CASE $$KIND_VARIABLES
				CASE $$KIND_CONSTANTS, $$KIND_SYSCONS
				CASE $$KIND_ARRAYS
							IFZ m_addr$[tt] THEN AssignAddress (ttoken)
							IF XERROR THEN EXIT FUNCTION
							htp       = tokenPtr
							NextToken (@check)
							NextToken (@check)
							IFF TokenMatch (@check, @#T_LBRAK) THEN tokenPtr = htp + 1: XcowlErr (38003036): GOTO eeeByVal
							NextToken (@check)
							IF TokenMatch (@check, @#T_RBRAK)  THEN tokenPtr = htp + 1: XcowlErr (38003038): GOTO eeeByVal
							tokenPtr  = htp
							valarray  = $$TRUE
				CASE $$KIND_CHARCONS, $$KIND_LITERALS
				CASE $$KIND_ADDR_OPS
				CASE $$KIND_UNARY_OPS, $$KIND_BINARY_OPS
				CASE $$KIND_INTRINSICS, $$KIND_STATEMENTS_INTRINSICS
				CASE $$KIND_FUNCTIONS, $$KIND_LPARENS
				CASE ELSE:  INC tokenPtr:  XcowlErr (38003046): GOTO eeeByVal
			END SELECT
		END IF
'
		IFZ skipit THEN
			test = 0: new_prec = 0: new_type = 0
			new_op = #T_ZERO
			new_data = #T_ZERO
			Expresso (@test, @new_op, @new_prec, @new_data, @new_type)
			IF XERROR THEN EXIT FUNCTION
			IFZ new_type THEN XcowlErr (38003056): GOTO eeeTypeMismatch
			IF (new_type < $$SLONG) THEN new_type = $$SLONG
		END IF
		skipit        = $$FALSE
		IF (new_type = $$STRING) THEN
			string_type = $$TRUE
		ELSE
			string_type = $$FALSE
		END IF
'
		IFZ refarray THEN
			IF (new_type >= $$SCOMPLEX) THEN
				IFF TokenMatch (@new_data, @#T_ZERO) THEN
					dacc = OpenAccForType (new_type)
					Move (dacc, $$XLONG, new_data.tindex, $$XLONG)
					new_data = #T_ZERO
				ELSE
					dacc = Top ()
					IF (dacc != $$RA0) THEN PRINT "??? OK ???"
				END IF
				IF qref THEN
					qref      = $$FALSE
				ELSE
					cname$  = ".compositeArg." + HEX$(compositeArg)
					INC compositeArg
					ctoken = AddSymbol (@cname$, 0, $$KIND_VARIABLES, $$AUTOX, 0, func_number)
					ctoken.tp.allo  = $$AUTOX                                                  ' needed ????????
					cnum = ctoken.tindex
					tab_sym[cnum] = ctoken
					tabType[cnum] = new_type
					IF m_addr[cnum] THEN XcowlErr (38003086): GOTO eeeCompiler
					AssignAddress (ctoken)
					IF XERROR THEN EXIT FUNCTION
					csizer  = typeSize[new_type]
					Move ($$rdi, $$XLONG, ctoken.tindex, $$XLONG)
					Move ($$rsi, $$XLONG, dacc, $$XLONG)
					Code ($$mov, $$regimm, $$rcx, csizer, 0,$$XLONG,"", $$rmk$+"814")
					Code ($$mov, $$regreg, dacc, $$rdi, 0, $$XLONG, "", $$rmk$+"815")
					Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_assignComposite", $$rmk$+"816")
				END IF
			END IF
		END IF
'
		SELECT CASE TRUE
			CASE etc:     IF (argNum > total_args) THEN
											parArg[argNum].tindex = new_type
											argArg[argNum].tindex = new_type
											to_type         = new_type
										ELSE
											to_type         = parArg[argNum].tindex
										END IF
			CASE ELSE:    IF (argNum > total_args) THEN
											IF func_num THEN XcowlErr (38003108): GOTO eeeTooManyArgs
										END IF
										to_type           = parArg[argNum].tindex
										IF (to_type = $$ANY) THEN
											IF refarray THEN
												kind  = $$KIND_ARRAYS
											ELSE
												kind  = $$KIND_VARIABLES
												IF (parArg[argNum].tp.kind = $$KIND_ARRAYS) THEN XcowlErr (38003116): GOTO eeeKindMismatch
											END IF
											parArg[argNum].tp.kind = kind
											parArg[argNum].tindex = new_type
'
											argArg[argNum].tp.kind = kind
											argArg[argNum].tindex = new_type
											to_type         = new_type
										END IF
		END SELECT
'
'   Check for KIND MISMATCH, except etc...
'
		IF func_num OR (argNum > total_args) THEN
			pkind = parArg[argNum].tp.kind
			IF refarray THEN
				IF (pkind != $$KIND_ARRAYS) THEN
					tokenPtr = tokenPtr - 3
					XcowlErr (38003134): GOTO eeeKindMismatch
				END IF
			ELSE
				IF (pkind = $$KIND_ARRAYS) THEN DEC tokenPtr: XcowlErr (38003137): GOTO eeeKindMismatch
			END IF
		END IF
		IFZ refarray THEN
			IF (to_type < $$SLONG) THEN to_type = $$SLONG
		END IF
		argToken[argNum]  = new_data
		from_type = new_type
		IF (to_type != $$ANY) THEN
			IF ((to_type = $$STRING) XOR (from_type = $$STRING)) THEN
				XcowlErr (38003147): GOTO eeeTypeMismatch
			END IF
		END IF
'
' If type conversion is required to assign value back to original
' variable, then fixArgs stack handling method is necessary to avoid
' overwriting arguments on stack when calling conversion routines.
'
		IF (to_type != from_type) THEN
			IF (to_type >= $$SCOMPLEX) THEN XcowlErr (38003156): GOTO eeeTypeMismatch
			IF (from_type >= $$SCOMPLEX) THEN XcowlErr (38003157): GOTO eeeTypeMismatch
			conv = typeConvert[to_type, from_type] {{$$BYTE0}}
			SELECT CASE conv
				CASE -1  : XcowlErr (38003160): GOTO eeeTypeMismatch
				CASE  0  : ' no conversion
				CASE ELSE: IF qref THEN fixArgs = $$TRUE
										IF refarray THEN tokenPtr = tokenPtr - 3: XcowlErr (38003163): GOTO eeeTypeMismatch
			END SELECT
			IF refarray THEN
				t = q_type_long_or_addr[to_type]
				f = q_type_long_or_addr[from_type]
				IF t THEN
					IFZ f THEN tokenPtr = tokenPtr - 3: XcowlErr (38003169): GOTO eeeTypeMismatch
				ELSE
					IF f THEN tokenPtr = tokenPtr - 3: XcowlErr (38003171): GOTO eeeTypeMismatch
				END IF
			END IF
		END IF
'
' if argument hasn't been stacked, stack it.
'
		stack = $$FALSE
		IFF TokenMatch (@new_data, @#T_ZERO) THEN
			kind = new_data.tp.kind
			nn = new_data.tindex
			orgReg[argNum] = r_addr[nn]
			argArg[argNum].tindex = from_type
			IF (parArg[argNum].tp.kind = $$KIND_ARRAYS) THEN
				farg[args].token = new_data
				farg[args].varType = $$XLONG
				farg[args].argType = $$XLONG
				farg[args].stack = $$FALSE
				farg[args].byRef = $$TRUE
				farg[args].kind = kind
			ELSE
				IF (from_type = $$STRING) THEN
					IF NullStringerCheck (nn) THEN qref = $$TRUE
					IFZ qref THEN
						GOSUB PassString
						fixArgs = $$TRUE
						kind = $$KIND_VARIABLES
						IF (argNum < total_args) THEN
							Push ($$rax, $$XLONG)
							stack = $$TRUE
							new_data = #T_ZERO
							nn = 0
						ELSE
							new_data.tindex = $$rax
							new_data.tproto = 0
						END IF
					END IF
					DEC oos
				END IF
				farg[args].token = new_data
				farg[args].varType = from_type
				farg[args].argType = to_type
				farg[args].stack = stack
				farg[args].byRef = qref
				farg[args].kind = kind
			END IF
			nn = 0
			new_data = #T_ZERO
			ref_flags = 0         ' variable
		ELSE
			nn = Top ()
			ref_flags = 0x80      ' expression
			IF qref THEN tokenPtr = tokenPtr - 3: XcowlErr (38003223): GOTO eeeByRef
			IF (from_type = $$STRING) THEN
				IF (oos[oos] = 'v') THEN GOSUB PassString
				fixArgs = $$TRUE
				DEC oos
			END IF
			IF (argNum < total_args) THEN
				Push (nn, from_type)
				stack = $$TRUE
				new_data = #T_ZERO
				nn = 0
			END IF
			DEC toes
			a0 = 0: a0_type = 0
			a1 = 0: a1_type = 0
			farg[args].token.tindex = nn                    ' 0 means "pushed"
			farg[args].varType = from_type
			farg[args].argType = to_type
			farg[args].byRef = $$FALSE
			farg[args].stack = stack
			farg[args].kind = $$KIND_VARIABLES
		END IF
		IF XERROR THEN EXIT FUNCTION
'
'   if arg had a "" BYREF prefix, note this in arg_type$
'
		IF qref THEN ref_flags = ref_flags OR 0x40 OR stringLit   ' by reference
		parArg[argNum].tp.kind = parArg[argNum].tp.kind OR ref_flags
'
		SELECT CASE TRUE
			CASE TokenMatch (@new_op, @#T_COMMA): argLoop = $$TRUE
			CASE TokenMatch (@new_op, @#T_SEMI):  argLoop = $$TRUE
			CASE TokenMatch (@new_op, @#T_COLON): argLoop = $$TRUE
			CASE TokenMatch (@new_op, @#T_RPAREN): argLoop = $$FALSE
			CASE ELSE:      XcowlErr (38003257): GOTO eeeSyntax
		END SELECT
		INC args
		INC argNum
	LOOP WHILE argLoop
	IF XERROR THEN EXIT FUNCTION
'
'
' *************************************
' *****  FUNCTION ARGS PROCESSED  *****
' *************************************
'
PastArgs:
	IF (args < total_args) THEN XcowlErr (38003270): GOTO eeeTooFewArgs
	IF (args > total_args) THEN
		IF etc THEN total_args = args ELSE XcowlErr (38003272): GOTO eeeTooManyArgs
	END IF
'
' *******************************************************
' *****  Push arguments onto stack in reverse order *****
' *******************************************************
'
	SELECT CASE callKind
		CASE $$XFUNC
			FOR arg = args-1 TO 0 STEP -1
				farg = farg[arg]
				PushXfuncArg (@farg)
				IF XERROR THEN EXIT FUNCTION
				argOffset = argOffset + 8
			NEXT arg
		CASE $$CFUNC
			rsp_mod = $$TRUE                                                          '*cw* 230730+
			IF (args <= 6) THEN                                                       '*cw* 230730+
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_rsp_even", $$rmk$+"817A")    '*cw* 230730+
			ELSE                                                                      '*cw* 230730+
				IF (args AND 1) THEN                                                    '*cw* 230730+
					Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_rsp_odd", $$rmk$+"817B")   '*cw* 230730+
				ELSE                                                                    '*cw* 230730+
					Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_rsp_even", $$rmk$+"817C")  '*cw* 230730+
				END IF                                                                  '*cw* 230730+
			END IF                                                                    '*cw* 230730+
'
			FOR arg = args-1 TO 0 STEP -1
				farg = farg[arg]
				PassCfuncArg (@farg, arg)
				IF XERROR THEN EXIT FUNCTION
				IF (arg > 5) THEN
					argOffset = argOffset + 8
				END IF
			NEXT arg
		CASE ELSE
					XcowlErr (38003297): GOTO eeeCompiler
	END SELECT

'
' ***************************
' *****  FUNCTION CALL  *****
' ***************************
'
	SELECT CASE fkind
		CASE $$KIND_FUNCTIONS
					funcScope = funcScope[func_num]
					SELECT CASE funcScope
						CASE $$FUNC_EXTERNAL
									funcLabel$ = funcLabel$[func_num]
									IF XERROR THEN EXIT FUNCTION
						CASE $$FUNC_INTERNAL, $$FUNC_DECLARE
									funcLabel$ = "func" + HEX$(func_num)
					END SELECT
					IFF TokenMatch (@rctoken, @#T_ZERO) THEN
						Move ($$rbx, $$XLONG, rctoken.tindex, $$XLONG)
						a1_type = 0
					END IF
'					IF (i486bin AND cfunc AND (funcScope == $$FUNC_EXTERNAL)) THEN                           '*cw* 230807-
					IF (i486bin AND (funcKind[func_num] = $$CFUNC) AND (funcScope == $$FUNC_EXTERNAL)) THEN  '*cw* 230807+
						Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_zero_whomask", $$rmk$+"817A")
						Code ($$mov, $$regimm, $$rax, 0, 0, $$XLONG, @funcLabel$, $$rmk$+"817B")  '*cw* 230731+
						Code ($$call, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"817C")             '*cw* 230731+
						Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_set_whomask", $$rmk$+"817D")
					ELSE
						Code ($$call, $$rel, 0, 0, 0, 0, funcLabel$, $$rmk$+"817E")
					END IF
		CASE $$KIND_VARIABLES, $$KIND_ARRAYS
					IFZ toes THEN XcowlErr (38003328): GOTO eeeCompiler
					Pop ($$rax, $$XLONG)
					a0 = 0: a0_type = 0
					DEC toes
					Code ($$call, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"818")
		CASE ELSE
					XcowlErr (38003334): GOTO eeeCompiler
	END SELECT
'
	IF (callKind != $$CFUNC) THEN
		IF fixArgs THEN
			Code ($$sub, $$regimm, $$rsp, argSize, 0, $$XLONG, "", $$rmk$+"819")
		END IF
	END IF
'
	INC toes
	a0 = toes
	a0_type = func_type
	GOSUB DoShuffle
'
functions_end:
	new_data  = #T_ZERO
	new_type  = func_type
	IF fixArgs THEN callKind = $$CFUNC
	IF etc THEN argSize = argOffset
	IFZ noArgs THEN
		SELECT CASE callKind
			CASE $$XFUNC
			CASE $$SFUNC: IF $$linux THEN XcowlErr (38003357): GOTO eeeCompiler
			CASE $$CFUNC: IF argSize THEN
											Code ($$add, $$regimm, $$rsp, argSize, 0, $$XLONG, "", $$rmk$+"820")
										END IF
		END SELECT
	END IF
	IF rsp_mod THEN                                                             '*cw* 230730+
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_rsp_restore", $$rmk$+"820A")   '*cw* 230730+
		rsp_mod = $$FALSE                                                         '*cw* 230730+
	END IF                                                                      '*cw* 230730+
	IF (fkind != $$KIND_FUNCTIONS) THEN EmitLabel (@fzip$)
	IF (func_type = $$STRING) THEN INC oos: oos[oos] = 's'
	IF func_type THEN
		IF (func_type < $$SLONG) THEN XcowlErr (38003366): GOTO eeeCompiler
	END IF
	GOTO express_op
'
' pass strings by value:  clone, pass clone address, deallocate after return
'
SUB PassString
	IF (nn != $$RA0) THEN Move ($$RA0, $$XLONG, nn, $$XLONG)
	IF qref THEN XcowlErr (38003374): GOTO eeeCompiler
	IF (oos[oos] != 'v') THEN XcowlErr (38003375): GOTO eeeCompiler
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0", $$rmk$+"821")
	nn = $$RA0
END SUB
'
'
' Update variables passed by reference
'
SUB DoShuffle
	mode = 0
	offset = 0
	FOR arg_num = 1 TO total_args
		oreg      = orgReg[arg_num]
		areg      = argReg[arg_num]
		ptype     = parArg[arg_num].tindex
		atype     = argArg[arg_num].tindex
		pkind     = parArg[arg_num].tp.kind
		atoken    = argToken[arg_num]
		stringLit = pkind{{1,5}}
		passByRef = pkind{{1,6}}
		IFZ stringLit THEN
			IF (passByRef OR (ptype = $$STRING)) THEN
				IF fixArgs THEN
					Shuffle (areg, oreg, atype, ptype, atoken.tindex, pkind, mode, offset)
				ELSE
					Shuffle (areg, oreg, atype, ptype, atoken.tindex, pkind, mode, offset - argSize)
				END IF
			END IF
		END IF
		k = pkind AND 0x001F
		IF (k != $$KIND_ARRAYS) THEN k = $$KIND_VARIABLES
		SELECT CASE k
			CASE $$KIND_ARRAYS
						offset  = offset + 8
			CASE $$KIND_VARIABLES
						offset  = offset + 8
		END SELECT
	NEXT arg_num
END SUB
'
'
' ******************************************************
' *****  BINARY OPERATOR WHEN WANTING DATA OBJECT  *****
' ******************************************************
'
' Binary ops are errors here...  could it be a unary op?
'
express_binary_op:
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_ADD):      token = #T_PLUS
		CASE TokenMatch (@token, @#T_SUBTRACT): token = #T_MINUS
		CASE TokenMatch (@token, @#T_ANDBIT):   token = #T_ADDR_OP:   GOTO express_addr_op
		CASE TokenMatch (@token, @#T_ANDL):     token = #T_HANDLE_OP: GOTO express_addr_op
		CASE ELSE:       XcowlErr (38003428): GOTO eeeSyntax
	END SELECT
	GOTO express_unary_op
'
'
' *****  LEFT PARENTHESES WHEN WANTING DATA ITEM  *****
'
express_lparen:
	IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (38003436): GOTO eeeSyntax
	new_test = old_test: new_type = 0: new_prec = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	IFF TokenMatch (@new_op, @#T_RPAREN) THEN XcowlErr (38003442): GOTO eeeSyntax
	new_op   = #T_ZERO
	new_prec = 0
	GOTO express_op
'
'
' *****  RIGHT PARENTHESES  *****  Error or null expression... ()
'
express_rparen:
	IF got_expression THEN XcowlErr (38003451): GOTO eeeSyntax
	old_test = 0
	old_op   = token
	old_data = #T_ZERO
	RETURN
'
'
' *****  ADDRESS OPERATORS  *****  &, &&
'
express_addr_op:
	SELECT CASE  TRUE
		CASE TokenMatch (@token, @#T_ADDR_OP):    addr_op   = $$TRUE
																							handle_op = $$FALSE
		CASE TokenMatch (@token, @#T_HANDLE_OP):  addr_op   = $$FALSE
																							handle_op = $$TRUE
		CASE ELSE: XcowlErr (38003466): GOTO eeeCompiler
	END SELECT
	stringAddr      = $$FALSE
	compositeAddr   = $$FALSE
	constantAddr    = $$FALSE
	register_string = $$FALSE
	NextToken (@new_data)
	kind            = new_data.tp.kind
	new_type        = TheType(new_data)
	IF (new_type = $$STRING) THEN stringAddr = $$TRUE
	IF (new_type >= $$SCOMPLEX) THEN compositeAddr = $$TRUE
	SELECT CASE kind
		CASE $$KIND_VARIABLES
					IF handle_op THEN
						IFF (stringAddr OR compositeAddr) THEN XcowlErr (38003480): GOTO eeeSyntax
					END IF
		CASE $$KIND_ARRAYS
					IF compositeAddr THEN EXIT SELECT
		CASE $$KIND_FUNCTIONS
					token = new_data
					GOTO addrop_func
		CASE $$KIND_ARRAYS
					GOTO addr_others
		CASE $$KIND_LITERALS
					IFZ stringAddr THEN XcowlErr (38003490): GOTO eeeTypeMismatch
					IF handle_op THEN XcowlErr (38003491): GOTO eeeLiteral
					constantAddr = $$TRUE
		CASE $$KIND_SYSCONS, $$KIND_CONSTANTS
					IFZ stringAddr THEN XcowlErr (38003494): GOTO eeeKindMismatch
					IF handle_op THEN XcowlErr (38003495): GOTO eeeLiteral
					constantAddr = $$TRUE
		CASE ELSE
					XcowlErr (38003498): GOTO eeeKindMismatch
	END SELECT
	nn = new_data.tindex
	got_expression = $$TRUE
	IFF m_addr$[nn] THEN AssignAddress (new_data)
	IF XERROR THEN EXIT FUNCTION
	new_type = TheType (new_data)
	IF (new_type < $$SLONG) THEN new_type = $$SLONG
	IF (new_type >= $$SCOMPLEX) THEN
		stringAddr = $$TRUE
'
'   subComposite == a composite expression including sub-element references
'   varComposite == a composite variable/array without sub-element references
'   Source:       GETADDR valid for subComposites
'                 GETHANDLE valid for pointer sub-elements in subComposites
'         ( tested in Composite() )
'
		lastElement = LastElement (new_data, 0, 0)    ' Drop through if varComposite
		IF XERROR THEN EXIT FUNCTION
		IFF lastElement THEN                          ' composite + elements
			SELECT CASE TRUE
				CASE addr_op:     command = $$GETADDR
				CASE handle_op:   command = $$GETHANDLE
			END SELECT
			Composite (@command, @new_type, @new_data, @theOffset, 0)
			IF XERROR THEN EXIT FUNCTION
			sreg = new_data.tindex
			IFZ command THEN
				dreg = OpenAccForType ($$XLONG)
				Code ($$lea, $$regro, dreg, sreg, theOffset, $$XLONG, "", $$rmk$+"822")
			ELSE
				IF theOffset THEN
					dreg = sreg
					Code ($$lea, $$regro, dreg, sreg, theOffset, $$XLONG, "", $$rmk$+"823")
				END IF
			END IF
			new_op = #T_ZERO
			new_prec = 0
			new_data = #T_ZERO
			new_type = $$XLONG
			GOTO express_op
		END IF
	END IF
'
	n$    = tab_sym$[nn]
	m$    = m_addr$[nn]
	rn    = r_addr[nn]
	mReg  = m_reg[nn]
	mAddr = m_addr[nn]
'
	IF (kind = $$KIND_ARRAYS) THEN GOTO addr_others
'
	IF (stringAddr AND addr_op) THEN
		aop486  = $$ld
	ELSE
		aop486  = $$lea
	END IF
'
	IF mReg THEN
		mode = $$regro
	ELSE
		IF constantAddr THEN
			mode = $$regimm
		ELSE
			mode = $$regabs
		END IF
	END IF
'
addr_var_x:
	accx = 0
	IF a0 THEN accx = accx + 1
	IF a1 THEN accx = accx + 2
	IF (accx = 3) THEN GOTO avma
	IF (accx = 2) THEN GOTO avmb
	IF (accx = 1) THEN GOTO avmc
	IF (accx = 0) THEN GOTO avmb
	XcowlErr (38003574): GOTO eeeCompiler
avma:
	IF (a1 > a0) THEN GOTO avm0
	IF (a1 < a0) THEN GOTO avm1
	XcowlErr (38003578): GOTO eeeCompiler
avm0:
	Push($$RA0, a0_type)
avmb:
	arc = $$rax
	INC toes
	a0 = toes: a0_type = $$XLONG
	GOTO avall
avm1:
	Push($$RA1, a1_type)
avmc:
	arc = $$rbx
	INC toes
	a1 = toes: a1_type = $$XLONG
	GOTO avall
avall:
	Code (aop486, mode, arc, mReg, mAddr, $$XLONG, @m$ , $$rmk$+"824")
	new_op = #T_ZERO
	new_prec = 0
	new_data = #T_ZERO
	new_type = $$XLONG
	GOTO express_op
'
' address of objects other than variables
'
addr_others:
	DEC tokenPtr
	new_op = token
	new_prec = new_op.tp.type AND 0xF            ' {$$PREC}
	new_data = #T_ZERO
	new_type = 0
	test = 0
	Expresso (@test, @new_op, @new_prec, @new_data, @new_type)
	excessComma = $$FALSE
	GOTO exo
'
'
' *****  TERMINATORS  *****
'
express_term:
	IF got_expression THEN XcowlErr (38003618): GOTO eeeSyntax
	old_test = 0
	old_op   = token
	old_prec = 0
	old_data = new_data
	old_type = new_type
	RETURN
'
'
' ****************************
' *****  SUB InitArrays  *****
' ****************************
'
SUB InitArrays
	DIM argToken[63]
	DIM dataKind[31]
	dataKind[ $$KIND_VARIABLES    ] = GOADDRESS (express_var)
	dataKind[ $$KIND_SYSCONS      ] = GOADDRESS (express_var)
	dataKind[ $$KIND_CHARCONS     ] = GOADDRESS (express_var)
	dataKind[ $$KIND_LITERALS     ] = GOADDRESS (express_var)
	dataKind[ $$KIND_CONSTANTS    ] = GOADDRESS (express_var)
	dataKind[ $$KIND_ARRAYS       ] = GOADDRESS (express_array)
	dataKind[ $$KIND_FUNCTIONS    ] = GOADDRESS (express_function)
	dataKind[ $$KIND_INTRINSICS   ] = GOADDRESS (express_intrinsic)
	dataKind[ $$KIND_STATE_INTRIN ] = GOADDRESS (express_intrinsic)
	dataKind[ $$KIND_UNARY_OPS    ] = GOADDRESS (express_unary_op)
	dataKind[ $$KIND_BINARY_OPS   ] = GOADDRESS (express_binary_op)
	dataKind[ $$KIND_ADDR_OPS     ] = GOADDRESS (express_addr_op)
	dataKind[ $$KIND_LPARENS      ] = GOADDRESS (express_lparen)
	dataKind[ $$KIND_RPARENS      ] = GOADDRESS (express_rparen)
	dataKind[ $$KIND_TERMINATORS  ] = GOADDRESS (express_term)
	dataKind[ $$KIND_COMMENTS     ] = GOADDRESS (express_term)
	dataKind[ $$KIND_STARTS       ] = GOADDRESS (express_term)
	dataKind[ $$KIND_CHARACTERS   ] = GOADDRESS (express_character)
'
	DIM opKind[31]
	opKind[ $$KIND_SYMBOLS       ] = GOADDRESS (express_op_component)
	opKind[ $$KIND_ARRAY_SYMBOLS ] = GOADDRESS (express_op_component)
	opKind[ $$KIND_LPARENS       ] = GOADDRESS (express_op_lparen)
	opKind[ $$KIND_COMMENTS      ] = GOADDRESS (express_op_rem)
	opKind[ $$KIND_TERMINATORS   ] = GOADDRESS (express_ops)
	opKind[ $$KIND_BINARY_OPS    ] = GOADDRESS (express_ops)
	opKind[ $$KIND_SEPARATORS    ] = GOADDRESS (express_ops)
	opKind[ $$KIND_STARTS        ] = GOADDRESS (express_ops)
'
	DIM firstIntrinToken[255]
	firstIntrinToken[ #T_ISDATA.ti.ndex      ] = GOADDRESS (i_isdata)
	firstIntrinToken[ #T_ISNODE.ti.ndex      ] = GOADDRESS (i_isnode)
	firstIntrinToken[ #T_LEN.ti.ndex         ] = GOADDRESS (i_lenof)
	firstIntrinToken[ #T_SIZE.ti.ndex        ] = GOADDRESS (i_sizeof)
	firstIntrinToken[ #T_TYPE.ti.ndex        ] = GOADDRESS (i_typeof)
	firstIntrinToken[ #T_UBOUND.ti.ndex      ] = GOADDRESS (i_ubound)
	firstIntrinToken[ #T_GOADDRESS.ti.ndex   ] = GOADDRESS (i_goaddress)
	firstIntrinToken[ #T_SUBADDRESS.ti.ndex  ] = GOADDRESS (i_subaddress)
	firstIntrinToken[ #T_FUNCADDRESS.ti.ndex ] = GOADDRESS (i_funcaddress)
	firstIntrinToken[ #T_SBYTEAT.ti.ndex     ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_UBYTEAT.ti.ndex     ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_SSHORTAT.ti.ndex    ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_USHORTAT.ti.ndex    ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_SLONGAT.ti.ndex     ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_ULONGAT.ti.ndex     ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_XLONGAT.ti.ndex     ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_GOADDRAT.ti.ndex    ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_SUBADDRAT.ti.ndex   ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_FUNCADDRAT.ti.ndex  ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_GIANTAT.ti.ndex     ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_SINGLEAT.ti.ndex    ] = GOADDRESS (i_atops)
	firstIntrinToken[ #T_DOUBLEAT.ti.ndex    ] = GOADDRESS (i_atops)
'
	DIM intrinToken[255]
	intrinToken[ #T_ABS.ti.ndex       ] = GOADDRESS (i_abs)
	intrinToken[ #T_ASC.ti.ndex       ] = GOADDRESS (i_asc)
	intrinToken[ #T_BIN_D.ti.ndex     ] = GOADDRESS (i_bin_d)
	intrinToken[ #T_BINB_D.ti.ndex    ] = GOADDRESS (i_binb_d)
	intrinToken[ #T_BITFIELD.ti.ndex  ] = GOADDRESS (i_bitfield)
	intrinToken[ #T_CHR_D.ti.ndex     ] = GOADDRESS (i_chr_d)
	intrinToken[ #T_CJUST_D.ti.ndex   ] = GOADDRESS (i_cjust_d)
	intrinToken[ #T_CLOSE.ti.ndex     ] = GOADDRESS (i_close)
	intrinToken[ #T_CLR.ti.ndex       ] = GOADDRESS (i_clr)
	intrinToken[ #T_CSIZE.ti.ndex     ] = GOADDRESS (i_csize)
	intrinToken[ #T_CSIZE_D.ti.ndex   ] = GOADDRESS (i_csize_d)
	intrinToken[ #T_CSTRING_D.ti.ndex ] = GOADDRESS (i_cstring_d)
	intrinToken[ #T_DHIGH.ti.ndex     ] = GOADDRESS (i_dhigh)
	intrinToken[ #T_DLOW.ti.ndex      ] = GOADDRESS (i_dlow)
	intrinToken[ #T_DMAKE.ti.ndex     ] = GOADDRESS (i_dmake)
	intrinToken[ #T_DOUBLE.ti.ndex    ] = GOADDRESS (i_types)
	intrinToken[ #T_EOF.ti.ndex       ] = GOADDRESS (i_eof)
	intrinToken[ #T_ERROR.ti.ndex     ] = GOADDRESS (i_error)
	intrinToken[ #T_ERROR_D.ti.ndex   ] = GOADDRESS (i_error_d)
	intrinToken[ #T_EXTS.ti.ndex      ] = GOADDRESS (i_exts)
	intrinToken[ #T_EXTU.ti.ndex      ] = GOADDRESS (i_extu)
	intrinToken[ #T_FIX.ti.ndex       ] = GOADDRESS (i_fix)
	intrinToken[ #T_FORMAT_D.ti.ndex  ] = GOADDRESS (i_format_d)
	intrinToken[ #T_FUNCADDR.ti.ndex  ] = GOADDRESS (i_types)
	intrinToken[ #T_GHIGH.ti.ndex     ] = GOADDRESS (i_ghigh)
	intrinToken[ #T_GIANT.ti.ndex     ] = GOADDRESS (i_types)
	intrinToken[ #T_GLOW.ti.ndex      ] = GOADDRESS (i_glow)
	intrinToken[ #T_GMAKE.ti.ndex     ] = GOADDRESS (i_gmake)
	intrinToken[ #T_GOADDR.ti.ndex    ] = GOADDRESS (i_types)
	intrinToken[ #T_HEX_D.ti.ndex     ] = GOADDRESS (i_hex_d)
	intrinToken[ #T_HEXX_D.ti.ndex    ] = GOADDRESS (i_hexx_d)
	intrinToken[ #T_HIGH0.ti.ndex     ] = GOADDRESS (i_high0)
	intrinToken[ #T_HIGH1.ti.ndex     ] = GOADDRESS (i_high1)
	intrinToken[ #T_INCHR.ti.ndex     ] = GOADDRESS (i_inchr)
	intrinToken[ #T_INCHRI.ti.ndex    ] = GOADDRESS (i_inchri)
	intrinToken[ #T_INFILE_D.ti.ndex  ] = GOADDRESS (i_infile_d)
	intrinToken[ #T_INLINE_D.ti.ndex  ] = GOADDRESS (i_inline_d)
	intrinToken[ #T_INSTR.ti.ndex     ] = GOADDRESS (i_instr)
	intrinToken[ #T_INSTRI.ti.ndex    ] = GOADDRESS (i_instri)
	intrinToken[ #T_INT.ti.ndex       ] = GOADDRESS (i_int)
	intrinToken[ #T_ISDATA.ti.ndex    ] = GOADDRESS (i_isdata)
	intrinToken[ #T_ISNODE.ti.ndex    ] = GOADDRESS (i_isnode)
	intrinToken[ #T_LCASE_D.ti.ndex   ] = GOADDRESS (i_lcase_d)
	intrinToken[ #T_LCLIP_D.ti.ndex   ] = GOADDRESS (i_lclip_d)
	intrinToken[ #T_LEFT_D.ti.ndex    ] = GOADDRESS (i_left_d)
	intrinToken[ #T_LEN.ti.ndex       ] = GOADDRESS (i_len)
	intrinToken[ #T_LIBRARY.ti.ndex   ] = GOADDRESS (i_library)
	intrinToken[ #T_LJUST_D.ti.ndex   ] = GOADDRESS (i_ljust_d)
	intrinToken[ #T_LOF.ti.ndex       ] = GOADDRESS (i_lof)
	intrinToken[ #T_LTRIM_D.ti.ndex   ] = GOADDRESS (i_ltrim_d)
	intrinToken[ #T_MAKE.ti.ndex      ] = GOADDRESS (i_make)
	intrinToken[ #T_MAX.ti.ndex       ] = GOADDRESS (i_max)
	intrinToken[ #T_MID_D.ti.ndex     ] = GOADDRESS (i_mid_d)
	intrinToken[ #T_MIN.ti.ndex       ] = GOADDRESS (i_min)
	intrinToken[ #T_NULL_D.ti.ndex    ] = GOADDRESS (i_null_d)
	intrinToken[ #T_OCT_D.ti.ndex     ] = GOADDRESS (i_oct_d)
	intrinToken[ #T_OCTO_D.ti.ndex    ] = GOADDRESS (i_octo_d)
	intrinToken[ #T_OPEN.ti.ndex      ] = GOADDRESS (i_open)
	intrinToken[ #T_POF.ti.ndex       ] = GOADDRESS (i_pof)
	intrinToken[ #T_PROGRAM_D.ti.ndex ] = GOADDRESS (i_program_d)
	intrinToken[ #T_QUIT.ti.ndex      ] = GOADDRESS (i_quit)
	intrinToken[ #T_RCLIP_D.ti.ndex   ] = GOADDRESS (i_rclip_d)
	intrinToken[ #T_RIGHT_D.ti.ndex   ] = GOADDRESS (i_right_d)
	intrinToken[ #T_RINCHR.ti.ndex    ] = GOADDRESS (i_rinchr)
	intrinToken[ #T_RINCHRI.ti.ndex   ] = GOADDRESS (i_rinchri)
	intrinToken[ #T_RINSTR.ti.ndex    ] = GOADDRESS (i_rinstr)
	intrinToken[ #T_RINSTRI.ti.ndex   ] = GOADDRESS (i_rinstri)
	intrinToken[ #T_RJUST_D.ti.ndex   ] = GOADDRESS (i_rjust_d)
	intrinToken[ #T_ROTATEL.ti.ndex   ] = GOADDRESS (i_rotatel)
	intrinToken[ #T_ROTATER.ti.ndex   ] = GOADDRESS (i_rotater)
	intrinToken[ #T_RTRIM_D.ti.ndex   ] = GOADDRESS (i_rtrim_d)
	intrinToken[ #T_SBYTE.ti.ndex     ] = GOADDRESS (i_types)
	intrinToken[ #T_SEEK.ti.ndex      ] = GOADDRESS (i_seek)
	intrinToken[ #T_SET.ti.ndex       ] = GOADDRESS (i_set)
	intrinToken[ #T_SGN.ti.ndex       ] = GOADDRESS (i_sgn)
	intrinToken[ #T_SHELL.ti.ndex     ] = GOADDRESS (i_shell)
	intrinToken[ #T_SIZE.ti.ndex      ] = GOADDRESS (i_size)
	intrinToken[ #T_SIGN.ti.ndex      ] = GOADDRESS (i_sign)
	intrinToken[ #T_SIGNED_D.ti.ndex  ] = GOADDRESS (i_signed_d)
	intrinToken[ #T_SINGLE.ti.ndex    ] = GOADDRESS (i_types)
	intrinToken[ #T_SPACE_D.ti.ndex   ] = GOADDRESS (i_space_d)
	intrinToken[ #T_SSHORT.ti.ndex    ] = GOADDRESS (i_types)
	intrinToken[ #T_SLONG.ti.ndex     ] = GOADDRESS (i_types)
	intrinToken[ #T_SMAKE.ti.ndex     ] = GOADDRESS (i_smake)
	intrinToken[ #T_STR_D.ti.ndex     ] = GOADDRESS (i_str_d)
	intrinToken[ #T_STRING.ti.ndex    ] = GOADDRESS (i_string)
	intrinToken[ #T_STRING_D.ti.ndex  ] = GOADDRESS (i_string_d)
	intrinToken[ #T_STUFF_D.ti.ndex   ] = GOADDRESS (i_stuff_d)
	intrinToken[ #T_SUBADDR.ti.ndex   ] = GOADDRESS (i_types)
	intrinToken[ #T_TAB.ti.ndex       ] = GOADDRESS (i_tab)
	intrinToken[ #T_TRIM_D.ti.ndex    ] = GOADDRESS (i_trim_d)
	intrinToken[ #T_UBYTE.ti.ndex     ] = GOADDRESS (i_types)
	intrinToken[ #T_UBOUND.ti.ndex    ] = GOADDRESS (i_ubound)
	intrinToken[ #T_UCASE_D.ti.ndex   ] = GOADDRESS (i_ucase_d)
	intrinToken[ #T_USHORT.ti.ndex    ] = GOADDRESS (i_types)
	intrinToken[ #T_ULONG.ti.ndex     ] = GOADDRESS (i_types)
	intrinToken[ #T_VERSION_D.ti.ndex ] = GOADDRESS (i_version_d)
	intrinToken[ #T_XLONG.ti.ndex     ] = GOADDRESS (i_types)
	intrinToken[ #T_XMAKE.ti.ndex     ] = GOADDRESS (i_xmake)
'
	DIM inlineToken[255]
	inlineToken[ #T_BITFIELD.ti.ndex  ] = $$TRUE
	inlineToken[ #T_DHIGH.ti.ndex     ] = $$TRUE
	inlineToken[ #T_DLOW.ti.ndex      ] = $$TRUE
	inlineToken[ #T_DMAKE.ti.ndex     ] = $$TRUE
	inlineToken[ #T_ERROR.ti.ndex     ] = $$TRUE
	inlineToken[ #T_ERROR_D.ti.ndex   ] = $$TRUE
	inlineToken[ #T_GHIGH.ti.ndex     ] = $$TRUE
	inlineToken[ #T_GLOW.ti.ndex      ] = $$TRUE
	inlineToken[ #T_GMAKE.ti.ndex     ] = $$TRUE
	inlineToken[ #T_HIGH0.ti.ndex     ] = $$TRUE
	inlineToken[ #T_HIGH1.ti.ndex     ] = $$TRUE
	inlineToken[ #T_LEN.ti.ndex       ] = $$TRUE
	inlineToken[ #T_LIBRARY.ti.ndex   ] = $$TRUE
	inlineToken[ #T_ROTATEL.ti.ndex   ] = $$TRUE
	inlineToken[ #T_ROTATER.ti.ndex   ] = $$TRUE
	inlineToken[ #T_SGN.ti.ndex       ] = $$TRUE
	inlineToken[ #T_SIGN.ti.ndex      ] = $$TRUE
	inlineToken[ #T_SIZE.ti.ndex      ] = $$TRUE
	inlineToken[ #T_SMAKE.ti.ndex     ] = $$TRUE
	inlineToken[ #T_XMAKE.ti.ndex     ] = $$TRUE
END SUB
'
' ********************
' *****  ERRORS  *****
' ********************
'
eeeBitSpec:
	XERROR = ERROR_BITSPEC
	EXIT FUNCTION
'
eeeByRef:
	XERROR = ERROR_BYREF
	EXIT FUNCTION
'
eeeByVal:
	XERROR = ERROR_BYVAL
	EXIT FUNCTION
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeComponent:
	XERROR = ERROR_COMPONENT
	EXIT FUNCTION
'
eeeKindMismatch:
	XERROR = ERROR_KIND_MISMATCH
	EXIT FUNCTION
'
eeeLiteral:
	XERROR = ERROR_LITERAL
	EXIT FUNCTION
'
eeeNeedExcessComma:
	XERROR = ERROR_NEED_EXCESS_COMMA
	EXIT FUNCTION
'
eeeOverflow:
	XERROR = ERROR_OVERFLOW
	EXIT FUNCTION
'
eeeRegAddr:
	XERROR = ERROR_REGADDR
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooFewArgs:
	XERROR = ERROR_TOO_FEW_ARGS
	EXIT FUNCTION
'
eeeTooManyArgs:
	XERROR = ERROR_TOO_MANY_ARGS
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
'
eeeUndeclared:
	XERROR = ERROR_UNDECLARED
	EXIT FUNCTION
'
eeeUndefined:
	XERROR = ERROR_UNDEFINED
	EXIT FUNCTION
'
eeeUnimplemented:
	XERROR = ERROR_UNIMPLEMENTED
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  FloatLoad ()  #####
' ##########################
'
FUNCTION  FloatLoad (dreg, stindex, stype)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   stoken
	SHARED  TOKEN   tab_sym[]
	SHARED  m_reg[],  m_addr[],  m_addr$[],  labelNumber
'
	IF (stype < $$SLONG) THEN stype = $$SLONG
	SELECT CASE stype
		CASE $$SLONG : op = $$fild
		CASE $$ULONG : op = $$fild
		CASE $$XLONG : op = $$fild
		CASE $$GIANT : op = $$fild
		CASE $$SINGLE: op = $$fld
		CASE $$DOUBLE: op = $$fld
		CASE ELSE    : PRINT "FloatLoad1": EXIT FUNCTION
	END SELECT
'
	ss      = stindex
	stoken  = tab_sym[ss]
	mReg    = m_reg[ss]
	mAddr   = m_addr[ss]
	kind    = stoken.tp.kind
	SELECT CASE kind
		CASE $$KIND_LITERALS,  $$KIND_CONSTANTS,  $$KIND_SYSCONS
					SELECT CASE stype
						CASE $$SINGLE:  LoadLitnum ($$RA0, $$SINGLE, stoken.tindex, stype)
						CASE ELSE:      LoadLitnum ($$RA0, $$DOUBLE, stoken.tindex, stype)
					END SELECT
		CASE $$KIND_VARIABLES
					IF (stype != $$ULONG) THEN
						IF mReg THEN
							Code (op, $$ro, 0, mReg, mAddr, stype, "", $$rmk$+"825")
						ELSE
							Code (op, $$abs, 0, 0, mAddr, stype, m_addr$[ss], $$rmk$+"826")
						END IF
					ELSE
'
' xxxxxxxxxx :  error - gets negative result for large ULONG values (treats as an SLONG)
'
						INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
						IF mReg THEN
							Code ($$push, $$imm, 0, 0, 0, $$XLONG, "", $$rmk$+"827")
							Code ($$push, $$ro, 0, mReg, mAddr, stype, "", $$rmk$+"828")
							Code ($$cmp, $$r0imm, 0, $$rsp, 0, $$XLONG, "", $$rmk$+"829")
							Code ($$jle, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"830")
							Code ($$mov, $$roimm, -1, $$rsp, 8, $$XLONG, "", $$rmk$+"831")
							EmitLabel (@d1$)
							Code (op, $$r0, 0, $$rsp, 0, $$GIANT, "", $$rmk$+"832")
						ELSE
							Code ($$push, $$imm, 0, 0, 0, $$XLONG, "", $$rmk$+"834")
							Code ($$push, $$abs, 0, 0, mAddr, stype, m_addr$[ss], $$rmk$+"835")
							Code ($$cmp, $$r0imm, 0, $$rsp, 0, $$XLONG, "", $$rmk$+"836")
							Code ($$jle, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"837")
							Code ($$mov, $$roimm, -1, $$rsp, 8, $$XLONG, "", $$rmk$+"838")
							EmitLabel (@d1$)
							Code (op, $$r0, 0, $$rsp, 0, $$GIANT, "", $$rmk$+"839")
						END IF
					END IF
	END SELECT
END FUNCTION
'
'
' ###########################
' #####  FloatStore ()  #####
' ###########################
'
FUNCTION  FloatStore (sreg, stindex, stype)
	SHARED  m_reg[],  m_addr[],  m_addr$[]
	SHARED  XERROR,  ERROR_COMPILER
'
	SELECT CASE stype
		CASE $$SLONG:   op = $$fistp
		CASE $$ULONG:   op = $$fistp
		CASE $$XLONG:   op = $$fistp
		CASE $$GIANT:   op = $$fistp
		CASE $$SINGLE:  op = $$fstp
		CASE $$DOUBLE:  op = $$fstp
		CASE ELSE: XcowlErr (400018): GOTO eeeCompiler
	END SELECT
'
	ss = stindex
	mReg  = m_reg[ss]
	mAddr = m_addr[ss]
	IF stype == $$ULONG THEN
		' This is a special case: the normal case will cause an overflow for
		' values larger than 0x7FFFFFFF. This special case allocates a temporary
		' 64 bit value on the stack, stores the float into that temporary variable
		' and uses the lower 32 bits.
'
		' Save eax (is needed later).
		' Note 1: theoretically mReg could be equal
		' to $$rax, in which case the following code fails. In reality this
		' can't be the case, because the eax can't be used in 'register/offset'
		' addressing mode.
		' Note 2: Often eax will be saved/restored while it's value is not
		' needed. Unfortunately I (EP) don't (yet) know a way to find out when
		' it's save and when it's not save to destroy the contents of eax.
		Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"841")
		' Allocate a 64 bit value on the stack.
		Code ($$sub, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"842")
		' Store the float value into this 64 bit value
		Code ($$fistp, $$r0, 0, $$rsp, 0, $$GIANT, "", $$rmk$+"843")
		' Load the low 32 bits of this 64 bit value into eax
		Code ($$ld, $$regr0, $$rax, $$rsp, 0, $$ULONG, "", $$rmk$+"844")
		' Store eax at the destination
		IF mReg THEN
			Code ($$st, $$roreg, $$rax, mReg, mAddr, stype, "", $$rmk$+"845")
		ELSE
			Code ($$st, $$absreg, $$rax, 0, mAddr, stype, m_addr$[ss], $$rmk$+"846")
		END IF
		' Free the 64 bit temporary.
		Code ($$add, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"847")
		' Restore $eax
		Code ($$pop, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"848")
	ELSE
		IF mReg THEN
			Code (op, $$ro, 0, mReg, mAddr, stype, "", $$rmk$+"849")
		ELSE
			Code (op, $$abs, 0, 0, mAddr, stype, m_addr$[ss], $$rmk$+"850")
		END IF
	END IF
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #################################
' #####  FunctionCallPost ()  #####
' #################################
'
FUNCTION  FunctionCallPost ()
'
' not needed for i486
'
END FUNCTION
'
'
' #################################
' #####  FunctionCallPrep ()  #####
' #################################
'
FUNCTION  FunctionCallPrep ()
'
' not needed for i486
'
END FUNCTION
'
'
' #################################
' #####  GenerateMakefile ()  ##### linux
' #################################
'
' generate makefile to generate .EXE or .DLL
'
FUNCTION  GenerateMakefile ()
	SHARED  libraryName$[]
	SHARED  program$
	SHARED  programName$
	SHARED  programPath$
'
	slot = 0
	fixlib = 0
'	PRINT "GenerateMakefile(17)"
	IF program$ THEN
		SELECT CASE LCASE$ (program$)
			CASE "xlib", "xdis", "xst", "xin", "xma", "xcm", "xit", "xcol", "xgr", "xui", "gdi32", "kernel32", "user32"
			CASE "xut", "xutpde", "xwin", "clib", "elf64"
			CASE ELSE  : fixlib = $$TRUE
		END SELECT
		IF fixlib THEN
			IF libraryName$[] THEN
				upper = UBOUND (libraryName$[])
				DIM lib$[upper]
				FOR i = 0 TO upper
					libname$ = TRIM$ (libraryName$[i])
					IF libname$ THEN
						SELECT CASE LCASE$ (libname$)
							CASE "xlib", "xdis", "xst", "xin", "xma", "xcm", "xit", "xcol", "xgr", "xui", "gdi32", "kernel32", "user32"
							CASE "xut", "xutpde", "xwin", "clib", "elf64"
							CASE ELSE  : lib$[slot] = " -l" + libname$
														INC slot
						END SELECT
					END IF
				NEXT i
			END IF
'
			attr = 0
			GetSubPath ("xxx", "", @path$[])
			IF library THEN
				XstFindFile ("xdll.xxx", @path$[], @file$, @attr)
			ELSE
				XstFindFile ("xapp.xxx", @path$[], @file$, @attr)
			END IF
'
			XstLoadStringArray (@file$, @file$[])
'
			app = $$FALSE
			libs = $$FALSE
			IF file$[] THEN
				FOR i = 0 TO UBOUND (file$[])
					IFZ app THEN
						app = INSTR (file$[i], "APP")
						IF app THEN
							line$ = file$[i]
							equal = RINSTR (line$, "=")
							IF equal THEN file$[i] = LEFT$ (line$, equal) + " " + programName$
						END IF
					END IF
					IFZ libs THEN
						libs = INSTR (file$[i], "LIBS")
						IF libs THEN
							libs$ = file$[i]
							equal = RINSTR (libs$, "=")
							IF equal THEN
								IF slot THEN
									FOR j = 0 TO slot-1
										libs$ = libs$ + " " + lib$[j]
									NEXT j
									file$[i] = libs$
								END IF
							END IF
						END IF
					END IF
					IF app THEN
						IF libs THEN
							mak$ = programPath$
							IF (RIGHT$(mak$,2) = ".x") THEN mak$ = RCLIP$(mak$,2)
							IF mak$ THEN
								ofile$ = mak$ + ".mak"
								XstSaveStringArray (@ofile$, @file$[])
								PRINT "GenerateMakefile(80)", ofile$
							END IF
							EXIT FOR
						END IF
					END IF
				NEXT i
			END IF
		END IF
	END IF
'
END FUNCTION
'
'
' ################################
' #####  GetAddrLabel64$ ()  #####
' ################################
'
'	Return label for this address, prefer function name if function address
'
'	In:				branchAddr
'	Out:			none				arg unchanged
'	Return:		label$
'
FUNCTION  GetAddrLabel64$ (branchAddr)
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN    funcToken[]
'
	label = XxxGetLabelGivenAddress (branchAddr, @labels$[])
	IFZ label THEN RETURN (HEXX$(branchAddr,8))
'
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
'
'
' #######################
' #####  GetArg ()  #####
' #######################
'
FUNCTION  GetArg (a_reg, a_type, source)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  a0,  a0_type,  a1,  a1_type
'
	IF (source = $$RA0) THEN a0 = 0: a0_type = 0
	IF (source = $$RA1) THEN a1 = 0: a1_type = 0
'
' *****  POTENTIAL PROBLEM with a.reg = 0 or source = 0  ???
'
	IF (a_reg <= $$R9) THEN
		IF (source < $$IMM16) THEN GOTO sreg_to_areg ELSE GOTO smem_to_areg
	ELSE
		IF (source < $$IMM16) THEN GOTO sreg_to_amem ELSE GOTO smem_to_amem
	END IF
	XcowlErr (450022): GOTO eeeCompiler
'
sreg_to_areg:
	Move (a_reg, a_type, source, a_type)
	RETURN (0)
'
smem_to_areg:
	Move (a_reg, a_type, source, a_type)
	RETURN (0)
'
sreg_to_amem:
	IF (a_reg < $$R9) THEN
		a_mem = (a_reg + 2) * 4
	ELSE
		a_mem = (a_reg - 2) * 4
	END IF
	a_mem$  = ",r31," + HEXX$(a_mem, 4)
	s_reg   = source
	EmitNull ($$rmk1$ + " GetArg(): who knows?")
	RETURN
'
smem_to_amem:
	IF (a_reg < $$R9) THEN
		a_mem = (a_reg + 2) * 4
	ELSE
		a_mem = (a_reg - 2) * 4
	END IF
	a_mem$ = ",r31," + HEXX$(a_mem, 4)
	Move ($$rsi, a_type, source, a_type)
	EmitNull ($$rmk1$ + " GetArg(): who knows?")
	RETURN
'
eeeCompiler:
	XERROR =  ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #####################################
' #####  GetExternalAddresses ()  #####  linux ELF version
' #####################################
'
FUNCTION  GetExternalAddresses_OLD ()
	SHARED  labaddr[]
	Elf64_Ehdr  elf
	Elf64_Shdr  sec,  sec[]
	Elf64_Phdr  pro,  pro[]
	Elf64_Sym   sym,  sym[]
	TOKEN token
'
' argc = -1 makes sure original arguments are returned,
' not those from any XstSetCommandLineArguments() calls.
'
	argc = -1
	XstGetCommandLineArguments (@argc, @argv$[])
'
	labels = $$FALSE
	##ERROR = $$FALSE
	ifile$ = TRIM$(argv$[0])                    ' 1st command line arg is name
	IF (argc > 1) THEN
		FOR ii = 1 TO argc
			IF (argv$[ii] = "-labels") THEN labels = ii: EXIT FOR
		NEXT ii
	END IF
'
	IFZ ifile$ THEN
		##ERROR = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidData)
		RETURN ($$FALSE)
	END IF
'
' find the path to the executable
'
	file$ = ifile$
	left$ = LEFT$ (file$, 2)
	IF file$ THEN
		IF (file${0} == '.') THEN
			IF (file${1} == '/') THEN
				XstGetCurrentDirectory (@dir$)
				IF (RIGHT$(dir$,1) != "/") THEN dir$ = dir$ + "/"
				file$ = dir$ + MID$ (file$, 3)                      ' ./xb becomes /usr/xb64/xb
			END IF
		END IF
	END IF
	XstGetExecutionPathArray (@path$[])               ' returns all directories in $PATH
	XstFindFile (@file$, @path$[], @ifile$, @attr)    ' returns full path to ifile$
	XstLoadString (@ifile$, @text$)                   ' load the executable
'
' PRINT "<"; file$; "> <"; ifile$; ">"
'
	##ERROR = $$FALSE
	ifile = OPEN (ifile$, $$RD)                       ' open xb64
	IF (ifile <= 0) THEN                              ' bad file number
		##ERROR = (($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent)
'   IF ##CAPSLOCK THEN PRINT "xcol.x-GetExternalAddresses():error"
		PRINT ifile$; " not found"
		RETURN ($$FALSE)
	END IF
'
	ilen = LOF (ifile)
	IF (ilen < 65536) THEN
		CLOSE (ifile)
		##ERROR = (($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent)
'   IF ##CAPSLOCK THEN PRINT "xcol.x-GetExternalAddresses():error"
		PRINT ifile$; " too small to be PDE: "; ilen
		RETURN ($$FALSE)
	END IF
'
' read in ELF header
'
	READ [ifile], elf                           ' ELF header
'
' PRINT
' PRINT "#####  ELF HEADER  #####"
' PRINT
' PRINT " elf.e_ident[]    =      ";
'
' FOR i = 0 TO 15
'   PRINT "  "; HEX$(elf.e_ident[i],2);
' NEXT i
'
	nonelf = $$FALSE
	SELECT CASE TRUE
		CASE (elf.e_ident[0] != 0x7F) : nonelf = $$TRUE
		CASE (elf.e_ident[1] != 'E')  : nonelf = $$TRUE
		CASE (elf.e_ident[2] != 'L')  : nonelf = $$TRUE
		CASE (elf.e_ident[3] != 'F')  : nonelf = $$TRUE
	END SELECT
'
	IF nonelf THEN PRINT "not an ELF file, can't get external symbols"
'
' print ELF header
'
' PRINT
' PRINT "  elf.e_type       =     "; HEX$(elf.e_type,4);      "  object file type"
' PRINT "  elf.e_machine    =     "; HEX$(elf.e_machine,4);   "  machine aka CPU"
' PRINT "  elf.e_version    = "; HEX$(elf.e_version,8);       "  object file version"
' PRINT "  elf.e_entry      = "; HEX$(elf.e_entry,8);         "  entry address"
' PRINT "  elf.e_phoff      = "; HEX$(elf.e_phoff,8);         "  program header table file offset"
' PRINT "  elf.e_shoff      = "; HEX$(elf.e_shoff,8);         "  section header table file offset"
' PRINT "  elf.e_flags      = "; HEX$(elf.e_flags,8);         "  processor specific flags"
' PRINT "  elf.e_ehsize     =     "; HEX$(elf.e_ehsize,4);    "  this elf header size"
' PRINT "  elf.e_phentsize  =     "; HEX$(elf.e_phentsize,4); "  size of each program header"
' PRINT "  elf.e_phnum      =     "; HEX$(elf.e_phnum,4);     "  number of program headers"
' PRINT "  elf.e_shentsize  =     "; HEX$(elf.e_shentsize,4); "  size of each section header"
' PRINT "  elf.e_shnum      =     "; HEX$(elf.e_shnum,4);     "  number of section headers"
' PRINT "  elf.e_shstrndx   =     "; HEX$(elf.e_shstrndx,4);  "  section name string table - element in section header array"
'
'
' collect program headers
'
' PRINT
' PRINT
' PRINT "#####  PROGRAM HEADERS  #####"
' PRINT
'
	IF elf.e_phnum THEN                         ' if there are program headers
		DIM pro[elf.e_phnum-1]                    ' make an array to hold them
		FOR i = 0 TO elf.e_phnum - 1              ' for all program headers
			READ [ifile], pro                       ' read program header
			pro[i] = pro                            ' save in array
'     PRINT "  pro.p_type       = "; HEX$(pro.p_type,8);          "  program segment type"
'     PRINT "  pro.p_offset     = "; HEX$(pro.p_offset,8);        "  file offset of 1st byte of segment"
'     PRINT "  pro.p_vaddr      = "; HEX$(pro.p_vaddr,8);         "  virtual address of 1st bype of segment"
'     PRINT "  pro.p_paddr      = "; HEX$(pro.p_paddr,8);         "  physical address of 1st byte of segment"
'     PRINT "  pro.p_filesz     = "; HEX$(pro.p_filesz,8);        "  size of file image of this segment"
'     PRINT "  pro.p_memsz      = "; HEX$(pro.p_memsz,8);         "  size of memory image of this segment"
'     PRINT "  pro.p_flags      = "; HEX$(pro.p_flags,8);         "  segment specific flags"
'     PRINT "  pro.p_align      = "; HEX$(pro.p_align,8);         "  segment alignment"
'     PRINT
		NEXT i                                    ' next header
	END IF
'
'
' move file pointer to section headers
'
	SEEK (ifile, elf.e_shoff)
'
'
' collect section headers
'
' PRINT
' PRINT "#####  SECTION HEADERS  #####"
' PRINT
'
	IF elf.e_shnum THEN                         ' if there are section headers
		DIM sec[elf.e_shnum-1]                    ' make an array to hold them
		FOR i = 0 TO elf.e_shnum - 1              ' for all section headers
			READ [ifile], sec                       ' read section header
			sec[i] = sec                            ' save in array
		NEXT i
'
		shstrndx = elf.e_shstrndx
		strsec = sec[shstrndx].sh_offset
'
'   PRINT HEX$(shstrndx,8); " = section header # that refers to section name string table"
'   PRINT HEX$(strsec,8); " = offset to beginning of section name string table"
'   PRINT
'
		FOR i = 0 TO elf.e_shnum - 1              ' for all section headers
			sec = sec[i]
			stroff = strsec + sec.sh_name
			IF (sec.sh_type = 2) THEN
				symndx = i
				symoff = sec.sh_offset
				symafter = symoff + sec.sh_size
				symcount = sec.sh_size \ sec.sh_entsize
				symstroff =  sec[sec.sh_link].sh_offset
			END IF
'     PRINT " "; LJUST$(CSTRING$(&text$ + stroff),20); "SECTION HEADER # "; HEX$(i,8);; i
'     PRINT "  sec.sh_name      = "; HEX$(sec.sh_name,8);         "  section name index into section header string table section"
'     PRINT "  sec.sh_type      = "; HEX$(sec.sh_type,8);         "  section type"
'     PRINT "  sec.sh_flags     = "; HEX$(sec.sh_flags,8);        "  miscellaneous flags"
'     PRINT "  sec.sh_addr      = "; HEX$(sec.sh_addr,8);         "  address of section in memory image of process"
'     PRINT "  sec.sh_offset    = "; HEX$(sec.sh_offset,8);       "  file offset of 1st byte of this section"
'     PRINT "  sec.sh_size      = "; HEX$(sec.sh_size,8);         "  size of this section"
'     PRINT "  sec.sh_link      = "; HEX$(sec.sh_link,8);         "  section header table index link"
'     PRINT "  sec.sh_info      = "; HEX$(sec.sh_info,8);         "  extra information - section type specific"
'     PRINT "  sec.sh_addralign = "; HEX$(sec.sh_addralign,8);    "  section address alignment requirements"
'     PRINT "  sec.sh_entsize   = "; HEX$(sec.sh_entsize,8);      "  size of each entry in section for sections with fixed size entries"
'     PRINT
		NEXT i
	END IF
'
' symndx is the entry in sec[] of the symbol table header
' symoff is the file offset of the symbol table headers
' symstroff is the file offset of the symbol table strings
'
' PRINT HEX$(symndx,8)
' PRINT HEX$(symoff,8)
' PRINT HEX$(symafter,8)
' PRINT HEX$(symcount,8)
' PRINT HEX$(symstroff,8)
'
'
' PRINT "#####  TEST dlopen() and dlclose()   #####"
'
' handle = dlopen (0, 0)
' PRINT "#####  handle = "; HEX$(handle,8); "  0,0"
' IFZ handle THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
'
' addr = dlsym (handle, &"Xst_0")
' PRINT "#####    addr = "; HEX$(addr,8); "  Xst_0"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"XstSleep_4")
' PRINT "#####    addr = "; HEX$(addr,8); "  XstSleep_4"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"Xgr_0")
' PRINT "#####    addr = "; HEX$(addr,8); "  Xgr_0"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"XgrSendMessage_32")
' PRINT "#####    addr = "; HEX$(addr,8); "  XgrSendMessage_32"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"XuiSendMessage_32")
' PRINT "#####    addr = "; HEX$(addr,8); "  XuiSendMessage_32"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"dlopen")
' PRINT "#####    addr = "; HEX$(addr,8); "  dlopen"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"dlclose")
' PRINT "#####    addr = "; HEX$(addr,8); "  dlclose"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"open")
' PRINT "#####    addr = "; HEX$(addr,8); "  open"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"write")
' PRINT "#####    addr = "; HEX$(addr,8); "  write"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"lseek")
' PRINT "#####    addr = "; HEX$(addr,8); "  lseek"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"rmdir")
' PRINT "#####    addr = "; HEX$(addr,8); "  rmdir"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"_xstat")
' PRINT "#####    addr = "; HEX$(addr,8); "  _xstat"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"XxxMain")
' PRINT "#####    addr = "; HEX$(addr,8); "  XxxMain"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"XxxG_0")
' PRINT "#####    addr = "; HEX$(addr,8); "  XxxG_0"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"main")
' PRINT "#####    addr = "; HEX$(addr,8); "  main"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"WinMain")
' PRINT "#####    addr = "; HEX$(addr,8); "  WinMain"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
' addr = dlsym (handle, &"WinMain_16")
' PRINT "#####    addr = "; HEX$(addr,8); "  WinMain_16"
' IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
'
' can't close the handle that belongs to the executable
'
'   error = dlclose (handle)
'   PRINT "#####   error = "; HEX$(error,8)
'   IF error THEN error = dlerror (): PRINT "#####   error = "; CSTRING$(error)
'
'
' *****  Update compiler symbol table from ELF symbol table data  *****
'
' PRINT
' PRINT "#####  SYMBOL TABLE  #####"
' PRINT
'
	IF symndx THEN
		SEEK (ifile, symoff)
		DIM sym[symcount-1]
		FOR i = 0 TO symcount-1
			READ [ifile], sym
			sym[i] = sym
			IFZ sym.st_name THEN DO NEXT                    ' no symbols string
			IFZ (sym.st_info AND 0x0030) THEN DO NEXT       ' skip local symbols
			addr = &text$ + symstroff + sym.st_name
			symbol$ = CSTRING$(addr)
			IF (symbol$ = $$ulpc$+"_StartApplication") THEN DO NEXT
'
' see if dlopen(), dlsym() give same address
'
'     addr = dlsym (handle, &symbol$)
'     PRINT "#####    addr = "; HEX$(addr,8); "  "; symbol$
'     IFZ addr THEN error = dlerror (): PRINT "#####  error = "; CSTRING$(error)
'
' strip invalid trash-suffix put there by ??????????
'
			atat = INSTR (symbol$, "@")
			IF atat THEN symbol$ = LEFT$ (symbol$, atat-1)
'
' add symbol$ in label symbol table
'
			token = AddLabel (@symbol$, $$KIND_LABELS, 0, $$XADD)
			labaddr[token.tindex] = sym.st_value
			IF labels THEN PRINT HEX$(token.tindex, 8), HEX$(sym.st_value, 8), symbol$
'
'     length = LEN(symbol$)
'     IF (length < 26) THEN pad$ = SPACE$(26-length) ELSE pad$ = ""
'     PRINT " \""; symbol$; "\"  "; pad$; HEX$(i,8);; i
'     PRINT "  sym.st_name      = "; HEX$(sym.st_name,8);          "  index into symbol string table"
'     PRINT "  sym.st_value     = "; HEX$(sym.st_value,8);         "  value of symbol - value, address, etc"
'     PRINT "  sym.st_size      = "; HEX$(sym.st_size,8);          "  size of object referred to by symbol"
'     PRINT "  sym.st_info      = "; HEX$(sym.st_info,8);          "  symbol type and binding information"
'     PRINT "  sym.st_other     = "; HEX$(sym.st_other,8);         "  reserved"
'     PRINT "  sym.st_shndx     = "; HEX$(sym.st_shndx,8);         "  associated section header table index"
'     PRINT
		NEXT i
	END IF
'
	text$ = ""
	CLOSE (ifile)
	RETURN (token.tindex+1)
END FUNCTION
'
'
' #####################################
' #####  GetExternalAddresses ()  #####  linux ELF version
' #####################################
'
FUNCTION  GetExternalAddresses ()
	SHARED  labaddr[]
	Elf64_Ehdr  elf
	Elf64_Shdr  sec,  sec[]
	Elf64_Phdr  pro,  pro[]
	Elf64_Sym   sym,  sym[]
	TOKEN token
'
' argc = -1 makes sure original arguments are returned,
' not those from any XstSetCommandLineArguments() calls.
'
	argc = -1
	XstGetCommandLineArguments (@argc, @argv$[])
'
	labels = $$FALSE
	##ERROR = $$FALSE
	ifile$ = TRIM$(argv$[0])                    ' 1st command line arg is name
	IF (argc > 1) THEN
		FOR ii = 1 TO argc
			IF (argv$[ii] = "-labels") THEN labels = ii: EXIT FOR
		NEXT ii
	END IF
'
	IFZ ifile$ THEN
		##ERROR = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidData)
		RETURN ($$FALSE)
	END IF
'
' find the path to the executable
'
	file$ = ifile$
	left$ = LEFT$ (file$, 2)
	IF file$ THEN
		IF (file${0} == '.') THEN
			IF (file${1} == '/') THEN
				XstGetCurrentDirectory (@dir$)
				IF (RIGHT$(dir$,1) != "/") THEN dir$ = dir$ + "/"
				file$ = dir$ + MID$ (file$, 3)                      ' ./xb becomes /usr/xb/xb
			END IF
		END IF
	END IF
	XstGetExecutionPathArray (@path$[])               ' returns all directories in $PATH
	XstFindFile (@file$, @path$[], @ifile$, @attr)    ' returns full path to ifile$
'	XstLoadString (@ifile$, @text$)                   ' load the executable
'
' PRINT "<"; file$; "> <"; ifile$; ">"
'
	##ERROR = $$FALSE
	ifile = OPEN (ifile$, $$RD)                       ' open xb
	IF (ifile <= 0) THEN                              ' bad file number
		##ERROR = (($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent)
'   IF ##CAPSLOCK THEN PRINT "xcol.x-GetExternalAddresses():error"
		PRINT ifile$; " not found"
		RETURN ($$FALSE)
	END IF
'
	ilen = LOF (ifile)
	IF (ilen < 65536) THEN
		CLOSE (ifile)
		##ERROR = (($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent)
'   IF ##CAPSLOCK THEN PRINT "xcol.x-GetExternalAddresses():error"
		PRINT ifile$; " too small to be PDE: "; ilen
		RETURN ($$FALSE)
	END IF
'
' read in ELF header
'
	READ [ifile], elf                           ' ELF header
'
' PRINT
' PRINT "#####  ELF HEADER  #####"
' PRINT
' PRINT " elf.e_ident[]    =      ";
'
' FOR i = 0 TO 15
'   PRINT "  "; HEX$(elf.e_ident[i],2);
' NEXT i
'
	nonelf = $$FALSE
	SELECT CASE TRUE
		CASE (elf.e_ident[0] != 0x7F) : nonelf = $$TRUE
		CASE (elf.e_ident[1] != 'E')  : nonelf = $$TRUE
		CASE (elf.e_ident[2] != 'L')  : nonelf = $$TRUE
		CASE (elf.e_ident[3] != 'F')  : nonelf = $$TRUE
	END SELECT
'
	IF nonelf THEN PRINT "not an ELF file, can't get external symbols"

' ******************* NEW READ 64-bit ELF FILE **********************************
'
'
	verEndClass = ULONGAT(&elf+4)
	IF (verEndClass != 0x010102) THEN
		PRINT "Version, Endian, Class", HEXX$(verEndClass, 8)
		RETURN
	END IF
	shentsize = elf.e_shentsize  'size of each entry in section header table
	sizesec = SIZE(sec)
	IF (shentsize != sizesec) THEN
		PRINT "sh entries size mismatch", shentsize, sizesec
		RETURN
	END IF

	shnum = elf.e_shnum  'number of entries in the section header table
	DIM sec[shnum-1]

	shoff = elf.e_shoff
	filePointer = SEEK(ifile, shoff)

	FOR i = 0 TO shnum-1
		READ [ifile], sec
		sec[i] = sec
	NEXT i
	FOR i = 0 TO shnum-1
		type = sec[i].sh_type
		IF (type == 2) THEN
			GOSUB GetSymEntries
		END IF
	NEXT i

	rc = CLOSE (ifile)
	RETURN (token.tindex+1)
'
'
' *****  GetSymEntries  *****
'
SUB GetSymEntries
	fileOffset = sec[i].sh_offset
	filePointer = SEEK(ifile, fileOffset)
	symShEntsize = sec[i].sh_entsize
	symSize = SIZE(sym)
	IF (symSize <> symShEntsize) THEN
		PRINT "sym table entry size mismatch", symShEntsize, symSize
	END IF
	symEntries = sec[i].sh_size \ symShEntsize
'
' local symbols are usually together at the beginning with externals at the end.
'
	FOR j = 0 TO symEntries-1
		READ [ifile], sym
		info = sym.st_info
		IF (info AND 0x30) THEN EXIT FOR  'exit when first external symbol found
	NEXT j
'
' Put remaining sym entries in an array
'
	symRemaining = symEntries - j
	DIM sym[symRemaining-1]
	sym[0] = sym
	FOR j = 1 TO symRemaining-1
		READ [ifile], sym
		sym[j] = sym
	NEXT j
'
' The string table section should follow the linker symbol table section
'
	nextType = sec[i+1].sh_type
	IF (nextType <> 3) THEN
		PRINT "symbol string table section missing"
		EXIT SUB
	END IF
	nextOffset = sec[i+1].sh_offset
	nextEntries = sec[i+1].sh_size
	buffer$ = NULL$(nextEntries)
	filePointer = SEEK(ifile, nextOffset)
	READ [ifile], buffer$
'
	FOR j = 0 TO symRemaining-1
		info = sym[j].st_info
		IFZ (info AND 0x30) THEN
			DO NEXT
		END IF
		sym = sym[j]
		symName = sym.st_name
		symbol$ = CSTRING$(&buffer$+symName)
		atat = INSTR(symbol$, "@")
		IF atat THEN symbol$ = LEFT$(symbol$, atat-1)
		IF (symbol$ = $$ulpc$+"_StartApplication") THEN DO NEXT
'
' add symbol$ in label symbol table
'
		token = AddLabel (@symbol$, $$KIND_LABELS, 0, $$XADD)
'		PRINT HEXX$(token.tindex), HEXX$(sym.st_value), symbol$
		labaddr[token.tindex] = sym.st_value
		IF labels THEN PRINT HEX$(token.tindex, 8), HEX$(sym.st_value, 8), symbol$
	NEXT j
'
END SUB
'
END FUNCTION
'
'
' ################################
' #####  GetFuncaddrInfo ()  #####
' ################################
'
' SYNTAX:   FUNCADDR [xFUNCTION] [typename] funcaddrVariableOrArray ( [args] )
'
' enter:    token       = [typename] or funcaddrVariableOrArray token
' return:   returnVal   = terminating token
'           token       = funcaddrVariableOrArray token
'           eleElements = # of elements in funcaddrArray[upperBound]
'                         0 if funcaddrVariable or funcaddrArray[]
'           arg[]:        arg[0] = return kind, type, # args
'                         arg[n] = argument kind and type
'           dataPtr     = tokenPtr at funcaddrVariable or funcaddrArray
'
FUNCTION  GetFuncaddrInfo (TOKEN token, eleElements, TOKEN arg[], dataPtr)
	TOKEN   arg
	TOKEN   check
	SHARED  TOKEN tabArg[]
	SHARED  inTYPE,  tokenPtr,  r_addr$[],  tab_sym$[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_COMPONENT
	SHARED  ERROR_DUP_DECLARATION,  ERROR_KIND_MISMATCH
	SHARED  ERROR_OVERFLOW,  ERROR_SYNTAX,  ERROR_TOO_MANY_ARGS
'
	DIM arg[19]
	argNumber   = 0
	eleElements = 0
'
' the following supports the second token in "FUNCADDR [xFUNCTION] DOUBLE cos (DOUBLE)"
'
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_FUNCTION) : callKind = $$XFUNC
		CASE TokenMatch (@token, @#T_CFUNCTION): callKind = $$CFUNC
		CASE TokenMatch (@token, @#T_SFUNCTION): IF $$linux THEN
																							callKind = $$CFUNC
																						ELSE
																							callKind = $$XFUNC
																						END IF
	END SELECT
	IF callKind THEN NextToken (@token)       ' skip xFUNCTION token
	IFZ callKind THEN callKind = $$XFUNC
'
	rtype       = TypenameToken (@token)
	IFZ rtype THEN rtype = $$XLONG
	arg[0].tindex = rtype
	arg[0].tp.stsp = callKind
	arg[0].tp.kind = $$KIND_VARIABLES
'
	kind        = token.tp.kind
	dataPtr     = tokenPtr
	NextToken (@check)
'
	IF inTYPE THEN
		SELECT CASE kind
			CASE $$KIND_SYMBOLS
						IFF TokenMatch (@check, @#T_LPAREN) THEN XcowlErr (480058): GOTO eeeSyntax
			CASE $$KIND_ARRAY_SYMBOLS
						IFF TokenMatch (@check, @#T_LBRAK) THEN XcowlErr (480060): GOTO eeeCompiler
						NextToken (@check)
						IFF TokenMatch (@check, @#T_RBRAK) THEN
							SELECT CASE check.tp.kind
								CASE $$KIND_LITERALS:   arrayDim = XLONG (tab_sym$[check.tindex])
								CASE $$KIND_SYSCONS:    arrayDim = XLONG (r_addr$[check.tindex])
								CASE ELSE:              XcowlErr (480066): GOTO eeeComponent
							END SELECT
							IF ((arrayDim < 0) OR (arrayDim > 16383)) THEN XcowlErr (480068): GOTO eeeOverflow
							eleElements = arrayDim + 1
							NextToken (@check)
							IFF TokenMatch (@check, @#T_RBRAK) THEN XcowlErr (480071): GOTO eeeSyntax
						END IF
						NextToken (@check)
						IFF TokenMatch (@check, @#T_LPAREN) THEN XcowlErr (480074): GOTO eeeSyntax
			CASE ELSE
						XcowlErr (480076): GOTO eeeKindMismatch
		END SELECT
	ELSE
		SELECT CASE kind
			CASE $$KIND_VARIABLES
			CASE $$KIND_ARRAYS
						IFF TokenMatch (@check, @#T_LBRAK) THEN XcowlErr (480082): GOTO eeeSyntax
						NextToken (@check)
						IFF TokenMatch (@check, @#T_RBRAK) THEN XcowlErr (480084): GOTO eeeSyntax
						NextToken (@check)
						IFF TokenMatch (@check, @#T_LPAREN) THEN XcowlErr (480086): GOTO eeeSyntax
			CASE ELSE:    XcowlErr (480087): GOTO eeeKindMismatch
		END SELECT
		IF tabArg[token.tindex, ] THEN XcowlErr (480089): GOTO eeeDupDeclaration
	END IF
'
	DO
		NextToken (@check)
		IF TokenMatch (@check, @#T_RPAREN) THEN EXIT DO
		argType   = TypenameToken (@check)
		IFZ argType THEN
			IFF TokenMatch (@check, @#T_ANY) THEN XcowlErr (480097): GOTO eeeSyntax
			NextToken (@check)
			argType = $$ANY
		END IF
'   PRINT "GetFuncaddrInfo(): argType = "; argType
		IF TokenMatch (@check, @#T_LBRAK) THEN
			NextToken (@check)
			IFF TokenMatch (@check, @#T_RBRAK) THEN XcowlErr (4800104): GOTO eeeSyntax
			NextToken (@check)
			arg.tproto = $$TP_ARRAYS
			arg.tindex = argType
		ELSE
			arg.tproto = $$TP_VARIABLES
			arg.tindex = argType
		END IF
		INC argNumber
		arg[argNumber]  = arg
		IF (argNumber > 16) THEN XcowlErr (4800114): GOTO eeeTooManyArgs
	LOOP WHILE TokenMatch (@check, @#T_COMMA)
	arg[0].tp.type = argNumber
	IFF TokenMatch (@check, @#T_RPAREN) THEN XcowlErr (4800117): GOTO eeeSyntax
	NextToken (@check)
	kind    = check.tp.kind
	SELECT CASE kind
		CASE $$KIND_STARTS, $$KIND_COMMENTS
		CASE ELSE:  XcowlErr (4800122): GOTO eeeSyntax
	END SELECT
	RETURN
'
'
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeComponent:
	XERROR = ERROR_COMPONENT
	EXIT FUNCTION
'
eeeOverflow:
	XERROR = ERROR_OVERFLOW
	EXIT FUNCTION
'
eeeDupDeclaration:
	XERROR = ERROR_DUP_DECLARATION
	EXIT FUNCTION
'
eeeKindMismatch:
	XERROR = ERROR_KIND_MISMATCH
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooManyArgs:
	XERROR = ERROR_TOO_MANY_ARGS
	EXIT FUNCTION
END FUNCTION
'
'
' ########################
' #####  GetSubPath  #####
' ########################
'
FUNCTION  GetSubPath (sub$, file$, path$[])
'
	n$ = ""
	dir$ = ""
	IF file$ THEN n$ = $$PathSlash$ + file$
	IF sub$ THEN dir$ = $$PathSlash$ + sub$
'
	SELECT CASE sub$
		CASE "app" : GOSUB App
		CASE "bak" : GOSUB Normal
		CASE "bin" : GOSUB Normal
		CASE "doc" : GOSUB Normal
		CASE "hlp"
			DIM path$[0]
			path$[ 0] = ##XBDir$ + "/help"                ' "/usr/xb/help"
		CASE "lib" : GOSUB Normal
		CASE "run" : GOSUB Normal
		CASE "win" : GOSUB Normal
		CASE "xxx"
			DIM path$[0]
			path$[ 0] = ##XBDir$ + "/templates"           ' "/usr/xb64/templates"
			IF ##WHOMASK THEN                               '*cw* 220301+ for testing
				XstGetCurrentDirectory (@curDir$)             '*cw* 220301+ for testing
				path$[0] = curDir$ + "/templates/"            '*cw* 220301+ for testing
			END IF                                          '*cw* 220301+ for testing
		CASE ELSE  : GOSUB Normal
	END SELECT
	RETURN
'
' *****  App  *****
'
SUB App
	DIM path$[19]
	path$[ 0] = "."                               ' "."
	path$[ 1] = "./xb"                            ' "./xb"
	path$[ 2] = "./xb" + n$                       ' "./xb/n"
	path$[ 3] = "./xb" + dir$                     ' "./xb/app"
	path$[ 4] = "./xb" + dir$ + n$                ' "./xb/app/n"
	path$[ 5] = "$(HOME)"                         ' "/u/user"
	path$[ 6] = "$(HOME)" + "/xb64"                 ' "/u/user/xb64"
	path$[ 7] = "$(HOME)" + "/xb64" + n$            ' "/u/user/xb64/n"
	path$[ 8] = "$(HOME)" + "/xb64" + dir$          ' "/u/user/xb64/app"
	path$[ 9] = "$(HOME)" + "/xb64" + dir$ + n$     ' "/u/user/xb64/app/n"
	path$[10] = "/usr"                            ' "/usr/"
	path$[11] = "/usr/xb64"                         ' "/usr/xb64"
	path$[12] = "/usr/xb64" + n$                    ' "/usr/xb64/n"
	path$[13] = "/usr/xb64" + dir$                  ' "/usr/xb64/app"
	path$[14] = "/usr/xb64" + dir$ + n$             ' "/usr/xb64/app/n"
	path$[15] = "/xb"                             ' "/xb"
	path$[16] = "/xb" + n$                        ' "/xb/n"
	path$[17] = "/xb" + dir$                      ' "/xb/app"
	path$[18] = "/xb" + dir$ + n$                 ' "/xb/app/n"
	path$[19] = ""                                ' current directory
END SUB
'
' *****  Normal  *****
'
SUB Normal
	DIM path$[7]
	path$[ 0] = "."                               ' "."
	path$[ 1] = "." + dir$                        ' "./xxx"
	path$[ 2] = "./xb" + dir$                     ' "./xb/xxx"
	path$[ 3] = "$(HOME)" + dir$                  ' "/u/user/xxx"
	path$[ 4] = "$(HOME)" + "/xb" + dir$          ' "/u/user/xb/xxx"
	path$[ 5] = "/usr/xb" + dir$                  ' "/usr/xb/xxx"
	path$[ 6] = "/usr" + dir$                     ' "/usr/xxx"
	path$[ 7] = "/xb" + dir$                      ' "/xb/xxx"
END SUB
END FUNCTION
'
'
' ###########################
' #####  GetSymbol$ ()  #####
' ###########################
'
FUNCTION  GetSymbol$ (info)
	SHARED  charPtr,  rawline$
	SHARED UBYTE  charsetSymbolInner[]
'
	char_start = charPtr                    ' 1st character of symbol in rawline$
	charV = rawline${charPtr}
	SELECT CASE charV
		CASE '$':   INC charPtr
								info  = $$LOCAL_CONSTANT            ' $LocalConstant
								charV = rawline${charPtr}
								IF (charV = '$') THEN
									INC charPtr
									info  = $$GLOBAL_CONSTANT         ' $$SharedConstant
									charV = rawline${charPtr}
								END IF
		CASE '#':   INC charPtr
								info  = $$SHARED_VARIABLE           ' #SharedVariable
								charV = rawline${charPtr}
								IF (charV = '#') THEN
									info  = $$EXTERNAL_VARIABLE       ' ##ExternalVariable
									INC charPtr
									charV = rawline${charPtr}
								END IF
								IFZ charsetSymbolInner[charV] THEN
									SELECT CASE info
										CASE $$SHARED_VARIABLE   : info = $$SOLO_POUND: RETURN
										CASE $$EXTERNAL_VARIABLE : info = $$DUAL_POUND: RETURN
									END SELECT
								END IF
		CASE '.':   INC charPtr
								info  = $$COMPONENT                 ' .component
								charV = rawline${charPtr}
		CASE ELSE:  info  = $$NORMAL_SYMBOL             ' normalSymbol
	END SELECT
'
	DO WHILE (charsetSymbolInner[charV])  ' TRUE while A-Z, a-z, 0-9, "_"
		INC charPtr
		charV = rawline${charPtr}
	LOOP
	y$ = MID$ (rawline$, char_start+1, charPtr-char_start)
	RETURN (y$)
END FUNCTION
'
'
' ##################################
' #####  GetTokenOrAddress ()  #####
' ##################################
'
' Returns input token if it is:
'         simple-type token except string (style = $$VAR_TOKEN)
'         composite-type token w/o components (style = $$VAR_TOKEN)
'         any-type null array (style = $$ARRAY_TOKEN)
'         string variable (style = $$ARRAY_TOKEN)
' Returns address of data if:
'         any array with excess comma subscript (style = $$ARRAY_NODE)
'         composite-type token with components (style = $$DATA_ADDR)
'         composite-type array with components (style = $$DATA_ADDR)
'         composite-type array without components (style = $$DATA_ADDR)
'
'
FUNCTION  GetTokenOrAddress (TOKEN token, style, TOKEN nextToken, theType, ntype, TOKEN base, offset, length)
	TOKEN   newOp, t1, t2
	SHARED  tokenPtr
	SHARED  typeSize[],  m_addr$[]
	SHARED  XERROR,  ERROR_COMPILER
'
	base      = #T_ZERO
	style     = 0
	offset    = 0
	length    = 0
	holdPtr   = tokenPtr
	kind      = token.tp.kind
	SELECT CASE kind
		CASE $$KIND_VARIABLES, $$KIND_ARRAYS
		CASE ELSE:  token = #T_ZERO: NextToken (@nextToken): style = 0: RETURN ($$FALSE)
	END SELECT
	IFZ m_addr$[token.tindex] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
	theType   = TheType (token)
	ntype     = theType
	SELECT CASE kind
		CASE $$KIND_VARIABLES:  GOTO variables
		CASE $$KIND_ARRAYS:     GOTO arrays
	END SELECT
	XcowlErr (510043): GOTO eeeCompiler
'
'
' *****  VARIABLES  *****  SIMPLE-TYPE, COMPOSITE-TYPE
'
variables:
	SELECT CASE TRUE
		CASE (theType < $$STRING)
					style   = $$VAR_TOKEN
		CASE (theType = $$STRING)
					style   = $$ARRAY_TOKEN
		CASE (theType >= $$SCOMPLEX)
					node    = 0
					IF LastElement (token, 0, @node) THEN
						style   = $$VAR_TOKEN
						length  = typeSize[theType]
					ELSE
						base    = token
						IF node THEN XcowlErr (510061): GOTO eeeCompiler
						command = $$GETDATAADDR
						Composite (command, @theType, @base, @offset, @length)
						IF XERROR THEN EXIT FUNCTION
						style   = $$DATA_ADDR
						token   = #T_ZERO
					END IF
		CASE ELSE
					XcowlErr (510069): GOTO eeeCompiler
	END SELECT
	NextToken (@nextToken)
	RETURN ($$TRUE)
'
'
'
' *****  ARRAYS  *****  NULL, SIMPLE-TYPE, COMPOSITE-TYPE
'
arrays:
	NextToken (@t1)
	NextToken (@t2)
	IFF TokenMatch (@t1, @#T_LBRAK) THEN XcowlErr (510081): GOTO eeeCompiler
	IF TokenMatch (@t2, @#T_RBRAK) THEN
		style       = $$ARRAY_TOKEN
		NextToken (@nextToken)
		RETURN ($$TRUE)
	END IF
	tokenPtr = holdPtr
	SELECT CASE TRUE
		CASE (theType < $$SCOMPLEX):  GOTO simpleArrays
		CASE ELSE:                    GOTO compositeArrays
	END SELECT
	XcowlErr (510092): GOTO eeeCompiler
'
'
' *****  SIMPLE ARRAYS  *****
'
simpleArrays:
	IF theType == $$STRING THEN node = $$TRUE
	holdType  = theType
	newOp = #T_ADDR_OP: newPrec = $$PREC_ADDR_OP
	ExpressArray (@newOp, @newPrec, @token, @theType, 0, @node, 0, 0)
	IF XERROR THEN EXIT FUNCTION
	IFF TokenMatch (@token, @#T_ZERO) THEN XcowlErr (5100103): GOTO eeeCompiler
	style       = $$DATA_ADDR
	IF node THEN
		style = $$ARRAY_NODE
	ELSE
		theType = holdType
	END IF
	length      = typeSize[theType]
	NextToken (@nextToken)
	base.tindex       = Top ()
	RETURN ($$TRUE)
'
'
' *****  COMPOSITE ARRAYS  *****
'
compositeArrays:
	last    = LastElement (token, 0, @node)
	IF node THEN GOTO simpleArrays
	command = $$GETDATAADDR
	style   = $$DATA_ADDR
	base    = token
	node    = 0
	Composite (command, @theType, @base, @offset, @length)
	IF XERROR THEN EXIT FUNCTION
	NextToken (@nextToken)
	RETURN ($$TRUE)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #########################
' #####  GetWords ()  #####
' #########################
'
FUNCTION  GetWords (srcTindex, gtype, w3, w2, w1, w0)
	SHARED  r_addr$[]
	SHARED  XERROR,  ERROR_OVERFLOW,  ERROR_TYPE_MISMATCH
'
	gg      = srcTindex
	x$      = r_addr$[gg]
	IFZ x$ THEN w3 = 0: w2 = 0: w1 = 0: w0 = 0: RETURN
	IF (gtype < $$SLONG) THEN gtype = $$SLONG
'
'
' *****  Normal numeric formats  *****
'
	SELECT CASE gtype
		CASE $$SLONG : x#  = DOUBLE (x$)
										x&  = x#
										w3  = 0
										w2  = 0
										w1  = x&{16, 16}
										w0  = x&{16,  0}
'		CASE $$ULONG : x#  = DOUBLE (x$)
'										PRINT "GetWords927)", x#, x$
'										IF (x# < $$MIN_SLONG) THEN XcowlErr (520027): GOTO eeeOverflow
'										IF (x# > $$MAX_ULONG) THEN XcowlErr (520028): GOTO eeeOverflow
		CASE $$ULONG : x  = XLONG (x$)
'										PRINT "GetWords31)", x, x$
										IF (x < $$MIN_SLONG) THEN XcowlErr (520027): GOTO eeeOverflow
										IF (x > $$MAX_ULONG) THEN XcowlErr (520028): GOTO eeeOverflow
										x&& = x
										w3  = 0
										w2  = 0
										w1  = x&&{16, 16}
										w0  = x&&{16,  0}
		CASE $$XLONG : x  = XLONG (x$)
										w3  = x{16, 48}
										w2  = x{16, 32}
										w1  = x{16, 16}
										w0  = x{16, 0}
		CASE $$GIANT : x  = XLONG (x$)
										w3  = x{16, 48}
										w2  = x{16, 32}
										w1  = x{16, 16}
										w0  = x{16, 0}
		CASE $$SINGLE: x#  = DOUBLE (x$)
										x!  = x#
										w3  = 0
										w2  = 0
										w1  = x!{16, 16}
										w0  = x!{16,  0}
		CASE $$DOUBLE
										x#  = DOUBLE (x$)
										w3  = USHORTAT(&x# + 6)
										w2  = USHORTAT(&x# + 4)
										w1  = USHORTAT(&x# + 2)
										w0  = USHORTAT(&x#)
		CASE ELSE:      XcowlErr (520056): GOTO eeeTypeMismatch
	END SELECT
	RETURN
'
eeeOverflow:
	XERROR = ERROR_OVERFLOW
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ###########################
' #####  InitArrays ()  #####
' ###########################
'
' Dimension all SHARED arrays, clearing the contents to zero.
' Define the contents of "information", "default", "charset" arrays.
'
FUNCTION  InitArrays ()
	STATIC  reEntry
	SHARED  ulabel,  upatch,  typePtr
	SHARED  labelPtr,  tab_sym_ptr,  uFunc,  uType,  xargNum
	SHARED  reg86$[31]
	SHARED  reg86c$[31]
'
' *****  DATA TYPE ARRAYS  *****
'
	SHARED  typeSymbol$[63]
	SHARED  typeSuffix$[63]
	SHARED  typeName$[63]
	SHARED  typeSize$[63]
	SHARED  typeAlias[63]
	SHARED  typeAlign[63]
	SHARED  TOKEN typeToken[63]
	SHARED  typeSize[63]
	SHARED  typeEleCount[63]
	SHARED  typeEleSymbol$[63,]
	SHARED  TOKEN   typeEleToken[63,]
	SHARED  typeEleAddr[63,]
	SHARED  typeEleSize[63,]
	SHARED  typeEleType[63,]
	SHARED  TOKEN  typeEleArg[63,]
	SHARED  typeEleVal[63,]
	SHARED  typeElePtr[63,]
	SHARED  typeEleStringSize[63,]
	SHARED  typeEleUBound[63,]
'
' *****  MISCELLANEOUS ARRAYS  *****
'
	SHARED UBYTE oos[255]
	SHARED  xerror$[63]
	SHARED  TOKEN  tokens[511]
	SHARED  charpos[255]
	SHARED  TOKEN stackData[31]
	SHARED  stackType[31]
	SHARED  r_addr[9999]
	SHARED  r_addr$[9999]
	SHARED  m_reg[9999]
	SHARED  m_addr[9999]
	SHARED  m_addr$[9999]
	SHARED  tab_sym$[9999]
	SHARED  tabType[9999]
	SHARED  TOKEN  tab_sym[9999]
	SHARED  TOKEN  tabArg[9999, ]
	SHARED  labhash[255, 63]
	SHARED  labaddr[16383]
	SHARED  TOKEN  tab_lab[16383]
	SHARED  tab_lab$[16383]
	SHARED  xargAddr[15]
	SHARED  xargName$[15]
'
	SHARED  hash%[63, ]
	SHARED  TOKEN   funcToken[63]
	SHARED  funcSymbol$[63]
	SHARED  funcLabel$[63]
	SHARED  funcFrameSize[63]
	SHARED  funcScope[63]
	SHARED  funcKind[63]
	SHARED  funcType[63]
	SHARED  funcArgSize[63]
	SHARED  TOKEN  funcArg[63, ]
	SHARED  autoAddr[63]
	SHARED  autoxAddr[63]
	SHARED  inargAddr[63]
	SHARED  defaultType[63]
	SHARED  compositeNumber[63]
	SHARED  TOKEN compositeStart[63, ]
	SHARED  TOKEN compositeToken[63, ]
	SHARED  TOKEN compositeNext[63, ]
'
	SHARED  patchType[8191]
	SHARED  patchAddr[8191]
	SHARED  TOKEN patchDest[8191]
	SHARED  TOKEN nestVar[63]
	SHARED  nestInfo[63]
	SHARED  nestStep[63]
	SHARED  nestLimit[63]
	SHARED  nestCount[63]
	SHARED  TOKEN  nestToken[63]
	SHARED  nestLevel[63]
	SHARED USHORT hx[255]
'
	SHARED assemblerBackslashAsm$[]
	SHARED UBYTE shiftMulti[]
	SHARED UBYTE charsetSymbolFirst[]
	SHARED UBYTE charsetSymbolInner[]
	SHARED UBYTE charsetSymbolFinal[]
	SHARED UBYTE charsetSymbol[]
	SHARED UBYTE charsetPath[]
	SHARED UBYTE charsetUpper[]
	SHARED UBYTE charsetLower[]
	SHARED UBYTE charsetNumeric[]
	SHARED UBYTE charsetUpperLower[]
	SHARED UBYTE charsetUpperNumeric[]
	SHARED UBYTE charsetLowerNumeric[]
	SHARED UBYTE charsetUpperLowerNumeric[]
	SHARED UBYTE charsetUpperToLower[]
	SHARED UBYTE charsetLowerToUpper[]
	SHARED UBYTE charsetVex[]
	SHARED UBYTE charsetHexUpper[]
	SHARED UBYTE charsetHexLower[]
	SHARED UBYTE charsetHexUpperLower[]
	SHARED UBYTE charsetHexUpperToLower[]
	SHARED UBYTE charsetHexLowerToUpper[]
	SHARED UBYTE charsetBackslash[]
	SHARED UBYTE charsetBackslashByte[]
	SHARED UBYTE charsetBackslashChar[]
	SHARED UBYTE charsetNormalChar[]
	SHARED UBYTE charsetPrintChar[]
	SHARED UBYTE charsetSpaceTab[]
	SHARED UBYTE charsetSuffix[]
'
	SHARED  alphaFirst[]
	SHARED  alphaLast[]
	SHARED  libraryCode$[]
	SHARED  libraryName$[]
	SHARED  libraryHandle[]
	SHARED  tab_sys$[]
	SHARED  TOKEN  tab_sys[]
	SHARED  minval#[]
	SHARED  maxval#[]
	SHARED  SLONG cop[]
'
	SHARED  q_type_int[]
	SHARED  q_type_long[]
	SHARED  q_type_long_or_addr[]
	SHARED  typeHigher[]
	SHARED SSHORT typeConvert[]
'
' ***************************************************
' *****  SET UP DATA TYPE ARRAYS AND VARIABLES  *****
' ***************************************************
' *****  Variables needed for Data Type Arrays  *****
' ***************************************************
'
	typePtr     = 34      ' slot after DCOMPLEX
	uFunc       = 63      ' room for 64 functions to start
	uType       = 63      ' room for 64 types to start
	upatch      = 8191    ' upper bound of patch arrays
	ulabel      = 16383   ' upper bound of label arrays
	xargNum     = 0
	labelPtr    = 0
	tab_sym_ptr = 0
'
	DIM libraryCode$[]    ' waste the previous libraries
	DIM libraryName$[]    '
	DIM libraryHandle[]   '
'
	DIM temp%[255, ]
	ATTACH temp%[] TO hash%[0, ]
'
'
' ******************
' *****  hx[]  *****  (For better hash distribution)
' ******************
'
	hx[  0] = 0xF3C9: hx[ 64] = 0x811D: hx[128] = 0x199C: hx[192] = 0xD0C8
	hx[  1] = 0xE034: hx[ 65] = 0xC6E3: hx[129] = 0x1299: hx[193] = 0x3C07
	hx[  2] = 0xB37C: hx[ 66] = 0xCA5D: hx[130] = 0xA314: hx[194] = 0xDDCA
	hx[  3] = 0x4E31: hx[ 67] = 0x5AF2: hx[131] = 0xEF45: hx[195] = 0xB2C1
	hx[  4] = 0xC0DE: hx[ 68] = 0xB2F3: hx[132] = 0xEFC3: hx[196] = 0x6A7C
	hx[  5] = 0x2487: hx[ 69] = 0xCF28: hx[133] = 0x8A2D: hx[197] = 0x5E02
	hx[  6] = 0x98E2: hx[ 70] = 0x4714: hx[134] = 0x2553: hx[198] = 0x4C8B
	hx[  7] = 0x557C: hx[ 71] = 0x32B0: hx[135] = 0x8CA6: hx[199] = 0x6652
	hx[  8] = 0xA6CB: hx[ 72] = 0x9A76: hx[136] = 0x60B8: hx[200] = 0x3C50
	hx[  9] = 0x410D: hx[ 73] = 0xB2A4: hx[137] = 0x2192: hx[201] = 0x02B8
	hx[ 10] = 0x7767: hx[ 74] = 0xDE9B: hx[138] = 0xA15C: hx[202] = 0x7B70
	hx[ 11] = 0x3861: hx[ 75] = 0xE0E1: hx[139] = 0xA527: hx[203] = 0x118F
	hx[ 12] = 0x5517: hx[ 76] = 0xA7C3: hx[140] = 0x1FAC: hx[204] = 0xEF65
	hx[ 13] = 0x0918: hx[ 77] = 0x0E48: hx[141] = 0xC554: hx[205] = 0x3D6E
	hx[ 14] = 0xF3AF: hx[ 78] = 0xFABE: hx[142] = 0x5ECB: hx[206] = 0xCAB2
	hx[ 15] = 0x2EAB: hx[ 79] = 0xE351: hx[143] = 0x7941: hx[207] = 0x23F0
	hx[ 16] = 0x210D: hx[ 80] = 0x4419: hx[144] = 0x3EA2: hx[208] = 0x927F
	hx[ 17] = 0xDF19: hx[ 81] = 0x5AB4: hx[145] = 0xE73D: hx[209] = 0x1F12
	hx[ 18] = 0x2F0B: hx[ 82] = 0xDDF9: hx[146] = 0xDE62: hx[210] = 0xEDCE
	hx[ 19] = 0x269A: hx[ 83] = 0x513E: hx[147] = 0x9FFA: hx[211] = 0x0D52
	hx[ 20] = 0xE171: hx[ 84] = 0x1BDF: hx[148] = 0x0CE8: hx[212] = 0x69B5
	hx[ 21] = 0x8D07: hx[ 85] = 0xA0BC: hx[149] = 0x8683: hx[213] = 0x9DC4
	hx[ 22] = 0x0AF1: hx[ 86] = 0xC2E5: hx[150] = 0x481C: hx[214] = 0x910F
	hx[ 23] = 0x4627: hx[ 87] = 0x5917: hx[151] = 0x80E4: hx[215] = 0xEE6D
	hx[ 24] = 0x7C4B: hx[ 88] = 0x0448: hx[152] = 0xC43E: hx[216] = 0xA0E7
	hx[ 25] = 0xA59A: hx[ 89] = 0xE110: hx[153] = 0x7830: hx[217] = 0xF2ED
	hx[ 26] = 0x561F: hx[ 90] = 0xA4C8: hx[154] = 0x3952: hx[218] = 0x6EA2
	hx[ 27] = 0x1F90: hx[ 91] = 0x5BC6: hx[155] = 0x2BBA: hx[219] = 0xFEFC
	hx[ 28] = 0x9407: hx[ 92] = 0x1250: hx[156] = 0x476D: hx[220] = 0x0A20
	hx[ 29] = 0xAAAA: hx[ 93] = 0x3D09: hx[157] = 0xF307: hx[221] = 0xA568
	hx[ 30] = 0x404B: hx[ 94] = 0xD230: hx[158] = 0x5A6A: hx[222] = 0xB90E
	hx[ 31] = 0xCCB2: hx[ 95] = 0x19F1: hx[159] = 0x232A: hx[223] = 0xFA26
	hx[ 32] = 0xB6B8: hx[ 96] = 0x28D0: hx[160] = 0x36DA: hx[224] = 0xFB8E
	hx[ 33] = 0x93E5: hx[ 97] = 0x0FD7: hx[161] = 0x1448: hx[225] = 0x3091
	hx[ 34] = 0xCD83: hx[ 98] = 0x79BD: hx[162] = 0x016A: hx[226] = 0x56A1
	hx[ 35] = 0x8392: hx[ 99] = 0xE856: hx[163] = 0xF0CC: hx[227] = 0x184A
	hx[ 36] = 0x951B: hx[100] = 0xDDDE: hx[164] = 0x5328: hx[228] = 0xDEC0
	hx[ 37] = 0x983F: hx[101] = 0xBD28: hx[165] = 0x8B83: hx[229] = 0xC39F
	hx[ 38] = 0x1BB3: hx[102] = 0xD9F7: hx[166] = 0x1566: hx[230] = 0xBED3
	hx[ 39] = 0x40A7: hx[103] = 0xCBB9: hx[167] = 0xB0D3: hx[231] = 0x51F5
	hx[ 40] = 0x5D7E: hx[104] = 0x9B85: hx[168] = 0xCE2F: hx[232] = 0xC0E9
	hx[ 41] = 0x65A1: hx[105] = 0x82DC: hx[169] = 0x30FA: hx[233] = 0x617B
	hx[ 42] = 0x8576: hx[106] = 0x67B0: hx[170] = 0x49C6: hx[234] = 0xF6E9
	hx[ 43] = 0xAC39: hx[107] = 0x8720: hx[171] = 0x94D9: hx[235] = 0x9775
	hx[ 44] = 0xFE04: hx[108] = 0x0CDF: hx[172] = 0xE69B: hx[236] = 0xD5A5
	hx[ 45] = 0x6C6F: hx[109] = 0xA884: hx[173] = 0x7B2C: hx[237] = 0xF7D3
	hx[ 46] = 0x838F: hx[110] = 0x238D: hx[174] = 0x340B: hx[238] = 0x2BD5
	hx[ 47] = 0xDA44: hx[111] = 0xACED: hx[175] = 0x2E46: hx[239] = 0xBB3D
	hx[ 48] = 0x7B93: hx[112] = 0x773B: hx[176] = 0xFD83: hx[240] = 0x1483
	hx[ 49] = 0x851E: hx[113] = 0x84F1: hx[177] = 0xB1A9: hx[241] = 0x5906
	hx[ 50] = 0xD23F: hx[114] = 0xB1A6: hx[178] = 0x6F78: hx[242] = 0x6D25
	hx[ 51] = 0x1F47: hx[115] = 0x049F: hx[179] = 0xF3FE: hx[243] = 0x0BEE
	hx[ 52] = 0x7C74: hx[116] = 0x8B30: hx[180] = 0x387B: hx[244] = 0xE76B
	hx[ 53] = 0xBF9D: hx[117] = 0xB545: hx[181] = 0xCCC2: hx[245] = 0x6751
	hx[ 54] = 0x7646: hx[118] = 0x48EC: hx[182] = 0x762C: hx[246] = 0x2A06
	hx[ 55] = 0xC9FF: hx[119] = 0xF885: hx[183] = 0x603E: hx[247] = 0x49E3
	hx[ 56] = 0x7944: hx[120] = 0x3985: hx[184] = 0x02F9: hx[248] = 0x9854
	hx[ 57] = 0x953D: hx[121] = 0x3D6A: hx[185] = 0x3F51: hx[249] = 0x11F4
	hx[ 58] = 0xE666: hx[122] = 0x6871: hx[186] = 0x6C2E: hx[250] = 0xA655
	hx[ 59] = 0xB2DA: hx[123] = 0x2F08: hx[187] = 0x0777: hx[251] = 0x742F
	hx[ 60] = 0x743C: hx[124] = 0x94DE: hx[188] = 0xE456: hx[252] = 0x8C19
	hx[ 61] = 0xDB99: hx[125] = 0x4CA5: hx[189] = 0x7AA0: hx[253] = 0xB74A
	hx[ 62] = 0x48BB: hx[126] = 0xD5EA: hx[190] = 0x0766: hx[254] = 0xD219
	hx[ 63] = 0xF794: hx[127] = 0xAD4C: hx[191] = 0x4882: hx[255] = 0x63DD
'
'
' ***************************
' *****  typeSymbol$[]  *****
' ***************************
'
	typeSymbol$[$$ZERO]     = "NONE"
	typeSymbol$[$$VOID]     = "VOID"
	typeSymbol$[$$SBYTE]    = "SBYTE"
	typeSymbol$[$$UBYTE]    = "UBYTE"
	typeSymbol$[$$SSHORT]   = "SSHORT"
	typeSymbol$[$$USHORT]   = "USHORT"
	typeSymbol$[$$SLONG]    = "SLONG"
	typeSymbol$[$$ULONG]    = "ULONG"
	typeSymbol$[$$XLONG]    = "XLONG"
	typeSymbol$[$$GOADDR]   = "GOADDR"
	typeSymbol$[$$SUBADDR]  = "SUBADDR"
	typeSymbol$[$$FUNCADDR] = "FUNCADDR"
	typeSymbol$[$$GIANT]    = "GIANT"
	typeSymbol$[$$SINGLE]   = "SINGLE"
	typeSymbol$[$$DOUBLE]   = "DOUBLE"
	typeSymbol$[$$ANY]      = "ANY"
	typeSymbol$[$$ETC]      = "ETC"
	typeSymbol$[$$STRING]   = "STRING"
	typeSymbol$[$$SCOMPLEX] = "SCOMPLEX"
	typeSymbol$[$$DCOMPLEX] = "DCOMPLEX"
'
'
' ***************************
' *****  typeSuffix$[]  *****
' ***************************
'
	typeSuffix$[$$ZERO]     = ""
	typeSuffix$[$$VOID]     = ""
	typeSuffix$[$$SBYTE]    = "@"
	typeSuffix$[$$UBYTE]    = "@@"
	typeSuffix$[$$SSHORT]   = "%"
	typeSuffix$[$$USHORT]   = "%%"
	typeSuffix$[$$SLONG]    = "&"
	typeSuffix$[$$ULONG]    = "&&"
	typeSuffix$[$$XLONG]    = "~"
	typeSuffix$[$$GIANT]    = "$$"
	typeSuffix$[$$SINGLE]   = "!"
	typeSuffix$[$$DOUBLE]   = "#"
	typeSuffix$[$$ANY]      = "[]"
	typeSuffix$[$$ETC]      = "..."
	typeSuffix$[$$STRING]   = "$"
'
'
'
' **************************
' *****  typeToken[]  *****                            New - - - Replaces typeToken[]
' **************************
'
	typeToken[$$SBYTE].tproto    = $$TP_TYPES: typeToken[$$SBYTE].tindex    = $$SBYTE
	typeToken[$$UBYTE].tproto    = $$TP_TYPES: typeToken[$$UBYTE].tindex    = $$UBYTE
	typeToken[$$SSHORT].tproto   = $$TP_TYPES: typeToken[$$SSHORT].tindex   = $$SSHORT
	typeToken[$$USHORT].tproto   = $$TP_TYPES: typeToken[$$SSHORT].tindex   = $$USHORT
	typeToken[$$SLONG].tproto    = $$TP_TYPES: typeToken[$$SLONG].tindex    = $$SLONG
	typeToken[$$ULONG].tproto    = $$TP_TYPES: typeToken[$$ULONG].tindex    = $$ULONG
	typeToken[$$XLONG].tproto    = $$TP_TYPES: typeToken[$$XLONG].tindex    = $$XLONG
	typeToken[$$GOADDR].tproto   = $$TP_TYPES: typeToken[$$GOADDR].tindex   = $$GOADDR
	typeToken[$$SUBADDR].tproto  = $$TP_TYPES: typeToken[$$SUBADDR].tindex  = $$SUBADDR
	typeToken[$$FUNCADDR].tproto = $$TP_TYPES: typeToken[$$FUNCADDR].tindex = $$FUNCADDR
	typeToken[$$GIANT].tproto    = $$TP_TYPES: typeToken[$$GIANT].tindex    = $$GIANT
	typeToken[$$SINGLE].tproto   = $$TP_TYPES: typeToken[$$SINGLE].tindex   = $$SINGLE
	typeToken[$$DOUBLE].tproto   = $$TP_TYPES: typeToken[$$DOUBLE].tindex   = $$DOUBLE
	typeToken[$$ANY].tproto      = $$TP_TYPES: typeToken[$$ZERO].tindex     = $$ZERO
	typeToken[$$STRING].tproto   = $$TP_TYPES: typeToken[$$STRING].tindex   = $$STRING
	typeToken[$$SCOMPLEX].tproto = $$TP_TYPES: typeToken[$$SCOMPLEX].tindex = $$SCOMPLEX
	typeToken[$$DCOMPLEX].tproto = $$TP_TYPES: typeToken[$$DCOMPLEX].tindex = $$DCOMPLEX
'
'
'
' *************************
' *****  typeName$[]  *****
' *************************
'
	typeName$[$$ZERO]       = "none"
	typeName$[$$VOID]       = "void"
	typeName$[$$SBYTE]      = "sbyte"
	typeName$[$$UBYTE]      = "ubyte"
	typeName$[$$SSHORT]     = "sshort"
	typeName$[$$USHORT]     = "ushort"
	typeName$[$$SLONG]      = "slong"
	typeName$[$$ULONG]      = "ulong"
	typeName$[$$XLONG]      = "xlong"
	typeName$[$$GOADDR]     = "goaddr"
	typeName$[$$SUBADDR]    = "subaddr"
	typeName$[$$FUNCADDR]   = "funcaddr"
	typeName$[$$GIANT]      = "giant"
	typeName$[$$SINGLE]     = "single"
	typeName$[$$DOUBLE]     = "double"
	typeName$[$$ANY]        = "any"
	typeName$[$$ETC]        = "etc"
	typeName$[$$STRING]     = "string"
	typeName$[$$SCOMPLEX]   = "singleComplex"
	typeName$[$$DCOMPLEX]   = "doubleComplex"
'
'
' **************************************
' *****  typeSize[],  typeSize$[]  *****
' **************************************
'
	FOR i = 0 TO 63
		SELECT CASE i
			CASE $$SBYTE:     typeSize[i] =  1:   typeSize$[i] =  "1"
			CASE $$UBYTE:     typeSize[i] =  1:   typeSize$[i] =  "1"
			CASE $$SSHORT:    typeSize[i] =  2:   typeSize$[i] =  "2"
			CASE $$USHORT:    typeSize[i] =  2:   typeSize$[i] =  "2"
			CASE $$SLONG:     typeSize[i] =  4:   typeSize$[i] =  "4"
			CASE $$ULONG:     typeSize[i] =  4:   typeSize$[i] =  "4"
			CASE $$GIANT:     typeSize[i] =  8:   typeSize$[i] =  "8"
			CASE $$SINGLE:    typeSize[i] =  4:   typeSize$[i] =  "4"
			CASE $$DOUBLE:    typeSize[i] =  8:   typeSize$[i] =  "8"
			CASE $$SCOMPLEX:  typeSize[i] =  8:   typeSize$[i] =  "8"
			CASE $$DCOMPLEX:  typeSize[i] = 16:   typeSize$[i] = "16"
			CASE ELSE:        typeSize[i] =  8:   typeSize$[i] =  "8"
		END SELECT
	NEXT
'
'
' ****************************************
' *****  typeAlias[],  typeAlign[]  ******
' ****************************************
'
	FOR i = 0 TO 63
		SELECT CASE i
			CASE $$SBYTE:     typeAlias[i] = i:   typeAlign[i] = 1
			CASE $$UBYTE:     typeAlias[i] = i:   typeAlign[i] = 1
			CASE $$SSHORT:    typeAlias[i] = i:   typeAlign[i] = 2
			CASE $$USHORT:    typeAlias[i] = i:   typeAlign[i] = 2
			CASE $$SLONG:     typeAlias[i] = i:   typeAlign[i] = 4
			CASE $$ULONG:     typeAlias[i] = i:   typeAlign[i] = 4
			CASE $$XLONG:     typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$GOADDR:    typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$SUBADDR:   typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$FUNCADDR:  typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$GIANT:     typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$SINGLE:    typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$DOUBLE:    typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$STRING:    typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$SCOMPLEX:  typeAlias[i] = i:   typeAlign[i] = 8
			CASE $$DCOMPLEX:  typeAlias[i] = i:   typeAlign[i] = 8
			CASE ELSE:        typeAlias[i] = 0:   typeAlign[i] = 0
		END SELECT
	NEXT
'
	reg86$[ 1] = "%rsp"     ' rsp
	reg86$[ 2] = "%al"      ' al
	reg86$[ 3] = "%dl"      ' dl
	reg86$[ 4] = "%bl"      ' bl
	reg86$[ 5] = "%cl"      ' cl
	reg86$[ 6] = "%ax"      ' ax
	reg86$[ 7] = "%dx"      ' dx
	reg86$[ 8] = "%bx"      ' bx
	reg86$[ 9] = "%cx"      ' cx
	reg86$[10] = "%eax"     ' eax
	reg86$[11] = "%edx"     ' edx     danger: register overload
	reg86$[12] = "%ebx"     ' ebx
	reg86$[13] = "%ecx"     ' ecx     danger: register overload
	reg86$[14] = "%rax"     ' rax
	reg86$[15] = "%rdx"     ' rdx
	reg86$[16] = "%rbx"     ' rbx
	reg86$[17] = "%rcx"     ' rcx
	reg86$[18] = "%r8"      ' rcx
	reg86$[19] = "%r9"      ' rcx
	reg86$[26] = "%rsi"     ' rsi
	reg86$[27] = "%rdi"     ' rdi
	reg86$[28] = "%ecx"     ' ecx     danger: register overload
	reg86$[29] = "%edx"     ' edx     danger: register overload
	reg86$[31] = "%rbp"     ' rbp
'
	reg86c$[ 1] = "%rsp,"   ' rsp
	reg86c$[ 2] = "%al,"    ' al
	reg86c$[ 3] = "%dl,"    ' dl
	reg86c$[ 4] = "%bl,"    ' bl
	reg86c$[ 5] = "%cl,"    ' cl
	reg86c$[ 6] = "%ax,"    ' ax
	reg86c$[ 7] = "%dx,"    ' dx
	reg86c$[ 8] = "%bx,"    ' bx
	reg86c$[ 9] = "%cx,"    ' cx
	reg86c$[10] = "%eax,"   ' eax
	reg86c$[11] = "%edx,"   ' edx,    danger: register overload
	reg86c$[12] = "%ebx,"   ' ebx,
	reg86c$[13] = "%ecx,"   ' ecx,    danger: register overload
	reg86c$[14] = "%rax,"   ' rax
	reg86c$[15] = "%rdx,"   ' rdx
	reg86c$[16] = "%rbx,"   ' rbx
	reg86c$[17] = "%rcx,"   ' rcx
	reg86c$[18] = "%r8,"    ' rcx
	reg86c$[19] = "%r9,"    ' rcx
	reg86c$[26] = "%rsi,"   ' rsi
	reg86c$[27] = "%rdi,"   ' rdi
	reg86c$[28] = "%ecx,"   ' ecx,    danger: register overload
	reg86c$[29] = "%edx,"   ' edx,    danger: register overload
	reg86c$[31] = "%rbp,"   ' rbp
'
'
' *****************************************************
' *****  DEFINE REGISTER ORIENTED ARRAY CONTENTS  *****
' *****************************************************
'
	r = 0
	DO WHILE (r < 32)
		r_addr[r]  = r                        ' r.addr[r]  = r
		INC r
	LOOP
	r_addr$[ 1] = "%rsp"    ' rsp
	r_addr$[ 2] = "%al"     ' al
	r_addr$[ 3] = "%dl"     ' dl
	r_addr$[ 4] = "%bl"     ' bl
	r_addr$[ 5] = "%cl"     ' cl
	r_addr$[ 6] = "%ax"     ' ax
	r_addr$[ 7] = "%dx"     ' dx
	r_addr$[ 8] = "%bx"     ' bx
	r_addr$[ 9] = "%cx"     ' cx
	r_addr$[10] = "%eax"    ' eax
	r_addr$[11] = "%edx"    ' edx
	r_addr$[12] = "%ebx"    ' ebx
	r_addr$[13] = "%ecx"    ' ecx
	r_addr$[26] = "%rsi"    ' rsi
	r_addr$[27] = "%rdi"    ' rdi
	r_addr$[28] = "%edx"    ' edx
	r_addr$[29] = "%ecx"    ' ecx
'
'
'  **************************************************************************
'  *****  DONE INITIALIZING ARRAYS THAT NEED INITIALIZATION EVERY TIME  *****
'  **************************************************************************
'
	IF reEntry THEN RETURN
	reEntry     = $$TRUE
'
' **************************************************************************
' *****  THE FOLLOWING ARRAYS NEED ONLY BE DIMENSIONED / DEFINED ONCE  *****
' **************************************************************************
'
	DIM shiftMulti[1040]
	DIM assemblerBackslashAsm$[255]
	DIM charsetSymbolFirst[255]
	DIM charsetSymbolInner[255]
	DIM charsetSymbolFinal[255]
	DIM charsetSymbol[255]
	DIM charsetPath[255]
	DIM charsetUpper[255]
	DIM charsetLower[255]
	DIM charsetNumeric[255]
	DIM charsetUpperLower[255]
	DIM charsetUpperNumeric[255]
	DIM charsetLowerNumeric[255]
	DIM charsetUpperLowerNumeric[255]
	DIM charsetUpperToLower[255]
	DIM charsetLowerToUpper[255]
	DIM charsetVex[255]
	DIM charsetHexUpper[255]
	DIM charsetHexLower[255]
	DIM charsetHexUpperLower[255]
	DIM charsetHexUpperToLower[255]
	DIM charsetHexLowerToUpper[255]
	DIM charsetBackslash[255]
	DIM charsetBackslashByte[255]
	DIM charsetBackslashChar[255]
	DIM charsetNormalChar[255]
	DIM charsetPrintChar[255]
	DIM charsetSpaceTab[255]
	DIM charsetSuffix[255]
	DIM alphaFirst[31]
	DIM alphaLast[31]
	DIM tab_sys$[255]
	DIM tab_sys[255]
	DIM minval#[63]
	DIM maxval#[63]
	DIM cop[11, 15, 15]
	DIM q_type_int[63]
	DIM q_type_long[63]
	DIM q_type_long_or_addr[63]
	DIM typeConvert[31, 31]
	DIM typeHigher[31, 31]
'
'
' **************************************
' *****  assemblerBackslashAsm$[]  *****
' **************************************
'
	FOR i = 0 TO 255
		o$  = "\\" + CHR$(0x30 + i{3,6}) + CHR$(0x30 + i{3,3}) + CHR$(0x30 + i{3,0})
		assemblerBackslashAsm$[i] = o$
	NEXT i
'
'
' *************************************
' *****  DEFINE "charset" ARRAYS  *****
' *************************************
'
'
' **********************************
' *****  charsetSymbolFirst[]  *****  A-Z  a-z  (others 0)
' **********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetSymbolFirst[i] = i
			CASE ((i >= 'a') AND (i <= 'z')):   charsetSymbolFirst[i] = i
			CASE  (i  = '_'):                   charsetSymbolFirst[i] = i
			CASE ELSE:                          charsetSymbolFirst[i] = 0
		END SELECT
	NEXT i
'
'
' **********************************
' *****  charsetSymbolInner[]  *****  A-Z  a-z  0-9  "_"  (others 0)
' **********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetSymbolInner[i] = i
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetSymbolInner[i] = i
			CASE ((i >= 'a') AND (i <= 'z')):   charsetSymbolInner[i] = i
			CASE  (i  = '_'):                   charsetSymbolInner[i] = i
			CASE ELSE:                          charsetSymbolInner[i] = 0
		END SELECT
	NEXT i
'
'
' **********************************
' *****  charsetSymbolFinal[]  *****  A-Z  a-z  0-9  "_"  (others 0)
' **********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetSymbolFinal[i] = i
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetSymbolFinal[i] = i
			CASE ((i >= 'a') AND (i <= 'z')):   charsetSymbolFinal[i] = i
			CASE  (i  = '_'):                   charsetSymbolFinal[i] = i
			CASE ELSE:                          charsetSymbolFinal[i] = 0
		END SELECT
	NEXT i
'
'
' *****************************
' *****  charsetSymbol[]  *****  A-Z  a-z  0-9  "_"  (others 0)
' *****************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetSymbol[i] = i
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetSymbol[i] = i
			CASE ((i >= 'a') AND (i <= 'z')):   charsetSymbol[i] = i
			CASE  (i  = '_'):                   charsetSymbol[i] = i
			CASE ELSE:                          charsetSymbol[i] = 0
		END SELECT
	NEXT i
'
'
' ***************************
' *****  charsetPath[]  *****  most characters except whitespace and ;:
' ***************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')) : charsetPath[i] = i
			CASE ((i >= 'A') AND (i <= 'Z')) : charsetPath[i] = i
			CASE ((i >= 'a') AND (i <= 'z')) : charsetPath[i] = i
			CASE  (i  = '.')                 : charsetPath[i] = i
			CASE  (i  = '-')                 : charsetPath[i] = i
			CASE  (i  = '_')                 : charsetPath[i] = i
			CASE  (i  = '@')                 : charsetPath[i] = i
			CASE  (i  = '#')                 : charsetPath[i] = i
			CASE  (i  = '$')                 : charsetPath[i] = i
			CASE  (i  = '%')                 : charsetPath[i] = i
			CASE  (i  = '^')                 : charsetPath[i] = i
			CASE  (i  = '&')                 : charsetPath[i] = i
			CASE  (i  = '*')                 : charsetPath[i] = i
			CASE  (i  = '/')                 : charsetPath[i] = i
			CASE  (i  = '(')                 : charsetPath[i] = i
			CASE  (i  = ')')                 : charsetPath[i] = i
			CASE  (i  = '[')                 : charsetPath[i] = i
			CASE  (i  = ']')                 : charsetPath[i] = i
			CASE  (i  = '{')                 : charsetPath[i] = i
			CASE  (i  = '}')                 : charsetPath[i] = i
			CASE  (i  = '\\')                : charsetPath[i] = i
			CASE ELSE:                          charsetPath[i] = 0
		END SELECT
	NEXT i
'
'
' ****************************
' *****  charsetUpper[]  *****  A-Z  (others 0)
' ****************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetUpper[i] = i
			CASE ELSE:                          charsetUpper[i] = 0
		END SELECT
	NEXT i
'
'
' ****************************
' *****  charsetLower[]  *****  a-z  (others 0)
' ****************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'a') AND (i <= 'z')):   charsetLower[i] = i
			CASE ELSE:                          charsetLower[i] = 0
		END SELECT
	NEXT i
'
'
' ******************************
' *****  charsetNumeric[]  *****  0-9  (others 0)
' ******************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetNumeric[i] = i
			CASE ELSE:                          charsetNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' *********************************
' *****  charsetUpperLower[]  *****  A-Z  a-z  (others 0)
' *********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetUpperLower[i] = i
			CASE ((i >= 'a') AND (i <= 'z')):   charsetUpperLower[i] = i
			CASE ELSE:                          charsetUpperLower[i] = 0
		END SELECT
	NEXT i
'
'
' ***********************************
' *****  charsetUpperNumeric[]  *****  A-Z  0-9  (others 0)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetUpperNumeric[i] = i
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetUpperNumeric[i] = i
			CASE ELSE:                          charsetUpperNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' ***********************************
' *****  charsetLowerNumeric[]  *****  a-z  0-9  (others 0)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetLowerNumeric[i] = i
			CASE ((i >= 'a') AND (i <= 'z')):   charsetLowerNumeric[i] = i
			CASE ELSE:                          charsetLowerNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' ****************************************
' *****  charsetUpperLowerNumeric[]  *****  A-Z  a-z  0-9  (others 0)
' ****************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetUpperLowerNumeric[i] = i
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetUpperLowerNumeric[i] = i
			CASE ((i >= 'a') AND (i <= 'z')):   charsetUpperLowerNumeric[i] = i
			CASE ELSE:                          charsetUpperLowerNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' ***********************************
' *****  charsetUpperToLower[]  *****  A-Z  ==>>  a-z  (others unchanged)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetUpperToLower[i] = i + 32
			CASE ELSE:                          charsetUpperToLower[i] = i
		END SELECT
	NEXT i
'
'
' ***********************************
' *****  charsetLowerToUpper[]  *****  a-z  ==>>  A-Z  (others unchanged)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'a') AND (i <= 'z')):   charsetLowerToUpper[i] = i - 32
			CASE ELSE:                          charsetLowerToUpper[i] = i
		END SELECT
	NEXT i
'
'
' **************************
' *****  charsetVex[]  *****  0-9  A-V  (others 0)
' **************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetVex[i] = i
			CASE ((i >= 'A') AND (i <= 'V')):   charsetVex[i] = i
			CASE ELSE:                          charsetVex[i] = 0
		END SELECT
	NEXT i
'
'
' *******************************
' *****  charsetHexUpper[]  *****  0-9  A-F  (others 0)
' *******************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetHexUpper[i] = i
			CASE ((i >= 'A') AND (i <= 'F')):   charsetHexUpper[i] = i
			CASE ELSE:                          charsetHexUpper[i] = 0
		END SELECT
	NEXT i
'
'
' *******************************
' *****  charsetHexLower[]  *****  0-9  a-f  (others 0)
' *******************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetHexLower[i] = i
			CASE ((i >= 'a') AND (i <= 'f')):   charsetHexLower[i] = i
			CASE ELSE:                          charsetHexLower[i] = 0
		END SELECT
	NEXT i
'
'
' ************************************
' *****  charsetHexUpperLower[]  *****  0-9  A-F  a-f  (others 0)
' ************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetHexUpperLower[i] = i
			CASE ((i >= 'A') AND (i <= 'F')):   charsetHexUpperLower[i] = i
			CASE ((i >= 'a') AND (i <= 'f')):   charsetHexUpperLower[i] = i
			CASE ELSE:                          charsetHexUpperLower[i] = 0
		END SELECT
	NEXT i
'
'
' **************************************  0-9
' *****  charsetHexUpperToLower[]  *****  A-F  ==>>  a-f  (others 0)
' **************************************  a-f
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetHexUpperToLower[i] = i
			CASE ((i >= 'A') AND (i <= 'F')):   charsetHexUpperToLower[i] = i + 32
			CASE ((i >= 'a') AND (i <= 'f')):   charsetHexUpperToLower[i] = i
			CASE ELSE:                          charsetHexUpperToLower[i] = 0
		END SELECT
	NEXT i
'
'
' **************************************  0-9
' *****  charsetHexLowerToUpper[]  *****  a-f  ==>>  A-F  (others 0)
' **************************************  A-F
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetHexLowerToUpper[i] = i
			CASE ((i >= 'A') AND (i <= 'F')):   charsetHexLowerToUpper[i] = i
			CASE ((i >= 'a') AND (i <= 'f')):   charsetHexLowerToUpper[i] = i - 32
			CASE ELSE:                          charsetHexLowerToUpper[i] = 0
		END SELECT
	NEXT i
'
'
' ********************************  \a  \b  \d  \f  \n  \r  \v  \\  \"  \z
' *****  charsetBackslash[]  *****  \0 - \V
' ********************************  (others unchanged)
'
' Convert character following a \ into the proper binary value
' For all characters without special binary values, return the character
'
	offset = 10 - 'A'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetBackslash[i] = i - '0'
			CASE ((i >= 'A') AND (i <= 'V')):   charsetBackslash[i] = i + offset
			CASE ELSE:                          charsetBackslash[i] = i
		END SELECT
	NEXT i
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE '\\':  charsetBackslash[i] = 0x5C    ' backslash
			CASE '"':   charsetBackslash[i] = 0x22    ' double-quote
			CASE 'a':   charsetBackslash[i] = 0x07    ' alarm (bell)
			CASE 'b':   charsetBackslash[i] = 0x08    ' backspace
			CASE 'd':   charsetBackslash[i] = 0x7F    ' delete
			CASE 'e':   charsetBackslash[i] = 0x1B    ' escape
			CASE 'f':   charsetBackslash[i] = 0x0C    ' form-feed
			CASE 'n':   charsetBackslash[i] = 0x0A    ' newline
			CASE 'r':   charsetBackslash[i] = 0x0D    ' return
			CASE 't':   charsetBackslash[i] = 0x09    ' tab
			CASE 'v':   charsetBackslash[i] = 0x0B    ' vertical-tab
			CASE 'z':   charsetBackslash[i] = 0xFF    ' finale  (highest UBYTE)
		END SELECT
	NEXT i
'
'
' ************************************  \a  \b  \d  \e  \f  \n  \r  \t  \v
' *****  charsetBackslashByte[]  *****  \\  \"
' ************************************
'
' Return printable character intended to follow \ backslash character for
' SIMPLE (only simple) 1 character backslash codes, as understood by dumb
' assemblers, for example.  Otherwise, return zero.
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE 0x5C:  charsetBackslashByte[i] = '\\'  ' backslash
			CASE 0x22:  charsetBackslashByte[i] = '"'   ' double-quote
			CASE 0x07:  charsetBackslashByte[i] = 'a'   ' alarm (bell)
			CASE 0x08:  charsetBackslashByte[i] = 'b'   ' backspace
			CASE 0x7F:  charsetBackslashByte[i] = 'd'   ' delete
			CASE 0x1B:  charsetBackslashByte[i] = 'e'   ' escape
			CASE 0x0C:  charsetBackslashByte[i] = 'f'   ' form-feed
			CASE 0x0A:  charsetBackslashByte[i] = 'n'   ' newline
			CASE 0x0D:  charsetBackslashByte[i] = 'r'   ' return
			CASE 0x09:  charsetBackslashByte[i] = 't'   ' tab
			CASE 0x0B:  charsetBackslashByte[i] = 'v'   ' vertical-tab
			CASE 0x00:  charsetBackslashByte[i] = '0'   ' null
			CASE ELSE:  charsetBackslashByte[i] = 0     ' non-simple backslash
		END SELECT
	NEXT i
'
'
' ************************************  \a  \b  \d  \e  \f  \n  \r  \t  \v
' *****  charsetBackslashChar[]  *****  \\  \"
' ************************************
'
' Return printable character intended to follow \ backslash character
' Return bytes that are normal, printable, non-backslash characters
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE 0x5C:  charsetBackslashChar[i] = '\\'  ' backslash
			CASE 0x22:  charsetBackslashChar[i] = '"'   ' double-quote
			CASE 0x07:  charsetBackslashChar[i] = 'a'   ' alarm (bell)
			CASE 0x08:  charsetBackslashChar[i] = 'b'   ' backspace
			CASE 0x7F:  charsetBackslashChar[i] = 'd'   ' delete
			CASE 0x1B:  charsetBackslashChar[i] = 'e'   ' escape
			CASE 0x0C:  charsetBackslashChar[i] = 'f'   ' form-feed
			CASE 0x0A:  charsetBackslashChar[i] = 'n'   ' newline
			CASE 0x0D:  charsetBackslashChar[i] = 'r'   ' return
			CASE 0x09:  charsetBackslashChar[i] = 't'   ' tab
			CASE 0x0B:  charsetBackslashChar[i] = 'v'   ' vertical-tab
			CASE ELSE:  charsetBackslashChar[i] = 0     ' not a backslash char
		END SELECT
	NEXT i
'
'
' *********************************  0x00 - 0x1F  ===>>  0
' *****  charsetNormalChar[]  *****  0x7F - 0xFF  ===>>  0  (others unchanged)
' *********************************   \  and  "   ===>>  0
'
' Normal printable characters = the character, all others = 0
' NOTE:  tab, newline, etc... not considered normal printable characters
' NOTE:  backslash not considered normal printable character (need \\)
' NOTE:  double-quote not considered normal printable character (need \")
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <=  31):  charsetNormalChar[i] = 0
			CASE (i >= 127):  charsetNormalChar[i] = 0
			CASE (i = '\\'):  charsetNormalChar[i] = 0
			CASE (i = '"'):   charsetNormalChar[i] = 0
			CASE ELSE:        charsetNormalChar[i] = i
		END SELECT
	NEXT i
'
'
' ********************************  0x00 - 0x1F  ===>>  0
' *****  charsetPrintChar[]  *****  0x7F - 0xFF  ===>>  0
' ********************************  (others unchanged)
'
' Printable characters = the character, all others = 0
' NOTE:  tab, newline, etc... not considered normal printable characters
' NOTE:  backslash is a printable character
' NOTE:  double-quote is a printable character
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <=  31):  charsetPrintChar[i] = 0
			CASE (i >= 127):  charsetPrintChar[i] = 0
			CASE ELSE:        charsetPrintChar[i] = i
		END SELECT
	NEXT i
'
'
' *******************************
' *****  charsetSpaceTab[]  *****  only <space> and <tab> are true
' *******************************
'
	charsetSpaceTab[0x09] = 0x09    ' <tab>   = '\t'
	charsetSpaceTab[0x20] = 0x20    ' <space> = ' '
'
'
' *****************************
' *****  charsetSuffix[]  *****  valid type suffixes
' *****************************
'
	charsetSuffix['@']  = '@'
	charsetSuffix['%']  = '%'
	charsetSuffix['&']  = '&'
	charsetSuffix['~']  = '~'
	charsetSuffix['!']  = '!'
	charsetSuffix['#']  = '#'
	charsetSuffix['$']  = '$'
'
'
' ********************************************************
' *****  Define the contents of several more arrays  *****
' ********************************************************
'
	minval#[$$SBYTE]    = $$MIN_SBYTE
	minval#[$$UBYTE]    = $$MIN_UBYTE
	minval#[$$SSHORT]   = $$MIN_SSHORT
	minval#[$$USHORT]   = $$MIN_USHORT
	minval#[$$SLONG]    = $$MIN_SLONG
	minval#[$$ULONG]    = $$MIN_ULONG
	minval#[$$XLONG]    = $$MIN_XLONG
	minval#[$$GOADDR]   = $$MIN_XLONG
	minval#[$$SUBADDR]  = $$MIN_XLONG
	minval#[$$FUNCADDR] = $$MIN_XLONG
	minval#[$$SINGLE]   = $$MIN_SINGLE
	minval#[$$DOUBLE]   = $$MIN_DOUBLE
	minval#[$$GIANT]    = $$MIN_GIANT
'
	maxval#[$$SBYTE]    = $$MAX_SBYTE
	maxval#[$$UBYTE]    = $$MAX_UBYTE
	maxval#[$$SSHORT]   = $$MAX_SSHORT
	maxval#[$$USHORT]   = $$MAX_USHORT
	maxval#[$$SLONG]    = $$MAX_SLONG
	maxval#[$$ULONG]    = $$MAX_ULONG
	maxval#[$$XLONG]    = $$MAX_XLONG
	maxval#[$$GOADDR]   = $$MAX_XLONG
	maxval#[$$SUBADDR]  = $$MAX_XLONG
	maxval#[$$FUNCADDR] = $$MAX_XLONG
	maxval#[$$SINGLE]   = $$MAX_SINGLE
	maxval#[$$DOUBLE]   = $$MAX_DOUBLE
	maxval#[$$GIANT]    = $$MAX_GIANT
'
'
' *****  q_type_int[]  *****  whole numbers
'
	q_type_int[ $$SBYTE ] = $$SBYTE
	q_type_int[ $$UBYTE ] = $$UBYTE
	q_type_int[ $$SSHORT] = $$SSHORT
	q_type_int[ $$USHORT] = $$USHORT
	q_type_int[ $$SLONG ] = $$SLONG
	q_type_int[ $$ULONG ] = $$ULONG
	q_type_int[ $$XLONG ] = $$XLONG
	q_type_int[ $$GIANT ] = $$GIANT
'
' *****  q_type_long[]  *****
'
	q_type_long[ $$SLONG ] = $$SLONG
	q_type_long[ $$ULONG ] = $$ULONG
	q_type_long[ $$XLONG ] = $$XLONG
	q_type_long[ $$GIANT ] = $$GIANT
'
	q_type_long_or_addr[ $$KIND_LITERALS] = $$XLONG
	q_type_long_or_addr[ $$SLONG        ] = $$SLONG
	q_type_long_or_addr[ $$ULONG        ] = $$ULONG
	q_type_long_or_addr[ $$XLONG        ] = $$XLONG
	q_type_long_or_addr[ $$GOADDR       ] = $$GOADDR
	q_type_long_or_addr[ $$SUBADDR      ] = $$SUBADDR
	q_type_long_or_addr[ $$FUNCADDR     ] = $$FUNCADDR
	q_type_long_or_addr[ $$GIANT        ] = $$GIANT
'
'
' **************************
' *****  shiftMulti[]  *****  UBYTE array
' **************************
'
	shiftMulti[   2]    =  1
	shiftMulti[   4]    =  2
	shiftMulti[   8]    =  3
	shiftMulti[  16]    =  4
	shiftMulti[  32]    =  5
	shiftMulti[  64]    =  6
	shiftMulti[ 128]    =  7
	shiftMulti[ 256]    =  8
	shiftMulti[ 512]    =  9
	shiftMulti[1024]    = 10
'
'
' ***************************
' *****  typeConvert[]  *****  SSHORT array
' ***************************
'
' typeConvert[i,j] is used to find out whether a source operand of type "j"
' can be converted to type "i".  The contents of typeConvert[i,j] is the
' working result type of the conversion will be, which is type "i" unless
' type "i" is less than SLONG, in which case the working result type is SLONG.
' If conversion from type "j" to type "i" is invalid, then the contents of
' typeConvert[i,j] = 1.  If conversion is unnecessary, typeConvert[i,j] = 0.
' Otherwise typeConvert[i,j] = working result type
'
' NOTE:  Entries for error cases are not needed in the CASE statements since
'        unspecified entries becomes an error by "typeConvert[i,j] = terror".
'
	terror  = -1                      ' terror  = error flag = -1
	FOR i = 0 TO 31                   ' i       = type "i" = destination type
		FOR j = 0 TO 31                 ' j       = type "j" = source type
			IF (i <= $$SLONG) THEN r = ($$SLONG << 8) ELSE r = (i << 8)
			none  = r                     ' conversion not necessary
			same  = r                     ' conversion not necessary
			conv  = r + i                 ' conversion OK  (defined)
			typeConvert[i,j] = terror     ' default = error
			SELECT CASE i
				CASE $$SBYTE
					SELECT CASE j
						CASE $$SBYTE:   typeConvert[i,j] = same     ' same
						CASE $$UBYTE:   typeConvert[i,j] = conv     ' j to i
						CASE $$SSHORT:  typeConvert[i,j] = conv     ' j to i
						CASE $$USHORT:  typeConvert[i,j] = conv     ' j to i
						CASE $$SLONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:   typeConvert[i,j] = none     ' r = i
						CASE $$GIANT:   typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:  typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:  typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$UBYTE
					SELECT CASE j
						CASE $$SBYTE:   typeConvert[i,j] = conv     ' j to i
						CASE $$UBYTE:   typeConvert[i,j] = same     ' same
						CASE $$SSHORT:  typeConvert[i,j] = conv     ' j to i
						CASE $$USHORT:  typeConvert[i,j] = conv     ' j to i
						CASE $$SLONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:   typeConvert[i,j] = none     ' r = i
						CASE $$GIANT:   typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:  typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:  typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$SSHORT
					SELECT CASE j
						CASE $$SBYTE:   typeConvert[i,j] = none     ' r = i
						CASE $$UBYTE:   typeConvert[i,j] = none     ' r = i
						CASE $$SSHORT:  typeConvert[i,j] = same     ' same
						CASE $$USHORT:  typeConvert[i,j] = conv     ' j to i
						CASE $$SLONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:   typeConvert[i,j] = none     ' r = i
						CASE $$GIANT:   typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:  typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:  typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$USHORT
					SELECT CASE j
						CASE $$SBYTE:   typeConvert[i,j] = conv     ' j to i
						CASE $$UBYTE:   typeConvert[i,j] = none     ' r = i
						CASE $$SSHORT:  typeConvert[i,j] = conv     ' j to i
						CASE $$USHORT:  typeConvert[i,j] = same     ' same
						CASE $$SLONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:   typeConvert[i,j] = none     ' r = i
						CASE $$GIANT:   typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:  typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:  typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$SLONG
					SELECT CASE j
						CASE $$SBYTE:   typeConvert[i,j] = none     ' r = i
						CASE $$UBYTE:   typeConvert[i,j] = none     ' r = i
						CASE $$SSHORT:  typeConvert[i,j] = none     ' r = i
						CASE $$USHORT:  typeConvert[i,j] = none     ' r = i
						CASE $$SLONG:   typeConvert[i,j] = same     ' same
						CASE $$ULONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:   typeConvert[i,j] = none     ' r = i
						CASE $$GIANT:   typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:  typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:  typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$ULONG
					SELECT CASE j
						CASE $$SBYTE:   typeConvert[i,j] = conv     ' j to i
						CASE $$UBYTE:   typeConvert[i,j] = none     ' r = i
						CASE $$SSHORT:  typeConvert[i,j] = conv     ' j to i
						CASE $$USHORT:  typeConvert[i,j] = none     ' r = i
						CASE $$SLONG:   typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:   typeConvert[i,j] = same     ' same
						CASE $$XLONG:   typeConvert[i,j] = none     ' r = i
						CASE $$GIANT:   typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:  typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:  typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$XLONG
					SELECT CASE j
						CASE $$SBYTE:     typeConvert[i,j] = none     ' r = i
						CASE $$UBYTE:     typeConvert[i,j] = none     ' r = i
						CASE $$SSHORT:    typeConvert[i,j] = none     ' r = i
						CASE $$USHORT:    typeConvert[i,j] = none     ' r = i
						CASE $$SLONG:     typeConvert[i,j] = none     ' r = i
						CASE $$ULONG:     typeConvert[i,j] = none     ' r = i
						CASE $$XLONG:     typeConvert[i,j] = same     ' same
						CASE $$GOADDR:    typeConvert[i,j] = none     ' r = i
						CASE $$SUBADDR:   typeConvert[i,j] = none     ' r = i
						CASE $$FUNCADDR:  typeConvert[i,j] = none     ' r = i
						CASE $$GIANT:     typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:    typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:    typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$GOADDR
					SELECT CASE j
						CASE $$XLONG:     typeConvert[i,j] = none     ' r = i
						CASE $$GOADDR:    typeConvert[i,j] = same     ' same
					END SELECT
				CASE $$SUBADDR
					SELECT CASE j
						CASE $$XLONG:     typeConvert[i,j] = none     ' r = i
						CASE $$SUBADDR:   typeConvert[i,j] = same     ' same
					END SELECT
				CASE $$FUNCADDR
					SELECT CASE j
						CASE $$XLONG:     typeConvert[i,j] = none     ' r = i
						CASE $$FUNCADDR:  typeConvert[i,j] = same     ' same
					END SELECT
				CASE $$GIANT
					SELECT CASE j
						CASE $$SBYTE:     typeConvert[i,j] = conv     ' j to i
						CASE $$UBYTE:     typeConvert[i,j] = conv     ' j to i
						CASE $$SSHORT:    typeConvert[i,j] = conv     ' j to i
						CASE $$USHORT:    typeConvert[i,j] = conv     ' j to i
						CASE $$SLONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$GIANT:     typeConvert[i,j] = same     ' same
						CASE $$SINGLE:    typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:    typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$SINGLE
					SELECT CASE j
						CASE $$SBYTE:     typeConvert[i,j] = conv     ' j to i
						CASE $$UBYTE:     typeConvert[i,j] = conv     ' j to i
						CASE $$SSHORT:    typeConvert[i,j] = conv     ' j to i
						CASE $$USHORT:    typeConvert[i,j] = conv     ' j to i
						CASE $$SLONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$GIANT:     typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:    typeConvert[i,j] = same     ' same
						CASE $$DOUBLE:    typeConvert[i,j] = conv     ' j to i
					END SELECT
				CASE $$DOUBLE
					SELECT CASE j
						CASE $$SBYTE:     typeConvert[i,j] = conv     ' j to i
						CASE $$UBYTE:     typeConvert[i,j] = conv     ' j to i
						CASE $$SSHORT:    typeConvert[i,j] = conv     ' j to i
						CASE $$USHORT:    typeConvert[i,j] = conv     ' j to i
						CASE $$SLONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$ULONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$XLONG:     typeConvert[i,j] = conv     ' j to i
						CASE $$GIANT:     typeConvert[i,j] = conv     ' j to i
						CASE $$SINGLE:    typeConvert[i,j] = conv     ' j to i
						CASE $$DOUBLE:    typeConvert[i,j] = same     ' same
					END SELECT
				CASE $$STRING
					SELECT CASE j
						CASE $$STRING:    typeConvert[i,j] = same     ' same
					END SELECT
		END SELECT
		NEXT j
	NEXT i
'
'
' **************************
' *****  typeHigher[]  *****
' **************************
'
' typeHigher[i,j] is used to find out which of two types must be converted
' to the type of the other to get to the "higher" type.  "i" and "j" are the
' data types of operand #1 and operand #2.  The contents of typeHigher[i,j]
' tells what type each operand must be converted to, the higher of the two
' types, plus the "working" result type (SLONG for SBYTE through SLONG).
'
' Each byte of the XLONG contents of typeHigher[i,j] contains information:
'
' LSB  Byte 0:  Data type to convert "j" to
'      Byte 1:  Data type to convert "i" to
'      Byte 2:  Higher type
' MSB  Byte 3:  Result type  (SLONG for Higher type = SBYTE to SLONG)
'
' typeHigher[i,j] = terror if type conversion is invalid.
' typeHigher[i,j] = inone  if "i" is higher type but conversion is unnecessary.
' typeHigher[i,j] = jnone  if "j" is higher type but conversion is unnecessary.
' typeHigher[i,j] = tsame  if "i" and "j" are the same type (no conversion).
'
' NOTE:  Entries for error cases are not needed in the CASE statements since
'        unspecified entries becomes an error by "typeHigher[i,j] = terror".
'
	terror  = -1                      ' error
	FOR i = 0 TO 31                   ' i     = 1st data type
		FOR j = 0 TO 31                 ' j     = 2nd data type
			IF ((i <= $$SLONG) AND (j <= $$SLONG)) THEN
				r = $$SLONG << 24
			ELSE
				IF (i > j) THEN r = i << 24 ELSE r = j << 24
			END IF
			ihi   = r + i << 16 + i       ' ihi   = i is "higher", convert j to i
			jhi   = r + j << 16 + j << 8  ' jhi   = j is "higher", convert i to j
			inone = r + i << 16           ' inone = i is "higher", no convert needed
			jnone = r + j << 16           ' jnone = j is "higher", no convert needed
			tsame = r + i << 16           ' tsame = i,j are same,  no convert needed
			typeHigher[i,j] = terror      ' default = error
			SELECT CASE i
				CASE $$SBYTE
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = tsame   ' same
						CASE $$UBYTE:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SSHORT:    typeHigher[i,j] = jnone   ' jhi, no
						CASE $$USHORT:    typeHigher[i,j] = jhi     ' i to j
						CASE $$SLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$ULONG:     typeHigher[i,j] = jhi     ' i to j
						CASE $$XLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$GIANT:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$UBYTE
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$UBYTE:     typeHigher[i,j] = tsame   ' same
						CASE $$SSHORT:    typeHigher[i,j] = jnone   ' jhi, no
						CASE $$USHORT:    typeHigher[i,j] = jnone   ' jhi, no
						CASE $$SLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$ULONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$XLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$GIANT:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$SSHORT
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$UBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$SSHORT:    typeHigher[i,j] = tsame   ' same
						CASE $$USHORT:    typeHigher[i,j] = jhi     ' i to j
						CASE $$SLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$ULONG:     typeHigher[i,j] = jhi     ' i to j
						CASE $$XLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$GIANT:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$USHORT
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$UBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$SSHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$USHORT:    typeHigher[i,j] = tsame   ' same
						CASE $$SLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$ULONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$XLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$GIANT:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$SLONG
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$UBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$SSHORT:    typeHigher[i,j] = inone   ' ihi, no
						CASE $$USHORT:    typeHigher[i,j] = inone   ' ihi, no
						CASE $$SLONG:     typeHigher[i,j] = tsame   ' same
						CASE $$ULONG:     typeHigher[i,j] = jhi     ' i to j
						CASE $$XLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$GIANT:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$ULONG
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$UBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$SSHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$USHORT:    typeHigher[i,j] = inone   ' ihi, no
						CASE $$SLONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$ULONG:     typeHigher[i,j] = tsame   ' same
						CASE $$XLONG:     typeHigher[i,j] = jnone   ' jhi, no
						CASE $$GIANT:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$XLONG
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$UBYTE:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$SSHORT:    typeHigher[i,j] = inone   ' ihi, no
						CASE $$USHORT:    typeHigher[i,j] = inone   ' ihi, no
						CASE $$SLONG:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$ULONG:     typeHigher[i,j] = inone   ' ihi, no
						CASE $$XLONG:     typeHigher[i,j] = tsame   ' same
						CASE $$GOADDR:    typeHigher[i,j] = jnone   ' jhi, no
						CASE $$SUBADDR:   typeHigher[i,j] = jnone   ' jhi, no
						CASE $$FUNCADDR:  typeHigher[i,j] = jnone   ' jhi, no
						CASE $$GIANT:     typeHigher[i,j] = jhi     ' i to j
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$GOADDR
					SELECT CASE j
						CASE $$XLONG:     typeHigher[i,j] = inone   ' jhi, no
						CASE $$GOADDR:    typeHigher[i,j] = tsame   ' same
					END SELECT
				CASE $$SUBADDR
					SELECT CASE j
						CASE $$XLONG:     typeHigher[i,j] = inone   ' jhi, no
						CASE $$SUBADDR:   typeHigher[i,j] = tsame   ' same
					END SELECT
				CASE $$FUNCADDR
					SELECT CASE j
						CASE $$XLONG:     typeHigher[i,j] = inone   ' jhi, no
						CASE $$FUNCADDR:  typeHigher[i,j] = tsame   ' same
					END SELECT
				CASE $$GIANT
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$UBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$SSHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$USHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$SLONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$ULONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$XLONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$GIANT:     typeHigher[i,j] = tsame   ' same
						CASE $$SINGLE:    typeHigher[i,j] = jhi     ' i to j
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$SINGLE
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$UBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$SSHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$USHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$SLONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$ULONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$XLONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$GIANT:     typeHigher[i,j] = ihi     ' j to i
						CASE $$SINGLE:    typeHigher[i,j] = tsame   ' same
						CASE $$DOUBLE:    typeHigher[i,j] = jhi     ' i to j
					END SELECT
				CASE $$DOUBLE
					SELECT CASE j
						CASE $$SBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$UBYTE:     typeHigher[i,j] = ihi     ' j to i
						CASE $$SSHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$USHORT:    typeHigher[i,j] = ihi     ' j to i
						CASE $$SLONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$ULONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$XLONG:     typeHigher[i,j] = ihi     ' j to i
						CASE $$GIANT:     typeHigher[i,j] = ihi     ' j to i
						CASE $$SINGLE:    typeHigher[i,j] = ihi     ' j to i
						CASE $$DOUBLE:    typeHigher[i,j] = tsame   ' same
					END SELECT
				CASE $$STRING
					SELECT CASE j
						CASE $$STRING:    typeHigher[i,j] = tsame   ' same
					END SELECT
		END SELECT
		NEXT j
	NEXT i
'
'
' *************************************************
' *****  Load cop[] from diskfile "copx.xxx"  *****
' *************************************************
'
	##ERROR = $$FALSE
	GetSubPath ("xxx", "", @path$[])
	XstFindFile ("copx.bin", @path$[], @f$, @attr)
	copfile = OPEN (f$, $$RD)
	IF (copfile <= 0) THEN
		f$ = "./xxx/copx.bin"
		copfile = OPEN (f$, $$RD)
		IF (copfile <= 0) THEN
			f$ = "$HOME/xb/xxx/copx.bin"
			copfile = OPEN (f$, $$RD)
			IF (copfile <= 0) THEN
				f$ = "/usr/xb/xxx/copx.bin"
				copfile = OPEN (f$, $$RD)
				IF (copfile <= 0) THEN
					f$ = "/xb/xxx/copx.bin"
					copfile = OPEN (f$, $$RD)
					IF (copfile <= 0) THEN
						PRINT "*****  FATAL ERROR  *****  file <copx.bin> not found  *****"
						RETURN
					END IF
				END IF
			END IF
		END IF
	END IF
'
	FOR x = 0 TO 11                     ' operator table # (operator class)
		FOR y = 0 TO 15                   ' operand 1 (left)
'     PRINT HEX$(x);; HEX$(y);;
			FOR z = 0 TO 15                 ' operand 2 (right)
				READ [copfile], temp&         ' get operator control word
				cop[x, y, z] = temp&          ' put it in cop[]
'       PRINT HEX$(temp&,8);;
			NEXT z
'     PRINT
		NEXT y
'   PRINT
	NEXT x
	CLOSE (copfile)
'
'
' *****  cop[] array modifications  *****
'
	cop[$$COP9 >> 4, 0, $$GOADDR]  = 0x00000808
	cop[$$COP9 >> 4, 0, $$SUBADDR] = 0x00000808
'
END FUNCTION
'
'
' ############################
' #####  InitComplex ()  #####
' ############################
'
FUNCTION  InitComplex ()
	TOKEN   tokenI, tokenR
	TOKEN   tempEleToken[]
	SHARED  typeEleSymbol$[]
	SHARED  TOKEN typeEleToken[]
	SHARED  typeEleAddr[]
	SHARED  typeEleSize[]
	SHARED  typeEleType[]
	SHARED  typeEleVal[]
	SHARED  typeElePtr[]
	SHARED  typeEleStringSize[]
	SHARED  typeEleUBound[]
	SHARED  typeEleCount[]
'
' Create arrays to hold information on SCOMPLEX data type
'
	DIM  tempEleSymbol$[3]
	DIM  tempEleToken[3]
	DIM  tempEleAddr[3]
	DIM  tempEleSize[3]
	DIM  tempEleType[3]
	DIM  tempEleVal[3]
	DIM  tempElePtr[3]
	DIM  tempEleStringSize[3]
	DIM  tempEleUBound[3]
'
' Attach arrays to type arrays at SCOMPLEX data type
'
	ATTACH tempEleSymbol$[] TO typeEleSymbol$[$$SCOMPLEX, ]
	ATTACH tempEleToken[] TO typeEleToken[$$SCOMPLEX, ]
	ATTACH tempEleAddr[] TO typeEleAddr[$$SCOMPLEX, ]
	ATTACH tempEleSize[] TO typeEleSize[$$SCOMPLEX, ]
	ATTACH tempEleType[] TO typeEleType[$$SCOMPLEX, ]
	ATTACH tempEleVal[] TO typeEleVal[$$SCOMPLEX, ]
	ATTACH tempElePtr[] TO typeElePtr[$$SCOMPLEX, ]
	ATTACH tempEleStringSize[] TO typeEleStringSize[$$SCOMPLEX, ]
	ATTACH tempEleUBound[] TO typeEleUBound[$$SCOMPLEX, ]
'
' Create arrays to hold information on DCOMPLEX data type
'
	DIM  tempEleSymbol$[3]
	DIM  tempEleToken[3]
	DIM  tempEleAddr[3]
	DIM tempEleSize[3]
	DIM  tempEleType[3]
	DIM  tempEleVal[3]
	DIM  tempElePtr[3]
	DIM  tempEleStringSize[3]
	DIM  tempEleUBound[3]
'
' Attach arrays to type arrays at DCOMPLEX data type
'
	ATTACH tempEleSymbol$[] TO typeEleSymbol$[$$DCOMPLEX, ]
	ATTACH tempEleToken[] TO typeEleToken[$$DCOMPLEX, ]
	ATTACH tempEleAddr[] TO typeEleAddr[$$DCOMPLEX, ]
	ATTACH tempEleSize[] TO typeEleSize[$$DCOMPLEX, ]
	ATTACH tempEleType[] TO typeEleType[$$DCOMPLEX, ]
	ATTACH tempEleVal[] TO typeEleVal[$$DCOMPLEX, ]
	ATTACH tempElePtr[] TO typeElePtr[$$DCOMPLEX, ]
	ATTACH tempEleStringSize[] TO typeEleStringSize[$$DCOMPLEX, ]
	ATTACH tempEleUBound[] TO typeEleUBound[$$DCOMPLEX, ]
'
' Fill in SCOMPLEX and DCOMPLEX data type arrays
'
	typeEleCount[$$SCOMPLEX]      = 2       ' 2 elements; real/imaginary
	typeEleCount[$$DCOMPLEX]      = 2       ' 2 elements; real/imaginary
'
	typeEleSymbol$[$$SCOMPLEX, 0] = ".R"    ' REAL
	typeEleSymbol$[$$SCOMPLEX, 1] = ".I"    ' IMAGINARY
	typeEleSymbol$[$$DCOMPLEX, 0] = ".R"    ' REAL
	typeEleSymbol$[$$DCOMPLEX, 1] = ".I"    ' IMAGINARY
'
' tokenR = AddSymbol (".R", $$T_SYMBOLS, 0)
' tokenI = AddSymbol (".I", $$T_SYMBOLS, 0)
'
' typeEleToken[$$SCOMPLEX, 0]   = tokenR
' typeEleToken[$$SCOMPLEX, 1]   = tokenI
' typeEleToken[$$DCOMPLEX, 0]   = tokenR
' typeEleToken[$$DCOMPLEX, 1]   = tokenI
'
	tokenR = AddSymbol (".R", 0, $$KIND_SYMBOLS, 0, 0, 0)
	tokenI = AddSymbol (".I", 0, $$KIND_SYMBOLS, 0, 0, 0)
'
	typeEleToken[$$SCOMPLEX, 0] = tokenR
	typeEleToken[$$SCOMPLEX, 1] = tokenI
	typeEleToken[$$DCOMPLEX, 0] = tokenR
	typeEleToken[$$DCOMPLEX, 1] = tokenI
'
	typeEleAddr[$$SCOMPLEX, 0]    =  0
	typeEleAddr[$$SCOMPLEX, 1]    =  4
	typeEleAddr[$$DCOMPLEX, 0]    =  0
	typeEleAddr[$$DCOMPLEX, 1]    =  8
'
	typeEleSize[$$SCOMPLEX, 0]    =  4
	typeEleSize[$$SCOMPLEX, 1]    =  4
	typeEleSize[$$DCOMPLEX, 0]    =  8
	typeEleSize[$$DCOMPLEX, 1]    =  8
'
	typeEleType[$$SCOMPLEX, 0]    =  $$SINGLE
	typeEleType[$$SCOMPLEX, 1]    =  $$SINGLE
	typeEleType[$$DCOMPLEX, 0]    =  $$DOUBLE
	typeEleType[$$DCOMPLEX, 1]    =  $$DOUBLE
'
	typeEleVal[$$SCOMPLEX, 0]   = 0
	typeEleVal[$$SCOMPLEX, 1]   = 0
	typeEleVal[$$DCOMPLEX, 0]   = 0
	typeEleVal[$$DCOMPLEX, 1]   = 0
'
	typeElePtr[$$SCOMPLEX, 0]   = 0
	typeElePtr[$$SCOMPLEX, 1]   = 0
	typeElePtr[$$DCOMPLEX, 0]   = 0
	typeElePtr[$$DCOMPLEX, 1]   = 0
'
	typeEleStringSize[$$SCOMPLEX, 0]    = 0
	typeEleStringSize[$$SCOMPLEX, 1]    = 0
	typeEleStringSize[$$DCOMPLEX, 0]    = 0
	typeEleStringSize[$$DCOMPLEX, 1]    = 0
'
	typeEleUBound[$$SCOMPLEX, 0]    = 0
	typeEleUBound[$$SCOMPLEX, 1]    = 0
	typeEleUBound[$$DCOMPLEX, 0]    = 0
	typeEleUBound[$$DCOMPLEX, 1]    = 0
END FUNCTION
'
'
' #######################
' #####  InitEntry  #####
' #######################
'
FUNCTION  InitEntry ()
	SHARED  ofile
	SHARED  xit
'
	xit = 0
	ofile     = $$STDOUT
	##GLOBAL  = ##GLOBAL0
	##GLOBALX = ##GLOBAL0
END FUNCTION
'
'
' ###########################
' #####  InitErrors ()  #####
' ###########################
'
FUNCTION  InitErrors ()
	SHARED ERROR_AFTER_ELSE
	SHARED ERROR_BAD_CASE_ALL
	SHARED ERROR_BAD_GOSUB
	SHARED ERROR_BAD_GOTO
	SHARED ERROR_BAD_SYMBOL
	SHARED ERROR_BITSPEC
	SHARED ERROR_BYREF
	SHARED ERROR_BYVAL
	SHARED ERROR_COMPILER
	SHARED ERROR_COMPONENT
	SHARED ERROR_CROSSED_FUNCTIONS
	SHARED ERROR_DECLARE
	SHARED ERROR_DECLARE_FUNCS_FIRST
	SHARED ERROR_DUP_DECLARATION
	SHARED ERROR_DUP_DEFINITION
	SHARED ERROR_DUP_LABEL
	SHARED ERROR_DUP_MISMATCH
	SHARED ERROR_DUP_TYPE
	SHARED ERROR_ELSE_IN_CASE_ALL
	SHARED ERROR_ENTRY_FUNCTION
	SHARED ERROR_EXPECT_ASSIGNMENT
	SHARED ERROR_EXPRESSION_STACK
	SHARED ERROR_FILE_NOT_FOUND
	SHARED ERROR_INTERNAL_EXTERNAL
	SHARED ERROR_KIND_MISMATCH
	SHARED ERROR_LITERAL
	SHARED ERROR_NEED_EXCESS_COMMA
	SHARED ERROR_NEED_SUBSCRIPT
	SHARED ERROR_NEST
	SHARED ERROR_NEST_DO
	SHARED ERROR_NEST_FOR
	SHARED ERROR_NEST_IF
	SHARED ERROR_NEST_SELECT
	SHARED ERROR_NEST_SUB
	SHARED ERROR_NODE_DATA_MISMATCH
	SHARED ERROR_OPEN_FILE
	SHARED ERROR_OUTSIDE_FUNCTIONS
	SHARED ERROR_OVERFLOW
	SHARED ERROR_PROGRAM_NOT_NAMED
	SHARED ERROR_REGADDR
	SHARED ERROR_RETYPED
	SHARED ERROR_SCOPE_MISMATCH
	SHARED ERROR_SHARENAME
	SHARED ERROR_SYNTAX
	SHARED ERROR_TOO_FEW_ARGS
	SHARED ERROR_TOO_LATE
	SHARED ERROR_TOO_MANY_ARGS
	SHARED ERROR_TYPE_MISMATCH
	SHARED ERROR_UNDECLARED
	SHARED ERROR_UNDEFINED
	SHARED ERROR_UNIMPLEMENTED
	SHARED ERROR_VOID
	SHARED ERROR_WITHIN_FUNCTION
	SHARED uerror
	SHARED xerror$[]
'
	e = 1
	ERROR_AFTER_ELSE          = e:  xerror$[e] = "After CASE ELSE":           INC e
	ERROR_BAD_CASE_ALL        = e:  xerror$[e] = "Bad CASE ALL":              INC e
	ERROR_BAD_GOSUB           = e:  xerror$[e] = "Bad GOSUB dest type":       INC e
	ERROR_BAD_GOTO            = e:  xerror$[e] = "Bad GOTO dest type":        INC e
	ERROR_BAD_SYMBOL          = e:  xerror$[e] = "Bad Symbol":                INC e
	ERROR_BITSPEC             = e:  xerror$[e] = "Bad Bitfield Spec":         INC e
	ERROR_BYREF               = e:  xerror$[e] = "Bad Pass By Reference":     INC e
	ERROR_BYVAL               = e:  xerror$[e] = "Bad Pass By Value":         INC e
	ERROR_COMPILER            = e:  xerror$[e] = "Compiler Error":            INC e
	ERROR_COMPONENT           = e:  xerror$[e] = "Component Error":           INC e
	ERROR_CROSSED_FUNCTIONS   = e:  xerror$[e] = "Crossed Functions (X/C)":   INC e
	ERROR_DECLARE             = e:  xerror$[e] = "DECLARE after SHARED":      INC e
	ERROR_DECLARE_FUNCS_FIRST = e:  xerror$[e] = "DECLARE too late":          INC e
	ERROR_DUP_DECLARATION     = e:  xerror$[e] = "Duplicate Declaration":     INC e
	ERROR_DUP_DEFINITION      = e:  xerror$[e] = "Duplicate Definition":      INC e
	ERROR_DUP_LABEL           = e:  xerror$[e] = "Duplicate Label":           INC e
	ERROR_DUP_MISMATCH        = e:  xerror$[e] = "Duplicate Mismatch":        INC e
	ERROR_DUP_TYPE            = e:  xerror$[e] = "Duplicate Type":            INC e
	ERROR_ELSE_IN_CASE_ALL    = e:  xerror$[e] = "CASE ELSE in CASE ALL":     INC e
	ERROR_ENTRY_FUNCTION      = e:  xerror$[e] = "Entry Function Error":      INC e
	ERROR_EXPECT_ASSIGNMENT   = e:  xerror$[e] = "Expect Assignment":         INC e
	ERROR_EXPRESSION_STACK    = e:  xerror$[e] = "Expression Error":          INC e
	ERROR_FILE_NOT_FOUND      = e:  xerror$[e] = "File Not Found":            INC e
	ERROR_INTERNAL_EXTERNAL   = e:  xerror$[e] = "Internal / External":       INC e
	ERROR_KIND_MISMATCH       = e:  xerror$[e] = "Kind Mismatch":             INC e
	ERROR_LITERAL             = e:  xerror$[e] = "Literal Error":             INC e
	ERROR_NEED_EXCESS_COMMA   = e:  xerror$[e] = "Need Excess Comma":         INC e
	ERROR_NEED_SUBSCRIPT      = e:  xerror$[e] = "Need Subscript":            INC e
	ERROR_NEST                = e:  xerror$[e] = "Nesting Error":             INC e
	ERROR_NEST_DO             = e:  xerror$[e] = "Nesting Error in 'DO'":     INC e
	ERROR_NEST_FOR            = e:  xerror$[e] = "Nesting Error in 'FOR'":    INC e
	ERROR_NEST_IF             = e:  xerror$[e] = "Nesting Error in 'IF'":     INC e
	ERROR_NEST_SELECT         = e:  xerror$[e] = "Nesting Error in 'SELECT'": INC e
	ERROR_NEST_SUB            = e:  xerror$[e] = "Nesting Error in 'SUB'":    INC e
	ERROR_NODE_DATA_MISMATCH  = e:  xerror$[e] = "Node / Data Mismatch":      INC e
	ERROR_OPEN_FILE           = e:  xerror$[e] = "Open Error":                INC e
	ERROR_OUTSIDE_FUNCTIONS   = e:  xerror$[e] = "Outside Functions Error":   INC e
	ERROR_OVERFLOW            = e:  xerror$[e] = "Overflow Error":            INC e
	ERROR_PROGRAM_NOT_NAMED   = e:  xerror$[e] = "Program Not Named":         INC e
	ERROR_REGADDR             = e:  xerror$[e] = "Register Address":          INC e
	ERROR_RETYPED             = e:  xerror$[e] = "Duplicate Type Spec":       INC e
	ERROR_SCOPE_MISMATCH      = e:  xerror$[e] = "Scope Mismatch":            INC e
	ERROR_SHARENAME           = e:  xerror$[e] = "Sharename Error":           INC e
	ERROR_SYNTAX              = e:  xerror$[e] = "Syntax Error":              INC e
	ERROR_TOO_FEW_ARGS        = e:  xerror$[e] = "Too Few Arguments":         INC e
	ERROR_TOO_LATE            = e:  xerror$[e] = "Too Late":                  INC e
	ERROR_TOO_MANY_ARGS       = e:  xerror$[e] = "Too Many Arguments":        INC e
	ERROR_TYPE_MISMATCH       = e:  xerror$[e] = "Type Mismatch":             INC e
	ERROR_UNDECLARED          = e:  xerror$[e] = "Undeclared":                INC e
	ERROR_UNDEFINED           = e:  xerror$[e] = "Undefined":                 INC e
	ERROR_UNIMPLEMENTED       = e:  xerror$[e] = "Unimplemented":             INC e
	ERROR_VOID                = e:  xerror$[e] = "Void Error":                INC e
	ERROR_WITHIN_FUNCTION     = e:  xerror$[e] = "Within Function":           INC e
	uerror                    = e - 1
END FUNCTION
'
'
' ############################
' #####  InitOptions ()  #####
' ############################
'
FUNCTION  InitOptions ()
	EXTERNAL /xxx/  i486asm,  i486bin
	i486asm       = $$TRUE
	i486bin       = $$FALSE
END FUNCTION
'
'
' ############################
' #####  InitProgram ()  #####
' ############################
'
FUNCTION  InitProgram ()
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  func_number
'
	maxFuncNumber = 0
	func_number = 0
END FUNCTION
'
'
' ##############################
' #####  InitVariables ()  #####
' ##############################
'
FUNCTION  InitVariables ()
	EXTERNAL /xxx/  entryFunction,  xpc,  errorCount
	SHARED  defaultType[]
	SHARED  XERROR
	SHARED  charPtr,  defaultType
	SHARED  end_program,  func_number
	SHARED  got_declare,  got_executable,  got_export,  got_function
	SHARED  got_import,  got_object_declaration,  got_program,  got_type
	SHARED  hfn$,  ifLine,  inlevel,  insub,  oos
	SHARED  labelNumber,  lineNumber
	SHARED  patchPtr,  labelPtr,  nestCount,  nestLevel
	SHARED  section,  subCount,  tokenPtr,  tab_sym_ptr
	SHARED  nullstring$
	SHARED  pass
	SHARED  prologCode
	SHARED  version$
	SHARED  TOKEN  backToken
	SHARED  TOKEN  lastToken
'
	#emitasm      = 0
	pass          = 0
	XERROR        = 0
	oos           = 0
	insub         = 0
	inlevel       = 0
	ifLine        = 0
	charPtr       = 0
	subCount      = 0
	tokenPtr      = 0
	nestCount     = 0
	nestLevel     = 0
	backToken     = #T_ZERO
	lastToken    = #T_ZERO
	xpc           = ##UCODE
	##GLOBAL      = ##GLOBAL0
	##GLOBALX     = ##GLOBAL0
'	PRINT "InitVariables(44)", HEX$(##GLOBAL), HEX$(##GLOBALX)
	errorCount    = 0
	patchPtr      = 0
	lineNumber    = 0
	func_number   = 0
	labelNumber   = 0
	hfn$          = "0"
	labelPtr      = 0
	tab_sym_ptr   = 0
	got_declare   = $$FALSE
	got_export    = $$FALSE
	got_function  = $$FALSE
	got_import    = $$FALSE
	got_program   = $$FALSE
	got_type      = $$FALSE
	end_program   = $$FALSE
	defaultType   = $$XLONG
	section       = $$TEXTSECTION
	nullstring$   = CHR$(34) + CHR$(34)
	prologCode    = 0
	version$      = ""
'
	entryFunction             = 1
	got_executable            = $$FALSE
	got_object_declaration    = $$FALSE
	IFZ defaultType[] THEN
		DIM defaultType[63]
	END IF
	defaultType[func_number]  = defaultType
'
END FUNCTION
'
' ######################################
' #####  InvalidExternalSymbol ()  #####
' ######################################
'
FUNCTION  InvalidExternalSymbol (x$)
	SHARED  XERROR,  ERROR_COMPILER
	SHARED UBYTE  charsetSymbolInner[]
'
	IFZ x$ THEN XcowlErr (600010): GOTO eeeCompiler
	testOffset  = LEN(x$) - 1
	testChar    = x${testOffset}
	IF charsetSymbolInner[testChar] THEN RETURN ($$FALSE)
	IF (testChar  = '$') THEN
		IFZ testOffset THEN XcowlErr (600015): GOTO eeeCompiler
		DEC testOffset
		testChar    = x${testOffset}
		IF charsetSymbolInner[testChar] THEN RETURN ($$FALSE)
	END IF
	RETURN ($$TRUE)
'
eeeCompiler:
	XERROR  = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ############################
' #####  LastElement ()  #####
' ############################
'
' Scans tokens ahead to determine if at last element in a composite
'
FUNCTION  LastElement (TOKEN token, lastPlace, excessComma)
	TOKEN   old_token
	SHARED  tokenPtr
	SHARED  XERROR, ERROR_SYNTAX
'
	excessComma = $$FALSE
	hold_place  = tokenPtr
	SELECT CASE token.tp.kind
		CASE $$KIND_ARRAYS, $$KIND_ARRAY_SYMBOLS
			NextToken (@token)                            ' skip [...]
			IFF TokenMatch (@token, @#T_LBRAK) THEN XcowlErr (610019): GOTO eeeSyntax
			hold_lbrak = tokenPtr
			brackCount = 1
			DO WHILE brackCount
				old_token = token
				NextToken (@token)
				SELECT CASE TRUE
					CASE TokenMatch (@token, @#T_RBRAK): DEC brackCount
					CASE TokenMatch (@token, @#T_LBRAK): INC brackCount
				END SELECT
			LOOP UNTIL (token.tp.kind = $$KIND_STARTS)
			IF brackCount THEN
				tokenPtr = hold_lbrak
				XcowlErr (610032): GOTO eeeSyntax
			END IF
			IF TokenMatch (@old_token, @#T_COMMA) THEN
				lastPlace   = tokenPtr
				NextToken (@token)
				tokenPtr    = hold_place
				excessComma = $$TRUE
				RETURN ($$TRUE)
			END IF
	END SELECT
'
	lastPlace   = tokenPtr                ' point to end of current composite
	NextToken (@token)                    ' is next token a composite?
	kind        = token.tp.kind
	tokenPtr    = hold_place
	IF (kind = $$KIND_SYMBOLS) THEN RETURN ($$FALSE)
	IF (kind = $$KIND_ARRAY_SYMBOLS) THEN RETURN ($$FALSE)
	RETURN ($$TRUE)
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
END FUNCTION
'
'
' ########################
' #####  Literal ()  #####
' ########################
'
FUNCTION  Literal (xx)
	SHARED  r_addr[]
'
	r = r_addr[xx{$$WORD0}]
	IF (r >= $$IMM16) AND (r <= $$CONNUM) THEN RETURN ($$TRUE)
	RETURN ($$FALSE)
END FUNCTION
'
'
' ###########################  dreg = 0 means push on CPU stack (rsp stack)
' #####  LoadLitnum ()  #####
' ###########################
'
FUNCTION  LoadLitnum (dreg, dtype, sourceTindex, stype)
	EXTERNAL /xxx/  xpc
	SHARED  m_addr[],  m_addr$[]
	SHARED  XERROR,  ERROR_COMPILER
	ULONG  w3, w2, w1, w0
'
	ss = sourceTindex
'
	IF NullStringerCheck (ss) THEN
		IF dreg THEN
			Code ($$xor, $$regreg, dreg, dreg, 0, $$XLONG, "", $$rmk$+"851")
		ELSE
			Move (dreg, $$XLONG, ss, $$XLONG)
		END IF
		RETURN
	END IF
'
	IF (dtype = $$STRING) THEN
		IFZ dreg THEN
			Code ($$mov, $$regimm, $$rax, 0, 0, $$XLONG, m_addr$[ss], $$rmk$+"852A")
			Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"852B")
		ELSE
			PRINT "LoadLitnum(): Slits"
			Code ($$mov, $$regimm, dreg, 0, m_addr[ss], $$XLONG, m_addr$[ss], $$rmk$+"853")
		END IF
		RETURN
	END IF
'
	GetWords (ss, dtype, @w3, @w2, @w1, @w0)
	IF XERROR THEN EXIT FUNCTION
'
	SELECT CASE dtype
		CASE $$GIANT, $$XLONG
					IFZ dreg THEN
						x_imm = w3 << 48 + w2 << 32 + w1 << 16 + w0
						minlong = -2147483649
						maxlong = 2147483647
						IF ((x_imm <= maxlong) AND (x_imm >= minlong)) THEN  'value less than 32 bits
							Code ($$push, $$imm, x_imm, 0, 0, $$XLONG, "", $$rmk$+"854")
						ELSE
							x_imm = w3 << 48 + w2 << 32 + w1 << 16 + w0
							Code ($$mov, $$regimm, $$rax, x_imm, 0, $$XLONG, "", $$rmk$+"855")
							Code ($$push, $$reg, $$rax, 0, 0, d_type, "", $$rmk$+"856")
						END IF
					ELSE
						x_imm = w3 << 48 + w2 << 32 + w1 << 16 + w0
						Code ($$mov, $$regimm, dreg, x_imm, 0, $$XLONG, "", $$rmk$+"857")
					END IF
		CASE $$DOUBLE
					x_imm = w3 << 48 + w2 << 32 + w1 << 16 + w0
					IFZ dreg THEN
						Code ($$mov, $$regimm, $$rbx, x_imm, 0, $$XLONG, "", $$rmk$+"858A")
						Code ($$push, $$reg, $$rbx, 0, 0, d_type, "", $$rmk$+"859A")
					ELSE
						Code ($$mov, $$regimm, dreg, x_imm, 0, $$XLONG, "", $$rmk$+"858B")
						Code ($$push, $$reg, dreg, 0, 0, d_type, "", $$rmk$+"859B")
					END IF
					IF dreg THEN
						Code ($$fld, $$ro, 0, $$rsp, 0, $$DOUBLE, "", $$rmk$+"860")
						Code ($$add, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"861")
					END IF
		CASE $$SINGLE
					GOSUB PushWords
					IF dreg THEN
						Code ($$fld, $$ro, 0, $$rsp, 0, $$SINGLE, "", $$rmk$+"863")
						Code ($$add, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"864")
					END IF
		CASE ELSE
					IFZ dreg THEN
						Code ($$push, $$imm, (w1 << 16 + w0), 0, 0, $$XLONG, "", $$rmk$+"865")
					ELSE
						Code ($$mov, $$regimm, dreg, (w1 << 16 + w0), 0, $$XLONG, "", $$rmk$+"866")
					END IF
	END SELECT
	RETURN
'
'
' *****  PushWords  *****
'
SUB PushWords
	x_imm = w3 << 48 + w2 << 32 + w1 << 16 + w0
	minlong = -2147483649
	maxlong = 2147483647
	IF ((x_imm < maxlong) AND (x_imm > minlong)) THEN  'value less than 32 bits
		Code ($$push, $$imm, x_imm, 0, 0, $$XLONG, "", $$rmk$+"866A")
	ELSE
		Code ($$mov, $$regimm, $$rax, x_imm, 0, $$XLONG, "", $$rmk$+"866B")
		Code ($$push, $$reg, $$rax, 0, 0, d_type, "", $$rmk$+"866C")
	END IF
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  MakeToken ()  #####
' ##########################
'
FUNCTION  TOKEN MakeToken (keyword$, kind, allo, type)
	TOKEN   token
	SHARED  TOKEN tab_sys[]
	SHARED  tab_sys$[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  tab_sys_ptr
'
	SELECT CASE kind
		CASE $$KIND_VARIABLES                                    : GOTO make_system
		CASE $$KIND_CONSTANTS, $$KIND_SYSCONS                    : GOTO make_system
		CASE $$KIND_ARRAYS                                       : GOTO make_system
		CASE $$KIND_STATEMENTS, $$KIND_INTRINSICS                : GOTO make_system
		CASE $$KIND_STATEMENTS_INTRINSICS                        : GOTO make_system
		CASE $$KIND_SEPARATORS, $$KIND_TERMINATORS               : GOTO make_system
		CASE $$KIND_LPARENS, $$KIND_RPARENS                      : GOTO make_system
		CASE $$KIND_UNARY_OPS, $$KIND_BINARY_OPS, $$KIND_ADDR_OPS: GOTO make_system
		CASE $$KIND_CHARACTERS                                   : GOTO make_system
		CASE $$KIND_COMMENTS, $$KIND_WHITES, $$KIND_STARTS       : GOTO make_comment
		CASE ELSE                                                : XcowlErr (640025): GOTO eeeCompiler
	END SELECT
'
make_system:
'
	token.tp.kind = kind
	token.tp.allo = allo
	token.tp.type = type
	token.tindex = tab_sys_ptr
	tab_sys$[tab_sys_ptr] = keyword$
	tab_sys[tab_sys_ptr] = token
	INC tab_sys_ptr
	RETURN (token)
'
' make white.space token  (data.type = # of spaces, word0 = error #)
' make start token  (word0 = # of tokens generated for this line)
' make error token  (data.type = # of bytes in error text)
'
make_comment:
'
	token.tp.kind = kind
	RETURN (token)
'
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##################################
' #####  MinTypeFromDouble ()  #####
' ##################################
'
FUNCTION  MinTypeFromDouble (value#)
	IF (value# < 0) THEN value# = -value#
	minSingleExponent#  = 0s00800000
	maxSingleExponent#  = 0s7F000000
	IF (value# < minSingleExponent#) THEN RETURN ($$DOUBLE)
	IF (value# > maxSingleExponent#) THEN RETURN ($$DOUBLE)
	svalue! = value#
	dvalue# = svalue!
	IF (value# = dvalue#) THEN RETURN ($$SINGLE)
	RETURN ($$DOUBLE)
END FUNCTION
'
'
' #################################
' #####  MinTypeFromGiant ()  #####
' #################################
'
FUNCTION  MinTypeFromGiant (v$$)
	SELECT CASE TRUE
		CASE ((v$$ >= $$MIN_USHORT) AND (v$$ <= $$MAX_USHORT)): rt = $$USHORT
		CASE ((v$$ >= $$MIN_SSHORT) AND (v$$ <= $$MAX_SSHORT)): rt = $$SSHORT
		CASE ((v$$ >= $$MIN_SLONG)  AND (v$$ <= $$MAX_SLONG)):  rt = $$SLONG
		CASE ELSE:                                              rt = $$GIANT
	END SELECT
	RETURN (rt)
END FUNCTION
'
'
' #####################  destin = 0 means push on CPU stack (rsp stack)
' #####  Move ()  #####
' #####################
'
' dest   > $$CONNUM means it is an index to tab_sym[] for the TOKEN
' source > $$CONNUM means it is an index to tab_sym[] for the TOKEN
'
FUNCTION  Move (destin, d_type, source, s_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   d, s
	SHARED  TOKEN tab_sym[]
	SHARED  m_reg[],  m_addr[],  m_addr$[]
	SHARED  r_addr[],  r_addr$[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_TYPE_MISMATCH
	SHARED  a0_type,  a1_type
	SHARED SSHORT typeConvert[]
'
	dext    = $$FALSE                 ' not EXTERNAL destination
	sext    = $$FALSE                 ' not EXTERNAL source
	dxarg   = $$FALSE                 ' not excess argument destination
	sxarg   = $$FALSE                 ' not excess argument source
	slits   = $$FALSE                 ' not "literal string"
	sdest   = destin
	ssource = source
	IF (sdest > $$CONNUM) THEN
		d   = tab_sym[sdest]
		k   = d.tp.kind
		da  = d.tp.allo
		IF (da = $$EXTERNAL) THEN dext = $$TRUE
	END IF
	IF (ssource > $$CONNUM) THEN
		s  = tab_sym[ssource]
		k  = s.tp.kind
		t  = TheType (s)
		sa = s.tp.allo
		SELECT CASE k
			CASE $$KIND_LITERALS, $$KIND_CONSTANTS, $$KIND_SYSCONS
						IF (t = $$STRING) THEN slits = $$TRUE
		END SELECT
		IF (sa = $$EXTERNAL) THEN sext = $$TRUE
	END IF
	IFZ d_type THEN d_type = s_type
	d_reg = 0
	s_reg = r_addr[ssource]
	IF destin THEN d_reg = r_addr[sdest]
	SELECT CASE d_type
		CASE $$SINGLE:  dfloat = $$TRUE
		CASE $$DOUBLE:  dfloat = $$TRUE
		CASE ELSE:      dfloat = $$FALSE
	END SELECT
	SELECT CASE s_type
		CASE $$SINGLE:  sfloat = $$TRUE
		CASE $$DOUBLE:  sfloat = $$TRUE
		CASE ELSE:      sfloat = $$FALSE
	END SELECT
	SELECT CASE d_type
		CASE $$STRING
					destString = $$TRUE
	END SELECT
	SELECT CASE s_type
		CASE $$STRING
					sourceString = $$TRUE
	END SELECT
	IF (destString XOR sourceString) THEN XcowlErr (670066): GOTO eeeCompiler
	IFZ sourceString THEN
		IF ((d_type >= $$SCOMPLEX) OR (s_type >= $$SCOMPLEX)) THEN
			IF  (d_type != s_type) THEN XcowlErr (670069): GOTO eeeTypeMismatch
		ELSE
			IF (typeConvert[d_type, s_type] {{$$BYTE0}}) THEN
				XcowlErr (670072): GOTO eeeCompiler
			END IF
		END IF
	END IF
	IF (destin = source) THEN RETURN
	IF (d_type < $$SLONG) THEN d_type = $$SLONG  '*cw* 230323-+
	IF (s_type < $$SLONG) THEN s_type = $$SLONG  '*cw* 230323-+
'	IF (d_type < $$XLONG) THEN d_type = $$XLONG  '*cw* 230323+-
'	IF (s_type < $$XLONG) THEN s_type = $$XLONG  '*cw* 230323+-
	SELECT CASE d_reg
		CASE $$RA0: a0_type = d_type
		CASE $$RA1: a1_type = d_type
	END SELECT
'
'
' *************************************************************
' *****  Dispatch based on destination/source in reg/mem  *****
' *************************************************************
'
	IF d_reg THEN
		IF s_reg THEN GOTO drsr ELSE GOTO drsm
	ELSE
		IF s_reg THEN GOTO dmsr ELSE GOTO dmsm
	END IF
'
'
' ************************************************************
' *****  Destination in Register  :  Source in Register  *****
' ************************************************************
'
drsr:
	IF (s_reg = $$CONNUM) OR (s_reg = $$LITNUM) THEN
		LoadLitnum (d_reg, d_type, source, @s_type)
		RETURN
	END IF
	IF ((s_reg = $$IMM16) OR (s_reg = $$NEG16)) THEN
		IF ((s_type >= $$GIANT) AND (s_type != $$STRING)) THEN
			LoadLitnum (d_reg, d_type, source, @s_type)
		ELSE
			IF NullStringerCheck (ssource) THEN
				Code ($$xor, $$regreg, d_reg, d_reg, 0, $$XLONG, "", $$rmk$+"867")
			ELSE
				x_imm = XLONG (r_addr$[ssource])
				Code ($$mov, $$regimm, d_reg, x_imm, 0, $$XLONG, "", $$rmk$+"868")
			END IF
		END IF
		RETURN
	END IF
	IFZ dfloat THEN
		Code ($$mov, $$regreg, d_reg, s_reg, 0, $$XLONG, "", $$rmk$+"869")
	END IF
	RETURN
'
'
' **********************************************************
' *****  Destination in Register  :  Source in Memory  *****
' **********************************************************
'
drsm:
	IFZ source THEN
		PRINT "source=0"
		XcowlErr (6700131): GOTO eeeCompiler
	END IF
	mReg  = m_reg[ssource]
	mAddr = m_addr[ssource]
	IFZ mReg THEN
		m$  = m_addr$[ssource]
		IF sfloat THEN
			Code ($$fld, $$abs, 0, 0, mAddr, s_type, @m$, $$rmk$+"871")
		ELSE
			IF slits THEN
				Code ($$mov, $$regimm, d_reg, mAddr, 0, s_type, @m$, $$rmk$+"872")
			ELSE
				Code ($$ld, $$regabs, d_reg, 0, mAddr, s_type, @m$, $$rmk$+"873")
			END IF
		END IF
	ELSE
		IF sfloat THEN
			Code ($$fld, $$ro, 0, mReg, mAddr, s_type, "", $$rmk$+"874")
		ELSE
			Code ($$ld, $$regro, d_reg, mReg, mAddr, s_type, "", $$rmk$+"875")
		END IF
	END IF
	RETURN
'
'
' **********************************************************
' *****  Destination in Memory  :  Source in Register  *****
' **********************************************************
'
dmsr:
	SELECT CASE s_reg
		CASE $$IMM16, $$NEG16
					IF ((s_type >= $$GIANT) AND (s_type != $$STRING)) THEN
						IFZ destin THEN
							LoadLitnum (0, d_type, source, s_type)          ' push literal
							RETURN
						ELSE
							LoadLitnum ($$rsi, d_type, source, s_type)
						END IF
					ELSE
						x_imm = XLONG (r_addr$[ssource])
						IFZ destin THEN
							Code ($$push, $$imm, x_imm, 0, 0, $$XLONG, "", $$rmk$+"876")    ' push literal
							RETURN
						ELSE
							Code ($$mov, $$regimm, $$rsi, x_imm, 0, $$XLONG, "", $$rmk$+"877")
						END IF
					END IF
					s_reg = $$rsi
		CASE $$LITNUM, $$CONNUM
					IFZ destin THEN
						LoadLitnum (0, d_type, source, @s_type)   ' push literal
						RETURN
					ELSE
						LoadLitnum ($$rsi, d_type, source, @s_type)
					END IF
					s_reg = $$rsi
	END SELECT
	mReg  = m_reg[sdest]
	mAddr = m_addr[sdest]
	IFZ mReg THEN
		m$  = m_addr$[sdest]
		IF dfloat THEN
			IFZ destin THEN
				SELECT CASE d_type
					CASE $$SINGLE : dsize = 4
					CASE $$DOUBLE : dsize = 8
				END SELECT
				Code ($$sub, $$regimm, $$rsp, dsize, 0, $$XLONG, "", $$rmk$+"878")
				Code ($$fstp, $$ro, 0, $$rsp, 0, d_type, "", $$rmk$+"879")
				RETURN
			ELSE
				Code ($$fstp, $$abs, 0, 0, mAddr, d_type, @m$, $$rmk$+"880")
			END IF
		ELSE
			IFZ destin THEN
				Code ($$push, $$reg, s_reg, 0, 0, d_type, "", $$rmk$+"881")
				RETURN
			ELSE
				Code ($$st, $$absreg, s_reg, 0, mAddr, d_type, @m$, $$rmk$+"882")
			END IF
		END IF
	ELSE
		IF dfloat THEN
			Code ($$fstp, $$ro, 0, mReg, mAddr, d_type, "", $$rmk$+"883")
		ELSE
			Code ($$st, $$roreg, s_reg, mReg, mAddr, d_type, "", $$rmk$+"884")
		END IF
	END IF
	RETURN
'
'
' ********************************************************
' *****  Destination in Memory  :  Source in Memory  *****
'
'
dmsm:
	mReg  = m_reg[ssource]
	mAddr = m_addr[ssource]
	IFZ mReg THEN
		m$  = m_addr$[ssource]
		IF slits THEN
			IFZ destin THEN
				Code ($$push, $$imm, 0, 0, mAddr, $$XLONG, @m$, $$rmk$+"885")
				RETURN
			ELSE
				Code ($$ld, $$regabs, $$rsi, 0, mAddr, $$XLONG, @m$, $$rmk$+"886")
			END IF
		ELSE
			IF sfloat THEN
				Code ($$fld, $$abs, 0, 0, mAddr, s_type, @m$, $$rmk$+"887")
			ELSE
				IFZ destin THEN
					Code ($$ld, $$regabs, $$rax, 0, mAddr, $$XLONG, @m$, $$rmk$+"888")
					Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"888B")
					RETURN
				ELSE
					Code ($$ld, $$regabs, $$rsi, 0, mAddr, s_type, @m$, $$rmk$+"889")
				END IF
			END IF
		END IF
	ELSE
		IF sfloat THEN
			Code ($$fld, $$ro, 0, mReg, mAddr, s_type, "", $$rmk$+"890")
		ELSE
			IFZ destin THEN
				Code ($$push, $$ro, 0, mReg, mAddr, s_type, "", $$rmk$+"891")
				RETURN
			ELSE
				Code ($$ld, $$regro, $$rsi, mReg, mAddr, s_type, "", $$rmk$+"892")
			END IF
		END IF
	END IF
'
	mReg  = m_reg[sdest]
	mAddr = m_addr[sdest]
	SELECT CASE d_type
'		CASE $$SINGLE : dsize = 4  '*cw* 220916-
		CASE $$SINGLE : dsize = 8  '*cw* 220916+
		CASE $$DOUBLE : dsize = 8
	END SELECT
	IFZ mReg THEN
		m$  = m_addr$[sdest]
		IF dfloat THEN
			IFZ destin THEN
				Code ($$sub, $$regimm, $$rsp, dsize, 0, $$XLONG, "", $$rmk$+"893")
				Code ($$fstp, $$ro, 0, $$rsp, 0, d_type, "", $$rmk$+"894")
			ELSE
				Code ($$fstp, $$abs, 0, 0, mAddr, d_type, @m$, $$rmk$+"895")
			END IF
		ELSE
			IFZ destin THEN PRINT "MoveYikes0"
			Code ($$st, $$absreg, $$rsi, 0, mAddr, d_type, @m$, $$rmk$+"896")
		END IF
	ELSE
		IF dfloat THEN
			IFZ destin THEN PRINT "MoveYikes1"
			Code ($$fstp, $$ro, 0, mReg, mAddr, d_type, "", $$rmk$+"897")
		ELSE
			IFZ destin THEN PRINT "MoveYikes2"
			Code ($$st, $$roreg, $$rsi, mReg, mAddr, d_type, "", $$rmk$+"898")
		END IF
	END IF
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  NextToken ()  #####
' ##########################
'
FUNCTION  NextToken (TOKEN token)
	SHARED  TOKEN funcToken[]
	SHARED  TOKEN tab_sym[]
	SHARED  TOKEN tokens[]
	SHARED  TOKEN typeToken[]

	SHARED  m_addr$[]
	SHARED  uType,  typeAlias[],  typeSymbol$[]
	SHARED  tab_sym$[]
	SHARED  tokenCount,  tokenPtr
	STATIC GOADDR  kindDispatch[]
'
	IFZ kindDispatch[] THEN GOSUB LoadKindDispatch    ' load dispatch table
'
skip_whities:
	INC tokenPtr
	IF (tokenPtr >= tokenCount) THEN
		token.tproto = $$TP_STARTS
		token.tindex = $$TI_ZERO
		RETURN
	END IF
'
	token.tproto = tokens[tokenPtr].tproto
	token.tindex = tokens[tokenPtr].tindex
	token.tp.stsp = 0
	tt    = token.tindex
	GOTO @kindDispatch[token.tp.kind]
	RETURN
'
from_tab_sym:
	token.tproto = tab_sym[tt].tproto
	token.tindex = tab_sym[tt].tindex
	RETURN
'
' from_variables added 08/12/93 to support adding a user-defined type with
' the same name as existing variables.  The variables need to be mapped into
' the type token.
'
from_variables:
	token.tproto = tab_sym[tt].tproto
	token.tindex = tab_sym[tt].tindex
	IF (token.tp.kind != $$KIND_VARIABLES) THEN ' mapped to non-variable kind ?
		tt = token.tindex
		GOTO @kindDispatch[token.tp.kind]       ' dispatch by mapped kind
	END IF
	IFZ m_addr$[tt] THEN                        ' if no address
		symbol$ = tab_sym$[tt]                    '
		FOR i = $$DCOMPLEX+1 TO uType             '
			IF (symbol$ = typeSymbol$[i]) THEN      ' supports adding a type
				token.tproto = typeToken[i].tproto   ' after a variable of the
				token.tindex = typeToken[i].tindex   ' after a variable of the
				tab_sym[tt].tproto = token.tproto    ' same name exists... and
				tab_sym[tt].tindex = token.tindex    ' same name exists... and
			END IF                                  ' to a type token (hopefully)
		NEXT i                                    '
	END IF
	IF (token.tp.kind != $$KIND_VARIABLES) THEN ' apped to non-variable kind ?
		tt = token.tindex
		GOTO @kindDispatch[token.tp.kind]         ' dispatch by mapped kind
	END IF
	RETURN
'
from_func_sym:
	token.tproto = funcToken[tt].tproto
	token.tindex = funcToken[tt].tindex
	RETURN
'
them_comments:
	tokenPtr = tokenCount
	token.tproto = $$TP_STARTS
	token.tindex = $$TI_ZERO
	RETURN
'
from_types:
	ttt   = typeAlias[tt]
	IF ttt THEN tt = ttt
	token.tproto = typeToken[tt].tproto
	token.tindex = typeToken[tt].tindex
	RETURN
'
'
' *****  LoadKindDispatch  *****
'
SUB LoadKindDispatch
	DIM kindDispatch[31]
	kindDispatch[ $$KIND_SYMBOLS       ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_ARRAY_SYMBOLS ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_VARIABLES     ] = GOADDRESS (from_variables)
	kindDispatch[ $$KIND_ARRAYS        ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_SYSCONS       ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_LITERALS      ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_CONSTANTS     ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_FUNCTIONS     ] = GOADDRESS (from_func_sym)
	kindDispatch[ $$KIND_COMMENTS      ] = GOADDRESS (them_comments)
	kindDispatch[ $$KIND_WHITES        ] = GOADDRESS (skip_whities)
	kindDispatch[ $$KIND_TYPES         ] = GOADDRESS (from_types)
END SUB
END FUNCTION
'
'
' ##################################
' #####  NullStringerCheck ()  #####
' ##################################
'
' IF NullStringerCheck (tindex) THEN
'
' END IF
'
FUNCTION  NullStringerCheck (tindex)
	SHARED  nullstringer
	SHARED  nullstringerProto
	SHARED  r_addr$[]
	SHARED  TOKEN tab_sym[]

	IF (tindex == nullstringer) THEN RETURN $$TRUE

	IF ((tab_sym[tindex].tproto XOR nullstringerProto) AND 0xFFFFFF) THEN RETURN $$FALSE

	IF (r_addr$[tindex] == "0") THEN RETURN $$TRUE

END FUNCTION
'
'
' ###################
' #####  Op ()  #####
' ###################
'
FUNCTION  Op (d_reg, s_reg, TOKEN the_op, rax, rt, st, ot, xt)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   ctoken0, ctoken1
	SHARED  TOKEN tab_sym[]

	SHARED  m_reg[],  m_addr[],  m_addr$[]
	SHARED  r_addr$[],  typeName$[]
	SHARED  XERROR, ERROR_COMPILER,  ERROR_OVERFLOW,  ERROR_TYPE_MISMATCH
	SHARED  a0,  a0_type,  a1,  a1_type,  oos,  comStk
	SHARED  labelNumber
	SHARED UBYTE oos[]
	STATIC GOADDR  opToken[]
'
	IFZ opToken[] THEN GOSUB LoadOpToken
'
' *****  Destination register
'
	SELECT CASE d_reg
		CASE $$RA0: a0_type = rt
		CASE $$RA1: a1_type = rt
	END SELECT
	d_regx = d_reg + 1
'
' *****  Source register 1
'
	ras = s_reg
	SELECT CASE s_reg
		CASE $$RA0, $$RA1
		CASE ELSE: XcowlErr (700035): GOTO eeeCompiler
	END SELECT
	s_regx = s_reg + 1
'
' *****  Source register 2 or immediate value
'
	revOp = $$FALSE
	SELECT CASE rax
		CASE $$FALSE : XcowlErr (700043): GOTO eeeCompiler
		CASE $$RA0   : x_reg = $$RA0: x_regx = x_reg + 1: mode = $$regreg
		CASE $$RA1   : x_reg = $$RA1: x_regx = x_reg + 1: mode = $$regreg
		CASE ELSE    : IF (d_reg != s_reg) THEN XcowlErr (700046): GOTO eeeCompiler
										SELECT CASE ot
											CASE $$SINGLE, $$DOUBLE
														Move ($$rsi, xt, rax, xt)
											CASE ELSE
														xx      = rax
														x_reg   = XLONG (r_addr$[xx])
														x_regx  = 0
														mode    = $$regimm
														ximm    = $$TRUE
														x_imm   = x_reg
														SELECT CASE TRUE
															CASE x_imm > $$MAX_SLONG : ximm64 = $$TRUE
															CASE x_imm < $$MIN_SLONG : ximm64 = $$TRUE
															CASE ELSE : ximm32 = $$TRUE
														END SELECT
										END SELECT
	END SELECT
	IF ((ot = $$SCOMPLEX) OR (ot = $$DCOMPLEX)) THEN
		SELECT CASE TRUE
			CASE TokenMatch (@the_op, @#T_EQ)
			CASE TokenMatch (@the_op, @#T_NE)
			CASE TokenMatch (@the_op, @#T_NEQ)
			CASE TokenMatch (@the_op, @#T_NNE)
			CASE TokenMatch (@the_op, @#T_EQL)
			CASE TokenMatch (@the_op, @#T_LT)
			CASE TokenMatch (@the_op, @#T_LE)
			CASE TokenMatch (@the_op, @#T_GE)
			CASE TokenMatch (@the_op, @#T_GT)
			CASE TokenMatch (@the_op, @#T_NLT)
			CASE TokenMatch (@the_op, @#T_NLE)
			CASE TokenMatch (@the_op, @#T_NGE)
			CASE TokenMatch (@the_op, @#T_NGT)
			CASE ELSE
						csymbol1$ = ".complex1." + HEX$(comStk)
						csymbol0$ = ".complex0." + HEX$(comStk)
						ctoken1 = AddSymbol (@csymbol1$, 0, $$KIND_VARIABLES, $$AUTOX, $$DOUBLE, f_number)
						ctoken0 = AddSymbol (@csymbol0$, 0, $$KIND_VARIABLES, $$AUTOX, $$DOUBLE, f_number)
						cnumber0  = ctoken0.tindex
						cnumber1  = ctoken1.tindex
'
						ctoken0.tp.allo   = $$AUTOX
						ctoken1.tp.allo   = $$AUTOX
						tab_sym[cnumber0] = ctoken0
						tab_sym[cnumber1] = ctoken1
'
						IFZ m_addr$[cnumber1] THEN
							AssignAddress (ctoken1)
							AssignAddress (ctoken0)
							IF XERROR THEN EXIT FUNCTION
						END IF
						cr0 = m_reg[cnumber0]
						cn0 = m_addr[cnumber0]
						Code ($$mov, $$regreg, $$rdi, x_reg, 0, $$XLONG, "", $$rmk$+"899")
						Code ($$mov, $$regreg, $$rsi, s_reg, 0, $$XLONG, "", $$rmk$+"900")
						Code ($$lea, $$regro, $$rax, cr0, cn0, $$XLONG, "", $$rmk$+"901")
						IF (d_reg != $$RA0) THEN XcowlErr (7000102): GOTO eeeCompiler
						INC comStk
		END SELECT
	ELSE
		IF ximm THEN
			IF (d_reg != s_reg) THEN XcowlErr (7000107): GOTO eeeCompiler
		ELSE
			SELECT CASE TRUE
				CASE (d_reg = s_reg)
							IF (d_reg = x_reg) THEN XcowlErr (7000111): GOTO eeeCompiler
				CASE (d_reg = x_reg)
							IF (d_reg = s_reg) THEN XcowlErr (7000113): GOTO eeeCompiler
							SWAP s_reg, x_reg
							SWAP s_regx, x_regx
							revOp = NOT revOp
				CASE ELSE
							XcowlErr (7000118): GOTO eeeCompiler
			END SELECT
		END IF
	END IF
	orderCounts = $$FALSE
'
'
' *****  Execute routine appropriate to binary operator token  *****
'
	GOTO @opToken[the_op.ti.ndex]
	PRINT "opdispatch"
	XcowlErr (7000129): GOTO eeeCompiler
'
' *****************************************************************************
' *****  Destinations of preceeding computed dispatch on operator tokens  *****
' *****************************************************************************
'
op_logical_or:  GOTO logical_or
op_logical_xor: GOTO logical_xor
op_logical_and: GOTO logical_and
op_logical_cmp: GOTO logical_cmp
op_test_EQ:eqt = $$TRUE:  GOSUB rop: GOTO test_EQ
op_test_NE:eqt = $$TRUE:  GOSUB rop: GOTO test_NE
op_test_LT:eqt = $$FALSE: GOSUB rop: GOTO test_LT
op_test_LE:eqt = $$FALSE: GOSUB rop: GOTO test_LE
op_test_GE:eqt = $$FALSE: GOSUB rop: GOTO test_GE
op_test_GT:eqt = $$FALSE: GOSUB rop: GOTO test_GT
op_orbit: op=$$or:  GOTO bitwise_or_xor_and
op_xorbit:op=$$xor: GOTO bitwise_or_xor_and
op_andbit:op=$$and: GOTO bitwise_or_xor_and
op_add:GOTO add
op_subtract:GOTO subtract
op_integer_mod:GOTO integer_modulus
op_integer_div:GOTO integer_divide
op_multiply:GOTO multiply
op_divide:GOTO divide
op_power:GOTO power
op_right_shift:GOTO right_shift
op_left_shift:GOTO left_shift
op_down_shift:GOTO down_shift
op_up_shift:GOTO up_shift
'
'
' ****************************************  Compares operands, leaves compare
' *****  Relational Operator Prolog  *****  flag bits in "d.reg".  The operator
' ****************************************  routines extract appropriate bits.
'
SUB rop
	op = $$cmp
	SELECT CASE TRUE
		CASE (ot <= $$GIANT):   GOSUB CompareGiant
		CASE (ot = $$SINGLE):   GOSUB CompareFloat
		CASE (ot = $$DOUBLE):   GOSUB CompareFloat
		CASE (ot = $$STRING):   GOSUB CompareString
		CASE (ot = $$SCOMPLEX): GOSUB CompareSCOMPLEX
		CASE (ot = $$DCOMPLEX): GOSUB CompareDCOMPLEX
		CASE ELSE:              GOTO  eeeTypeMismatch
	END SELECT
END SUB
'
SUB CompareGiant
	IF ximm64 THEN
		Code ($$mov, $$regimm, $$rbx, x_imm, 0, $$XLONG, "", $$rmk$+"902A")
		Code ($$cmp, $$regreg, s_reg, $$rbx, 0, $$XLONG, "", $$rmk$+"903B")
	ELSE
		Code ($$cmp, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"902")
	END IF
END SUB
'
'
' Note GIANT routines completed in specific condition tests
'
'
SUB CompareFloat
	Code ($$fcompp, 0, 0, 0, 0, $$DOUBLE, "", $$rmk$+"904")
	IF a0 THEN Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"905")
'	Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"906")              '*cw* 220701-
	Code ($$fnstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"906")             '*cw* 220701+
	Code ($$sahf, 0, 0, 0, 0, $$XLONG, "", $$rmk$+"907")
	IF a0 THEN Code ($$pop, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"908")
END SUB
'
SUB CompareString
	IFZ revOp THEN
		ooos$ = CHR$(oos[oos-1]) + CHR$(oos[oos])
		IF ((ras != $$RA0) OR (rax != $$RA1)) THEN XcowlErr (7000202): GOTO eeeCompiler
	ELSE
		ooos$ = CHR$(oos[oos]) + CHR$(oos[oos-1])
		IF ((ras != $$RA1) OR (rax != $$RA0)) THEN XcowlErr (7000205): GOTO eeeCompiler
	END IF
	d1$ = $$ulpc$+"_string.compare." + ooos$
	Code ($$call, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"909")
	oos = oos - 2
END SUB
'
SUB CompareSCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_compare.SCOMPLEX", $$rmk$+"910")
END SUB
'
SUB CompareDCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, $$XLONG, $$ulpc$+"_compare.DCOMPLEX", $$rmk$+"911")
END SUB
'
'
' *********************
' *****  COMPARE  *****  Checking for ot = $$GIANT not needed in 64-bit
' *********************
'
test_EQ:
	the_op.tindex = $$o2
	the_op.tproto = $$TP_ZERO
	RETURN
'
test_NE:
	the_op.tindex = $$o3
	the_op.tproto = $$TP_ZERO
	RETURN
'
test_LT:
	SELECT CASE ot
		CASE $$ULONG, $$STRING
					IF revOp THEN the_op.tindex = $$o8 ELSE the_op.tindex = $$o10
		CASE $$SINGLE, $$DOUBLE
					IF revOp THEN the_op.tindex = $$o10 ELSE the_op.tindex = $$o8
		CASE ELSE
					IF revOp THEN the_op.tindex = $$o4 ELSE the_op.tindex = $$o6
	END SELECT
	the_op.tproto = $$TP_ZERO
	RETURN
'
test_LE:
	SELECT CASE ot
		CASE $$ULONG, $$STRING
					IF revOp THEN the_op.tindex = $$o11 ELSE the_op.tindex = $$o9
		CASE $$SINGLE, $$DOUBLE
					IF revOp THEN the_op.tindex = $$o9 ELSE the_op.tindex = $$o11
		CASE ELSE
					IF revOp THEN the_op.tindex = $$o7 ELSE the_op.tindex = $$o5
	END SELECT
	the_op.tproto = $$TP_ZERO
	RETURN
'
test_GE:
	SELECT CASE ot
		CASE $$ULONG, $$STRING
					IF revOp THEN the_op.tindex = $$o9 ELSE the_op.tindex = $$o11
		CASE $$SINGLE, $$DOUBLE
					IF revOp THEN the_op.tindex = $$o11 ELSE the_op.tindex = $$o9
		CASE ELSE
					IF revOp THEN the_op.tindex = $$o5 ELSE the_op.tindex = $$o7
	END SELECT
	the_op.tproto = $$TP_ZERO
	RETURN
'
test_GT:
	SELECT CASE ot
		CASE $$ULONG, $$STRING
					IF revOp THEN the_op.tindex = $$o10 ELSE the_op.tindex = $$o8
		CASE $$SINGLE, $$DOUBLE
					IF revOp THEN the_op.tindex = $$o8 ELSE the_op.tindex = $$o10
		CASE ELSE
					IF revOp THEN the_op.tindex = $$o6 ELSE the_op.tindex = $$o4
	END SELECT
	the_op.tproto = $$TP_ZERO
	RETURN
'
'
' ************************
' *****  logical OR  *****
' ************************
'
logical_or:
	Code ($$or, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"951")
	Code ($$neg, $$reg, s_reg, 0, 0, $$XLONG, "", $$rmk$+"952")
	Code ($$rcr, $$regimm, s_reg, 1, 0, $$XLONG, "", $$rmk$+"953")
	Code ($$sar, $$regimm, s_reg, 63, 0, $$XLONG, "", $$rmk$+"954")
	the_op = #T_ZERO
	RETURN
'
'
' *************************
' *****  logical AND  *****
' *************************
'
logical_and:
	GOSUB Logical_GIANT_LONG
	Code ($$and, $$regreg, s_reg, s_regx, 0, $$XLONG, "", $$rmk$+"955")
	the_op = #T_ZERO
	RETURN
'
'
' *************************
' *****  logical CMP  *****
' *************************
'
logical_cmp:
	GOSUB Logical_GIANT_LONG
	Code ($$xor, $$regreg, s_reg, s_regx, 0, $$XLONG, "", $$rmk$+"956")
	Code ($$not, $$reg, d_reg, 0, 0, $$XLONG, "", $$rmk$+"957")
	the_op = #T_ZERO
	RETURN
'
'
' *************************
' *****  logical XOR  *****
' *************************
'
logical_xor:
	GOSUB Logical_GIANT_LONG
	Code ($$xor, $$regreg, s_reg, s_regx, 0, $$XLONG, "", $$rmk$+"958")
	the_op = #T_ZERO
	RETURN
'
SUB Logical_GIANT_LONG
		Code ($$neg, $$reg, s_reg, 0, 0, $$XLONG, "", $$rmk$+"965")
		Code ($$rcr, $$regimm, s_reg, 1, 0, $$XLONG, "", $$rmk$+"966")
		Code ($$sar, $$regimm, s_reg, 63, 0, $$XLONG, "", $$rmk$+"967")
		Code ($$mov, mode, s_regx, x_reg, 0, $$XLONG, "", $$rmk$+"968")
	Code ($$neg, $$reg, s_regx, 0, 0, $$XLONG, "", $$rmk$+"969")
	Code ($$rcr, $$regimm, s_regx, 1, 0, $$XLONG, "", $$rmk$+"970")
	Code ($$sar, $$regimm, s_regx, 63, 0, $$XLONG, "", $$rmk$+"971")
END SUB
'
'
' *************************
' *****  bitwise OR   *****
' *****  bitwise XOR  *****
' *****  bitwise AND  *****
' *************************
'
bitwise_or_xor_and:
	IF ximm64 THEN
		Code ($$mov, $$regimm, $$rbx, x_reg, 0, $$XLONG, "", $$rmk$+"972")
		Code (op, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"973")
	ELSE
		Code (op, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"974")
	END IF
	the_op = #T_ZERO
	RETURN
'
'
' **********************
' *****  ADDITION  *****
' **********************
'
add:
	op = $$add
	SELECT CASE ot
		CASE $$SLONG:     GOSUB AddSLONG
		CASE $$ULONG:     GOSUB AddULONG
		CASE $$XLONG:     GOSUB AddXLONG
		CASE $$GIANT:     GOSUB AddGIANT
		CASE $$SINGLE:    GOSUB type_stuff
		CASE $$DOUBLE:    GOSUB type_stuff
		CASE $$STRING:    GOSUB Concatenate
		CASE $$SCOMPLEX:  GOSUB AddSCOMPLEX
		CASE $$DCOMPLEX:  GOSUB AddDCOMPLEX
		CASE ELSE:        XcowlErr (7000374): GOTO eeeTypeMismatch
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB AddSLONG
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$add, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"981")
	Code ($$jno, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"982")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"982b")
	EmitLabel (@d1$)
END SUB
'
SUB AddULONG
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$add, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"983")
	Code ($$jnc, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"984")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"985")
	EmitLabel (@d1$)
END SUB
'
SUB AddXLONG
	Code ($$add, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"986")
END SUB
'
SUB AddGIANT
	IF ximm64 THEN
		Code ($$mov, $$regimm, s_regx, x_reg, 0, $$XLONG, "", $$rmk$+"987A")
		Code ($$add, $$regreg, s_reg, s_regx, 0, $$XLONG, "", $$rmk$+"988A")
	ELSE
		Code ($$add, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"988B")
	END IF


	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$jno, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"989a")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"989b")
	EmitLabel (@d1$)
END SUB
'
SUB AddSCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_add.SCOMPLEX", $$rmk$+"990")
END SUB
'
SUB AddDCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_add.DCOMPLEX", $$rmk$+"991")
END SUB
'
SUB Concatenate
	IF (ot != $$STRING) THEN XcowlErr (7000423): GOTO eeeTypeMismatch
	ooos$   = CHR$(oos[oos-1]) + CHR$(oos[oos])
	IF revOp THEN
		dx$ = $$ulpc$+"_concat.ubyte.a0.eq.a1.plus.a0." + ooos$
	ELSE
		dx$ = $$ulpc$+"_concat.ubyte.a0.eq.a0.plus.a1." + ooos$
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, dx$, $$rmk$+"992")
	DEC oos
	oos[oos] = 's'
	the_op = #T_ZERO
END SUB
'
'
' *************************
' *****  SUBTRACTION  *****
' *************************
'
subtract:
	op = $$sub
	SELECT CASE ot
		CASE $$SLONG:     GOSUB SubtractSLONG
		CASE $$ULONG:     GOSUB SubtractULONG
		CASE $$XLONG:     GOSUB SubtractXLONG
		CASE $$GIANT:     GOSUB SubtractGIANT
		CASE $$SINGLE:    GOSUB type_stuff
		CASE $$DOUBLE:    GOSUB type_stuff
		CASE $$SCOMPLEX:  GOSUB SubtractSCOMPLEX
		CASE $$DCOMPLEX:  GOSUB SubtractDCOMPLEX
		CASE ELSE:        GOTO  eeeTypeMismatch
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB SubtractSLONG
	IF revOp THEN Code ($$xchg, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"993")
	Code ($$sub, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"994")
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$jno, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"995a")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"995b")
	EmitLabel (@d1$)
END SUB
'
SUB SubtractULONG
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	IF revOp THEN Code ($$xchg, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"996")
	Code ($$sub, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"997")
	Code ($$jnc, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"998")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"999")
	EmitLabel (@d1$)
END SUB
'
SUB SubtractXLONG
	IF revOp THEN Code ($$xchg, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1000")
	Code ($$sub, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1001")
END SUB
'
SUB SubtractGIANT
	IF (mode = $$regimm) THEN
		Code ($$mov, $$regimm, s_regx, x_reg, 0, $$XLONG, "", $$rmk$+"1001")
		IF revOp THEN
			Code ($$xchg, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"1002")
		END IF
		Code ($$sub, $$regreg, s_reg, s_regx, 0, $$XLONG, "", $$rmk$+"1003")
	ELSE
		IF revOp THEN
			Code ($$xchg, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"1004")
		END IF
		Code ($$sub, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1004B")
	END IF
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$jno, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"1006a")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"1006b")
	EmitLabel (@d1$)
END SUB
'
SUB SubtractSCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_sub.SCOMPLEX", $$rmk$+"1008")
END SUB
'
SUB SubtractDCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_sub.DCOMPLEX", $$rmk$+"1010")
END SUB
'
'
' ****************************
' *****  MULTIPLICATION  *****
' ****************************
'
multiply:
	op = $$mul
	SELECT CASE ot
		CASE $$SLONG:     GOSUB MultiplySLONG
		CASE $$ULONG:     GOSUB MultiplyULONG
		CASE $$XLONG:     GOSUB MultiplyXLONG
		CASE $$GIANT:     GOSUB MultiplyXLONG
		CASE $$SINGLE:    GOSUB type_stuff
		CASE $$DOUBLE:    GOSUB type_stuff
		CASE $$SCOMPLEX:  GOSUB MultiplySCOMPLEX
		CASE $$DCOMPLEX:  GOSUB MultiplyDCOMPLEX
		CASE ELSE:        XcowlErr (7000523): GOTO eeeTypeMismatch
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB MultiplySLONG
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$imul, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1011")
	Code ($$jnc, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"1012")
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_eeeOverflow", $$rmk$+"1013")
	EmitLabel (@d1$)
END SUB
'
SUB MultiplyULONG
	Code ($$imul, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1014")
END SUB
'
SUB MultiplyXLONG
'	PRINT "Op(723)MultiplyXLONG", mode, s_reg, x_reg
	Code ($$imul, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1015")
END SUB
'
SUB MultiplyGIANT
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_mul.GIANT", $$rmk$+"1016")
END SUB
'
SUB MultiplySCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_mul.SCOMPLEX", $$rmk$+"1017")
END SUB
'
SUB MultiplyDCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_mul.DCOMPLEX", $$rmk$+"1018")
END SUB
'
'
' *********************************************
' *****  DIVISION  *****  FLOATING POINT  *****
' *********************************************
'
divide:
	op = $$div
	SELECT CASE ot
		CASE $$SLONG:     GOSUB DivideSLONG
		CASE $$ULONG:     GOSUB DivideULONG
		CASE $$XLONG:     GOSUB DivideSLONG
		CASE $$GIANT:     GOSUB DivideSLONG
		CASE $$SINGLE:    GOSUB type_stuff
		CASE $$DOUBLE:    GOSUB type_stuff
		CASE $$SCOMPLEX:  GOSUB DivideSCOMPLEX
		CASE $$DCOMPLEX:  GOSUB DivideDCOMPLEX
		CASE ELSE:  XcowlErr (7000573): GOTO eeeTypeMismatch
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB DivideSLONG
	wierdOp = $$idiv
	GOSUB WierdOp
END SUB
'
SUB DivideULONG
	wierdOp = $$div
	GOSUB WierdOp
END SUB
'
SUB DivideGIANT
	IF (s_reg == $$RA1) THEN revOp = NOT revOp
	IF revOp THEN
		Code ($$xchg, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1019")
		Code ($$xchg, $$regreg, s_regx, x_regx, 0, $$XLONG, "", $$rmk$+"1020")
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_div.GIANT", $$rmk$+"1021")
	IF (s_reg == $$RA1) THEN
		Code ($$mov, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1022")
		Code ($$mov, $$regreg, s_regx, x_regx, 0, $$XLONG, "", $$rmk$+"1023")
	END IF
END SUB
'
SUB DivideSCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_div.SCOMPLEX", $$rmk$+"1025")
END SUB
'
SUB DivideDCOMPLEX
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_div.DCOMPLEX", $$rmk$+"1027")
END SUB
'
'
' ****************************
' *****  INTEGER DIVIDE  *****
' ****************************
'
integer_divide:
	op = $$div
	SELECT CASE ot
		CASE $$SLONG: GOSUB IntegerDivideSLONG
		CASE $$ULONG: GOSUB IntegerDivideULONG
		CASE $$XLONG: GOSUB IntegerDivideSLONG
		CASE $$GIANT: GOSUB IntegerDivideSLONG
		CASE ELSE:    XcowlErr (7000621): GOTO eeeTypeMismatch
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB IntegerDivideSLONG
	wierdOp = $$idiv
	GOSUB WierdOp
END SUB
'
SUB IntegerDivideULONG
	wierdOp = $$div
	GOSUB WierdOp
END SUB
'
SUB IntegerDivideGIANT
	IF (s_reg == $$RA1) THEN revOp = NOT revOp
	IF revOp THEN
		Code ($$xchg, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1028")
		Code ($$xchg, $$regreg, s_regx, x_regx, 0, $$XLONG, "", $$rmk$+"1029")
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_div.GIANT", $$rmk$+"1030")
	IF (s_reg == $$RA1) THEN
		Code ($$mov, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1031")
		Code ($$mov, $$regreg, s_regx, x_regx, 0, $$XLONG, "", $$rmk$+"1032")
	END IF
END SUB
'
'
'
' *****************************
' *****  INTEGER MODULUS  *****  result = x - (x\y * y)
' *****************************
'
integer_modulus:
	orderCounts = $$TRUE
	SELECT CASE ot
		CASE $$SLONG: GOSUB IntegerModulusSLONG
		CASE $$ULONG: GOSUB IntegerModulusULONG
		CASE $$XLONG: GOSUB IntegerModulusSLONG
		CASE $$GIANT: GOSUB IntegerModulusSLONG
		CASE ELSE:    XcowlErr (7000662): GOTO eeeTypeMismatch
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB IntegerModulusSLONG
	wierdOp = $$idiv
	GOSUB WierdOp
	Code ($$mov, $$regreg, s_reg, $$rdx, 0, $$XLONG, "", $$rmk$+"1033")
END SUB
'
SUB IntegerModulusULONG
	wierdOp = $$div
	GOSUB WierdOp
	Code ($$mov, $$regreg, s_reg, $$rdx, 0, $$XLONG, "", $$rmk$+"1034")
END SUB
'
SUB IntegerModulusGIANT
	IF (s_reg == $$RA1) THEN revOp = NOT revOp
	IF revOp THEN
		Code ($$xchg, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1035")
		Code ($$xchg, $$regreg, s_regx, x_regx, 0, $$XLONG, "", $$rmk$+"1036")
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_mod.GIANT", $$rmk$+"1037")
	IF (s_reg == $$RA1) THEN
		Code ($$mov, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1038")
		Code ($$mov, $$regreg, s_regx, x_regx, 0, $$XLONG, "", $$rmk$+"1039")
	END IF
END SUB
'
'
'
SUB WierdOp
	SELECT CASE mode
		CASE $$regreg:  mode = $$reg
		CASE $$regimm:  Code ($$mov, $$regimm, $$rsi, x_reg, 0, $$XLONG, "", $$rmk$+"1040")
										mode = $$reg
										x_reg = $$rsi
		CASE ELSE:      XcowlErr (7000700): GOTO eeeCompiler
	END SELECT
	IF revOp THEN Code ($$xchg, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1041")
	IF (s_reg != $$rax) THEN
		Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1042")
		Code ($$mov, $$regreg, $$rax, s_reg, 0, $$XLONG, "", $$rmk$+"1043")
		SELECT CASE wierdOp
			CASE  $$idiv: Code ($$cdq, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"1044")
			CASE  $$div:  Code ($$xor, $$regreg, $$rdx, $$rdx, 0, $$XLONG, "", $$rmk$+"1045")
		END SELECT
		Code (wierdOp, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1046")
		Code ($$mov, $$regreg, s_reg, $$rax, 0, $$XLONG, "", $$rmk$+"1047")
		Code ($$pop, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1048")
	ELSE
		SELECT CASE wierdOp
			CASE  $$idiv: Code ($$cdq, $$none, 0, 0, 0, $$XLONG, "", $$rmk$+"1049")
			CASE  $$div:  Code ($$xor, $$regreg, $$rdx, $$rdx, 0, $$XLONG, "", $$rmk$+"1050")
		END SELECT
		Code (wierdOp, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1051")
	END IF
END SUB
'
' ****************************
' *****  RAISE TO POWER  *****  (x ** y) = raise "x" to the power "y"
' ****************************
'
power:
	IF (s_reg = $$RA1) AND ((ot != $$SINGLE) AND (ot != $$DOUBLE)) THEN revOp = NOT revOp
	IF revOp THEN
		dx$ = $$ulpc$+"_rpower." + typeName$[ot]
	ELSE
		dx$ = $$ulpc$+"_power." + typeName$[ot]
	END IF
	SELECT CASE ot
		CASE $$SLONG, $$ULONG, $$XLONG
			IF (mode == $$regimm) THEN
				IF revOp THEN
					Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1052")
					Code ($$mov, $$regimm, $$rax, x_reg, 0, $$XLONG, "", $$rmk$+"1053")
				ELSE
					Code ($$mov, $$regimm, $$rbx, x_reg, 0, $$XLONG, "", $$rmk$+"1054")
				END IF
			END IF
		CASE $$GIANT, $$SINGLE, $$DOUBLE
		CASE  ELSE: XcowlErr (7000744): GOTO eeeCompiler
	END SELECT
	Code ($$call, $$rel, 0, 0, 0, 0, dx$, $$rmk$+"1055")
	IF (s_reg = $$RA1) THEN
		SELECT CASE ot
			CASE $$SINGLE, $$DOUBLE   ' hopefully no problem - in coprocessor
			CASE $$GIANT              : Code ($$mov, $$regreg, $$rbx, $$rax, 0, $$XLONG, "", $$rmk$+"1056")
																: Code ($$mov, $$regreg, $$rcx, $$rdx, 0, $$XLONG, "", $$rmk$+"1057")
			CASE ELSE                 : Code ($$mov, $$regreg, $$rbx, $$rax, 0, $$XLONG, "", $$rmk$+"1058")
		END SELECT
	END IF
	IF (mode == $$regimm) THEN
		IF revOp THEN
			Code ($$pop, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1059")
		END IF
	END IF
	the_op = #T_ZERO
	RETURN
'
'
' *********************************
' *****  BITWISE SHIFT RIGHT  *****  RIGHT SHIFT  *****  carry in zeros
' *********************************
'
right_shift:
	shop = $$slr
	GOTO xshift
'
'
' ********************************
' *****  BITWISE SHIFT LEFT  *****  LEFT SHIFT  *****  carry in zeros
' ********************************
'
left_shift:
	shop = $$sll
	GOTO xshift
'
'
' *********************************
' *****  ARITHMETIC SHIFT UP  *****  UP SHIFT  *****  carry in zeros
' *********************************
'
up_shift:
	shop = $$sll                       'arithmetic same as bit shift when to left
	GOTO xshift
'
'
' ***********************************
' *****  ARITHMETIC SHIFT DOWN  *****  DOWN SHIFT  *****  sign extend msb
' ***********************************
'
down_shift:
	shop = $$sar
	GOTO xshift
'
'
'
xshift:
	IF revOp THEN
		IF (mode = $$regimm) THEN XcowlErr (7000803): GOTO eeeCompiler
		Code ($$mov, $$regreg, $$rcx, s_reg, 0, $$XLONG, "", $$rmk$+"1060")
		Code ($$mov, $$regreg, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1061")
		x_reg = $$cl
	END IF
	SELECT CASE mode
		CASE $$regimm
					Code (shop, mode, s_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1062")
		CASE $$regreg
					IF ((x_reg != $$rcx) AND (x_reg != $$cl)) THEN
						Code ($$mov, $$regreg, $$rcx, x_reg, 0, $$XLONG, "", $$rmk$+"1063")
					END IF
					Code (shop, $$regreg, s_reg, $$cl, 0, $$XLONG, "", $$rmk$+"1064")
		CASE ELSE
					XcowlErr (7000817): GOTO eeeCompiler
	END SELECT
	the_op = #T_ZERO
	RETURN
'
'
' *************************************************************
' *****  GIANT upshift, downshift, leftshift, rightshift  *****
' *************************************************************
'
gshift:
	IF (s_reg = $$RA1) THEN revOp = NOT revOp
	IF revOp THEN
		Code ($$mov, $$regreg, $$rdx, $$rcx, 0, $$XLONG, "", $$rmk$+"1065")
		Code ($$mov, $$regreg, $$rcx, $$rax, 0, $$XLONG, "", $$rmk$+"1066")
		Code ($$mov, $$regreg, $$rax, $$rbx, 0, $$XLONG, "", $$rmk$+"1067")
	ELSE
		Code ($$mov, mode, $$rcx, x_reg, 0, $$XLONG, "", $$rmk$+"1068")
	END IF
	Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"1069")
	IF (s_reg = $$RA1) THEN
		Code ($$mov, $$regreg, $$rbx, $$rax, 0, $$XLONG, "", $$rmk$+"1070")
		Code ($$mov, $$regreg, $$rcx, $$rdx, 0, $$XLONG, "", $$rmk$+"1071")
	END IF
	the_op = #T_ZERO
	RETURN
'
'
' Set up types of floating point result and two floating point operands
'
SUB type_stuff
	SELECT CASE op
		CASE $$add: op486 = $$fadd
		CASE $$sub: op486 = $$fsub: IF revOp THEN op486 = $$fsubr
		CASE $$mul: op486 = $$fmul
		CASE $$div: op486 = $$fdiv: IF revOp THEN op486 = $$fdivr
		CASE ELSE:  PRINT "??? No such floating point operator ???"
	END SELECT
	Code (op486, 0, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1072")
END SUB
'
'
'
'
' ****************************************************************
' *****  Load opToken[] with addresses of operator routines  *****
' ****************************************************************
'
SUB LoadOpToken
	DIM opToken[255]
	opToken[ #T_ORL.ti.ndex ]      = GOADDRESS (op_logical_or)
	opToken[ #T_XORL.ti.ndex ]     = GOADDRESS (op_logical_xor)
	opToken[ #T_ANDL.ti.ndex ]     = GOADDRESS (op_logical_and)
	opToken[ #T_CMPL.ti.ndex ]     = GOADDRESS (op_logical_cmp)
	opToken[ #T_EQL.ti.ndex ]      = GOADDRESS (op_test_EQ)
	opToken[ #T_EQ.ti.ndex ]       = GOADDRESS (op_test_EQ)
	opToken[ #T_NNE.ti.ndex ]      = GOADDRESS (op_test_EQ)
	opToken[ #T_NE.ti.ndex ]       = GOADDRESS (op_test_NE)
	opToken[ #T_NEQ.ti.ndex ]      = GOADDRESS (op_test_NE)
	opToken[ #T_LT.ti.ndex ]       = GOADDRESS (op_test_LT)
	opToken[ #T_NGE.ti.ndex ]      = GOADDRESS (op_test_LT)
	opToken[ #T_LE.ti.ndex ]       = GOADDRESS (op_test_LE)
	opToken[ #T_NGT.ti.ndex ]      = GOADDRESS (op_test_LE)
	opToken[ #T_GE.ti.ndex ]       = GOADDRESS (op_test_GE)
	opToken[ #T_NLT.ti.ndex ]      = GOADDRESS (op_test_GE)
	opToken[ #T_GT.ti.ndex ]       = GOADDRESS (op_test_GT)
	opToken[ #T_NLE.ti.ndex ]      = GOADDRESS (op_test_GT)
	opToken[ #T_OR.ti.ndex ]       = GOADDRESS (op_orbit)
	opToken[ #T_ORBIT.ti.ndex ]    = GOADDRESS (op_orbit)
	opToken[ #T_XOR.ti.ndex ]      = GOADDRESS (op_xorbit)
	opToken[ #T_XORBIT.ti.ndex ]   = GOADDRESS (op_xorbit)
	opToken[ #T_AND.ti.ndex ]      = GOADDRESS (op_andbit)
	opToken[ #T_ANDBIT.ti.ndex ]   = GOADDRESS (op_andbit)
	opToken[ #T_SUBTRACT.ti.ndex ] = GOADDRESS (op_subtract)
	opToken[ #T_ADD.ti.ndex ]      = GOADDRESS (op_add)
	opToken[ #T_MOD.ti.ndex ]      = GOADDRESS (op_integer_mod)
	opToken[ #T_IDIV.ti.ndex ]     = GOADDRESS (op_integer_div)
	opToken[ #T_MUL.ti.ndex ]      = GOADDRESS (op_multiply)
	opToken[ #T_DIV.ti.ndex ]      = GOADDRESS (op_divide)
	opToken[ #T_POWER.ti.ndex ]    = GOADDRESS (op_power)
	opToken[ #T_RSHIFT.ti.ndex ]   = GOADDRESS (op_right_shift)
	opToken[ #T_LSHIFT.ti.ndex ]   = GOADDRESS (op_left_shift)
	opToken[ #T_DSHIFT.ti.ndex ]   = GOADDRESS (op_down_shift)
	opToken[ #T_USHIFT.ti.ndex ]   = GOADDRESS (op_up_shift)
END SUB
'
'
' ************************************
' *****  BINARY OPERATOR ERRORS  *****
' ************************************
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeOverflow:
	XERROR = ERROR_OVERFLOW
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ###############################
' #####  OpenAccForType ()  #####
' ###############################
'
FUNCTION  OpenAccForType (theType)
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  toes,  a0,  a0_type,  a1,  a1_type
'
	IFZ a0 THEN GOTO open0
	IFZ a1 THEN GOTO open1
	IF (a0 < a1) THEN Push ($$RA0, a0_type): GOTO open0
	IF (a0 > a1) THEN Push ($$RA1, a1_type): GOTO open1
	XcowlErr (710015): GOTO eeeCompiler
'
open0: INC toes: a0 = toes: a0_type = theType: RETURN ($$RA0)
open1: INC toes: a1 = toes: a1_type = theType: RETURN ($$RA1)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #############################
' #####  OpenBothAccs ()  #####
' #############################
'
FUNCTION  OpenBothAccs ()
	SHARED  a0,  a0_type,  a1,  a1_type,  toes
'
	IFZ toes THEN RETURN            ' nothing on stack
	IFZ (a0 OR a1) THEN RETURN      ' nothing in stack registers
	IF a0 AND (a0 < a1) THEN
		Push($$RA0, a0_type)
		a0 = 0: a0_type = 0
	END IF
	IF a1 THEN
		Push($$RA1, a1_type)
		a1 = 0: a1_type = 0
	END IF
	IF a0 THEN
		Push($$RA0, a0_type)
		a0 = 0: a0_type = 0
	END IF
	RETURN
END FUNCTION
'
'
' ###########################
' #####  OpenOneAcc ()  #####
' ###########################
'
FUNCTION  OpenOneAcc ()
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  a0,  a0_type,  a1,  a1_type
'
	IFZ a0 THEN RETURN ($$RA0)
	IFZ a1 THEN RETURN ($$RA1)
	IF (a0 < a1) THEN
		Push($$RA0, a0_type)
		RETURN ($$RA0)
	END IF
	IF (a0 > a1) THEN
		Push($$RA1, a1_type)
		RETURN ($$RA1)
	END IF
	PRINT "open1"
	XcowlErr (730022): GOTO eeeCompiler
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  ParseChar ()  #####
' ##########################
'
FUNCTION  TOKEN ParseChar ()
	TOKEN   token
	SHARED  TOKEN charToken[]
	SHARED  TOKEN tab_sym[]
	SHARED  TOKEN tokens[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  nullstring$,  nullstringer,  rawLength,  rawline$
	SHARED  func_number,  charPtr,  tokenPtr
	SHARED UBYTE  charsetNumeric[],  charsetUpperLower[]
	STATIC GOADDR parseChar[]
'
	IFZ parseChar[] THEN GOSUB LoadParseChar
	charV = rawline${charPtr}
	INC charPtr
	GOTO @parseChar[charV]                ' GOTO routine to parse this character
	PRINT "ParseChar"                      ' there is no routine for invalid characters
	XcowlErr (740023): GOTO eeeCompiler  ' so log an error message
'
'
'
pc_token:
	token = charToken[charV]        ' get token for this character
	ParseOutToken (token)           ' output token to token list
	RETURN (token)                  ' return token
'
'
' *************************************************************************
' *****  Parse characters that may be part of 1+ character sequences  *****
' *************************************************************************
'
'
' *****  !  *****  !   !!   !=   !<   !<=   !>=   !>
'
l_not_test:
	charV = rawline${charPtr}
	SELECT CASE charV
		CASE '!':   token = #T_TESTL
								INC charPtr
		CASE '=':   token = #T_NEQ
								INC charPtr
		CASE '<':   INC charPtr
								charV = rawline${charPtr}
								IF (charV = '=') THEN
									token = #T_NLE
									INC charPtr
								ELSE
									IF (charV = '>') THEN
										token = #T_NNE
										INC charPtr
									ELSE
										token = #T_NLT
									END IF
								END IF
		CASE '>':   INC charPtr
								charV = rawline${charPtr}
								IF (charV = '=') THEN
									token = #T_NGE
									INC charPtr
								ELSE
									token = #T_NGT
								END IF
		CASE ELSE:  token = #T_NOTL
	END SELECT
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  "  *****  Literal string  *****
'
double_quote:
	scans = charPtr       ' 0 offset to character after opening double-quote
	start = charPtr       ' 1 offset to opening double-quote
	final = rawLength     ' 0 offset to null-terminator
	IF (scans < final) THEN
		rawChar = rawline${scans}
		DO UNTIL (rawChar = '"')
			IF (rawChar = '\\') THEN
				INC scans
				rawChar = rawline${scans}
			END IF
			INC scans
			rawChar = rawline${scans}
		LOOP WHILE (scans < final)
	END IF
	IF (scans < final) THEN
		INC scans
		charPtr = scans   ' terminated by "  (normal case)
	ELSE
		charPtr = scans   ' terminated by null, not "
		INC scans
	END IF
	lit$ = MID$(rawline$, start, (scans-start)) + "\""
'
'  The literal string is in lit$
'
' token = $$T_LITERALS + ($$EXTERNAL << 21) + ($$STRING << 16)
	IF (lit$ = nullstring$) THEN
		token = tab_sym[nullstringer]
	ELSE
		token = AddSymbol (@lit$, $$ZERO, $$KIND_LITERALS, $$EXTERNAL, $$STRING, 0)
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  &  *****  & = addr.op:  && = and.op:  && = handle.op
'
amper:
	charV = rawline${charPtr}
	IF (charV = '&') THEN
		INC charPtr
		charV = rawline${charPtr}
		token = #T_ANDL               ' && = logical AND or handle operator
	ELSE
		token = #T_ANDBIT             ' &  = bitwise AND or address operator
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  :  *****  ::  *****
'
colon:
	charV = rawline${charPtr}
	IF (charV = ':') THEN
		INC charPtr
		charV = rawline${charPtr}
		token = #T_CMPL               ':: = logical CMP operator
	ELSE
		token = #T_COLON              ':  =
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  '  *****
'
remark:
	IFZ tokenPtr THEN GOTO sendRemark             ' first token ' is a remark
	charV = rawline${charPtr}                     ' 1st byte of comment / charcon
	IFZ charV THEN                                ' nothing after ' character, so
		token = #T_REM                                '     ...it's an empty comment
		ParseOutToken (token)                       ' Add comment to token list
		RETURN (token)                              ' that's all folks
	ELSE                                          ' comment or charcon follows '
		IF charV THEN charW = rawline${charPtr+1}   ' 2nd byte of comment or charcon
		IF charW THEN charX = rawline${charPtr+2}   ' 3rd byte of comment or charcon
		IF charX THEN charY = rawline${charPtr+3}   ' 4th byte of comment or charcon
		SELECT CASE TRUE
			CASE ((charW = ''') AND (charV != '\\')): c = 3                       '   '?'   charcon
			CASE ((charV = '\\') AND (charX = ''')):  c = 4   '   '\?'  charcon
			CASE ELSE:  GOTO sendRemark                       ' comment, not charcon
		END SELECT
	END IF
'
' It's a charcon  ( '?'  ...or...  '\?' )
'
	clit$ = MID$(rawline$, charPtr, c)
	token = AddSymbol (@clit$, 0, $$KIND_CHARCONS, $$SHARED, $$UBYTE, func_number)
	charPtr = charPtr + c - 1
	ParseOutToken (token)
	RETURN (token)
'
sendRemark:
	token.tproto = $$TP_COMMENTS
	token.tindex = $$TI_ZERO
	length = (rawLength - charPtr)              ' Length of comment in bytes
	IF (length < 255) THEN                      ' imbed length in token
		token.tp.type = length                    ' Build complete token
		INC tokenPtr                              ' move to next token
		tokens[tokenPtr].tproto = token.tproto   ' Add remark token to token list
		tokens[tokenPtr].tindex = token.tindex   ' Add remark token to token list
	ELSE
		token.tp.type = 0xFF                      ' Build complete token
		INC tokenPtr                              ' move to next token
		tokens[tokenPtr].tproto = token.tproto   ' Add remark token to token list
		tokens[tokenPtr].tindex = token.tindex   ' Add remark token to token list
		INC tokenPtr                              ' move to next token
		tokens[tokenPtr].tindex = length         ' add remark length to token list
	END IF
	IF length THEN
		TokenRestOfLine ()                        ' Tokenize rest of comment
	END IF
	RETURN (token)
'
'
' #####  *  #####  *   **
'
star:
	charV = rawline${charPtr}
	IF (charV = '*') THEN
		token = #T_POWER
		INC charPtr
	ELSE
		token = #T_MUL
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  .  *****   "..."  or  ".2345e3" (a number)  or  ".COMPONENTNAME"
'
dot:
	afterDot = rawline${charPtr}
	IF (afterDot = '.') THEN
		afterAfterDot = rawline${charPtr+1}
		IF (afterAfterDot = '.') THEN
			charPtr = charPtr + 2
			token = #T_ETC
			ParseOutToken (token)
			RETURN (token)
		ELSE
			INC charPtr
			ParseOutToken (#T_DOT)
			ParseOutToken (#T_DOT)
			RETURN (#T_DOT)
		END IF
	ELSE
		SELECT CASE TRUE
			CASE charsetNumeric[afterDot]
						DEC charPtr
						token = ParseNumber()
						RETURN (token)
			CASE charsetUpperLower[afterDot]
						DEC charPtr
						token = ParseSymbol()
						RETURN (token)
			CASE ELSE
						token = #T_DOT
						ParseOutToken (token)
						RETURN (token)
			END SELECT
	END IF
'
'
' *****  <  *****   <   <>   <=   <<   <<<
'
less_than:
	charV = rawline${charPtr}                         ' char after "<"
	SELECT CASE charV
		CASE '>':   token = #T_NE:      INC charPtr       ' <>
		CASE '=':   token = #T_LE:      INC charPtr       ' <=
		CASE '<':   token = #T_LSHIFT:  INC charPtr       ' <<  (or <<< maybe)
								charV = rawline${charPtr}           ' what's after "<<"
								IF (charV = '<') THEN               ' another "<" ???
									token = #T_USHIFT                 ' <<<
									INC charPtr                       ' past last "<"
								END IF
		CASE ELSE:  token = #T_LT                       ' <
	END SELECT
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  =  *****  =   ==
'
equals:
	charV = rawline${charPtr}
	IF (charV = '=') THEN
		token = #T_EQL
		INC charPtr
	ELSE
		token = #T_EQ
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  >  *****  ><   >=   >>   >>>
'
greater_than:
	charV = rawline${charPtr}
	SELECT CASE charV
		CASE '=':   token = #T_GE:        INC charPtr         ' >=
		CASE '<':   token = #T_NE:        INC charPtr         ' <>
		CASE '>':   token = #T_RSHIFT:    INC charPtr         ' >>
								charV = rawline${charPtr}
								IF (charV = '>') THEN
									token = #T_DSHIFT                     ' >>>
									INC charPtr
								END IF
		CASE ELSE:  token = #T_GT                           ' >
	END SELECT
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  ?  *****   "???"  or  just a simple "?" character
'
question:
	ParseOutToken (#T_QMARK)
	RETURN (#T_QMARK)
'
'
' *****  ^  *****   ^   ^^
'
upper:
	charV = rawline${charPtr}
	IF (charV = '^') THEN
		token = #T_XORL
		INC charPtr
	ELSE
		token = #T_XORBIT
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  {  *****  {   {{
'
lbrace:
	charV = rawline${charPtr}
	IF (charV = '{') THEN
		token = #T_LBRACES
		INC charPtr
	ELSE
		token = #T_LBRACE
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
' *****  |  *****  |   ||
'
vbar:
	charV = rawline${charPtr}
	IF (charV = '|') THEN
		token = #T_ORL
		INC charPtr
	ELSE
		token = #T_ORBIT
	END IF
	ParseOutToken (token)
	RETURN (token)
'
'
'
' *****************************************************************************
' *****  Load parseChar[] with addresses of routines to parse characters  *****
' *****************************************************************************
'
SUB LoadParseChar
	DIM parseChar[255]
'                                               '    00-32 handled elsewhere
	parseChar[  33 ] = GOADDRESS (l_not_test)   '  !  !!  !=  !<  !<=  !>=  !>
	parseChar[  34 ] = GOADDRESS (double_quote) '  "
	parseChar[  35 ] = GOADDRESS (pc_token)     '  #  #T_POUND
	parseChar[  36 ] = GOADDRESS (pc_token)     '  $  #T_DOLLAR
	parseChar[  37 ] = GOADDRESS (pc_token)     '  %  #T_PERCENT
	parseChar[  38 ] = GOADDRESS (amper)        '  &  &&
	parseChar[  39 ] = GOADDRESS (remark)       '  '
	parseChar[  40 ] = GOADDRESS (pc_token)     '  (  #T_LPAREN
	parseChar[  41 ] = GOADDRESS (pc_token)     '  )  #T_RPAREN
	parseChar[  42 ] = GOADDRESS (star)         '  *  **
	parseChar[  43 ] = GOADDRESS (pc_token)     '  +  #T_ADD
	parseChar[  44 ] = GOADDRESS (pc_token)     '  ,  #T_COMMA
	parseChar[  45 ] = GOADDRESS (pc_token)     '  -  #T_SUBTRACT
	parseChar[  46 ] = GOADDRESS (dot)          '  .
	parseChar[  47 ] = GOADDRESS (pc_token)     '  /  #T_DIVIDE
'                                               '     48-57 handled elsewhere
	parseChar[  58 ] = GOADDRESS (colon)        '  :  #T_COLON
	parseChar[  59 ] = GOADDRESS (pc_token)     '  ;  #T_SEMI
	parseChar[  60 ] = GOADDRESS (less_than)    '  <  <=  <>
	parseChar[  61 ] = GOADDRESS (equals)       '  =  ==
	parseChar[  62 ] = GOADDRESS (greater_than) '  >  >=
	parseChar[  63 ] = GOADDRESS (pc_token)     '  ?  #T_QMARK
	parseChar[  64 ] = GOADDRESS (pc_token)     '  @  #T_ATSIGN
'                                             '     65-90 handled elsewhere
	parseChar[  91 ] = GOADDRESS (pc_token)     ' [   #T_LBRAK
	parseChar[  92 ] = GOADDRESS (pc_token)     '  \  #T_IDIV
	parseChar[  93 ] = GOADDRESS (pc_token)     '  ]  #T_RBRAK
	parseChar[  94 ] = GOADDRESS (upper)        '  ^  ^^
	parseChar[  95 ] = GOADDRESS (pc_token)     '  _  #T_ULINE
	parseChar[  96 ] = GOADDRESS (pc_token)     '  `  #T_TICK
'                                             '     97-122 handled elsewhere
	parseChar[ 123 ] = GOADDRESS (lbrace)       '  {  {{
	parseChar[ 124 ] = GOADDRESS (vbar)         '  |
	parseChar[ 125 ] = GOADDRESS (pc_token)     '  }
	parseChar[ 126 ] = GOADDRESS (pc_token)     '  ~  #T_TILDA
	parseChar[ 127 ] = GOADDRESS (pc_token)     '     #T_MARK
'                                             '     128-255 are trash
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  ParseLine ()  #####
' ##########################
'
FUNCTION  ParseLine (TOKEN tok[])
	TOKEN   token, ctoken, importToken
	TOKEN   holdToken[]
	SHARED  TOKEN lastToken
	SHARED  TOKEN tokens[]
	SHARED  charpos[]
	SHARED  XERROR
	SHARED  function_line,  tokenCount,  tokenPtr
	SHARED  declareAlloTypeLine,  declareFuncaddrLine
	SHARED  charPtr,  rawLength,  rawline$
	SHARED UBYTE  charsetNumeric[]
	STATIC FUNCADDR TOKEN parseFirstChar[]()
'
	IF (RIGHT$(rawline$) == "\0") THEN
		PRINT "ParseLine(21)", rawline$
	END IF
'
	IFZ parseFirstChar[] THEN GOSUB LoadParseFirstChar
	charPtr = 0
	tokenPtr = 0
	XERROR = $$FALSE
	lastToken = #T_STARTS
	function_line = $$FALSE
	declareAlloTypeLine = $$FALSE
	declareFuncaddrLine = $$FALSE
'
	IFZ rawLength THEN                        ' empty source line
		charpos[tokenPtr] = 1
		tokens[tokenPtr].tproto = $$TP_STARTS
		tokens[tokenPtr].tindex = $$TI_ZERO
		GOTO doneLine
	END IF
'
	charV = rawline${charPtr}
	IF charsetNumeric[charV] THEN             ' errorIndex on this line
		errorIndex = XLONG(LEFT$(rawline$, 3))
		IF (rawLength <= 3) THEN GOTO doneLine
		charPtr = 3
		charV = rawline${charPtr}
	ELSE
		errorIndex = 0
	END IF
'
	IF (charV = '>') THEN                     ' current executable line
		markLine = $$EXE
		INC charPtr
		charV = rawline${charPtr}
	END IF
'
	IF (charV = ':') THEN                     ' breakpoint set on this line
		markLine = markLine OR $$BP
		INC charPtr
		charV = rawline${charPtr}
	END IF
'
	SELECT CASE charV                       ' check for leading spaces and tabs
		CASE ' '
					DO WHILE (charV = ' ')          ' check for leading spaces  " "
						INC stsp
						INC charPtr
						IF (stsp >= 127) THEN EXIT DO ' maximum spaces per toklen
						charV = rawline${charPtr}
					LOOP
					IF (stsp > 127) THEN stsp = 127
					skip = stsp
		CASE '\t'
					DO WHILE (charV = '\t')         ' check for leading tabs  "\t"
						INC tabs
						INC charPtr
						IF (tabs >= 127) THEN EXIT DO ' maximum tabs per toklen
						charV = rawline${charPtr}
					LOOP
					IF (tabs > 128) THEN tabs = 128
					skip = tabs << 1
					stsp = -tabs AND 0x00FF
	END SELECT
	charpos[tokenPtr] = skip + 1
	tokens[tokenPtr].tproto = $$TP_STARTS
	tokens[tokenPtr].tindex = $$TI_ZERO
'
' parse the line
'
	DO WHILE (charV)
		charpos[tokenPtr] = charPtr
		charV = rawline${charPtr}
		token = @parseFirstChar[charV]()                ' token = 0 on trash
'
		IFZ token.tproto THEN
			IFZ token.tindex THEN
				IF (rawline$ <> "\n") THEN
					PRINT "ParseLine(98): empty token", charPtr, "\"";rawline$;"\""
				END IF
				INC charPtr
			END IF
		END IF
		IF importLine THEN
			IF TokenMatch (@importToken, @#T_ZERO) THEN
				IF (token.tp.kind = $$KIND_LITERALS) THEN
					IF (token.tp.type = $$STRING) THEN importToken = token
				END IF
			END IF
		END IF
'
		IF (tokenPtr = 1) THEN
			IF (token.tp.kind == $$KIND_STATEMENTS) THEN
				SELECT CASE token.tindex
					CASE #T_FUNCTION.tindex  : function_line = $$TRUE
					CASE #T_SFUNCTION.tindex : function_line = $$TRUE
					CASE #T_CFUNCTION.tindex : function_line = $$TRUE
					CASE #T_IMPORT.tindex    : importLine    = $$TRUE
				END SELECT
			END IF
		END IF
		IF XERROR THEN markLine = 0: EXIT FUNCTION
	LOOP WHILE (charPtr < rawLength)
'
'
'
doneLine:
	INC tokenPtr
	charpos[tokenPtr] = 0
	tokenCount = tokenPtr AND 0x00FF
	tokens[0].ti.bpexe = markLine
	tokens[0].tp.kind = $$KIND_STARTS
	tokens[0].tp.stsp = stsp
	tokens[0].ti.ndex = tokenCount
	tokens[0].ti.errno = errorIndex
'
	i = 0
	DIM tok[tokenCount]
	DO WHILE (i < tokenCount)
		tok[i].tproto = tokens[i].tproto
		tok[i].tindex = tokens[i].tindex
		INC i
	LOOP
	tok[i].tproto = $$TP_STARTS  ' terminate with #T_STARTS token
	tok[i].tindex = $$TI_ZERO    '  with zero token count
'
	IF importLine THEN
		IFF TokenMatch (@importToken, @#T_ZERO) THEN
			ATTACH tok[] TO holdToken[]       ' hold IMPORT "libname" line tokens
			XxxParseLibrary (importToken)
			ATTACH holdToken[] TO tok[]
		END IF
	END IF
	RETURN
'
'
' *****************************************************************************
' *****  Load parseFirstChar[] with functions to parse based on 1st char  *****
' *****************************************************************************
'
SUB LoadParseFirstChar
	DIM parseFirstChar[255]
	FOR c = 0 TO 255
		SELECT CASE TRUE
			CASE (c >= 128)                                         ' trash
			CASE (c >= 123):  parseFirstChar[c] = &ParseChar ()     ' char / operator
			CASE (c >=  97):  parseFirstChar[c] = &ParseSymbol()    ' "a-z"
			CASE (c  =  95):  parseFirstChar[c] = &ParseSymbol()    ' "_"
			CASE (c >=  91):  parseFirstChar[c] = &ParseChar ()     ' char / operator
			CASE (c >=  65):  parseFirstChar[c] = &ParseSymbol()    ' "A-Z"
			CASE (c >=  58):  parseFirstChar[c] = &ParseChar ()     ' char / operator
			CASE (c >=  48):  parseFirstChar[c] = &ParseNumber()    ' "0-9"
			CASE (c  =  36):  parseFirstChar[c] = &ParseSymbol()    ' "$con" or "$$con
			CASE (c  =  35):  parseFirstChar[c] = &ParseSymbol()    ' "#var" or "##var"
			CASE (c >=  33):  parseFirstChar[c] = &ParseChar ()     ' char / operator
			CASE (c  =  32):  parseFirstChar[c] = &ParseWhite ()    ' space chars
			CASE (c  =   9):  parseFirstChar[c] = &ParseWhite ()    ' tab chars
			CASE (c  <   9):                                        ' trash
		END SELECT
	NEXT c
END SUB
'
END FUNCTION
'
'
' ############################
' #####  ParseNumber ()  #####
' ############################
'
FUNCTION  TOKEN ParseNumber ()
	TOKEN   token
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  func_number,  charPtr,  rawline$
'
	startPtr  = charPtr
	specType  = XstStringToNumber (@rawline$, @startPtr, @charPtr, @rtype, @value$$)
	value     = value$$
	suffixOne = rawline${charPtr}
	IF suffixOne THEN suffixTwo = rawline${charPtr+1}
	IF (specType < 0) THEN specType = 0
'
' see if number is followed by a type-suffix
'
	IFZ specType THEN
		SELECT CASE suffixOne
			CASE '@':   IF (suffixTwo = '@') THEN
										charPtr   = charPtr + 2
										specType  = $$USHORT
									ELSE
										charPtr   = charPtr + 1
										specType  = $$SLONG
									END IF
			CASE '%':   IF (suffixTwo = '%') THEN
										charPtr   = charPtr + 2
										specType  = $$USHORT
									ELSE
										charPtr   = charPtr + 1
										specType  = $$SLONG
									END IF
			CASE '&':   IF (suffixTwo = '&') THEN
										charPtr   = charPtr + 2
										specType  = $$ULONG
									ELSE
										charPtr   = charPtr + 1
										specType  = $$SLONG
									END IF
			CASE '$':   IF (suffixTwo = '$') THEN
										charPtr   = charPtr + 2
										specType  = $$GIANT
									END IF
			CASE '~':   charPtr     = charPtr + 1
									specType    = $$XLONG
			CASE '!':   charPtr     = charPtr + 1
									specType    = $$SINGLE
			CASE '#':   charPtr     = charPtr + 1
									specType    = $$DOUBLE
		END SELECT
	END IF
	number$   = MID$(rawline$, startPtr+1, charPtr-startPtr)
'
' if type not specified by anything yet, decide on basis of the value
'
	IFZ specType THEN
		SELECT CASE rtype
			CASE 0       : specType  = $$USHORT                '  zero
			CASE $$SLONG : specType  = $$SLONG
											IF ((value >= 0) AND (value < 65536)) THEN specType = $$USHORT
			CASE $$XLONG : specType  = $$XLONG                 ' "0x..."
											IF ((value >= 0) AND (value < 65536)) THEN specType = $$USHORT
			CASE $$SINGLE: specType  = $$SINGLE                ' "0s..."
			CASE $$GIANT : specType  = MinTypeFromGiant (value$$)
			CASE $$DOUBLE: value#    = DMAKE (vhi, vlo)
											specType  = MinTypeFromDouble (value#)
			CASE ELSE    : XcowlErr (760071): GOTO eeeCompiler
		END SELECT
	END IF
'
	SELECT CASE specType
		CASE $$UBYTE : specType = $$USHORT
		CASE $$SBYTE : specType = $$SSHORT
	END SELECT
'
' add the literal number token to the token stream
'
	token = AddSymbol (@number$, 0, $$KIND_LITERALS, 0, specType, func_number)
	ParseOutToken (token)
	RETURN (token)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##############################
' #####  ParseOutError ()  #####
' ##############################
'
FUNCTION  ParseOutError (TOKEN token)
	SHARED  TOKEN tokens[]
	SHARED  charpos[]
	SHARED  charPtr,  rawLength,  tokenCount,  tokenPtr
'
	charPtr   = 1
	tokenPtr  = 0
	hold      = tokenPtr
	l%        = rawLength
	charpos[tokenPtr] = 1
	IF (l% > 255) THEN l% = 255
	token.tp.type = token.tp.type + 1%
	tokens[tokenPtr] = #T_STARTS
	ParseOutToken (token)
	TokenRestOfLine ()
	ParseOutToken (#T_STARTS)
	tokenCount = tokenPtr
	tokens[hold].tproto = $$TP_STARTS
	tokens[hold].tindex = tokenPtr
'
END FUNCTION
'
'
' ##############################
' #####  ParseOutToken ()  #####
' ##############################
'
FUNCTION  ParseOutToken (TOKEN token)
	SHARED  charpos[]
	SHARED  charPtr,  tokenPtr,  rawline$
	SHARED  declareAlloTypeLine,  declareFuncaddrLine
	SHARED  TOKEN  backToken
	SHARED  TOKEN  lastToken
	SHARED  TOKEN  tokens[]
'
' count and skip trailing spaces and tabs
'
	spaces = 0
	charV = rawline${charPtr}
	SELECT CASE charV
		CASE ' '
			DO WHILE (charV = ' ')    ' space characters
				INC spaces
				INC charPtr
				charV = rawline${charPtr}
			LOOP
			blanks = spaces
			IF (blanks > 127) THEN blanks = 127   ' more then 127 is rediculous
			token.tp.stsp = blanks               ' 1 to 127 spaces
			excess = 0
		CASE '\t'
			DO WHILE (charV = '\t')                 ' tab character
				INC tabs
				INC charPtr
				charV = rawline${charPtr}
			LOOP
			blanks = -tabs
			IF (blanks < -128) THEN blanks = -128 ' more then 128 is rediculous
			token.tp.stsp = blanks               ' 1 to 128 tabs
			excess = 0
		CASE ELSE
			blanks = 0
			excess = 0
	END SELECT
'
	backToken = lastToken
	lastToken = token
	lastToken.tp.stsp = 0
	IFZ tokenPtr THEN
		declareFuncaddrLine = $$FALSE
		IF (AlloToken(lastToken) OR TypeToken(lastToken)) THEN
			declareAlloTypeLine = $$TRUE
		ELSE
			declareAlloTypeLine = $$FALSE
		END IF
	END IF
	IF declareAlloTypeLine THEN
		IF TokenMatch (@lastToken, @#T_FUNCADDR) THEN declareFuncaddrLine = $$TRUE
	END IF
'
	INC tokenPtr
	tokens[tokenPtr]  = token
	charpos[tokenPtr] = charPtr
'
'  This to be rewritten for more than 127 spaces +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'
'
'  If (>3) spaces or (>4) tabs, output whitespace token
'
' IF excess THEN
'   INC tokenPtr                 ' should not come here *********
'   tokens[tokenPtr].tproto = excess
'   charpos[tokenPtr] = charPtr
' END IF
	RETURN
'
END FUNCTION
'
'
' ############################
' #####  ParseSymbol ()  #####
' ############################
'
FUNCTION  TOKEN ParseSymbol ()
	TOKEN   token
	SHARED  charPtr,  func_number,  tokenPtr
	SHARED  declareFuncaddrLine
	SHARED  rawline$,  hfn$
	SHARED UBYTE charsetUpperLower[]
	SHARED UBYTE charsetUpperLowerNumeric[]
	SHARED UBYTE charsetSpaceTab[]
	SHARED  XERROR, ERROR_COMPILER
	SHARED  TOKEN  backToken
	SHARED  TOKEN  lastToken
'
' Collect the symbol
'
	symbol$ = GetSymbol$ (@symbolInfo)
	charV = rawline${charPtr}
'
' See if symbol is a keyword
'
	SELECT CASE symbolInfo
		CASE $$NORMAL_SYMBOL     : token = TestForKeyword (@symbol$)     ' 0
		CASE $$LOCAL_CONSTANT    : token = TestForKeyword (@symbol$)     ' 1 $Constant
		CASE $$GLOBAL_CONSTANT   : token = TestForKeyword (@symbol$)     ' 2 $$Constant
		CASE $$EXTERNAL_VARIABLE : scope = $$EXTERNAL                    ' 4 ##Extern
		CASE $$SHARED_VARIABLE   : scope = $$SHARED                      ' 3 #Shared
		CASE $$SOLO_POUND        : token = #T_POUND                      ' 5 solo #
'   CASE $$DUAL_POUND        : ParseOutToken (T_POUND)               ' 6 dual ##
																token = #T_POUND
		CASE $$COMPONENT         :   ' 7 not a keyword
		CASE ELSE                : XcowlErr (790036): GOTO eeeCompiler
	END SELECT
'
	IFZ symbol$ THEN
		ParseOutToken (token)     ' non-symbol
		RETURN (token)            ' ERROR: no symbol
	END IF
'
	IFF TokenMatch (@token, @#T_ZERO) THEN
		ParseOutToken (token)     ' got token already
		RETURN (token)
	END IF
'
	char0 = symbol${0}          ' 1st byte in symbol
	char1 = symbol${1}          ' 2nd byte in symbol
'
' 1st and 2nd tokens on line need special attention
'
	SELECT CASE tokenPtr
		CASE 0 : IF ((charV = ':') AND (LEN(symbol$) = charPtr)) THEN  ' label:
'               symbol$ = ".g." + symbol$ + "." + hfn$                ' gas ?
								symbol$ = $$GOTOlead$ + symbol$ + $$ulpc$ + hfn$                ' unspas
								token = AddLabel (@symbol$, $$KIND_LABELS, $$GOADDR, $$XADD)
								IF XERROR THEN EXIT FUNCTION
								ParseOutToken (@token)
								INC charPtr
								RETURN (token)
							END IF
		CASE 1 : SELECT CASE TRUE
								CASE TokenMatch(@lastToken, @#T_TYPE), TokenMatch(@lastToken, @#T_PACKED):
										first = symbol${0}
										final = rawline${charPtr-1}
										IF charsetUpperLower[first] THEN
											IF charsetUpperLowerNumeric[final] THEN
												token = AddSymbol (@symbol$, 0, $$KIND_TYPES, 0, 0, 0)
												ParseOutToken (token)
												RETURN (token)
											END IF
										END IF
								CASE TokenMatch(@lastToken, @#T_IMPORT): PRINT "Hello IMPORT"         ' what is this ???????????????
							END SELECT
	END SELECT
'
' Certain symbols are interpreted differently if following certain tokens
'
	SELECT CASE TRUE
		CASE TokenMatch (@lastToken, @#T_GOTO)                                   ' GOTO label
'     symbol$ = ".g." + symbol$ + "." + hfn$            ' gas ?
			symbol$ = $$GOTOlead$ + symbol$ + $$ulpc$ + hfn$
			token = AddLabel (@symbol$, $$KIND_LABELS, $$GOADDR, $$XADD)
			IF XERROR THEN EXIT FUNCTION
			ParseOutToken (@token)
			RETURN (token)
		CASE TokenMatch (@lastToken, @#T_GOSUB), TokenMatch (@lastToken, @#T_SUB):  ' SUB/GOSUB subname
'     symbol$ = ".s." + symbol$ + "." + hfn$            ' gas ?
			symbol$ = $$SUBlead$ + symbol$ + $$ulpc$ + hfn$           ' unspas
			token = AddLabel (@symbol$, $$KIND_LABELS, $$SUBADDR, $$XADD)
			ParseOutToken (@token)
			RETURN (token)
		CASE TokenMatch (@lastToken, @#T_LPAREN):
'     SELECT CASE backToken
			SELECT CASE TRUE
				CASE TokenMatch (@backToken, @#T_GOADDRESS)                        ' GOADDRESS (label)
'         symbol$ = ".g." + symbol$ + "." + hfn$        ' gas ?
					symbol$ = $$GOTOlead$ + symbol$ + $$ulpc$ + hfn$        ' unspas
					token = AddLabel (@symbol$, $$KIND_LABELS, $$GOADDR, $$XADD)
					IF XERROR THEN EXIT FUNCTION
					ParseOutToken (@token)
					RETURN (token)
				CASE TokenMatch (@backToken, @#T_SUBADDRESS)                       ' SUBADDRESS (subname)
'         symbol$ = ".s." + symbol$ + "." + hfn$        ' gas ?
					symbol$ = $$SUBlead$ + symbol$ + $$ulpc$ + hfn$       ' unspas
					token = AddLabel (@symbol$, $$KIND_LABELS, $$SUBADDR, $$XADD)
					IF XERROR THEN EXIT FUNCTION
					ParseOutToken (@token)
					RETURN (token)
			END SELECT
		CASE ELSE
	END SELECT
'
' Symbols that begin with certain characters require special attention
'
	IF (char0 = '.') THEN                                                       ' ASC(46)  .COMPONENT name
		sx = 0
		test_char = rawline${charPtr + sx}
		DO WHILE ((test_char = ' ') OR (test_char = '\t'))  ' space or tab
			INC sx
			test_char = rawline${charPtr + sx}
		LOOP
'
		testing_done = $$TRUE
		SELECT CASE test_char
			CASE 0   : token.tproto = $$TP_SYMBOLS                                 ' end
			CASE 39  : token.tproto = $$TP_SYMBOLS                                 ' comment
			CASE '[' : token.tproto = $$TP_ARRAY_SYMBOLS                           ' array
			CASE '(' : token.tproto = $$TP_SYMBOLS
			CASE ELSE: IFZ func_number THEN
										testing_done = $$FALSE
									ELSE
										token.tproto = $$TP_SYMBOLS
									END IF
		END SELECT
'
		IF testing_done THEN
			spaces = token.tp.stsp
			kind   = token.tp.kind
			allo   = token.tp.allo
			type   = token.tp.type
			token = AddSymbol (symbol$, spaces, kind, allo, type, f_number)
			ParseOutToken (token)
			RETURN (token)
		END IF
	END IF
'
' Check for $LocalConstants and $$SharedConstants
'
	symbolLength = LEN(symbol$)
	IF (char0 = '$') THEN                                   ' ASC(36)
		charV = rawline${charPtr}
		IF (charV = '$') THEN                                 ' ASC(36)
			symbol$ = symbol$ + CHR$(charV)                     ' string $$SYSCON$
			sysconscope = $$EXTERNAL
			locconscope = $$SHARED
			type = $$STRING
			INC charPtr
		END IF
		IF (symbolLength = 1) THEN
			ParseOutToken (#T_DOLLAR)                           ' symbol is "$"   ***** ?????
			RETURN (#T_DOLLAR)
		END IF
		IF (char1 = '$') THEN                                 ' ASC(36)
			IF (symbolLength = 2) THEN
				ParseOutToken (#T_DOLLAR)
				ParseOutToken (#T_DOLLAR)                         ' symbol is "$$"
				RETURN (#T_DOLLAR)
			END IF
			token = AddSymbol (@symbol$, 0, $$KIND_SYSCONS, sysconscope, type, func_number)
			ParseOutToken (token)
			RETURN (token)
		ELSE
			IF (symbol$ = "$XERROR") THEN
				kind = $$KIND_VARIABLES                           ' $XERROR
				scope = 0
				type = $$XLONG
			ELSE
				kind  = $$KIND_CONSTANTS                          ' $LOCAL_CONSTANT
				scope = locconscope
'       type  = $$STRING
			END IF
			token = AddSymbol (@symbol$, 0, kind, scope, type, func_number)   ' $CONSTANTS
			ParseOutToken (token)
			RETURN (token)
		END IF
	END IF
'
' Normal symbols can have type suffix characters
'
	IF (char0 = '#') THEN
		scope = $$SHARED
		IF (char1 = '#') THEN scope = $$EXTERNAL    'ASC(35)
	END IF
	SELECT CASE charV
		CASE '@' : symbol$ = symbol$ + "@"         'ASC(64)
								data_type = $$SBYTE
								INC charPtr
								charV = rawline${charPtr}
								IF (charV = '@') THEN
									symbol$ = symbol$ + "@"
									data_type = $$UBYTE
									INC charPtr
								END IF
		CASE '%' : symbol$ = symbol$ + "%"         'ASC(37)
								data_type = $$SSHORT
								INC charPtr
								charV = rawline${charPtr}
								IF (charV = '%') THEN
									symbol$ = symbol$ + "%"       'ASC(37)
									data_type = $$USHORT
									INC charPtr
								END IF
		CASE '&' : symbol$ = symbol$ + "&"         'ASC(38)
								data_type = $$SLONG
								INC charPtr
								charV = rawline${charPtr}
								IF (charV = '&') THEN
									symbol$ = symbol$ + "&"       'ASC(38)
									data_type = $$ULONG
									INC charPtr
								END IF
		CASE '~' : symbol$ = symbol$ + "~"         'ASC(126)
								data_type = $$XLONG
								INC charPtr
		CASE '!' : symbol$ = symbol$ + "!"         'ASC(33)
								data_type = $$SINGLE
								INC charPtr
		CASE '#' : symbol$ = symbol$ + "#"         'ASC(35)
								data_type = $$DOUBLE
								INC charPtr
		CASE '$' : symbol$ = symbol$ + "$"         'ASC(36)
								data_type = $$STRING
								INC charPtr
								charV = rawline${charPtr}
								IF (charV = '$') THEN
									symbol$ = symbol$ + "$"       'ASC(36)
									data_type = $$GIANT
									INC charPtr
								END IF
		CASE ELSE: data_type = 0
	END SELECT
'
' See what follows trailing spaces/tabs
'
pass_out:
	sx = 0
	test_char = rawline${charPtr + sx}
	DO WHILE (charsetSpaceTab[test_char])     ' skip <spaces> and <tabs>
		INC sx
		test_char = rawline${charPtr + sx}
	LOOP
'
' See if this is an array or function symbol
'
	SELECT CASE test_char
		CASE '(':   IF scope THEN NEXT CASE
								IF (declareFuncaddrLine OR TokenMatch (@lastToken, @#T_ATSIGN)) THEN
									token.tp.kind = $$KIND_VARIABLES
									token.tp.type = data_type
								ELSE
									token.tp.kind = $$KIND_FUNCTIONS
									token.tp.type = data_type
								END IF
		CASE '[':   token.tp.kind = $$KIND_ARRAYS
								token.tp.allo = scope
								token.tp.type = data_type
		CASE ELSE:  token.tp.kind = $$KIND_VARIABLES
								token.tp.allo = scope
								token.tp.type = data_type
	END SELECT
	spaces = token.tp.stsp
	kind   = token.tp.kind
	allo   = token.tp.allo
	type   = token.tp.type
	token = AddSymbol (symbol$, spaces, kind, allo, type, func_number)
	ParseOutToken (token)
	RETURN (token)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ###########################
' #####  ParseWhite ()  #####
' ###########################
'
FUNCTION  TOKEN ParseWhite ()
	TOKEN   token
	SHARED  charPtr,  rawline$
	SHARED  XERROR,  ERROR_COMPILER
'
	charV = rawline${charPtr}
	SELECT CASE charV
		CASE ' ':
			DO WHILE (charV = ' ')      ' space character
				INC spaces
				INC charPtr
				charV = rawline${charPtr}
			LOOP
		CASE '\t':
			DO WHILE (charV = '\t')     ' tab character
				INC tabs
				INC charPtr
				charV = rawline${charPtr}
			LOOP
			spaces = -tabs
		CASE ELSE
			PRINT "www"
			XcowlErr (800029): GOTO eeeCompiler
	END SELECT
	token.tp.kind = $$KIND_WHITES
	token.tp.stsp = spaces
	ParseOutToken (@token)
	RETURN (token)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #############################
' #####  PassCfuncArg ()  #####
' #############################
'
FUNCTION  PassCfuncArg (FUNCARG farg, argNum)
	TOKEN   token
	SHARED  XERROR
	SHARED  ERROR_BYREF, ERROR_COMPILER
	SHARED  ERROR_TYPE_MISMATCH
	SHARED  SSHORT  typeConvert[]
'
	token = farg.token
	stack = farg.stack
	argType = farg.argType
	varType = farg.varType
	tt = token.tindex
'
	SELECT CASE argNum
		CASE 0    : destin = $$rdi
		CASE 1    : destin = $$rsi
		CASE 2    : destin = $$rdx
		CASE 3    : destin = $$rcx
		CASE 4    : destin = $$r8
		CASE 5    : destin = $$r9
		CASE ELSE : destin = 0           'push onto stack
	END SELECT
'
	SELECT CASE farg.kind
		CASE $$KIND_ARRAYS
					IFZ farg.byRef THEN XcowlErr (810032): GOTO eeeByRef
					Move (0, $$XLONG, token.tindex, $$XLONG)
		CASE $$KIND_VARIABLES
					IF ((argType > 31) OR (varType > 31)) THEN
						IF (argType != varType) THEN XcowlErr (810036): GOTO eeeTypeMismatch
						argType = $$XLONG
						varType = $$XLONG
					END IF
					conv = typeConvert[argType,varType] {{$$BYTE0}}
					SELECT CASE conv
						CASE -1  : XcowlErr (810042): GOTO eeeTypeMismatch
						CASE  0  : IF TokenMatch (@token, @#T_ZERO) THEN
													Pop (destin, varType)
												ELSE
													Move (destin, varType, token.tindex, varType)
												END IF
						CASE ELSE: IF TokenMatch (@token, @#T_ZERO) THEN
													Pop ($$rax, varType)
												ELSE
													Move ($$rax, varType, token.tindex, varType)
												END IF
												token.tindex = $$eax
												token.tproto = 0
												Conv ($$rax, argType, $$rax, varType)
												SELECT CASE argType
													CASE $$DOUBLE  : Code ($$sub, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"1101")
																					: Code ($$fstp, $$ro, 0, $$rsp, 0, $$DOUBLE, "", $$rmk$+"1102")
													CASE $$SINGLE  : Code ($$sub, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"1103")
																					: Code ($$fstp, $$ro, 0, $$rsp, 0, $$SINGLE, "", $$rmk$+"1104")
													CASE ELSE      : Code ($$push, $$reg, $$rax, 0, 0, argType, "", $$rmk$+"1105")
												END SELECT
					END SELECT
		CASE $$KIND_LITERALS, $$KIND_SYSCONS, $$KIND_CONSTANTS, $$KIND_CHARCONS
					LoadLitnum (destin, argType, token.tindex, varType)
		CASE ELSE
					XcowlErr (810067): GOTO eeeCompiler
	END SELECT
	RETURN
'
eeeByRef:
	XERROR = ERROR_BYREF
	EXIT FUNCTION
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ##########################
' #####  PeekToken ()  #####
' ##########################
'
FUNCTION  PeekToken (TOKEN token)
	SHARED  typeAlias[]
	SHARED  tokenCount,  tokenPtr
	SHARED  TOKEN  funcToken[]
	SHARED  TOKEN  tab_sym[]
	SHARED  TOKEN  tokens[]
	SHARED  TOKEN  typeToken[]
	STATIC GOADDR  kindDispatch[]
'
	IFZ kindDispatch[] THEN GOSUB LoadKindDispatch    ' load dispatch table
	htp = tokenPtr
'
skip_whities:
	INC tokenPtr
	IF (tokenPtr >= tokenCount) THEN
		token.tproto = $$TP_STARTS
		token.tindex = $$TI_ZERO
		RETURN
	END IF
	token.tproto = tokens[tokenPtr].tproto
	token.tindex = tokens[tokenPtr].tindex
	token.tp.stsp = 0
	tt= token.tindex
	GOTO @kindDispatch[token.tp.kind]
	tokenPtr = htp
	RETURN
'
from_tab_sym:
	tokenPtr = htp
	token.tproto = tab_sym[tt].tproto
	token.tindex = tab_sym[tt].tindex
	RETURN
'
from_func_sym:
	tokenPtr = htp
	token.tproto = funcToken[tt].tproto
	token.tindex = funcToken[tt].tindex
	RETURN
'
them_comments:
	tokenPtr = htp
	token.tproto = $$TP_STARTS
	token.tindex = $$TI_ZERO
	RETURN
'
from_types:
	tokenPtr = htp
	ttt = typeAlias[tt]
	IF ttt THEN tt = ttt
	token.tproto = typeToken[tt].tproto
	token.tindex = typeToken[tt].tindex
	RETURN
'
'
SUB LoadKindDispatch
	DIM kindDispatch[31]
	kindDispatch[ $$KIND_SYMBOLS       ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_ARRAY_SYMBOLS ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_VARIABLES     ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_ARRAYS        ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_SYSCONS       ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_LITERALS      ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_CONSTANTS     ] = GOADDRESS (from_tab_sym)
	kindDispatch[ $$KIND_FUNCTIONS     ] = GOADDRESS (from_func_sym)
	kindDispatch[ $$KIND_COMMENTS      ] = GOADDRESS (them_comments)
	kindDispatch[ $$KIND_WHITES        ] = GOADDRESS (skip_whities)
	kindDispatch[ $$KIND_TYPES         ] = GOADDRESS (from_types)
END SUB
END FUNCTION
'
'
' ####################
' #####  Pop ()  #####
' ####################
'
FUNCTION  Pop (d_reg, d_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   xdata
	SHARED  TOKEN  stackData[]
	SHARED  stackType[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  toms,  a0_type,  a1_type
'
	DEC toms
	IF (toms < 0) THEN XcowlErr (830016): GOTO eeeCompiler
	IF (d_type < $$SLONG) THEN d_type = $$SLONG
'
	SELECT CASE d_reg
		CASE $$RA0: a0_type = d_type
		CASE $$RA1: a1_type = d_type
	END SELECT
'
	xdata = stackData[toms]
	xtype = stackType[toms]
'
	IF d_reg THEN
		IF ((d_type != $$SINGLE) AND (d_type != $$DOUBLE)) THEN
			Move (d_reg, d_type, xdata.tindex, d_type)
		END IF
	ELSE
		IF ((d_type = $$SINGLE) | (d_type = $$DOUBLE)) THEN
'			IF d_type = $$SINGLE THEN                                         '*cw* 230217
'				dsize = 4                                                       '*cw* 230217
'			ELSE                                                              '*cw* 230217
				dsize = 8
'			END IF                                                            '*cw* 230217
			Code ($$sub, $$regimm, $$rsp, dsize, 0, $$XLONG, "", $$rmk$+"1073")
			Code ($$fstp, $$ro, 0, $$rsp, 0, d_type, "", $$rmk$+"1074")
		ELSE
			Move (d_reg, d_type, xdata.tindex, d_type)
		END IF
	END IF
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ###########################
' #####  PrintError ()  #####
' ###########################
'
' Return TRUE if user requests Quit
'
FUNCTION  PrintError (err)
	EXTERNAL /xxx/  errorCount
	TOKEN   token
	SHARED  xerror$[],  charpos[]
	SHARED  XERROR,  rawLength,  rawline$,  tokenPtr,  lineNumber,  uerror
	SHARED  a0,  a0_type,  a1,  a1_type,  toes,  toms,  oos
	SHARED UBYTE oos[]
	SHARED  abort
'
	IF abort THEN RETURN $$TRUE
'
	IF (err <= 0) THEN XcowlErr (840020): GOTO eeePrintError
	IF (err > uerror) THEN XcowlErr (840021): GOTO eeePrintError
	error_message$ = xerror$[err]
	tp = tokenPtr
	rawline$  = Deparse$($$rmk1$ + " ")
	rawLength = LEN(rawline$)
	pointer   = charpos[tp]
	IF rawline$ THEN
		i = 0
		newPointer = -1
		lenRawline = LEN(rawline$)
		DO WHILE (i < lenRawline)
			INC newPointer
			rawChar = rawline${i}
			IF (rawChar = '\t') THEN
				IF (newPointer AND 1) THEN
					INC newPointer
					newRawline$ = newRawline$ + "  "        ' two spaces
				ELSE
					newRawline$ = newRawline$ + " "         ' one space
				END IF
			ELSE
				newRawline$ = newRawline$ + CHR$(rawChar)
			END IF
			IF (i <= pointer) THEN tokenPointer = newPointer
			INC i
		LOOP
	END IF
	PRINT newRawline$
	INC tokenPointer
	IF (tokenPointer > 77) THEN
		pointer = 77
	ELSE
		pointer = tokenPointer
	END IF
	IF (pointer > 2) THEN
		PRINT "; "; SPACE$(pointer - 3) + "|"
	ELSE
		PRINT "; |"
	END IF
'
	message_length = LEN(error_message$)
	half_message_length = message_length >> 1
	start_message = pointer - half_message_length
	IF (pointer + half_message_length) > 77 THEN
		start_message = 77 - message_length
	END IF
	IF (start_message < 1) THEN start_message = 0
'
	PRINT "; "; SPACE$(start_message) + error_message$
	PRINT "; "; SPACE$(start_message) + "on line"; lineNumber
	ParseOutError (@token)
	INC errorCount
	a$ = INLINE$ ("*****  Press RETURN to continue  (q to quit)  *****")
	XERROR  = 0
	toes    = 0
	toms    = 0
	oos     = 0
	oos[0]  = 0
	a0      = 0
	a1      = 0
	a0_type = 0
	a1_type = 0
	IF a$ THEN
		a$ = TRIM$(LCASE$(a$))
		IF LEFT$(a$, 1) = "q" THEN abort = $$TRUE: RETURN ($$TRUE)
	END IF
	RETURN ($$FALSE)
'
eeePrintError:
	XERROR = 0
	EXIT FUNCTION
END FUNCTION
'
'
' ############################
' #####  PrintTokens ()  #####
' ############################
'
FUNCTION  PrintTokens ()
	SHARED TOKEN tokens[]
'
	IF tokens[] THEN
		FOR x = 0 TO tokens[0].ti.ndex
			PRINT HEX$(tokens[x].tproto, 8);".";HEX$(tokens[x].tindex, 8);;;
		NEXT x
		PRINT
	END IF
END FUNCTION
'
'
' #########################
' #####  Printoid ()  #####
' #########################
'
FUNCTION  TOKEN Printoid ()
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN   token, dtoken, ftoken
	SHARED  q_type_long[],  typeName$[],  m_addr$[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_SYNTAX,  ERROR_TYPE_MISMATCH
	SHARED  a0,  a0_type,  a1,  a1_type,  oos,  toes
	SHARED  inPrint,  tokenPtr
	SHARED UBYTE oos[]
	SHARED func_number
	STATIC GOADDR printKind[]
'
	IFZ printKind[] THEN GOSUB LoadPrintKind
'
	zippo = $$FALSE
	inPrint = $$TRUE
	first_arg = $$TRUE
	free_after = $$TRUE
	add_newline = $$TRUE
	NextToken (@token)
	tkind = token.tp.kind
	IF TokenMatch (@token, @#T_LBRAK) THEN
		token = Eval (@result_type)
		IF (result_type > $$XLONG) THEN XcowlErr (860029): GOTO eeeTypeMismatch
		IFF q_type_long[result_type] THEN XcowlErr (860030): GOTO eeeTypeMismatch
		acc = Topax1 ()
		IFZ acc THEN XcowlErr (860032): GOTO eeeSyntax
		IFF TokenMatch (@token, @#T_RBRAK) THEN XcowlErr (860033): GOTO eeeSyntax        ' PRINT[ofile]
		NextToken (@token)                                ' token after "]"
		tkind = token.tp.kind
		SELECT CASE tkind
			CASE $$KIND_STARTS     : zippo = $$TRUE
			CASE $$KIND_COMMENTS   : zippo = $$TRUE
			CASE $$KIND_TERMINATORS: zippo = $$TRUE
			CASE $$KIND_SEPARATORS : NextToken (@token)
																tkind = token.tp.kind
																SELECT CASE tkind
																	CASE $$KIND_STARTS:       XcowlErr (860043): GOTO eeeSyntax
																	CASE $$KIND_COMMENTS:     XcowlErr (860044): GOTO eeeSyntax
																	CASE $$KIND_TERMINATORS:  XcowlErr (860045): GOTO eeeSyntax
																END SELECT
			CASE ELSE              : XcowlErr (860047): GOTO eeeSyntax
		END SELECT
		IF zippo THEN
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_PrintFileNewline", $$rmk$+"1075")
			RETURN (token)
		END IF
	ELSE
		symbol$ = ".filenumber"
		ftoken = AddSymbol (@symbol$, 0, $$KIND_VARIABLES, $$AUTOX, $$XLONG, func_number)
		fnum = ftoken.tindex
		IFZ m_addr$[fnum] THEN AssignAddress (ftoken)
		IF XERROR THEN EXIT FUNCTION
		SELECT CASE tkind
			CASE $$KIND_STARTS:       zippo = $$TRUE
			CASE $$KIND_COMMENTS:     zippo = $$TRUE
			CASE $$KIND_TERMINATORS:  zippo = $$TRUE
		END SELECT
		IF zippo THEN
			Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_PrintConsoleNewline", $$rmk$+"1076")
			RETURN (token)
		END IF
		Code ($$push, $$imm, 1, 0, 0, $$XLONG, "", $$rmk$+"1077")
		noPush = $$TRUE
	END IF
'
	IFZ noPush THEN Code ($$push, $$reg, acc, 0, 0, $$XLONG, "", $$rmk$+"1078")
	Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"1079")
'
'
'
print_loopie:
	lastk = kind
	kind  = token.tp.kind
	GOTO @printKind[kind]           ' dispatch based on kind
	XcowlErr (860081): GOTO eeeSyntax
'
'
' *****  routines invoked through "GOTO @printKind [kind]" above  *****
'
print_character:
	IF TokenMatch (@token, @#T_ATSIGN) THEN GOTO print_last_data
	XcowlErr (860088): GOTO eeeSyntax
'
' *****  append data expression to print string  *****
'
print_last_data:
	DEC tokenPtr
print_data:
	dtoken = token
	token = Eval (@new_type)
	IF XERROR THEN
		inPrint = $$FALSE
		EXIT FUNCTION
	END IF
	IF (new_type >= $$SCOMPLEX) THEN XcowlErr (8600101): GOTO eeeTypeMismatch
	acc = Topx (@xreg, @xregx, @oreg, @oregx)
'
' if expression was TAB(value), do special TAB routine, otherwise concatenate
'
	IF TokenMatch (@dtoken, @#T_TAB) THEN
		SELECT CASE acc
			CASE $$RA0
				a0_type = $$STRING
				IF first_arg THEN
					routine$ = $$ulpc$+"_print.tab.first.a0"
				ELSE
					IF (oreg = 0) AND (toes = 2) THEN
						Pop ($$RA1, $$STRING)
						a1 = toes - 1
					END IF
					routine$ = $$ulpc$+"_print.tab.a0.eq.a1.tab.a0"
				END IF
			CASE $$RA1
				a1_type = $$STRING
				IF first_arg THEN
					routine$ = $$ulpc$+"_print.tab.first.a1"
				ELSE
					IF (oreg = 0) AND (toes = 2) THEN
						Pop ($$RA0, $$STRING)
						a0 = toes - 1
					END IF
					routine$ = $$ulpc$+"_print.tab.a0.eq.a0.tab.a1"
				END IF
			CASE ELSE
				XcowlErr (8600131): GOTO eeeCompiler
		END SELECT
		INC oos
		oos[oos] = 's'
		new_type = $$STRING
	ELSE
		SELECT CASE acc
			CASE $$RA0
				IF (oreg = 0) AND (toes = 2) THEN
					Pop ($$RA1, $$STRING)
					a1 = toes - 1
					oreg = $$RA1
				END IF
				routine$ = $$ulpc$+"_concat.ubyte.a0.eq.a1.plus.a0.ss"
			CASE $$RA1
				IF (oreg = 0) AND (toes = 2) THEN
					Pop ($$RA0, $$STRING)
					a0 = toes - 1
					oreg = $$RA0
				END IF
				routine$ = $$ulpc$+"_concat.ubyte.a0.eq.a0.plus.a1.ss"
			CASE ELSE
				XcowlErr (8600153): GOTO eeeCompiler
		END SELECT
	END IF
'
' I think there's a stack tangle problem below on complex expressions !!!
'
	IF (new_type != $$STRING) THEN
		IF oreg THEN Code ($$push, $$reg, oreg, 0, 0, $$XLONG, "", $$rmk$+"1080")
		Code ($$sub, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"1081")
		SELECT CASE new_type
			CASE $$SINGLE, $$DOUBLE
						Code ($$fstp, $$ro, 0, $$rsp, 0, new_type, "", $$rmk$+"1082")
			CASE ELSE
						Code ($$st, $$roreg, xreg, $$rsp, 0, $$XLONG, "", $$rmk$+"1085")
		END SELECT
		dest$ = $$ulpc$+"_str.d." + typeName$[new_type AND 0x1F]
		Code ($$call, $$rel, 0, 0, 0, 0, dest$, $$rmk$+"1086")
		Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"1087")
		IF (acc != $$rax) THEN
			Code ($$mov, $$regreg, acc, $$rax, 0, $$XLONG, "", $$rmk$+"1088")
		END IF
		IF oreg THEN
			Code ($$pop, $$reg, oreg, 0, 0, $$XLONG, "", $$rmk$+"1089")
		END IF
		INC oos
		oos[oos] = 's'
		a0_type = $$STRING
	END IF
'
	IF first_arg THEN
		IF TokenMatch (@dtoken, @#T_TAB) THEN
			Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"1090")
		END IF
	ELSE
		Code ($$call, $$rel, 0, 0, 0, 0, routine$, $$rmk$+"1091")
		DEC toes
		a0 = toes
		a0_type = $$STRING
		a1 = 0
		a1_type = 0
		DEC oos
		oos[oos] = 's'
	END IF
	first_arg = $$FALSE
	add_newline = $$TRUE
	GOTO print_loopie
'
print_separator:
	oneSemi = $$FALSE
	SELECT CASE TRUE
		CASE TokenMatch (@token, @#T_COMMA)
			IF first_arg THEN
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_PrintFirstComma", $$rmk$+"1092")
				INC toes
				a0 = toes
				a0_type = $$STRING
				INC oos
				oos[oos] = 's'
			ELSE
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_PrintAppendComma", $$rmk$+"1093")
				a0 = toes
				a0_type = $$STRING
				oos[oos] = 's'
			END IF
		CASE TokenMatch (@token, @#T_SEMI)
			semiCount = 0
			DO
				INC semiCount
				stp = tokenPtr
				NextToken (@token)
			LOOP WHILE TokenMatch (@token, @#T_SEMI)
			tokenPtr = stp
			DEC semiCount
			IFZ semiCount THEN      ' one semi-colon does nothing
				oneSemi = $$TRUE
				EXIT SELECT
			END IF
			semiCount$ = STRING(semiCount)
			IF first_arg THEN
				Code ($$mov, $$regimm, $$rbx, semiCount, 0, $$XLONG, "", $$rmk$+"1094")
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_PrintFirstSpaces", $$rmk$+"1095")
				INC toes
				a0 = toes
				a0_type = $$STRING
				INC oos
				oos[oos] = 's'
			ELSE
				Code ($$mov, $$regimm, $$rbx, semiCount, 0, $$XLONG, "", $$rmk$+"1096")
				Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_PrintAppendSpaces", $$rmk$+"1097")
			END IF
	END SELECT
	IFZ oneSemi THEN first_arg = $$FALSE
	add_newline = $$FALSE
	NextToken (@token)
	GOTO print_loopie
'
print_line:
print_terminator:
	Code ($$add, $$regimm, $$rsp, 128, 0, $$XLONG, "", $$rmk$+"1098")
	IFZ first_arg THEN
		IF add_newline THEN
			p$ = $$ulpc$+"_PrintWithNewlineThenFree"
		ELSE
			p$ = $$ulpc$+"_PrintThenFree"
		END IF
		Code ($$call, $$rel, 0, 0, 0, 0, p$, $$rmk$+"1099")
	END IF
	Code ($$add, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"1100")
	inPrint = $$FALSE
	IFZ first_arg THEN DEC oos
	toes = 0: a0 = 0: a0_type = 0: a1 = 0: a1_type = 0
	RETURN (token)
'
'
' ************************************************************************
' *****  Load printKind[] with routines to print various token kinds *****
' ************************************************************************
'
SUB LoadPrintKind
	DIM printKind[31]
	printKind[ $$KIND_STATE_INTRIN ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_INTRINSICS   ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_BINARY_OPS   ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_UNARY_OPS    ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_VARIABLES    ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_CONSTANTS    ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_FUNCTIONS    ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_LITERALS     ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_CHARCONS     ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_LPARENS      ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_SYSCONS      ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_ARRAYS       ] = GOADDRESS (print_last_data)
	printKind[ $$KIND_STARTS       ] = GOADDRESS (print_terminator)
	printKind[ $$KIND_COMMENTS     ] = GOADDRESS (print_terminator)
	printKind[ $$KIND_STATEMENTS   ] = GOADDRESS (print_terminator)
	printKind[ $$KIND_TERMINATORS  ] = GOADDRESS (print_terminator)
	printKind[ $$KIND_SEPARATORS   ] = GOADDRESS (print_separator)
	printKind[ $$KIND_CHARACTERS   ] = GOADDRESS (print_character)
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	inPrint = $$FALSE
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	inPrint = $$FALSE
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	inPrint = $$FALSE
	EXIT FUNCTION
END FUNCTION
'
'
' #####################
' #####  Push ()  #####
' #####################
'
FUNCTION  Push (sreg, stype)
	TOKEN   xtoken
	SHARED  TOKEN  stackData[]
	SHARED  TOKEN  tab_sym[]
	SHARED  m_addr$[]
	SHARED  stackType[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  toms,  a0,  a0_type,  a1,  a1_type
	SHARED  func_number,  hfn$
'
	s_reg = sreg
	s_type = stype
	IF (s_type < $$XLONG) THEN s_type = $$XLONG
	xname$ = ".xstk" + hfn$ + "." + HEX$(toms, 4)
	xtoken = AddSymbol (@xname$, 0, $$KIND_VARIABLES, $$AUTOX, $$DOUBLE, func_number)
	xtoken.tp.allo = $$AUTOX                                                          'is this necessary ?????
	xx = xtoken.tindex
	tab_sym[xx] = xtoken
	IFZ m_addr$[xx] THEN AssignAddress (xtoken)
	IF XERROR THEN RETURN
	SELECT CASE s_reg
		CASE $$RA0: a0 = 0: a0_type = 0
		CASE $$RA1: a1 = 0: a1_type = 0
		CASE ELSE:  XcowlErr (870030): GOTO eeeCompiler
	END SELECT
	stackData[toms] = xtoken
	stackType[toms] = s_type
	INC toms
	IF ((stype = $$SINGLE) | (stype = $$DOUBLE)) THEN RETURN
	Move (xtoken.tindex, s_type, s_reg, s_type)
	RETURN
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ############################
' #####  PushXfuncArg ()  #####
' ############################
'
FUNCTION  PushXfuncArg (FUNCARG arg)
	TOKEN   token
	SHARED  XERROR
	SHARED  ERROR_BYREF, ERROR_COMPILER
	SHARED  ERROR_TYPE_MISMATCH
	SHARED  SSHORT  typeConvert[]
'
	token = arg.token
	stack = arg.stack
	argType = arg.argType
	varType = arg.varType
	tt = token.tindex
'
	SELECT CASE arg.kind
		CASE $$KIND_ARRAYS
					IFZ arg.byRef THEN XcowlErr (880022): GOTO eeeByRef
					Move (0, $$XLONG, token.tindex, $$XLONG)
		CASE $$KIND_VARIABLES
					IF ((argType > 31) OR (varType > 31)) THEN
						IF (argType != varType) THEN XcowlErr (880026): GOTO eeeTypeMismatch
						argType = $$XLONG
						varType = $$XLONG
					END IF
					conv = typeConvert[argType,varType] {{$$BYTE0}}
					SELECT CASE conv
						CASE -1  : XcowlErr (880032): GOTO eeeTypeMismatch
						CASE  0  : IF TokenMatch (@token, @#T_ZERO) THEN
													Pop (0, varType)
												ELSE
													Move (0, varType, token.tindex, varType)
												END IF
						CASE ELSE: IF TokenMatch (@token, @#T_ZERO) THEN
													Pop ($$rax, varType)
												ELSE
													Move ($$rax, varType, token.tindex, varType)
												END IF
												token.tindex = $$eax
												token.tproto = 0
												Conv ($$rax, argType, $$rax, varType)
												SELECT CASE argType
													CASE $$DOUBLE	: Code ($$sub, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"1101")
																				: Code ($$fstp, $$ro, 0, $$rsp, 0, $$DOUBLE, "", $$rmk$+"1102")
													CASE $$SINGLE	: Code ($$sub, $$regimm, $$rsp, 8, 0, $$XLONG, "", $$rmk$+"1103")
																				: Code ($$fstp, $$ro, 0, $$rsp, 0, $$SINGLE, "", $$rmk$+"1104")
													CASE ELSE     : Code ($$push, $$reg, $$rax, 0, 0, argType, "", $$rmk$+"1105")
												END SELECT
					END SELECT
		CASE $$KIND_LITERALS, $$KIND_SYSCONS, $$KIND_CONSTANTS, $$KIND_CHARCONS
					LoadLitnum (0, argType, token.tindex, varType)
		CASE ELSE
					XcowlErr (880057): GOTO eeeCompiler
	END SELECT
	RETURN
'
eeeByRef:
	XERROR = ERROR_BYREF
	EXIT FUNCTION
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ###########################
' #####  RangeCheck ()  #####
' ###########################
'
FUNCTION  RangeCheck (ctype, symbol$)
	SHARED  maxval#[],  minval#[]
'
	x# = DOUBLE (symbol$)
	IF (ctype = $$DOUBLE) THEN RETURN ($$TRUE)
	IF (x# < minval#[ctype]) OR (x# > maxval#[ctype]) THEN RETURN ($$TRUE)
	RETURN ($$FALSE)
END FUNCTION
'
'
' ####################
' #####  Reg ()  #####  Register, imm16, neg16, litnum, connum
' ####################
'
FUNCTION  Reg (xx)
	SHARED  r_addr[]
'
	IF (xx <= $$CONNUM) THEN RETURN (xx)
	RETURN (r_addr[xx])
END FUNCTION
'
'
' ########################
' #####  RegOnly ()  #####  Register Only  (not imm16, neg16, litnum, connum)
' ########################
'
FUNCTION  RegOnly (xx)
	SHARED  r_addr[]
'
	IF (xx < $$IMM16) THEN RETURN (xx)
	RETURN (r_addr[xx])
END FUNCTION
'
'
' ############################
' #####  ReturnValue ()  #####
' ############################
'
FUNCTION  TOKEN ReturnValue (returnType)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	TOKEN  new_op, new_data
	SHARED SSHORT typeConvert[]
	SHARED  r_addr[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_TYPE_MISMATCH,  ERROR_VOID
	SHARED  toes,  toms,  a0,  a0_type,  a1,  a1_type,  oos
	SHARED  func_number,  typeSize[]

	SHARED TOKEN crvtoken
	SHARED TOKEN funcToken[]
	SHARED UBYTE oos[]
'
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	funcType = TheType (funcToken[func_number])
	IF (new_type AND (funcType = $$VOID)) THEN XcowlErr (920026): GOTO eeeVoid
	IF (funcType >= $$SCOMPLEX) THEN GOTO returnComposite
	IF new_type THEN                                  ' something returned
		IF (new_type >= $$SCOMPLEX) THEN XcowlErr (920029): GOTO eeeTypeMismatch
		IFF TokenMatch (@new_data, @#T_ZERO) THEN       ' a token
			nn  = new_data.tindex                       ' nn = token #
			ro  = r_addr[nn]                              ' ro = register #
			rr  = ro                                      ' rr = ditto
			SELECT CASE typeConvert[funcType, new_type] {{$$BYTE0}}
				CASE -1:    XcowlErr (920035): GOTO eeeTypeMismatch                          ' error
				CASE  0:    Move ($$RA0, funcType, new_data.tindex, funcType)   ' data to RA0
				CASE ELSE:  IF rr THEN
											Conv ($$RA0, funcType, new_data.tindex, new_type) ' convert
										ELSE
											Move ($$RA0, new_type, new_data.tindex, new_type) ' data to RA0
											Conv ($$RA0, funcType, $$RA0, new_type)     ' convert
										END IF
			END SELECT
			IF (new_type = $$STRING) THEN           ' if token is string-type
				SELECT CASE new_data.tp.allo                ' ... and the allo is
					CASE $$AUTO, $$AUTOX: GOSUB ClearString   ' temp:  clear it
					CASE ELSE:            GOSUB CloneString   ' other: clone it
				END SELECT
			END IF
		ELSE
			top = Topax1 ()                               ' where's the data ???
			Conv ($$RA0, funcType, top, new_type)         ' put it in RA0
			IF (new_type = $$STRING) THEN                 ' if data is string-type
				IF (oos[oos] = 'v') THEN GOSUB CloneString  ' uncloned: clone it
			END IF
		END IF
	ELSE                                              ' no return expression
		SELECT CASE funcType
			CASE $$GIANT
						Code ($$xor, $$regreg, $$rdx, $$rdx, 0, $$XLONG, "", $$rmk$+"1106")
			CASE $$SINGLE, $$DOUBLE
						Code ($$fldz, 0, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1107")
			CASE ELSE
						Code ($$xor, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"1108")
		END SELECT
	END IF
	returnType = funcType
	oos   = 0:  oos[0]  = 0
	toes  = 0:  toms    = 0
	a0    = 0:  a0_type = 0
	a1    = 0:  a1_type = 0
	RETURN (new_op)
'
'
' *****  return composite data type  *****
'
returnComposite:
	IF TokenMatch (@crvtoken, @#T_ZERO) THEN XcowlErr (920078): GOTO eeeCompiler
	ts = typeSize[funcType]
	IF new_type THEN
		IF (new_type <> funcType) THEN XcowlErr (920081): GOTO eeeTypeMismatch
		Move ($$rdi, $$XLONG, crvtoken.tindex, $$XLONG)
		IFF TokenMatch (@new_data, @#T_ZERO) THEN                    ' a token
			Move ($$rsi, $$XLONG, new_data.tindex, $$XLONG)
		ELSE
			top = Topax1 ()
			Move ($$rsi, $$XLONG, top, $$XLONG)
		END IF
		Code ($$mov, $$regimm, $$rcx, ts, 0, $$XLONG, "", $$rmk$+"1109")
		Code ($$mov, $$regreg, $$rax, $$rdi, 0, $$XLONG, "", $$rmk$+"1110")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_assignComposite", $$rmk$+"1111")
	ELSE
		Move ($$rdi, $$XLONG, crvtoken.tindex, $$XLONG)
		Code ($$xor, $$regreg, $$rsi, $$rsi, 0, $$XLONG, "", $$rmk$+"1112")
		Code ($$mov, $$regimm, $$rcx, ts, 0, $$XLONG, "", $$rmk$+"1113")
		Code ($$mov, $$regreg, $$rax, $$rdi, 0, $$XLONG, "", $$rmk$+"1114")
		Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_assignComposite", $$rmk$+"1115")
	END IF
	oos   = 0:  oos[0]  = 0
	toes  = 0:  toms    = 0
	a0    = 0:  a0_type = 0
	a1    = 0:  a1_type = 0
	returnType = funcType
	RETURN (new_op)
'
' *****  supporting subroutines  *****
'
SUB ClearString
	IF ro THEN
		Code ($$xor, $$regreg, ro, ro, 0, $$XLONG, "", $$rmk$+"1116")
	ELSE
		Code ($$xor, $$regreg, $$rsi, $$rsi, 0, $$XLONG, "", $$rmk$+"1117")
		Move (new_data.tindex, $$XLONG, $$rsi, $$XLONG)
	END IF
END SUB
'
SUB CloneString
	Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_clone.a0", $$rmk$+"1118")
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
'
eeeVoid:
	XERROR = ERROR_VOID
	EXIT FUNCTION
END FUNCTION
'
'
' ###########################
' #####  ScopeToken ()  #####
' ###########################
'
' match = ScopeToken (token)
'
' match is returned TRUE if token matches one of the list of scope tokens
'
FUNCTION  ScopeToken (TOKEN token)
	SHARED TOKEN tab_sys[]
'
	STATIC tn_auto
	STATIC tn_autox
	STATIC tn_static
	STATIC tn_shared
	STATIC tn_external
'
	IF (token.tp.kind != $$KIND_STATEMENTS) THEN RETURN ($$FALSE)
'
	IFZ tn_external THEN GOSUB InitIntegers
'
	tnumber = token.tindex
	SELECT CASE tnumber
		CASE tn_auto    : return = $$AUTO
		CASE tn_autox   : return = $$AUTOX
		CASE tn_static  : return = $$STATIC
		CASE tn_shared  : return = $$SHARED
		CASE tn_external: return = $$EXTERNAL
		CASE ELSE       : RETURN ($$FALSE)
	END SELECT
	IF ((token.tproto AND 0x00FFFFFF) != tab_sys[tnumber].tproto) THEN
		PRINT "ScopeToken(34)", HEXX$(token.tproto), HEXX$(token.tindex)
		RETURN ($$FALSE)
	END IF
	RETURN (return)
'
'-------------------------------------------------------------------------------------
'
' *****  InitIntegers  *****
'
' The SELECT CASE works faster with integer values
'
SUB InitIntegers
		tn_auto     = #T_AUTO.tindex
		tn_autox    = #T_AUTOX.tindex
		tn_static   = #T_STATIC.tindex
		tn_shared   = #T_SHARED.tindex
		tn_external = #T_EXTERNAL.tindex
END SUB
'
END FUNCTION
'
'
' #########################
' #####  SignHex$ ()  #####
' #########################
'
FUNCTION  SignHex$ (GIANT value)
	SHARED  signhex64

	signhex64 = $$FALSE
	SELECT CASE TRUE
		CASE value > $$MAX_SLONG : signhex64 = $$TRUE
		CASE value < $$MIN_SLONG : signhex64 = $$TRUE
	END SELECT

	IF (value < 0) THEN
		IF (value < -1048576) THEN
			RETURN HEXX$(value)
		ELSE
			RETURN "-" + HEXX$(-value)
		END IF
	ELSE
		RETURN HEXX$(value)
	END IF

END FUNCTION
'
'
' ########################
' #####  Shuffle ()  #####
' ########################
'
FUNCTION  Shuffle (areg, oreg, atype, ptype, argTindex, kind, mode, argOffset)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED SSHORT typeConvert[]
'
	IF (kind AND 0x40) THEN by_ref = $$TRUE
	kind = kind AND 0x001F
	IF (ptype = $$STRING) THEN string_type = $$TRUE
	IF (kind = $$KIND_ARRAYS) THEN atype = $$XLONG: ptype = $$XLONG
'
	IFZ string_type THEN
		IFZ by_ref THEN RETURN
		GOTO numeric_shuffle
	END IF
'
' deallocate strings passed by value
'
string_shuffle:
	IFZ by_ref THEN
		Code ($$ld, $$regro, $$rdi, $$rsp, argOffset, $$XLONG,"", $$rmk$+"1119")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"1120")
		RETURN
	END IF
'
' update numeric and string variables passed by reference
'
numeric_shuffle:
	IFZ by_ref THEN RETURN
	IF NullStringerCheck (argTindex) THEN THEN RETURN
	IF (atype >= $$SCOMPLEX) THEN RETURN
	x_convert = typeConvert[ptype, atype] {{$$BYTE0}}
'
	SELECT CASE ptype
		CASE $$DOUBLE
					Code ($$fld, $$ro, 0, $$rsp, argOffset, $$DOUBLE, "", $$rmk$+"1121")
					IF x_convert THEN
						Conv ($$rsi, atype, $$rsi, ptype)
					END IF
					Move (argTindex, atype, $$rsi, atype)
		CASE $$SINGLE
					Code ($$fld, $$ro, 0, $$rsp, argOffset, $$SINGLE, "", $$rmk$+"1122")
					IF x_convert THEN
						Conv ($$rsi, atype, $$rsi, ptype)
					END IF
					Move (argTindex, atype, $$rsi, atype)
		CASE $$GIANT
					Code ($$ld, $$regro, $$rsi, $$rsp, argOffset, $$XLONG, "", $$rmk$+"1123")
					IF x_convert THEN
						Conv ($$rsi, atype, $$rsi, ptype)
					END IF
					Move (argTindex, atype, $$rsi, atype)
		CASE ELSE
					Code ($$ld, $$regro, $$rsi, $$rsp, argOffset, $$XLONG, "", $$rmk$+"1125")
					IF x_convert THEN
						Conv ($$rsi, atype, $$rsi, ptype)
					END IF
					Move (argTindex, atype, $$rsi, atype)
	END SELECT
	RETURN
'
END FUNCTION
'
'
' ##########################
' #####  Shuffle_C ()  #####
' ##########################
'
FUNCTION  Shuffle_C (atype, ptype, argTindex, kind, argNum, argOffset)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED SSHORT typeConvert[]
'
	IF (kind AND 0x40) THEN by_ref = $$TRUE
	kind = kind AND 0x001F
	IF (ptype = $$STRING) THEN string_type = $$TRUE
	IF (kind = $$KIND_ARRAYS) THEN atype = $$XLONG: ptype = $$XLONG
'
	SELECT CASE argNum
		CASE 1 : argReg = $$rdi
		CASE 2 : argReg = $$rsi
		CASE 3 : argReg = $$rdx
		CASE 4 : argReg = $$rcx
		CASE 5 : argReg = $$r8
		CASE 6 : argReg = $$r9
		CASE ELSE : argReg = $$rsi
	END SELECT
'
	IFZ string_type THEN
		IFZ by_ref THEN RETURN
		GOTO numeric_shuffle
	END IF
'
' deallocate strings passed by value
'
string_shuffle:
	IFZ by_ref THEN
		Code ($$ld, $$regro, $$rdi, $$rsp, argOffset, $$XLONG,"", $$rmk$+"1119")
		Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"1120")
		RETURN
	END IF
'
' update numeric and string variables passed by reference
'
numeric_shuffle:
	IF NullStringerCheck (argTindex) THEN THEN RETURN
	IF (atype >= $$SCOMPLEX) THEN RETURN
	x_convert = typeConvert[ptype, atype] {{$$BYTE0}}
'
	IF (argNum > 6) THEN
		SELECT CASE ptype
			CASE $$DOUBLE
						Code ($$fld, $$ro, 0, $$rsp, argOffset, $$DOUBLE, "", $$rmk$+"1121")
			CASE $$SINGLE
						Code ($$fld, $$ro, 0, $$rsp, argOffset, $$SINGLE, "", $$rmk$+"1122")
			CASE $$GIANT
						Code ($$ld, $$regro, argReg, $$rsp, argOffset, $$XLONG, "", $$rmk$+"1123")
			CASE ELSE
						Code ($$ld, $$regro, argReg, $$rsp, argOffset, $$XLONG, "", $$rmk$+"1125")
		END SELECT
	END IF
	IF x_convert THEN
		Conv (argReg, atype, argReg, ptype)
	END IF
	Move (argTindex, atype, argReg, atype)
'
	RETURN
'
END FUNCTION
'
'
' ########################
' #####  StackIt ()  #####
' ########################
'
FUNCTION  StackIt (to_type, source, from_type, offset)
	EXTERNAL /xxx/  i486bin,  i486asm
	SHARED  toes,  a0,  a0_type
	SHARED  r_addr[],  typeSize[]
'
	ss  = source
	rr  = r_addr[ss]
	SELECT CASE rr
		CASE $$RA0: source = $$RA0: ss = $$RA0
		CASE $$RA1: source = $$RA1: ss = $$RA1
		CASE ELSE:  Move ($$RA0, from_type, source, from_type)
								source = $$RA0: ss = $$RA0
								INC toes
	END SELECT
	IF (to_type != from_type) THEN
		Conv (source, to_type, source, from_type)
	END IF
	dsize     = typeSize[to_type]
	SELECT CASE to_type
		CASE $$DOUBLE, $$SINGLE
					Code ($$fstp, $$ro, 0, $$rsp, offset, to_type, "", $$rmk$+"1126")
		CASE ELSE
					Code ($$st, $$roreg, ss, $$rsp, offset, $$XLONG, "", $$rmk$+"1130")
	END SELECT
	offset  = offset + 8
	DEC toes
	a0 = 0
	a0_type = 0
	RETURN
'
END FUNCTION
'
'
' ############################
' #####  StackOneArg ()  #####
' ############################
'
' StackOneArg (tokenPos, argNum, @argType, @rparen)
'
FUNCTION  StackOneArg (tokenPos, argNum, argType, rparen)
	TOKEN   token, check, new_op, new_data, varToken, openBrace, hold_token
	SHARED  tokenPtr
	SHARED  r_addr$[]
	STATIC  argOff
	STATIC  firstpos
	STATIC  frameStarted
'
	argType = 0
	rparen = $$FALSE
	IF tokenPos THEN
		savePtr = tokenPtr
		tokenPtr = tokenPos
	END IF
'
	IF (argNum < 0) THEN GOTO FrameDone
'
	IFZ argNum THEN
		IF frameStarted THEN XcowlErr (980027): GOTO eeeCompiler
		NextToken (@token)
		IFF TokenMatch (@token, @#T_LPAREN) THEN XcowlErr (980029): GOTO eeeSyntax
		PeekToken (@check)
		IF TokenMatch (@check, @#T_RPAREN) THEN XcowlErr (980031): GOTO eeeTooFewArgs
		firstpos  = tokenPtr
		argOff    = 0
		OpenBothAccs ()
		IF TokenMatch (@hold_token, @#T_FORMAT_D) THEN
			frameSize = 16
		ELSE
			frameSize = 64
		END IF
		Code ($$sub, $$regimm, $$rsp, frameSize, 0, $$XLONG, "", $$rmk$+"1131")
		frameStarted = $$TRUE
	END IF
'
	IFZ frameStarted THEN XcowlErr (980044): GOTO eeeCompiler
	args = argNum
	new_test = 0: new_prec = 0: new_type = 0
	new_op = #T_ZERO
	new_data = #T_ZERO
	Expresso (@new_test, @new_op, @new_prec, @new_data, @new_type)
	IF XERROR THEN EXIT FUNCTION
	INC args
	IF (new_type > $$STRING) THEN XcowlErr (980052): GOTO eeeTypeMismatch
	IF (args > 2) THEN
		IF (new_type >= $$GIANT) THEN XcowlErr (980054): GOTO eeeTypeMismatch
	END IF
	argOut  = $$FALSE
	ntype   = new_type
	IF (ntype < $$SLONG) THEN ntype = $$SLONG
	IF TokenMatch (@hold_token, @#T_FORMAT_D) THEN
		IF (args = 2) THEN
			Code ($$st, $$roimm, ntype, $$rsp, argOff, $$XLONG, "", $$rmk$+"1132")
			argOff = argOff + 4
		END IF
	END IF
	IFF TokenMatch (@new_data, @#T_ZERO) THEN
		kind  = new_data.tp.kind
		IF ((kind = $$KIND_CONSTANTS) OR (kind = $$KIND_SYSCONS) OR (kind = $$KIND_LITERALS)) THEN
			SELECT CASE ntype
				CASE $$DOUBLE:  argOut  = $$TRUE
												ntype = $$GIANT
												v#      = DOUBLE(r_addr$[new_data.tindex])
												hi      = DHIGH(v#)
												lo      = DLOW(v#)
												Code ($$st, $$roimm, lo, $$rsp, argOff, $$XLONG, "", $$rmk$+"1133")
												Code ($$st, $$roimm, hi, $$rsp, argOff+4, $$XLONG, "", $$rmk$+"1134")
				CASE $$SINGLE:  argOut  = $$TRUE
												ntype   = $$XLONG
												v       = XMAKE(SINGLE(r_addr$[new_data.tindex]))
												Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"1135")
				CASE $$GIANT:   argOut  = $$TRUE
'												v$$     = GIANT(r_addr$[new_data.tindex])                             '*cw* 230318-
'												hi      = GHIGH(v$$)                                                  '*cw* 230318-
'												lo      = GLOW(v$$)                                                   '*cw* 230318-
'												Code ($$st, $$roimm, lo, $$rsp, argOff, $$XLONG, "", $$rmk$+"1136")   '*cw* 230318-
'												Code ($$st, $$roimm, hi, $$rsp, argOff+4, $$XLONG, "", $$rmk$+"1137") '*cw* 230318-
												v       = XLONG(r_addr$[new_data.tindex])                             '*cw* 230318+
												Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"1136")    '*cw* 230318+
				CASE $$XLONG:   argOut  = $$TRUE
												v       = XLONG(r_addr$[new_data.tindex])
												Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"1138")
				CASE $$ULONG:   argOut  = $$TRUE
												v       = ULONG(r_addr$[new_data.tindex])
												Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"1139")
				CASE $$SLONG:   argOut  = $$TRUE
												v       = SLONG(r_addr$[new_data.tindex])
												Code ($$st, $$roimm, v, $$rsp, argOff, $$XLONG, "", $$rmk$+"1140")
				CASE ELSE:      acc     = OpenAccForType (ntype)
												Move (acc, ntype, new_data.tindex, ntype)
			END SELECT
		ELSE
			SELECT CASE ntype
				CASE $$SINGLE:  ntype = $$XLONG
				CASE $$DOUBLE:  ntype = $$GIANT
			END SELECT
			acc   = OpenAccForType (ntype)
			Move (acc, ntype, new_data.tindex, ntype)
		END IF
	ELSE
		acc   = Top ()
		SELECT CASE ntype
			CASE $$SINGLE:  Code ($$fstp, $$ro, 0, $$rsp, argOff, $$SINGLE, "", $$rmk$+"1141")
											argOut  = $$TRUE
											ntype   = $$XLONG
											acc     = Topax1 ()
			CASE $$DOUBLE:  Code ($$fstp, $$ro, 0, $$rsp, argOff, $$DOUBLE, "", $$rmk$+"1142")
											argOut  = $$TRUE
											ntype   = $$GIANT
											acc     = Topax1 ()
		END SELECT
	END IF
'
	IFZ argOut THEN StackIt (ntype, acc, ntype, argOff)
	SELECT CASE ntype
		CASE $$DOUBLE, $$GIANT : argOff = argOff + 8
		CASE ELSE              : argOff = argOff + 4
	END SELECT

	SELECT CASE TRUE
		CASE TokenMatch (@new_op, @#T_COMMA): GOTO StackReturn
		CASE TokenMatch (@new_op, @#T_STARTS): GOTO StackReturn
		CASE TokenMatch (@new_op, @#T_COLON): GOTO StackReturn
		CASE ELSE
	END SELECT
'
'
	IF TokenMatch (@new_op, @#T_RBRAK) AND TokenMatch (@hold_token, @#T_UBOUND) THEN NextToken (@new_op)
	IFF TokenMatch (@new_op, @#T_RPAREN) THEN XcowlErr (9800135): GOTO eeeSyntax
	rparen = $$TRUE
	GOTO StackReturn
'
'
' got all the arguments
'
FrameDone:
	Code ($$add, $$regimm, $$rsp, 64, 0, $$XLONG, "", $$rmk$+"1143")
	frameStarted = $$FALSE
'
StackReturn:
	IF tokenPos THEN
		tokenPos = tokenPtr
		tokenPtr = savePtr
	END IF
	argType = ntype
	RETURN
'
'--------------------------------------------------------
'
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooFewArgs:
	XERROR = ERROR_TOO_FEW_ARGS
	EXIT FUNCTION
'
eeeTooManyArgs:
	XERROR = ERROR_TOO_MANY_ARGS
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION

END FUNCTION
'
'
' ################################
' #####  StatementExport ()  #####
' ################################
'
FUNCTION  StatementExport (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  library
	SHARED  export
	SHARED  got_function
	SHARED  got_program
	SHARED  got_export
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_NEST
	SHARED  ERROR_PROGRAM_NOT_NAMED,  ERROR_TOO_LATE
'
	IF export THEN XcowlErr (990016): GOTO eeeNest
	IF got_function THEN XcowlErr (990017): GOTO eeeTooLate
	IFZ got_program THEN XcowlErr (990018): GOTO eeeProgramNotNamed
	IFF TokenMatch (@token, @#T_EXPORT) THEN XcowlErr (990019): GOTO eeeCompiler
	got_export = $$TRUE
	export = $$TRUE
'
	token = #T_STARTS
	RETURN
'
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeNest:
	XERROR = ERROR_NEST
	EXIT FUNCTION
'
eeeProgramNotNamed:
	XERROR = ERROR_PROGRAM_NOT_NAMED
	EXIT FUNCTION
'
eeeTooLate:
	XERROR = ERROR_TOO_LATE
	EXIT FUNCTION
END FUNCTION
'
'
' ################################
' #####  StatementImport ()  #####
' ################################
'
FUNCTION  StatementImport (TOKEN token)
	SHARED  got_declare
	SHARED  got_import
	SHARED  m_addr$[]
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_SYNTAX,  ERROR_TOO_LATE
'
	IFF TokenMatch(@token, @#T_IMPORT) THEN
		IFF TokenMatch(@token, @#T_LIBRARY) THEN
			XcowlErr (1000015): GOTO eeeCompiler
		END IF
	END IF
'
	IF got_declare THEN XcowlErr (1000019): GOTO eeeTooLate
	NextToken (@token)
'
	SELECT CASE token.tp.kind
		CASE $$KIND_LITERALS : IF (token.tp.type != $$STRING) THEN XcowlErr (1000023): GOTO eeeSyntax
														IFZ m_addr$[token.tindex] THEN AssignAddress (token)
														IF XERROR THEN EXIT FUNCTION
														XxxLoadLibrary (token)
														got_import = $$TRUE
		CASE ELSE            : XcowlErr (1000028): GOTO eeeSyntax
	END SELECT
'
	token = #T_STARTS
	RETURN
'
'
eeeCompiler:
	XERROR = ERROR_COMPILER
		EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooLate:
	XERROR = ERROR_TOO_LATE
	EXIT FUNCTION
END FUNCTION
'
'
' #################################
' #####  StatementProgram ()  #####
' #################################
'
' StatementProgram (@token)
'
FUNCTION  StatementProgram (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  library
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_DUP_DEFINITION
	SHARED  ERROR_PROGRAM_NOT_NAMED
	SHARED  ERROR_SYNTAX,  ERROR_TOO_LATE,  ERROR_TYPE_MISMATCH
	SHARED  got_declare,  got_export,  got_function
	SHARED  got_import,  got_program,  got_type
	SHARED  programName$
	SHARED  program$
	SHARED  tab_sym$[]
	SHARED  m_addr$[]
	SHARED TOKEN programToken
'
	IF got_program THEN XcowlErr (1010022): GOTO eeeDupDefinition
	IFF TokenMatch (@token, @#T_PROGRAM) THEN XcowlErr (1010023): GOTO eeeCompiler
	IF (got_declare OR got_export OR got_function OR got_import OR got_type) THEN XcowlErr (1010024): GOTO eeeTooLate
'
	NextToken (@token)
	IF (token.tp.kind != $$KIND_LITERALS) THEN XcowlErr (1010027): GOTO eeeSyntax
	IF (token.tp.type != $$STRING) THEN XcowlErr (1010028): GOTO eeeTypeMismatch
	IFZ m_addr$[token.tindex] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
	program$ = tab_sym$[token.tindex]
	program$ = TRIM$(MID$(program$,2,LEN(program$)-2))    ' remove "quotes"
	StripNonSymbol (@program$)
	IFZ program$ THEN program$ = programName$
	IFZ program$ THEN XcowlErr (1010035): GOTO eeeProgramNotNamed
	got_program = $$TRUE
	programToken = token
	token = #T_STARTS
	RETURN
'
' *****  Errors  *****
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeDupDefinition:
	XERROR = ERROR_DUP_DEFINITION
	EXIT FUNCTION
'
eeeProgramNotNamed:
	XERROR = ERROR_PROGRAM_NOT_NAMED
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooLate:
	XERROR = ERROR_TOO_LATE
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
'
END FUNCTION
'
'
' #################################
' #####  StatementVersion ()  #####
' #################################
'
' StatementVersion (@token)
'
FUNCTION  StatementVersion (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  library
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_DUP_DEFINITION
	SHARED  ERROR_SYNTAX,  ERROR_TOO_LATE,  ERROR_TYPE_MISMATCH
	SHARED  got_declare,  got_export,  got_function
	SHARED  got_import,  got_type
	SHARED  version$
	SHARED  tab_sym$[]
	SHARED  m_addr$[]
	SHARED  TOKEN versionToken
'
	IF version$ THEN XcowlErr (1020020): GOTO eeeDupDefinition
	IFF TokenMatch (@token, @#T_VERSION) THEN XcowlErr (1020021): GOTO eeeCompiler
	IF (got_declare OR got_export OR got_function OR got_import OR got_type) THEN XcowlErr (1020022): GOTO eeeTooLate
'
	NextToken (@token)
	IF (token.tp.kind != $$KIND_LITERALS) THEN XcowlErr (1020025): GOTO eeeSyntax
	IF (token.tp.type != $$STRING) THEN XcowlErr (1020026): GOTO eeeTypeMismatch
	IFZ m_addr$[token.tindex] THEN AssignAddress (token)
	IF XERROR THEN EXIT FUNCTION
	version$ = tab_sym$[token.tindex]
	version$ = TRIM$(MID$(version$,2,LEN(version$)-2))
	versionToken = token
'
	token = #T_STARTS
	RETURN
'
' *****  Errors  *****
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeDupDefinition:
	XERROR = ERROR_DUP_DEFINITION
	EXIT FUNCTION
'
eeeSyntax:
	XERROR = ERROR_SYNTAX
	EXIT FUNCTION
'
eeeTooLate:
	XERROR = ERROR_TOO_LATE
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
'
END FUNCTION
'
'
' ############################
' #####  StripExtent ()  #####
' ############################
'
FUNCTION  StripExtent (filename$)
'
	dot = RINSTR (filename$, ".")
	IF dot THEN filename$ = TRIM$(LEFT$(filename$, dot-1))
END FUNCTION
'
'
' ###############################
' #####  StripNonSymbol ()  #####
' ###############################
'
FUNCTION  StripNonSymbol (name$)
	SHARED  UBYTE  charsetUpperLower[]
	SHARED  UBYTE  charsetUpperLowerNumeric[]
'
	IFZ name$ THEN RETURN
	upper = UBOUND (name$)
'
	first = -1
	FOR i = 0 TO upper
		IF charsetUpperLower[name${i}] THEN first = i: EXIT FOR
	NEXT i
	IF (first < 0) THEN name$ = "": RETURN
'
	final = -1
	FOR i = first TO upper
		IFZ charsetUpperLowerNumeric[name${i}] THEN final = i-1: EXIT FOR
	NEXT i
	IF (final < 0) THEN final = upper
'
	IFZ first THEN
		IF (final = upper) THEN RETURN        ' no change
		name$ = LEFT$ (name$, final-first+1)  ' strip right hand excess
	ELSE
		d = 0
		FOR i = first TO final
			name${d} = name${i}
			INC d
		NEXT i
		name${d} = 0x00
		name$ = LEFT$ (name$, d)
	END IF
END FUNCTION
'
'
' #############################
' #####  StripSuffix$ ()  #####
' #############################
'
FUNCTION  StripSuffix$ (x$)
	SHARED UBYTE  charsetSymbolInner[]
'
	d = LEN(x$)
	IFZ d THEN RETURN
	DO
		DEC d
		check  = x${d}
	LOOP UNTIL (charsetSymbolInner[check])
	RETURN (LEFT$(x$, d+1))
END FUNCTION
'
'
' ###############################
' #####  TestForKeyword ()  #####
' ###############################
'
FUNCTION  TOKEN TestForKeyword (symbol$)
	TOKEN   token
	SHARED  TOKEN  tab_sym[]
	SHARED  TOKEN  tab_sys[]
	SHARED  TOKEN  typeToken[]
	SHARED  alphaFirst[],  alphaLast[],  tab_sym$[], tab_sys$[]
	SHARED  typeSymbol$[]
	SHARED  charPtr,  pastSystemSymbols,  rawline$,  typePtr
	SHARED UBYTE  charsetSuffix[]
	SHARED UBYTE  charsetSpaceTab[]
	EXTERNAL /xxx/ autoUpperCase
'
	IFZ symbol$ THEN RETURN
	SELECT CASE symbol${0}
		CASE '$':   IF (symbol${1} != '$') THEN RETURN
								gotSystemSymbol = $$TRUE                        ' $$
								x$  = symbol$
								x   = 0
		CASE '#':   IF (symbol${1} != '#') THEN RETURN
								gotSystemSymbol = $$TRUE                        ' ##
								x$  = symbol$
								x   = 0
		CASE '_':   RETURN
		CASE ELSE:  gotSystemSymbol = $$FALSE
								x$  = symbol$
								x   = x${0} - 64
								IF (x > 26) THEN x = x - 32
	END SELECT
'
	first = alphaFirst[x]
	last  = alphaLast[x]
	x     = first
	token = #T_ZERO
'
	charV = rawline${charPtr}
	IF (charV = '$') THEN
		sys$  = x$ + "$"
		xtra  = $$TRUE
	ELSE
		sys$  = x$
	END IF
	symbolLength = LEN (sys$)
'
'
' *****  See if valid $$SystemConstant or ##SystemVariable
'
	IF gotSystemSymbol THEN
		token = #T_ZERO
		x = 0
		DO
			IF (tab_sym$[x] = sys$) THEN
				token = tab_sym[x]
				IF xtra THEN INC charPtr
				EXIT DO
			END IF
			INC x
		LOOP WHILE (x < pastSystemSymbols)
		RETURN (token)
	END IF
'
' Only switch to upper case if every character of symbol is lower case
'
	IF autoUpperCase THEN
		doUpperCaseCheck = $$TRUE
		uSymbol = UBOUND(symbol$)
		FOR i = 0 TO uSymbol
			char = symbol${i}
			IF ((char > 64) && (char < 91)) THEN
				doUpperCaseCheck = $$FALSE
				EXIT FOR
			END IF
		NEXT i
	ELSE
		doUpperCaseCheck = $$FALSE
	END IF
'
' *****  See if KEYWORD  *****
'
	IF doUpperCaseCheck THEN
	DO
			IF (tab_sys$[x] = UCASE$(sys$)) THEN ' UCASE$() add by technicorn
			token = tab_sys[x]
			IF xtra THEN INC charPtr
				tokenKind = token.tp.kind
'       PRINT tab_sys$[x];" KIND = ";tokenKind
				charPtrAfterKeyword = charPtr
				DO
					charAfterKeyword = rawline${charPtrAfterKeyword}
					INC charPtrAfterKeyword
					IF charsetSpaceTab[charAfterKeyword] THEN DO DO
					SELECT CASE charAfterKeyword
						CASE '['
							SELECT CASE UCASE$(sys$)
								CASE "READ", "WRITE", "PRINT": EXIT DO
								CASE ELSE: EXIT DO 2
							END SELECT
						CASE '{'
							IF xtra THEN DEC charPtr
							EXIT DO 2
						CASE '('
							IF ((tokenKind = $$KIND_INTRINSICS) || (tokenKind = $$KIND_STATE_INTRIN)) THEN EXIT DO
						CASE ELSE
							IF (tokenKind = $$KIND_STATE_INTRIN) || (tokenKind = $$KIND_STATEMENTS) || (tokenKind = $$KIND_BINARY_OPS) || (tokenKind = $$KIND_UNARY_OPS) THEN
								EXIT DO
							ELSE
								IF xtra THEN DEC charPtr
								EXIT DO 2
							END IF
					END SELECT
				LOOP
			RETURN (token)
		END IF
		INC x
	LOOP WHILE (x <= last)
	ELSE
		DO
			IF (tab_sys$[x] = sys$) THEN 'Original
				token = tab_sys[x]
				IF xtra THEN INC charPtr
				RETURN (token)
			END IF
			INC x
		LOOP WHILE (x <= last)
	END IF
'
'
' *****  See if user defined TYPE name  *****
'
	IF charsetSuffix[charV] THEN RETURN
	typeNumber  = $$SCOMPLEX
	DO WHILE (typeNumber < typePtr)
		IF (typeSymbol$[typeNumber] = symbol$) THEN
			token = typeToken[typeNumber]
			RETURN (token)
		END IF
		INC typeNumber
	LOOP
	RETURN
END FUNCTION
'
'
' ########################
' #####  TheType ()  #####
' ########################
'
FUNCTION  TheType (TOKEN token)
	SHARED  defaultType[],  tabType[],  funcType[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  defaultType,  func_number
	STATIC GOADDR typeKind[]
'
	IFZ typeKind[] THEN GOSUB LoadTypeKind
'
	qtype = token.tp.type
	IF qtype THEN RETURN (qtype)            ' already has type
	tt = token.tindex
	kind = token.tp.kind
	scope = token.tp.allo
	GOTO @typeKind[kind]                    ' figure type for this kind
	RETURN                                  ' no type for other kinds
'
'
' *****  Routines to figure type for all valid kinds  *****
'
type_arrays:
type_variables:
	qtype = tabType[tt]                 ' type = tabType[tt]
	IF qtype THEN RETURN (qtype)        ' if (type != 0), return type
'
	SELECT CASE scope
		CASE $$SHARED    : RETURN (defaultType)
		CASE $$EXTERNAL  : RETURN (defaultType)
		CASE ELSE        : RETURN (defaultType[func_number])
	END SELECT
	RETURN (defaultType)                ' return system-wide default type
'
type_literals:
type_constants:
	qtype = tabType[tt]                 ' type = tabType[tt]
	IF qtype THEN RETURN (qtype)        ' if (type != 0), return type
	qtype = defaultType[func_number]    ' type = defaultType for this function
	IF qtype THEN RETURN (qtype)        ' if (type != 0), return type
	RETURN (defaultType)                ' return system-wide default type
'
type_functions:
	qtype = funcType[tt]                ' get type from funcType[] array
	IF qtype THEN RETURN (qtype)        ' return declared function type
	RETURN ($$XLONG)                    ' return default function type
'
type_syscons:
	qtype = tabType[tt]                 ' type = tabType[tt]
	IF qtype THEN RETURN (qtype)        ' if (type != 0), return type
	XcowlErr (1070054): GOTO eeeCompiler    ' no type at all  (compiler error)
'
type_bitcons:
type_charcons:
	RETURN ($$USHORT)                   ' all charcons and bitcons are USHORT
'
type_types:
	RETURN (tt)                         ' type of TYPE token
'
SUB LoadTypeKind
	DIM typeKind[31]
	typeKind[ $$KIND_VARIABLES      ] = GOADDRESS (type_variables)
	typeKind[ $$KIND_CONSTANTS      ] = GOADDRESS (type_constants)
	typeKind[ $$KIND_FUNCTIONS      ] = GOADDRESS (type_functions)
	typeKind[ $$KIND_LITERALS     ] = GOADDRESS (type_literals)
	typeKind[ $$KIND_CHARCONS     ] = GOADDRESS (type_charcons)
	typeKind[ $$KIND_SYSCONS        ] = GOADDRESS (type_syscons)
	typeKind[ $$KIND_ARRAYS       ] = GOADDRESS (type_arrays)
	typeKind[ $$KIND_TYPES          ] = GOADDRESS (type_types)
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ####################
' #####  Tok ()  #####
' ####################
'
FUNCTION  TOKEN Tok (symbol$, space, kind, allo, type, raddr, value, value$)
	TOKEN   token
	SHARED  r_addr[],  r_addr$[],  m_addr$[]
	SHARED  XERROR
'
	token = AddSymbol (@symbol$, 0, kind, allo, type, 0)
'
	IF (kind = $$KIND_SYSCONS) THEN
		IF XERROR THEN EXIT FUNCTION
		tn = token.tindex
		r_addr[tn]  = raddr
		r_addr$[tn] = value$
		m_addr$[tn] = "$$SYSCON"
	ELSE
		IF XERROR THEN EXIT FUNCTION
		AssignAddress (token)
	END IF
	RETURN (token)
END FUNCTION
'
'
' ###########################
' #####  TokenMatch ()  #####
' ###########################
'
' match = TokenMatch (@token1, @token2)
'
' match is returned TRUE if all but the "spaces" element are equal
'
' NOTE: the token.tp.spsc is not matched
'
FUNCTION  TokenMatch (TOKEN token1, TOKEN token2)
'
	IF (token1.tindex != token2.tindex) THEN RETURN ($$FALSE)
	IF (token1.tproto XOR token2.tproto) AND 0xFFFFFF THEN RETURN ($$FALSE)
	RETURN ($$TRUE)
'
END FUNCTION
'
'
' ################################
' #####  TokenRestOfLine ()  #####
' ################################
'
FUNCTION  TokenRestOfLine ()
	TOKEN   token
	SHARED  TOKEN  tokens[]
	SHARED  charPtr,  rawLength,  rawline$,  tokenPtr
'
	finalOffset = rawLength - charPtr
	midOffset = finalOffset AND 0xFFFFFFF8
	rawAddr = &rawline$ + charPtr
	charPtr = rawLength
'
	c   = 0
	DO WHILE (c < midOffset)
		INC tokenPtr
		tokens[tokenPtr].tindex = XLONGAT (rawAddr, c)
		tokens[tokenPtr].tproto = XLONGAT (rawAddr, c+4)
		c   = c + 8
	LOOP
'
	IF (c >= finalOffset) THEN RETURN
'
	tokenOffset = 0
	tokenAddr = &token
	DO WHILE (c < finalOffset)
		UBYTEAT(tokenAddr, tokenOffset) = UBYTEAT(rawAddr, c)
		INC c
		INC tokenOffset
	LOOP
	INC tokenPtr
	tokens[tokenPtr] = token
'
	RETURN
'
END FUNCTION
'
'
' ##############################
' #####  TokensDefined ()  #####
' ##############################
'
FUNCTION  TokensDefined ()
	EXTERNAL /xxx/  i486asm,  i486bin,  checkBounds
	TOKEN   token
	SHARED  alphaFirst[],  alphaLast[]
	SHARED  r_addr[]
	SHARED  tab_lab$[],  labaddr[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  nullstringer, nullstringerProto
	SHARED  pastSystemLabels,  pastSystemSymbols
	SHARED  tab_sym_ptr,  tab_sys_ptr,  xit
	SHARED  entryCheckBounds
'
	SHARED  TOKEN falseToken
	SHARED  TOKEN charToken[]
	SHARED  TOKEN tab_lab[]
	STATIC  notFirstTime,  x$
'
'
' Put $$IMM16, $$NEG16, $$LITNUM, $$CONNUM in symbol table as 32 - 35
'
	r_addr[$$IMM16] = $$IMM16
	r_addr[$$NEG16] = $$NEG16
	r_addr[$$LITNUM] = $$LITNUM
	r_addr[$$CONNUM] = $$CONNUM
'
	tab_sym_ptr     = 36
	alphaFirst[0]   = 1
'
' Put labels and their addresses into label symbol table (from asm libraries).
'
	##ERROR = $$FALSE
	IFZ xit THEN
		past = GetExternalAddresses ()
		IF ##ERROR THEN
			XstErrorNumberToName (##ERROR, @error$)
			PRINT "Error #: name = "; HEXX$(##ERROR,4); ": "; error$
			PRINT "Can't load external addresses.  Don't compile into memory!"
			pastSystemLabels = 1
		END IF
		pastSystemLabels = past
	END IF
	##ERROR = $$FALSE
'
	GOSUB DefineSystemTokens
'
	saveBin = i486bin
	i486bin = $$TRUE
	GOSUB DefineSystemConstants           ' Define system constants
	i486bin = saveBin
'
' *****  Test Only  *****
'
' PRINT "TokensDefined():  "; past; " labels extracted from COFF executable."
'
	XstGetCommandLineArguments (@argc, @argv$[])
	IF (argc > 1) THEN
		IF (TRIM$(argv$[1]) = "-xlabs") THEN
'   test$ = argv$[1]
'   test$ = TRIM$(test$)
'   IF (test$ = "-xlabs") THEN
			PRINT                             ' Bug
			FOR i = 0 TO past
					PRINT HEX$(tab_lab[i].tproto,8), HEX$(tab_lab[i].tindex,8), HEX$(labaddr[i],8), tab_lab$[i]
			NEXT i
		END IF
	END IF
'
	RETURN
'
' *****  End Test  *****
'
' *************************************************************
' *****  THE REST OF THIS FUNCTION IS EXECUTED ONLY ONCE  *****
' *************************************************************
'
' ************************************************************************
' *****  Define all system tokens:  keywords, operators, characters  *****
' ************************************************************************
'
SUB DefineSystemTokens
	IF notFirstTime THEN EXIT SUB
	notFirstTime = $$TRUE
	entryCheckBounds = checkBounds
'
	#T_STARTS.tp.kind = $$KIND_STARTS
	#T_ZERO.tp.kind = $$ZERO
'
	tab_sys_ptr    = 1                ' lowest pointer one to reduce errors
	alphaLast[0]   = tab_sys_ptr - 1
	alphaFirst[1]  = tab_sys_ptr
	#T_ABS         = MakeToken ("ABS",    $$KIND_INTRINSICS, $$ARGS1, $$TYPE_INPUT)
	#T_ALL         = MakeToken ("ALL",    $$KIND_STATEMENTS, 0, 0)
	#T_AND         = MakeToken ("AND",    $$KIND_BINARY_OPS, 0, $$COP3  OR $$PREC_AND)
	#T_ANY         = MakeToken ("ANY",    $$KIND_STATEMENTS, 0, $$ANY)
	#T_ASC         = MakeToken ("ASC",    $$KIND_INTRINSICS, $$ARGS2, $$XLONG)
	#T_ATTACH      = MakeToken ("ATTACH", $$KIND_STATEMENTS, 0, 0)
	#T_AUTO        = MakeToken ("AUTO",   $$KIND_STATEMENTS, $$AUTO, 0)
	#T_AUTOX       = MakeToken ("AUTOX",  $$KIND_STATEMENTS, $$AUTOX, 0)
	alphaLast[1]   = tab_sys_ptr - 1
	alphaFirst[2]  = tab_sys_ptr
	#T_BIN_D       = MakeToken ("BIN$",     $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_BINB_D      = MakeToken ("BINB$",    $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_BITFIELD    = MakeToken ("BITFIELD", $$KIND_INTRINSICS, $$ARGS2, $$USHORT)
	alphaLast[2]   = tab_sys_ptr - 1
	alphaFirst[3]  = tab_sys_ptr
	#T_CASE        = MakeToken ("CASE",      $$KIND_STATEMENTS, 0, 0)
	#T_CFUNCTION   = MakeToken ("CFUNCTION", $$KIND_STATEMENTS, 0, 0)
	#T_CHR_D       = MakeToken ("CHR$",      $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_CJUST_D     = MakeToken ("CJUST$",    $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_CLOSE       = MakeToken ("CLOSE",     $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	#T_CLR         = MakeToken ("CLR",       $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_CSIZE       = MakeToken ("CSIZE",     $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	#T_CSIZE_D     = MakeToken ("CSIZE$",    $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	#T_CSTRING_D   = MakeToken ("CSTRING$",  $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	alphaLast[3]   = tab_sys_ptr - 1
	alphaFirst[4]  = tab_sys_ptr
	#T_DEC         = MakeToken ("DEC",      $$KIND_STATEMENTS,   0, 0)
	#T_DECLARE     = MakeToken ("DECLARE",  $$KIND_STATEMENTS,   0, 0)
	#T_DHIGH       = MakeToken ("DHIGH",    $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_DIM         = MakeToken ("DIM",      $$KIND_STATEMENTS,   0, 0)
	#T_DLOW        = MakeToken ("DLOW",     $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_DMAKE       = MakeToken ("DMAKE",    $$KIND_INTRINSICS,   $$ARGS2, $$DOUBLE)
	#T_DO          = MakeToken ("DO",       $$KIND_STATEMENTS,   0, 0)
	#T_DOUBLE      = MakeToken ("DOUBLE",   $$KIND_STATE_INTRIN, $$ARGS1, $$DOUBLE)
	#T_DOUBLEAT    = MakeToken ("DOUBLEAT", $$KIND_STATE_INTRIN, $$ARGS2, $$DOUBLE)
	alphaLast[4]   = tab_sys_ptr - 1
	alphaFirst[5]  = tab_sys_ptr
	#T_ELSE        = MakeToken ("ELSE",     $$KIND_STATEMENTS, 0, 0)
	#T_END         = MakeToken ("END",      $$KIND_STATEMENTS, 0, 0)
	#T_ENDIF       = MakeToken ("ENDIF",    $$KIND_STATEMENTS, 0, 0)
	#T_EOF         = MakeToken ("EOF",      $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	#T_ERROR       = MakeToken ("ERROR",    $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	#T_ERROR_D     = MakeToken ("ERROR$",   $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	#T_EXIT        = MakeToken ("EXIT",     $$KIND_STATEMENTS, 0, 0)
	#T_EXPORT      = MakeToken ("EXPORT",   $$KIND_STATEMENTS, 0, 0)
	#T_EXTERNAL    = MakeToken ("EXTERNAL", $$KIND_STATEMENTS, $$EXTERNAL, 0)
	#T_EXTS        = MakeToken ("EXTS",     $$KIND_INTRINSICS, $$ARGS3, $$SLONG)
	#T_EXTU        = MakeToken ("EXTU",     $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	alphaLast[5]   = tab_sys_ptr - 1
	alphaFirst[6]  = tab_sys_ptr
	#T_FALSE       = MakeToken ("FALSE",       $$KIND_STATEMENTS,   0, 0)
	#T_FIX         = MakeToken ("FIX",         $$KIND_INTRINSICS,   $$ARGS1, $$TYPE_INPUT)
	#T_FOR         = MakeToken ("FOR",         $$KIND_STATEMENTS,   0, 0)
	#T_FORMAT_D    = MakeToken ("FORMAT$",     $$KIND_INTRINSICS,   $$ARGS2, $$STRING)
	#T_FUNCADDR    = MakeToken ("FUNCADDR",    $$KIND_STATE_INTRIN, $$ARGS1, $$FUNCADDR)
	#T_FUNCADDRAT  = MakeToken ("FUNCADDRAT",  $$KIND_STATE_INTRIN, $$ARGS2, $$FUNCADDR)
	#T_FUNCADDRESS = MakeToken ("FUNCADDRESS", $$KIND_INTRINSICS,   $$ARGS1, $$FUNCADDR)
	#T_FUNCTION    = MakeToken ("FUNCTION",    $$KIND_STATEMENTS,   0, 0)
	alphaLast[6]   = tab_sys_ptr - 1
	alphaFirst[7]  = tab_sys_ptr
	#T_GHIGH       = MakeToken ("GHIGH",     $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_GIANT       = MakeToken ("GIANT",     $$KIND_STATE_INTRIN, $$ARGS1, $$GIANT)
	#T_GIANTAT     = MakeToken ("GIANTAT",   $$KIND_STATE_INTRIN, $$ARGS1, $$GIANT)
	#T_GLOW        = MakeToken ("GLOW",      $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_GMAKE       = MakeToken ("GMAKE",     $$KIND_INTRINSICS,   $$ARGS2, $$GIANT)
	#T_GOADDR      = MakeToken ("GOADDR",    $$KIND_STATE_INTRIN, $$ARGS1, $$GOADDR)
	#T_GOADDRAT    = MakeToken ("GOADDRAT",  $$KIND_STATE_INTRIN, $$ARGS2, $$GOADDR)
	#T_GOADDRESS   = MakeToken ("GOADDRESS", $$KIND_INTRINSICS,   $$ARGS1, $$GOADDR)
	#T_GOSUB       = MakeToken ("GOSUB",     $$KIND_STATEMENTS,   0, 0)
	#T_GOTO        = MakeToken ("GOTO",      $$KIND_STATEMENTS,   0, 0)
	alphaLast[7]   = tab_sys_ptr - 1
	alphaFirst[8]  = tab_sys_ptr
	#T_HEX_D       = MakeToken ("HEX$",     $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_HEXX_D      = MakeToken ("HEXX$",    $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_HIGH0       = MakeToken ("HIGH0",    $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	#T_HIGH1       = MakeToken ("HIGH1",    $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	alphaLast[8]   = tab_sys_ptr - 1
	alphaFirst[9]  = tab_sys_ptr
	#T_IF          = MakeToken ("IF",       $$KIND_STATEMENTS, 0, 0)
	#T_IFF         = MakeToken ("IFF",      $$KIND_STATEMENTS, 0, 0)
	#T_IFT         = MakeToken ("IFT",      $$KIND_STATEMENTS, 0, 0)
	#T_IFZ         = MakeToken ("IFZ",      $$KIND_STATEMENTS, 0, 0)
	#T_IMPORT      = MakeToken ("IMPORT",   $$KIND_STATEMENTS, 0, 0)
	#T_INC         = MakeToken ("INC",      $$KIND_STATEMENTS, 0, 0)
	#T_INCHR       = MakeToken ("INCHR",    $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_INCHRI      = MakeToken ("INCHRI",   $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_INFILE_D    = MakeToken ("INFILE$",  $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	#T_INLINE_D    = MakeToken ("INLINE$",  $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	#T_INSTR       = MakeToken ("INSTR",    $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_INSTRI      = MakeToken ("INSTRI",   $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_INT         = MakeToken ("INT",      $$KIND_INTRINSICS, $$ARGS1, $$TYPE_INPUT)
	#T_INTERNAL    = MakeToken ("INTERNAL", $$KIND_STATEMENTS, 0, 0)
	#T_ISDATA      = MakeToken ("ISDATA",   $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	#T_ISNODE      = MakeToken ("ISNODE",   $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	alphaLast[9]   = tab_sys_ptr - 1
	alphaFirst[10] = 0
	alphaLast[10]  = -1
	alphaFirst[11] = tab_sys_ptr
	alphaLast[11]  = -1
	alphaFirst[12] = tab_sys_ptr
	#T_LCASE_D     = MakeToken ("LCASE$",  $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_LCLIP_D     = MakeToken ("LCLIP$",  $$KIND_INTRINSICS,   $$ARGS2, $$STRING)
	#T_LEFT_D      = MakeToken ("LEFT$",   $$KIND_INTRINSICS,   $$ARGS2, $$STRING)
	#T_LEN         = MakeToken ("LEN",     $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_LIBRARY     = MakeToken ("LIBRARY", $$KIND_STATE_INTRIN, $$ARGS1, $$XLONG)
	#T_LJUST_D     = MakeToken ("LJUST$",  $$KIND_INTRINSICS,   $$ARGS2, $$STRING)
	#T_LOF         = MakeToken ("LOF",     $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_LOOP        = MakeToken ("LOOP",    $$KIND_STATEMENTS,   0, 0)
	#T_LTRIM_D     = MakeToken ("LTRIM$",  $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	alphaLast[12]  = tab_sys_ptr - 1
	alphaFirst[13] = tab_sys_ptr
	#T_MAKE        = MakeToken ("MAKE",  $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_MAX         = MakeToken ("MAX",   $$KIND_INTRINSICS, $$ARGS2, $$TYPE_INPUT)
	#T_MID_D       = MakeToken ("MID$",  $$KIND_INTRINSICS, $$ARGS3, $$STRING)
	#T_MIN         = MakeToken ("MIN",   $$KIND_INTRINSICS, $$ARGS2, $$TYPE_INPUT)
	#T_MOD         = MakeToken ("MOD",   $$KIND_BINARY_OPS, 0, $$COP6 OR $$PREC_MOD)
	alphaLast[13]  = tab_sys_ptr - 1
	alphaFirst[14] = tab_sys_ptr
	#T_NEXT        = MakeToken ("NEXT",  $$KIND_STATEMENTS, 0, 0)
	#T_NOT         = MakeToken ("NOT",   $$KIND_UNARY_OPS,  0, $$COPA OR $$PREC_NOT)
	#T_NULL_D      = MakeToken ("NULL$", $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	alphaLast[14]  = tab_sys_ptr - 1
	alphaFirst[15] = tab_sys_ptr
	#T_OCT_D       = MakeToken ("OCT$",  $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_OCTO_D      = MakeToken ("OCTO$", $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_OPEN        = MakeToken ("OPEN",  $$KIND_INTRINSICS, $$ARGS2, $$XLONG)
	#T_OR          = MakeToken ("OR",    $$KIND_BINARY_OPS, 0, $$COP3 OR $$PREC_OR)
	alphaLast[15]  = tab_sys_ptr - 1
	alphaFirst[16] = tab_sys_ptr
	#T_PACKED      = MakeToken ("PACKED",   $$KIND_STATEMENTS, 0, 0)
	#T_POF         = MakeToken ("POF",      $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	#T_PRINT       = MakeToken ("PRINT",    $$KIND_STATEMENTS, 0, 0)
	#T_PROGRAM     = MakeToken ("PROGRAM",  $$KIND_STATEMENTS, 0, 0)
	#T_PROGRAM_D   = MakeToken ("PROGRAM$", $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	alphaLast[16]  = tab_sys_ptr - 1
	alphaFirst[17] = tab_sys_ptr
	#T_QUIT        = MakeToken ("QUIT",     $$KIND_INTRINSICS, $$ARGS1, $$XLONG)
	alphaLast[17]  = tab_sys_ptr - 1
	alphaFirst[18] = tab_sys_ptr
	#T_RCLIP_D     = MakeToken ("RCLIP$",  $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_READ        = MakeToken ("READ",    $$KIND_STATEMENTS, 0, 0)
	#T_REDIM       = MakeToken ("REDIM",   $$KIND_STATEMENTS, 0, 0)
	#T_RETURN      = MakeToken ("RETURN",  $$KIND_STATEMENTS, 0, 0)
	#T_RIGHT_D     = MakeToken ("RIGHT$",  $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_RINCHR      = MakeToken ("RINCHR",  $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_RINCHRI     = MakeToken ("RINCHRI", $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_RINSTR      = MakeToken ("RINSTR",  $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_RINSTRI     = MakeToken ("RINSTRI", $$KIND_INTRINSICS, $$ARGS3, $$XLONG)
	#T_RJUST_D     = MakeToken ("RJUST$",  $$KIND_INTRINSICS, $$ARGS2, $$STRING)
	#T_ROTATEL     = MakeToken ("ROTATEL", $$KIND_INTRINSICS, $$ARGS2, $$XLONG)
	#T_ROTATER     = MakeToken ("ROTATER", $$KIND_INTRINSICS, $$ARGS2, $$XLONG)
	#T_RTRIM_D     = MakeToken ("RTRIM$",  $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	alphaLast[18]  = tab_sys_ptr - 1
	alphaFirst[19] = tab_sys_ptr
	#T_SBYTE       = MakeToken ("SBYTE",      $$KIND_STATE_INTRIN, $$ARGS1, $$SBYTE)
	#T_SBYTEAT     = MakeToken ("SBYTEAT",    $$KIND_STATE_INTRIN, $$ARGS2, $$SBYTE)
	#T_SEEK        = MakeToken ("SEEK",       $$KIND_INTRINSICS,   $$ARGS2, $$XLONG)
	#T_SELECT      = MakeToken ("SELECT",     $$KIND_STATEMENTS,   0, 0)
	#T_SET         = MakeToken ("SET",        $$KIND_INTRINSICS,   $$ARGS3, $$XLONG)
	#T_SFUNCTION   = MakeToken ("SFUNCTION",  $$KIND_STATEMENTS,   0, 0)
	#T_SGN         = MakeToken ("SGN",        $$KIND_INTRINSICS,   $$ARGS1, $$SLONG)
	#T_SHARED      = MakeToken ("SHARED",     $$KIND_STATEMENTS,   $$SHARED, 0)
	#T_SHELL       = MakeToken ("SHELL",      $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_SIGN        = MakeToken ("SIGN",       $$KIND_INTRINSICS,   $$ARGS1, $$SLONG)
	#T_SIGNED_D    = MakeToken ("SIGNED$",    $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_SINGLE      = MakeToken ("SINGLE",     $$KIND_STATE_INTRIN, $$ARGS1, $$SINGLE)
	#T_SINGLEAT    = MakeToken ("SINGLEAT",   $$KIND_STATE_INTRIN, $$ARGS2, $$SINGLE)
	#T_SIZE        = MakeToken ("SIZE",       $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_SLONG       = MakeToken ("SLONG",      $$KIND_STATE_INTRIN, $$ARGS1, $$SLONG)
	#T_SLONGAT     = MakeToken ("SLONGAT",    $$KIND_STATE_INTRIN, $$ARGS2, $$SLONG)
	#T_SMAKE       = MakeToken ("SMAKE",      $$KIND_INTRINSICS,   $$ARGS1, $$SINGLE)
	#T_SPACE_D     = MakeToken ("SPACE$",     $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_SSHORT      = MakeToken ("SSHORT",     $$KIND_STATE_INTRIN, $$ARGS1, $$SSHORT)
	#T_SSHORTAT    = MakeToken ("SSHORTAT",   $$KIND_STATE_INTRIN, $$ARGS2, $$SSHORT)
	#T_STATIC      = MakeToken ("STATIC",     $$KIND_STATEMENTS,   $$STATIC, 0)
	#T_STEP        = MakeToken ("STEP",       $$KIND_STATEMENTS,   0, 0)
	#T_STOP        = MakeToken ("STOP",       $$KIND_STATEMENTS,   0, 0)
	#T_STR_D       = MakeToken ("STR$",       $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_STRING      = MakeToken ("STRING",     $$KIND_STATE_INTRIN, $$ARGS1, $$STRING)
	#T_STRING_D    = MakeToken ("STRING$",    $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_STUFF_D     = MakeToken ("STUFF$",     $$KIND_INTRINSICS,   $$ARGS4, $$STRING)
	#T_SUB         = MakeToken ("SUB",        $$KIND_STATEMENTS,   0, 0)
	#T_SUBADDR     = MakeToken ("SUBADDR",    $$KIND_STATE_INTRIN, $$ARGS1, $$SUBADDR)
	#T_SUBADDRAT   = MakeToken ("SUBADDRAT",  $$KIND_STATE_INTRIN, $$ARGS2, $$SUBADDR)
	#T_SUBADDRESS  = MakeToken ("SUBADDRESS", $$KIND_INTRINSICS,   $$ARGS1, $$SUBADDR)
	#T_SWAP        = MakeToken ("SWAP",       $$KIND_STATEMENTS,   0, 0)
	alphaLast[19]  = tab_sys_ptr - 1
	alphaFirst[20] = tab_sys_ptr
	#T_TAB         = MakeToken ("TAB",   $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_THEN        = MakeToken ("THEN",  $$KIND_STATEMENTS,   0, 0)
	#T_TO          = MakeToken ("TO",    $$KIND_STATEMENTS,   0, 0)
	#T_TRIM_D      = MakeToken ("TRIM$", $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_TRUE        = MakeToken ("TRUE",  $$KIND_STATEMENTS,   0, 0)
	#T_TYPE        = MakeToken ("TYPE",  $$KIND_STATE_INTRIN, $$ARGS1, $$XLONG)
	alphaLast[20]  = tab_sys_ptr - 1
	alphaFirst[21] = tab_sys_ptr
	#T_UBOUND      = MakeToken ("UBOUND",   $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_UBYTE       = MakeToken ("UBYTE",    $$KIND_STATE_INTRIN, $$ARGS1, $$UBYTE)
	#T_UBYTEAT     = MakeToken ("UBYTEAT",  $$KIND_STATE_INTRIN, $$ARGS2, $$UBYTE)
	#T_UCASE_D     = MakeToken ("UCASE$",   $$KIND_INTRINSICS,   $$ARGS1, $$STRING)
	#T_ULONG       = MakeToken ("ULONG",    $$KIND_STATE_INTRIN, $$ARGS1, $$ULONG)
	#T_ULONGAT     = MakeToken ("ULONGAT",  $$KIND_STATE_INTRIN, $$ARGS2, $$ULONG)
	#T_UNION       = MakeToken ("UNION",    $$KIND_STATEMENTS,   0, 0)
	#T_UNTIL       = MakeToken ("UNTIL",    $$KIND_STATEMENTS,   0, 0)
	#T_USHORT      = MakeToken ("USHORT",   $$KIND_STATE_INTRIN, $$ARGS1, $$USHORT)
	#T_USHORTAT    = MakeToken ("USHORTAT", $$KIND_STATE_INTRIN, $$ARGS2, $$USHORT)
	alphaLast[21]  = tab_sys_ptr - 1
	alphaFirst[22] = tab_sys_ptr
	#T_VERSION     = MakeToken ("VERSION",  $$KIND_STATEMENTS, 0, 0)
	#T_VERSION_D   = MakeToken ("VERSION$", $$KIND_INTRINSICS, $$ARGS1, $$STRING)
	#T_VOID        = MakeToken ("VOID",     $$KIND_STATEMENTS, 0, $$VOID)
	alphaLast[22]  = tab_sys_ptr - 1
	alphaFirst[23] = tab_sys_ptr
	#T_WHILE       = MakeToken ("WHILE",    $$KIND_STATEMENTS, 0, 0)
	#T_WRITE       = MakeToken ("WRITE",    $$KIND_STATEMENTS, 0, 0)
	alphaLast[23]  = tab_sys_ptr - 1
	alphaFirst[24] = tab_sys_ptr
	#T_XLONG       = MakeToken ("XLONG",    $$KIND_STATE_INTRIN, $$ARGS1, $$XLONG)
	#T_XLONGAT     = MakeToken ("XLONGAT",  $$KIND_STATE_INTRIN, $$ARGS2, $$XLONG)
	#T_XMAKE       = MakeToken ("XMAKE",    $$KIND_INTRINSICS,   $$ARGS1, $$XLONG)
	#T_XOR         = MakeToken ("XOR",      $$KIND_BINARY_OPS,   0, $$COP3 OR $$PREC_XOR)
	alphaLast[24]  = tab_sys_ptr - 1
	alphaFirst[25] = 0
	alphaLast[25]  = -1
	alphaFirst[26] = 0
	alphaLast[26]  = -1
	alphaFirst[27] = tab_sys_ptr
'
' *****  Bitwise  *****
'
	#T_TILDA      = MakeToken ("~",    $$KIND_UNARY_OPS,  0, $$COPA OR $$PREC_TILDA)
	#T_NOTBIT     = MakeToken ("~",    $$KIND_UNARY_OPS,  0, $$COPA OR $$PREC_NOTBIT)
	#T_ANDBIT     = MakeToken ("&",    $$KIND_BINARY_OPS, 0, $$COP3 OR $$PREC_ANDBIT)
	#T_XORBIT     = MakeToken ("^",    $$KIND_BINARY_OPS, 0, $$COP3 OR $$PREC_XORBIT)
	#T_ORBIT      = MakeToken ("|",    $$KIND_BINARY_OPS, 0, $$COP3 OR $$PREC_ORBIT)
'
' *****  Logical  *****
'
	#T_TESTL      = MakeToken ("!!",   $$KIND_UNARY_OPS,  0, $$COP9 OR $$PREC_TESTL)
	#T_NOTL       = MakeToken ("!",    $$KIND_UNARY_OPS,  0, $$COP9 OR $$PREC_NOTL)
	#T_ANDL       = MakeToken ("&&",   $$KIND_BINARY_OPS, 0, $$COP1 OR $$PREC_ANDL)
	#T_CMPL       = MakeToken ("::",   $$KIND_BINARY_OPS, 0, $$COP1 OR $$PREC_ANDL)
	#T_XORL       = MakeToken ("^^",   $$KIND_BINARY_OPS, 0, $$COP1 OR $$PREC_XORL)
	#T_ORL        = MakeToken ("||",   $$KIND_BINARY_OPS, 0, $$COP1 OR $$PREC_ORL)
'
' *****  Comparison  *****
'
	#T_EQL        = MakeToken ("==",   $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_EQL)
	#T_EQ         = MakeToken ("=",    $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_EQ)
	#T_LT         = MakeToken ("<",    $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_LT)
	#T_GT         = MakeToken (">",    $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_GT)
	#T_NE         = MakeToken ("<>",   $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_NE)
	#T_LE         = MakeToken ("<=",   $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_LE)
	#T_GE         = MakeToken (">=",   $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_GE)
	#T_NEQ        = MakeToken ("!=",   $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_NEQ)
	#T_NNE        = MakeToken ("!<>",  $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_NNE)
	#T_NLT        = MakeToken ("!<",   $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_NLT)
	#T_NGT        = MakeToken ("!>",   $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_NGT)
	#T_NLE        = MakeToken ("!<=",  $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_NLE)
	#T_NGE        = MakeToken ("!>=",  $$KIND_BINARY_OPS, 0, $$COP2 OR $$PREC_NGE)
'
' *****  Shift  *****
'
	#T_RSHIFT     = MakeToken (">>",   $$KIND_BINARY_OPS, 0, $$COP7 OR $$PREC_RSHIFT)
	#T_LSHIFT     = MakeToken ("<<",   $$KIND_BINARY_OPS, 0, $$COP7 OR $$PREC_LSHIFT)
	#T_DSHIFT     = MakeToken (">>>",  $$KIND_BINARY_OPS, 0, $$COP7 OR $$PREC_DSHIFT)
	#T_USHIFT     = MakeToken ("<<<",  $$KIND_BINARY_OPS, 0, $$COP7 OR $$PREC_USHIFT)
'
' *****  Arithmetic  *****
'
	#T_SUBTRACT   = MakeToken ("-",    $$KIND_BINARY_OPS, 0, $$COP4 OR $$PREC_SUBTRACT)
	#T_ADD        = MakeToken ("+",    $$KIND_BINARY_OPS, 0, $$COP5 OR $$PREC_ADD)
	#T_IDIV       = MakeToken ("\\",   $$KIND_BINARY_OPS, 0, $$COP6 OR $$PREC_IDIV) ' xx6n
	#T_MUL        = MakeToken ("*",    $$KIND_BINARY_OPS, 0, $$COP4 OR $$PREC_MUL)
	#T_DIV        = MakeToken ("/",    $$KIND_BINARY_OPS, 0, $$COP4 OR $$PREC_DIV)
	#T_POWER      = MakeToken ("**",   $$KIND_BINARY_OPS, 0, $$COP4 OR $$PREC_POWER)
	#T_PLUS       = MakeToken ("+",    $$KIND_UNARY_OPS,  0, $$COP8 OR $$PREC_UNARY)
	#T_MINUS      = MakeToken ("-",    $$KIND_UNARY_OPS,  0, $$COP8 OR $$PREC_UNARY)
'
' *****  Address  *****
'
	#T_ADDR_OP    = MakeToken ("&",    $$KIND_ADDR_OPS,   0, $$COPB OR $$PREC_ADDR_OP)
	#T_HANDLE_OP  = MakeToken ("&&",   $$KIND_ADDR_OPS,   0, $$COPB OR $$PREC_HANDLE_OP)
	#T_STORE_OP   = MakeToken ("",     $$KIND_ADDR_OPS,   0, $$COPB OR $$PREC_STORE_OP)
'
' *****  Symbols  *****
'
	#T_LPAREN     = MakeToken ("(",    $$KIND_LPARENS,      0, 0)
	#T_RPAREN     = MakeToken (")",    $$KIND_RPARENS,      0, 0)
	#T_COMMA      = MakeToken (",",    $$KIND_SEPARATORS, 0, 0)
	#T_SEMI       = MakeToken (";",    $$KIND_SEPARATORS, 0, 0)
	#T_COLON      = MakeToken (":",    $$KIND_TERMINATORS,  0, 0)
	#T_REM        = MakeToken ("'",    $$KIND_COMMENTS,   0, 0)
	#T_PERCENT    = MakeToken ("%",    $$KIND_CHARACTERS, 0, 0)
	#T_XMARK      = MakeToken ("!",    $$KIND_CHARACTERS, 0, 0)
	#T_ATSIGN     = MakeToken ("@",    $$KIND_CHARACTERS, 0, 0)
	#T_POUND      = MakeToken ("#",    $$KIND_CHARACTERS, 0, 0)
	#T_DOLLAR     = MakeToken ("$",    $$KIND_CHARACTERS, 0, 0)
	#T_DQUOTE     = MakeToken ("\"",   $$KIND_CHARACTERS, 0, 0)
	#T_DOT        = MakeToken (".",    $$KIND_CHARACTERS, 0, 0)
	#T_LBRAK      = MakeToken ("[",    $$KIND_LPARENS,      0, 0)
	#T_RBRAK      = MakeToken ("]",    $$KIND_RPARENS,      0, 0)
	#T_LBRACE     = MakeToken ("{",    $$KIND_LPARENS,      0, 0)
	#T_RBRACE     = MakeToken ("}",    $$KIND_RPARENS,      0, 0)
	#T_LBRACES    = MakeToken ("{{",   $$KIND_LPARENS,      0, 0)
	#T_ULINE      = MakeToken ("_",    $$KIND_CHARACTERS, 0, 0)
	#T_QMARK      = MakeToken ("?",    $$KIND_CHARACTERS, 0, 0)
	#T_TICK       = MakeToken ("`",    $$KIND_CHARACTERS, 0, 0)
	#T_MARK       = MakeToken ("\x7F", $$KIND_CHARACTERS, 0, 0)
	#T_ETC        = MakeToken ("...",  $$KIND_CHARACTERS, 0, $$ETC)
	alphaLast[27] = tab_sys_ptr - 1
'
'
' *****************************************************************************
' *****  Load array charToken[] with tokens that stand for one character  *****
' *****************************************************************************
'
	DIM charToken[255]
'                                   ' 00 - 32 don't have tokens
	charToken[33] = #T_NOTL
	charToken[34] = #T_DQUOTE
	charToken[35] = #T_POUND
	charToken[36] = #T_DOLLAR
	charToken[37] = #T_PERCENT
	charToken[38] = #T_ANDBIT
	charToken[39] = #T_REM
	charToken[40] = #T_LPAREN
	charToken[41] = #T_RPAREN
	charToken[42] = #T_MUL
	charToken[43] = #T_ADD
	charToken[44] = #T_COMMA
	charToken[45] = #T_SUBTRACT
	charToken[46] = #T_DOT
	charToken[47] = #T_DIV
'                                   ' 48 - 57 don't have tokens:  ("0" - "9")
	charToken[58] = #T_COLON
	charToken[59] = #T_SEMI
	charToken[60] = #T_LT
	charToken[61] = #T_EQ
	charToken[62] = #T_GT
	charToken[63] = #T_QMARK
	charToken[64] = #T_ATSIGN
'                                   ' 65 - 90 don't have tokens:  ("A" - "Z")
	charToken[91] = #T_LBRAK
	charToken[92] = #T_IDIV
	charToken[93] = #T_RBRAK
	charToken[94] = #T_XORBIT
	charToken[95] = #T_ULINE
	charToken[96] = #T_TICK
'                                   ' 97 - 122 don't have tokens:  ("a" - "z")
	charToken[123] = #T_LBRACE
	charToken[124] = #T_ORBIT
	charToken[125] = #T_RBRACE
	charToken[126] = #T_NOTBIT
	charToken[127] = #T_MARK
END SUB ' 128 - 255 don't have tokens
'
'
' *****  DefineSystemConstants  *****       ' Don't change spaces in strings
'
SUB DefineSystemConstants
'
	token = Tok ("\"\"", $$ZERO, $$KIND_SYSCONS, $$EXTERNAL, $$STRING, $$IMM16, 0, "0")
	nullstringer = token.tindex
	nullstringerProto = token.tproto
	token = Tok ("$$TRUE",  $$ZERO, $$KIND_SYSCONS, $$SHARED, $$XLONG, $$NEG16, -1, "-1")
	token = Tok ("$$FALSE", $$ZERO, $$KIND_SYSCONS, $$SHARED, $$XLONG, $$IMM16,  0, "0")
	falseToken = token
	pastSystemSymbols = token.tindex + 1
'
END SUB
'
'
' *****  ERRORS  *****
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ####################
' #####  Top ()  #####
' ####################
'
FUNCTION  Top ()
	SHARED  a0,  a1,  toes
'
	IF a0 AND (a0 = toes) THEN RETURN ($$RA0)
	IF a1 AND (a1 = toes) THEN RETURN ($$RA1)
	RETURN (0)
END FUNCTION
'
'
' ########################
' #####  Topaccs ()  #####
' ########################
'
FUNCTION  Topaccs (topa, topb)
	SHARED  stackType[]
	SHARED  toms,  toes,  a0,  a1
	SHARED  XERROR,  ERROR_COMPILER
'
	SELECT CASE TRUE
		CASE (a0 AND (a0 = toes))
			topa = $$rax
			IF (toes > 1) THEN
				topb = $$rbx
				IFZ a1 THEN
					IFZ toms THEN XcowlErr (1130018): GOTO eeeCompiler
					Pop ($$RA1, stackType[toms-1])
					a1 = toes - 1
				END IF
			ELSE
				topb = 0
			END IF
			RETURN ($$rax)
		CASE (a1 AND (a1 = toes))
			topa = $$rbx
			IF (toes > 1) THEN
				topb = $$rax
				IFZ a0 THEN
					IFZ toms THEN XcowlErr (1130031): GOTO eeeCompiler
					Pop ($$RA0, stackType[toms-1])
					a0 = toes - 1
				END IF
			ELSE
				topb = 0
			END IF
			RETURN ($$rbx)
		CASE ELSE
			topa = 0
			topb = 0
	END SELECT
	RETURN (topa)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #######################
' #####  Topax1 ()  #####
' #######################
'
FUNCTION  Topax1 ()
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  toes,  toms,  a0,  a0_type,  a1,  a1_type
	SHARED  stackType[]
'
	SELECT CASE TRUE
		CASE (a0 AND (a0 = toes))
			DEC toes: a0 = 0: a0_type = 0: RETURN ($$RA0)
		CASE (a1 AND (a1 = toes))
			DEC toes: a1 = 0: a1_type = 0: RETURN ($$RA1)
		CASE ELSE
			IFZ toes THEN XcowlErr (1140018): GOTO eeeCompiler
			IFZ toms THEN XcowlErr (1140019): GOTO eeeCompiler
			Pop ($$RA0, stackType[toms-1])
			a0 = 0: a0_type = 0
			RETURN ($$RA0)
	END SELECT
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #######################
' #####  Topax2 ()  #####
' #######################
'
FUNCTION  Topax2 (topa, topb)
	SHARED  stackType[]
	SHARED  XERROR,  ERROR_COMPILER
	SHARED  toms,  toes,  a0,  a0_type,  a1,  a1_type
'
	IF (toes < 2) THEN XcowlErr (1150012): GOTO eeeCompiler
	SELECT CASE TRUE
		CASE (a0 = toes)
					DEC toes: topa = $$rax: a0 = 0: a0_type = 0
					IFZ a1 THEN Pop ($$rbx, stackType[toms-1])
					DEC toes: topb = $$rbx: a1 = 0: a1_type = 0
		CASE (a1 = toes)
					DEC toes: topa = $$rbx: a1 = 0: a1_type = 0
					IFZ a0 THEN Pop ($$rax, stackType[toms-1])
					DEC toes: topb = $$rax: a0 = 0: a0_type = 0
		CASE ELSE
					XcowlErr (1150023): GOTO eeeCompiler
	END SELECT
	RETURN (topa)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' #####################
' #####  Topx ()  #####
' #####################
'
FUNCTION  Topx (tr, trx, nr, nrx)
	SHARED  a0,  a1,  toes
'
	IFZ toes THEN
		tr = 0: trx = 0
		nr = 0: nrx = 0
		RETURN (0)
	END IF
	IF (a0 AND (a0 = toes)) THEN
		tr = $$R14: trx = $$R15           'rax rdx
		IF (a1 AND (a1 = toes - 1)) THEN
			nr = $$R16: nrx = $$R17         'rbx rcx
		ELSE
			nr = 0: nrx = 0
		END IF
		RETURN ($$R14)                    'rax
	END IF
	IF (a1 AND (a1 = toes)) THEN
		tr = $$R16: trx = $$R17           'rbx rcx
		IF (a0 AND (a0 = toes - 1)) THEN
			nr = $$R14: nrx = $$R15         'rax rdx
		ELSE
			nr = 0: nrx = 0
		END IF
		RETURN ($$R16)                    'rbx
	END IF
	RETURN (0)
END FUNCTION
'
'
' ##############################
' #####  TypenameToken ()  #####
' ##############################
'
FUNCTION  TypenameToken (TOKEN token)
	SHARED TOKEN tab_sys[]
'
	IF (token.tp.kind = $$KIND_TYPES) THEN       ' (0x10) *****  USER DEFINED TYPE  *****
		dataType = token.tindex
		NextToken (@token)
		RETURN (dataType)
	END IF
	SELECT CASE token.tindex
		CASE #T_VOID.tindex    :
		CASE #T_ETC.tindex     :
		CASE #T_SBYTE.tindex   :
		CASE #T_UBYTE.tindex   :
		CASE #T_SSHORT.tindex  :
		CASE #T_USHORT.tindex  :
		CASE #T_SLONG.tindex   :
		CASE #T_ULONG.tindex   :
		CASE #T_XLONG.tindex   :
		CASE #T_GOADDR.tindex  :
		CASE #T_SUBADDR.tindex :
		CASE #T_FUNCADDR.tindex:
		CASE #T_SINGLE.tindex  :
		CASE #T_DOUBLE.tindex  :
		CASE #T_GIANT.tindex   :
		CASE #T_STRING.tindex  :
		CASE ELSE:    RETURN (0)
	END SELECT
	IF (tab_sys[token.tindex].tproto != token.tproto) THEN RETURN (0)
	dataType = token.tp.type
	NextToken (@token)
	RETURN (dataType)
'
END FUNCTION
'
'
' ##########################
' #####  TypeToken ()  #####
' ##########################
'
' match = TypeToken (token)
'
' Checks for $$KIND_STATEMENTS_INTRINSICS token kinds
' meaning it is either a statement or intrinsic command
'
' match is returned TRUE if token matches one of the list of tokens
'
FUNCTION  TypeToken (TOKEN token)
	STATIC tn_sbyte
	STATIC tn_ubyte
	STATIC tn_sshort
	STATIC tn_ushort
	STATIC tn_slong
	STATIC tn_ulong
	STATIC tn_xlong
	STATIC tn_goaddr
	STATIC tn_subaddr
	STATIC tn_funcaddr
	STATIC tn_single
	STATIC tn_double
	STATIC tn_giant
	STATIC tn_string
'
	IF (token.tp.kind != $$KIND_STATEMENTS_INTRINSICS) THEN RETURN ($$FALSE)
'
	IFZ tn_string THEN GOSUB InitIntegers
'
	tnumber = token.tindex
	SELECT CASE tnumber
		CASE tn_xlong   :
		CASE tn_string  :
		CASE tn_ulong   :
		CASE tn_ubyte   :
		CASE tn_slong   :
		CASE tn_sbyte   :
		CASE tn_sshort  :
		CASE tn_ushort  :
		CASE tn_goaddr  :
		CASE tn_subaddr :
		CASE tn_funcaddr:
		CASE tn_single  :
		CASE tn_double  :
		CASE tn_giant   :
		CASE ELSE       : RETURN ($$FALSE)
	END SELECT
	RETURN ($$TRUE)
'
'-------------------------------------------------------------------------------------
'
' *****  InitIntegers  *****
'
' The SELECT CASE works faster with integer values
'
SUB InitIntegers
		tn_sbyte    = #T_SBYTE.tindex
		tn_ubyte    = #T_UBYTE.tindex
		tn_sshort   = #T_SSHORT.tindex
		tn_ushort   = #T_USHORT.tindex
		tn_slong    = #T_SLONG.tindex
		tn_ulong    = #T_ULONG.tindex
		tn_xlong    = #T_XLONG.tindex
		tn_goaddr   = #T_GOADDR.tindex
		tn_subaddr  = #T_SUBADDR.tindex
		tn_funcaddr = #T_FUNCADDR.tindex
		tn_single   = #T_SINGLE.tindex
		tn_double   = #T_DOUBLE.tindex
		tn_giant    = #T_GIANT.tindex
		tn_string   = #T_STRING.tindex
END SUB
'
END FUNCTION
'
'
' ####################
' #####  Uop ()  #####
' ####################
'
FUNCTION  Uop (rad, TOKEN the_op, rax, d_type, o_type, x_type)
	EXTERNAL /xxx/  i486asm,  i486bin,  xpc
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_NEG_ULONG,  ERROR_TYPE_MISMATCH
	SHARED  a0_type,  a1_type,  tokenPtr,  labelNumber
	STATIC GOADDR opToken[]
'
	IFZ opToken[] THEN GOSUB LoadOpToken
'
	SELECT CASE rad
		CASE $$RA0: d_reg = $$RA0:  a0_type = d_type
		CASE $$RA1: d_reg = $$RA1:  a1_type = d_type
		CASE ELSE: XcowlErr (1190018): GOTO eeeCompiler
	END SELECT
	d_regx = d_reg + 1
'
	SELECT CASE rax
		CASE $$RA0: x_reg = $$RA0: IF (d_reg != x_reg) THEN XcowlErr (1190023): GOTO eeeCompiler
		CASE $$RA1: x_reg = $$RA1: IF (d_reg != x_reg) THEN XcowlErr (1190024): GOTO eeeCompiler
		CASE ELSE:  XcowlErr (1190025): GOTO eeeCompiler
	END SELECT
	x_regx = x_reg + 1
'
'
' ************************************************************
' *****  DISPATCH TO APPROPRIATE UNARY OPERATOR ROUTINE  *****
' ************************************************************
'
	GOTO @opToken[the_op.ti.ndex]
	PRINT "uop dispatch"
	XcowlErr (1190036): GOTO eeeCompiler
'
'
' *************************
' *****  LOGICAL NOT  *****
' *************************
'
unary_not:
	SELECT CASE o_type
		CASE $$SLONG:   GOSUB Logical_Not_LONG
		CASE $$ULONG:   GOSUB Logical_Not_LONG
		CASE $$XLONG:   GOSUB Logical_Not_LONG
		CASE $$GIANT:   GOSUB Logical_Not_GIANT
		CASE $$SINGLE:  GOSUB Logical_Not_DOUBLE
		CASE $$DOUBLE:  GOSUB Logical_Not_DOUBLE
		CASE $$STRING:  GOSUB Logical_Not_STRING
		CASE ELSE:      XcowlErr (1190052): GOTO eeeCompiler
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB Logical_Not_LONG
	Code ($$neg, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1144")
	Code ($$cmc, 0, 0, 0, 0, 0, "", $$rmk$+"1145")
	Code ($$rcr, $$regimm, x_reg, 1, 0, $$XLONG, "", $$rmk$+"1146")
	Code ($$sar, $$regimm, x_reg, 63, 0, $$XLONG, "", $$rmk$+"1147")
END SUB
'
SUB Logical_Not_GIANT
	Code ($$or, $$regreg, x_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1148")
	Code ($$neg, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1149")
	Code ($$cmc, 0, 0, 0, 0, 0, "", $$rmk$+"1150")
	Code ($$rcr, $$regimm, x_reg, 1, 0, $$XLONG, "", $$rmk$+"1151")
	Code ($$sar, $$regimm, x_reg, 63, 0, $$XLONG, "", $$rmk$+"1152")
END SUB
'
SUB Logical_Not_DOUBLE
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$fldz, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1153")
	Code ($$fcompp, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1154")
	IF (d_reg == $$rax) THEN
		Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"1156")
		Code ($$sahf, 0, 0, 0, 0, 0, "", $$rmk$+"1157")
	ELSE
		Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1158")
		Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"1159")
		Code ($$sahf, 0, 0, 0, 0, 0, "", $$rmk$+"1160")
		Code ($$pop, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1161")
	END IF
	Code ($$mov, $$regimm, d_reg, -1, 0, $$XLONG, "", $$rmk$+"1162")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"1163")
	Code ($$not, $$reg, d_reg, 0, 0, $$XLONG, "", $$rmk$+"1164")
	EmitLabel (@d1$)
END SUB
'
SUB Logical_Not_STRING
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$or, $$regreg, x_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1165")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"1166")
	Code ($$ld, $$regro, x_reg, x_reg, -8, $$XLONG, "", $$rmk$+"1167")
	EmitLabel (@d1$)
	Code ($$neg, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1168")
	Code ($$cmc, 0, 0, 0, 0, 0, "", $$rmk$+"1169")
	Code ($$rcr, $$regimm, x_reg, 1, 0, $$XLONG, "", $$rmk$+"1170")
	Code ($$sar, $$regimm, x_reg, 63, 0, $$XLONG, "", $$rmk$+"1171")
END SUB
'
'
' **************************
' *****  LOGICAL TEST  *****
' **************************
'
unary_test:
	SELECT CASE o_type
		CASE $$SLONG:   GOSUB Logical_Test_LONG
		CASE $$ULONG:   GOSUB Logical_Test_LONG
		CASE $$XLONG:   GOSUB Logical_Test_LONG
		CASE $$GIANT:   GOSUB Logical_Test_GIANT
		CASE $$SINGLE:  GOSUB Logical_Test_DOUBLE
		CASE $$DOUBLE:  GOSUB Logical_Test_DOUBLE
		CASE $$STRING:  GOSUB Logical_Test_STRING
		CASE ELSE:      XcowlErr (11900117): GOTO eeeCompiler
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB Logical_Test_LONG
	Code ($$neg, $$reg, d_reg, 0, 0, $$XLONG, "", $$rmk$+"1172")
	Code ($$rcr, $$regimm, d_reg, 1, 0, $$XLONG, "", $$rmk$+"1173")
	Code ($$sar, $$regimm, d_reg, 63, 0, $$XLONG, "", $$rmk$+"1174")
END SUB
'
SUB Logical_Test_GIANT
	Code ($$or, $$regreg, d_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1175")
	Code ($$neg, $$reg, d_reg, 0, 0, $$XLONG, "", $$rmk$+"1176")
	Code ($$rcr, $$regimm, d_reg, 1, 0, $$XLONG, "", $$rmk$+"1177")
	Code ($$sar, $$regimm, d_reg, 63, 0, $$XLONG, "", $$rmk$+"1178")
END SUB
'
SUB Logical_Test_DOUBLE
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$fldz, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1179")
	Code ($$fcompp, $$none, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1180")
	IF (d_reg == $$rax) THEN
		Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"1182")
		Code ($$sahf, 0, 0, 0, 0, 0, "", $$rmk$+"1183")
	ELSE
		Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1184")
		Code ($$fstsw, $$reg, $$ax, 0, 0, $$XLONG, "", $$rmk$+"1185")
		Code ($$sahf, 0, 0, 0, 0, 0, "", $$rmk$+"1186")
		Code ($$pop, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1187")
	END IF
	Code ($$mov, $$regimm, d_reg, 0, 0, $$XLONG, "", $$rmk$+"1188")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"1189")
	Code ($$not, $$reg, d_reg, 0, 0, $$XLONG, "", $$rmk$+"1190")
	EmitLabel (@d1$)
END SUB
'
SUB Logical_Test_STRING
	INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
	Code ($$or, $$regreg, x_reg, x_reg, 0, $$XLONG, "", $$rmk$+"1191")
	Code ($$jz, $$rel, 0, 0, 0, 0, d1$, $$rmk$+"1192")
	Code ($$ld, $$regro, x_reg, x_reg, -8, $$XLONG, "", $$rmk$+"1193")
	EmitLabel (@d1$)
	Code ($$neg, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1194")
	Code ($$rcr, $$regimm, x_reg, 1, 0, $$XLONG, "", $$rmk$+"1195")
	Code ($$sar, $$regimm, x_reg, 63, 0, $$XLONG, "", $$rmk$+"1196")
END SUB
'
'
' ************************
' *****  UNARY PLUS  *****
' ************************
'
unary_plus:
	the_op = #T_ZERO
	RETURN
'
'
' *************************
' *****  UNARY MINUS  *****
' *************************
'
unary_minus:
	SELECT CASE o_type
		CASE $$SLONG:   GOSUB Unary_Minus_SLONG
		CASE $$XLONG:   GOSUB Unary_Minus_XLONG
		CASE $$GIANT:   GOSUB Unary_Minus_GIANT
		CASE $$SINGLE:  GOSUB Unary_Minus_SINGLE
		CASE $$DOUBLE:  GOSUB Unary_Minus_DOUBLE
		CASE $$ULONG:   GOTO  eeeNegULONG
		CASE ELSE:      XcowlErr (11900187): GOTO eeeCompiler
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB Unary_Minus_SLONG
	Code ($$neg, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1197")
END SUB
'
SUB Unary_Minus_XLONG
	Code ($$neg, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1198")
END SUB
'
SUB Unary_Minus_GIANT
	Code ($$neg, $$reg, x_regx, 0, 0, $$XLONG, "", $$rmk$+"1199")
	Code ($$neg, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1200")
	Code ($$sbb, $$regimm, x_regx, 0, 0, $$XLONG, "", $$rmk$+"1201")
END SUB
'
SUB Unary_Minus_SINGLE
	Code ($$fchs, 0, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1202")
END SUB
'
SUB Unary_Minus_DOUBLE
	Code ($$fchs, 0, 0, 0, 0, $$DOUBLE, "", $$rmk$+"1203")
END SUB
'
'
' *************************
' *****  BITWISE NOT  *****
' *************************
'
unary_notbit:
	SELECT CASE o_type
		CASE $$GIANT:   GOSUB Notbit_GIANT
		CASE $$SINGLE:  DEC tokenPtr: XcowlErr (11900222): GOTO eeeTypeMismatch
		CASE $$DOUBLE:  DEC tokenPtr: XcowlErr (11900223): GOTO eeeTypeMismatch
		CASE ELSE:      GOSUB Notbit_LONG
	END SELECT
	the_op = #T_ZERO
	RETURN
'
SUB Notbit_LONG
	Code ($$not, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1204")
END SUB
'
SUB Notbit_GIANT
	Code ($$not, $$reg, x_reg, 0, 0, $$XLONG, "", $$rmk$+"1205")
	Code ($$not, $$reg, x_regx, 0, 0, $$XLONG, "", $$rmk$+"1206")
END SUB
'
'
' ************************************************
' *****  Load UNARY OPERATOR dispatch array  *****
' ************************************************
'
SUB LoadOpToken
	DIM opToken[255]
	opToken[ #T_NOTL.ti.ndex    ] = GOADDRESS (unary_not)
	opToken[ #T_TESTL.ti.ndex   ] = GOADDRESS (unary_test)
	opToken[ #T_PLUS.ti.ndex    ] = GOADDRESS (unary_plus)
	opToken[ #T_MINUS.ti.ndex   ] = GOADDRESS (unary_minus)
	opToken[ #T_NOTBIT.ti.ndex  ] = GOADDRESS (unary_notbit)
	opToken[ #T_TILDA.ti.ndex   ] = GOADDRESS (unary_notbit)
	opToken[ #T_NOT.ti.ndex     ] = GOADDRESS (unary_notbit)
END SUB
'
'
' **************************
' *****  UNARY ERRORS  *****
' **************************
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeNegULONG:
	XERROR = ERROR_NEG_ULONG
	EXIT FUNCTION
'
eeeTypeMismatch:
	XERROR = ERROR_TYPE_MISMATCH
	EXIT FUNCTION
END FUNCTION
'
'
' ############################
' #####  UpdateToken ()  #####
' ############################
'
FUNCTION  UpdateToken (TOKEN token)
	SHARED  TOKEN tab_sym[]
'
	x = token.tindex
	tab_sym[x] = token
'
END FUNCTION
'
'
' ######################
' #####  Value ()  #####
' ######################
'
' Value() returns the address of the specified label$.  If the address of
' the specified label$ has not been defined, a zero is returned and the
' patch table arrays are updated to have the current xpc location updated
' with the label$ address on the final pass.  When Value() is called, xpc
' must point to the location in memory where the address is to be stored,
' not the location of the first byte of the instruction that it's a part of.
'
' addrmode is $$VALUEABS or $$VALUEDISP, according to whether the number
' to be stored in memory is the absolute value of label$ or a relative offset
' (displacement) from label$.
'
FUNCTION  Value (label$, addrmode)
	EXTERNAL /xxx/  xpc
	TOKEN   token
	SHARED TOKEN patchDest[]
	SHARED  labaddr[],  patchType[],  patchAddr[]
	SHARED  XERROR,  ERROR_COMPILER,  patchPtr,  upatch
'
	IFF label$ THEN
		XcowlErr (1210027): GOTO eeeCompiler
	END IF
	token = AddLabel (@label$, $$KIND_LABELS, 0, $$XADD)
	IF XERROR THEN EXIT FUNCTION
	IFF TokenMatch (@token, @#T_ZERO) THEN
		tt = token.tindex
		vv = labaddr[tt]
		IF vv THEN
			value = vv
		ELSE
			IF (patchPtr >= upatch) THEN
				upatch = upatch + 8192
				REDIM patchType[upatch]
				REDIM patchAddr[upatch]
				REDIM patchDest[upatch]
			END IF
			patchType[patchPtr] = addrmode
			patchAddr[patchPtr] = xpc
			patchDest[patchPtr] = token
			INC patchPtr
			value = 0
		END IF
	ELSE
		XcowlErr (1210050): GOTO eeeCompiler
	END IF
	RETURN (value)
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ##################################
' #####  WriteDeclarationFile  #####
' ##################################
'
FUNCTION  WriteDeclarationFile (string$)
	EXTERNAL /xxx/  i486asm,  i486bin,  library
	SHARED  declareCount
	SHARED  declare$[]
'
	IFZ i486asm THEN RETURN
	IFZ string$ THEN RETURN
'
' put string$ in declare$[] that will become "prog.dec" file
'
	upper = UBOUND (declare$[])
	IF (declareCount > upper) THEN
		upper = upper + 64
		REDIM declare$[upper]
'   PRINT "WriteDeclarationFile", upper
	END IF
'
	declare$[declareCount] = string$
	INC declareCount
'
END FUNCTION
'
'
' #################################
' #####  WriteDefinitionFile  #####
' #################################
'
FUNCTION  WriteDefinitionFile (string$)
	EXTERNAL /xxx/  i486asm,  i486bin,  library
	SHARED  export$[]
	SHARED  import$[]
	SHARED  exportCount
	SHARED  importCount
'
	IFZ i486asm THEN RETURN
	IFZ string$ THEN RETURN
'
	xport = INSTR (string$, "EXPORT")
	IF (xport = 1) THEN
		upper = UBOUND (export$[])
		IF (exportCount > upper) THEN
			upper = upper + 64
			REDIM export$[upper]
		END IF
		export$[exportCount] = string$
		INC exportCount
		RETURN
	END IF
'
	import = INSTR (string$, "IMPORT")
	IF (import = 1) THEN
		upper = UBOUND (import$[])
		IF (importCount > upper) THEN
			upper = upper + 64
			REDIM import$[upper]
		END IF
		import$[importCount] = string$
		INC importCount
		RETURN
	END IF
'
	PRINT "WriteDefinitionFile(): error: string does not start with EXPORT or IMPORT: "; string$
END FUNCTION
'
'
' #########################
' #####  XcowlErr ()  #####
' #########################
'
' The id = the function number + two zeros + the line number
'
FUNCTION  XcowlErr (id)
	ULONG frame, stack
	SHARED  TOKEN tokens[]
	SHARED  tokenCount,  tokenPtr
'
	IFZ ##XBDV THEN RETURN
	IF ##WHOMASK THEN STOP   ' permanent breakpoint
'
	id$ = STRING$(id)
	zeros = INSTR(id$, "000")  ' function numbers 10, 20, 30 ...
	IF zeros THEN
		funcNum$ = LEFT$(id$, zeros)
		lineNum$ = MID$(id$, zeros+3)
	ELSE
		zeros = INSTR(id$, "00")
		IF zeros THEN
			funcNum$ = LEFT$(id$, zeros-1)
			lineNum$ = MID$(id$, zeros+2)
		ELSE
			PRINT "XcowlErr(1240028) invalid id", id
		END IF
	END IF
'
	PRINT "XcowlErr(1240032) function", funcNum$, "line", lineNum$
'
	RETURN   ' comment out this line to get additional frame information on linux terminal
'
	IFZ ##WHOMASK THEN
		XxxGetRbpRsp (@frame, @stack)
		funcAddress = XLONGAT(frame,4)
		frames$ = Frames$ ()
		frames$ = "XcowlErr(1240040):frames\n" + frames$
		XxxLog(frames$)
'
		s$ = "     tokens\n"
		FOR i = 0 TO tokenCount
			s$ = s$ + HEX$(tokens[i].tproto,8) + "." + HEX$(tokens[i].tindex,8)
			IF (i == tokenPtr) THEN
				s$ = s$ + "*\n"
			ELSE
				s$ = s$ + "\n"
			END IF
		NEXT i
		XxxLog(s$)
	END IF
'
END FUNCTION
'
'
' #############################
' #####  XxxCheckLine ()  #####
' #############################
'
FUNCTION  XxxCheckLine (lineNum, TOKEN tok[])
	SHARED  XERROR,  tokenCount,  lineNumber
	SHARED  pass2errors,  ERROR_UNDEFINED
	SHARED  TOKEN tokens[]
'
	lineNumber = lineNum
	tokenCount = UBOUND(tok[])
	FOR i = 0 TO tokenCount
		tokens[i].tproto = tok[i].tproto
		tokens[i].tindex = tok[i].tindex
	NEXT i

	IF (tokens[tokenCount].tproto <> $$TP_STARTS) THEN
		PRINT "XxxCheckLine(22)", HEX$(tokens[tokenCount].tproto,8); "."; HEX$(tokens[tokenCount].tindex,8)
	END IF
	CheckOneLine ()
	IF pass2errors THEN RETURN (ERROR_UNDEFINED)
	RETURN (XERROR)
END FUNCTION
'
'
' #####################################
' #####  XxxCloseCompileFiles ()  #####
' #####################################
'
FUNCTION  XxxCloseCompileFiles ()
	EXTERNAL /xxx/  i486asm,  i486bin,  library
	SHARED  ofile
	SHARED  asmFile$
	SHARED  version$
	SHARED  program$
	SHARED  programPath$
	SHARED  export$[]
	SHARED  import$[]
	SHARED  declare$[]
	SHARED  exportCount
	SHARED  importCount
	SHARED  declareCount
	SHARED  export
'
	p$ = programPath$                                   ' has path and filename
	IF (RIGHT$(p$,2) = ".x") THEN p$ = RCLIP$(p$,2)     ' remove ".x" suffix
	IFZ p$ THEN p$ = program$
	IFZ p$ THEN p$ = "NoName"
'
' close the "prog.s" file
'
	IF (ofile > 2) THEN CLOSE (ofile)
	asmFile$ = ""
	ofile = 0
'
' save "prog.dec" file if declare$[] has contents
'
	IF declareCount THEN
		file$ = p$ + ".dec"
		REDIM declare$[declareCount]
		XstSaveStringArray (@file$, @declare$[])
	END IF
	DIM declare$[]
	declareCount = 0
'
' save "prog.def" file if export$[] or import$[] has contents
'
	IF (exportCount OR importCount) THEN
		IF library THEN
			prog$ = "LIBRARY  " + p$
		ELSE
			prog$ = "PROGRAM  " + p$
		END IF
'
		vers$ = version$
		IFZ vers$ THEN vers$ = "0.0000"
		vers$ = "VERSION  " + vers$
'
		upper = exportCount + importCount + 2
		DIM def$[upper]
		def$[0] = prog$
		def$[1] = vers$
'
		REDIM export$[exportCount-1]
		REDIM import$[importCount-1]
		XstQuickSort (@export$[], @n[], 0, exportCount-1, 0)
		XstQuickSort (@import$[], @n[], 0, importCount-1, 0)
'
		def = 2
		FOR i = 0 TO exportCount-1
			def$[def] = export$[i]
			INC def
		NEXT i
'
		FOR i = 0 TO importCount-1
			def$[def] = import$[i]
			INC def
		NEXT i
'
		file$ = p$ + ".def"
		XstSaveStringArray (@file$, @def$[])
	END IF
'
	export = 0
	exportCount = 0
	importCount = 0
	DIM export$[]
	DIM import$[]
END FUNCTION
'
'
' ###############################
' #####  XxxCompilePrep ()  #####
' ###############################
'
FUNCTION  XxxCompilePrep ()
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   token
	TOKEN   tokenTemp[]
	SHARED  funcKind[], labaddr[], tab_sym$[]
	SHARED  r_addr[],  r_addr$[],  m_reg[],  m_addr[],  m_addr$[]
	SHARED  tabType[],  patchType[],  patchAddr[]
	SHARED  pastSystemLabels,  pastSystemSymbols,  oos
	SHARED  tab_sym_ptr,  upatch,  ulabel,  uFunc, uType
	SHARED  compositeNumber[]
	SHARED  typeSize$[]
	SHARED  typeAlias[]
	SHARED  typeAlign[]
	SHARED  typeSize[]
	SHARED  typeEleCount[]
	SHARED  typeEleSymbol$[]
	SHARED  typeEleAddr[]
	SHARED  typeEleSize[]
	SHARED  typeEleType[]
	SHARED  typeEleVal[]
	SHARED  typeElePtr[]
	SHARED  typeEleStringSize[]
	SHARED  typeEleUBound[]
'
	SHARED  TOKEN compositeNext[]
	SHARED  TOKEN compositeStart[]
	SHARED  TOKEN compositeToken[]
	SHARED  TOKEN funcToken[]
	SHARED  TOKEN patchDest[]
	SHARED  TOKEN tabArg[]
	SHARED  TOKEN tab_sym[]
	SHARED  TOKEN typeEleArg[]
	SHARED  TOKEN typeEleToken[]

'
	oos = 0
	DIM compositeNumber[uFunc]
	DIM compositeNext[uFunc, ]
	DIM compositeStart[uFunc, ]
	DIM compositeToken[uFunc, ]
'
'
' *****  Clear type information for types > DCOMPLEX  (all user-types)
'
	i = $$DCOMPLEX + 1
	DO WHILE (i <= uType)
		typeSize$[i]    = ""
		typeAlias[i]    =  0
		typeAlign[i]    =  0
		typeSize[i]     =  0
		typeEleCount[i] =  0
		ATTACH typeEleSymbol$[i, ] TO temp$[]:    DIM temp$[]
		ATTACH typeEleToken[i, ] TO tokenTemp[]:      DIM tokenTemp[]
		ATTACH typeEleAddr[i, ] TO temp[]:        DIM temp[]
		ATTACH typeEleSize[i, ] TO temp[]:        DIM temp[]
		ATTACH typeEleType[i, ] TO temp[]:        DIM temp[]
		ATTACH typeEleArg[i, ]  TO tokenTemp[]:      DIM tokenTemp[]
		ATTACH typeEleVal[i, ] TO temp[]:         DIM temp[]
		ATTACH typeElePtr[i, ] TO temp[]:         DIM temp[]
		ATTACH typeEleStringSize[i, ] TO temp[]:  DIM temp[]
		ATTACH typeEleUBound[i, ] TO temp[]:      DIM temp[]
		INC i
	LOOP
'
' *****  Clear CFUNCTION, DECLARED, DEFINED bits in all function tokens
'
	i = 1
	DO
		funcToken[i].tp.allo = 0
		funcKind[i]   = $$FALSE
		INC i
	LOOP WHILE (i <= maxFuncNumber)
'
' *****  Clear all label addresses
'
	i = pastSystemLabels
	DO
		labaddr[i]  = 0
		INC i
	LOOP WHILE (i <= ulabel)
'
' *****  Clear variable allocation addresses, allo/type fields, etc...
'
	utoken = tab_sym_ptr
	i = pastSystemSymbols
	DO
		r_addr[i]     = 0
		r_addr$[i]    = ""
		m_reg[i]      = 0
		m_addr[i]     = 0
		m_addr$[i]    = ""
		tabType[i]    = 0
		token         = tab_sym[i]
		kind          = token.tp.kind
		ATTACH tabArg[i, ] TO tokenTemp[]: DIM tokenTemp[]
		SELECT CASE kind
			CASE $$KIND_VARIABLES, $$KIND_ARRAYS
						IF tab_sym$[i] THEN
							IF (tab_sym$[i]{0} != '#') THEN tab_sym[i].tp.allo = 0
						END IF
		CASE $$KIND_SYSCONS, $$KIND_CONSTANTS
						IF (tab_sym[i].tp.type != $$STRING) THEN
							tab_sym[i].tp.type = 0
						END IF
		END SELECT
		INC i
	LOOP WHILE (i <= utoken)
'
' *****  Clear patch arrays
'
	i = 0
	DO
		patchType[i] = 0
		patchAddr[i] = 0
		patchDest[i] = #T_ZERO
		INC i
	LOOP WHILE (i <= upatch)
END FUNCTION
'
'
' ######################################
' #####  XxxCreateCompileFiles ()  #####
' ######################################
'
FUNCTION  XxxCreateCompileFiles ()
	EXTERNAL /xxx/  i486asm,  i486bin
	SHARED  ofile
	SHARED  asmFile$
	SHARED  programName$
	SHARED  programPath$
	SHARED  XERROR,  ERROR_OPEN_FILE,  ERROR_PROGRAM_NOT_NAMED
'
	IFZ i486asm THEN PRINT "a": RETURN
	IF (ofile > 0) THEN PRINT "b": RETURN
	IFZ programName$ THEN XcowlErr (1280017): GOTO eeeProgramNotNamed
	IFZ programPath$ THEN XcowlErr (1280018): GOTO eeeProgramNotNamed
	IF (RIGHT$(programPath$,2) != ".x") THEN XcowlErr (1280019): GOTO eeeProgramNotNamed
'
	pathname$ = programPath$
	XstDecomposePathname (@pathname$, @oldpath$, @parent$, @filename$, @file$, @extent$)
	oldfile$ = oldpath$ + $$PathSlash$ + filename$      ' original full path filename$
	XstGetFileAttributes (@oldfile$, @attr)             ' original filename attributes
	GOSUB OldWay                                        ' puts stuff in source file directory
'
' GOSUB NewWay                                        ' creates project directory
' GOSUB Backup                                        ' backup source file
'
' open assembly file
'
	programPath$ = newpath$ + $$PathSlash$ + filename$
	asmFile$ = newpath$ + $$PathSlash$ + file$ + ".s"
	ofile = OPEN (asmFile$, $$WRNEW)
	IF (ofile < 0) THEN ofile = 0: XcowlErr (1280035): GOTO eeeOpenFile
	RETURN
'
'
' *****  OldWay  *****
'
SUB OldWay
	newpath$ = oldpath$
END SUB
'
'
' *****  NewWay  *****
'
SUB NewWay
	IF (parent$ = file$) THEN                           ' prog.x file is in a project directory
		newpath$ = oldpath$                               ' so newpath$ = oldpath$
		oldfile$ = newpath$ + $$PathSlash$ + filename$    ' and oldfile$ = oldpath$ + filename$
		newfile$ = newpath$ + $$PathSlash$ + filename$    ' and newfile$ = oldpath$ + filename$
	ELSE                                                ' prog.x file not in a project directory
		newpath$ = oldpath$ + $$PathSlash$ + file$        ' newpath$ is project directory name
		XstGetFileAttributes (@newpath$, @pattr)          ' does newpath$ exist?  if so what is it?
		IFZ (pattr AND $$FileDirectory) THEN              ' no newpath$ directory
			XstMakeDirectory (@newpath$)                    ' so create newpath$ directory
			XstGetFileAttributes (@newpath$, @pattr)        ' make sure newpath$ now exists
			IFZ (pattr AND $$FileDirectory) THEN            ' didn't create newpath$ directory
				XstGetFileAttributes (@oldpath$, @pattr)      ' make sure current path$ is a directory
				newpath$ = oldpath$                           ' give up - settle for current path$
			END IF
		END IF
'
' newpath$ better be a directory at this point else resort to current directory
'
		IFZ (pattr AND $$FileDirectory) THEN              ' if newpath$ is a directory
			XstGetCurrentDirectory (@newpath$)              ' newpath$ = current directory
			XstGetFileAttributes (@newpath$, @pattr)        ' make sure newpath$ exists
		END IF
	END IF
END SUB
'
'
' *****  Backup  *****  backup previous newfile$ or make copy of oldfile$
'
SUB Backup
	newfile$ = newpath$ + $$PathSlash$ + filename$    ' newfile$ is filename in newpath$
	XstGetFileAttributes (@newfile$, @fattr)          ' does newfile$ exist?
	IFZ fattr THEN                                    ' newfile$ does not exist in project directory
		IF attr THEN                                    ' if oldfile$ exists
			XstCopyFile (@oldfile$, @newfile$)            ' create newfile$
		END IF
	END IF
'
	XstGetFileAttributes (@newfile$, @fattr)          ' does newfile$ exist?
	IFZ fattr THEN                                    '
		IF attr THEN
			XstCopyFile (oldfile$, newfile$)              ' make backup copy of oldfile
		END IF
	ELSE                                              ' backup existing newfile$
		checkfile$ = newfile$ + "??"                    ' look for all backups of newfile$
		XstGetFiles (@checkfile$, @file$[])             ' get names of previous versions
		IFZ file$[] THEN                                ' if no previous versions exist
			backfile$ = newfile$ + "00"                   ' start backup filenames at ".x00"
		ELSE
			upper = UBOUND (file$[])                      ' upper bound of previous versions array
			XstQuickSort (@file$[], @n[], 0, upper, 0)    ' in alphabetical order
			backfile$ = newpath$ + $$PathSlash$ + file$[upper]  ' get previous backup filename
			IF (RIGHT$(backfile$,2) = ".x") THEN          ' no backups filenames yet
				backfile$ = backfile$ + "00"                ' start backup filenames at ".x00"
			ELSE
				u = UBOUND (backfile$)                      ' offset to last character in backfile$
				z = backfile${u}                            ' last character in backfile$ version
				y = backfile${u-1}                          ' last-1 character in backfile$ version
				x = backfile${u-2}                          ' last-2 character in backfile$ version
				d = backfile${u-3}                          ' last-3 character in backfile$ version
				IF (x != 'x') THEN PRINT "x yipes, stripes" ' last-2 must be an 'x' character !!!
				IF (d != '.') THEN PRINT ". yipes, stripes" ' last-3 must be a '.' character !!!
				SELECT CASE z
					CASE '9' : z = 'A'
					CASE 'Z' : z = '0'
					CASE ELSE: INC z
				END SELECT
				IF (z = '0') THEN
					SELECT CASE y
						CASE '9' : y = 'A'
						CASE 'Z' : y = '0'
						CASE ELSE: INC y
					END SELECT
					IF (y = '0') THEN
						SELECT CASE x
							CASE 'x' : x = 'y'
							CASE ELSE: PRINT "version overflow - readjust version numbers"
						END SELECT
					END IF
				END IF
				backfile${u} = z
				backfile${u-1} = y
				backfile${u-2} = x
				IF (x != 'x') THEN PRINT "DANGER: out of new backup version #s: "; backfile$
			END IF
		END IF
		XstCopyFile (@newfile$, @backfile$)             ' back up previous newfile$
	END IF
'
' now that newfile$ is backed up, copy oldfile$ to newfile$
'
	IF attr THEN
		IF (oldfile$ != newfile$) THEN                  '
			XstCopyFile (@oldfile$, newfile$)
		END IF
	END IF
END SUB
'
'
' *****  Errors  *****
'
eeeOpenFile:
	XERROR = ERROR_OPEN_FILE
	RETURN
'
eeeProgramNotNamed:
	XERROR = ERROR_PROGRAM_NOT_NAMED
	RETURN
END FUNCTION
'
'
' ##################################
' #####  XxxDeleteFunction ()  #####
' ##################################
'
FUNCTION  XxxDeleteFunction (funcNumber)
	SHARED  funcLabel$[],  funcKind[],  funcType[],  funcScope[]
	TOKEN   tempToken[]
	SHARED  TOKEN  funcArg[]
	SHARED  TOKEN  funcToken[]
'
	funcKind[funcNumber]      = 0
	funcType[funcNumber]      = 0
	funcScope[funcNumber]     = 0
	funcLabel$[funcNumber]    = ""
	funcToken[funcNumber].tp.allo = 0
	ATTACH funcArg[funcNumber, ] TO tempToken[]
	DIM tempToken[]
END FUNCTION
'
'
' ###################################
' #####  XxxDeparseFunction ()  #####
' ###################################
'
FUNCTION  XxxDeparseFunction (func$, TOKEN func[], lastLine, flags)
	TOKEN   startToken
	TOKEN   token
	TOKEN   tok[]
	SHARED  funcSymbol$[],  tab_lab$[],  tab_sym$[],  tab_sys$[]
	SHARED  typeSymbol$[]
	SHARED  XERROR,  ERROR_COMPILER
	STATIC SUBADDR kindDeparse[]
'
	IFZ kindDeparse[] THEN GOSUB LoadKindDeparse
	IFZ func[] THEN func$ = "": RETURN
	IF (lastLine > UBOUND(func[])) THEN XcowlErr (1300018): GOTO eeeCompiler
'
	tokens = 0
	FOR funcLine = 0 TO lastLine
		tokens = tokens + UBOUND(func[funcLine,]) + 1
	NEXT funcLine
	funcSize  = tokens * 8 + 256          ' about twice the average size needed
	IF (funcSize < 511) THEN funcSize = 511   ' minimum size = 511 characters
	funcTerm = funcSize - 256
	func$ = NULL$(funcSize)               ' make room to deparse function string
	funcBase = &func$                     ' build deparsed function string here
	offset = 0                            ' cumulative offset into func$
'
	FOR funcLine = 0 TO lastLine          ' deparse all lines in function
		ATTACH func[funcLine, ] TO tok[]    ' get tokens for this line
		IFZ tok[] THEN                      ' no tokens for this line
			GOSUB AppendNewline               ' append newline (blank line)
			DO NEXT                           ' do next line of tokens
		END IF
		IF (flags AND 0x01) THEN            ' clearBP_EXE
			startToken = tok[0]
			tok[0].ti.bpexe = $$BPEXECLR      ' clears BP/EXE
			tok[0].ti.errno = 0               ' clears error number
		END IF
		uToken  = UBOUND(tok[])             ' upper bound of this line of tokens
		count   = 0                         ' start with 0th token
		DO WHILE (count <= uToken)          ' deparse through last token
			token   = tok[count]              ' get the next token
			tt      = token.tindex          ' get the token number
			kind    = token.tp.kind         ' get the token kind
			spaces  = token.tp.stsp         ' get the space field
			IF TokenMatch (@token, @#T_ZERO) THEN EXIT DO       ' end of line
			IF (count AND (kind = $$KIND_STARTS)) THEN EXIT DO  ' START tokens stop
			IF (spaces >= 0) THEN
				whiteChar = 32                  ' spaces (not tabs)
			ELSE
				whiteChar = 9                   ' tabs (not spaces)
				spaces = -spaces
			END IF
			IF (offset >= funcTerm) THEN      ' need more space in function string
				expand = funcSize               ' double function string size
				GOSUB ExpandFuncString
			END IF
			done    = $$FALSE                 ' not done this line of tokens yet
			GOSUB @kindDeparse[kind]          ' deparse this kind of token
			INC count                         ' next token on this line
		LOOP UNTIL done
		IF (flags AND 0x01) THEN tok[0] = startToken  ' clearBP_EXE: restore startToken
		ATTACH tok[] TO func[funcLine, ]              ' replace line of tokens in func[]
		GOSUB AppendNewline
	NEXT funcLine
	funcLength  = offset                  ' funcLength
	funcHead    = &func$ - 16             ' address of function string header
	XLONGAT (funcHead) = offset           ' set final function string length
	RETURN (funcLength)                   ' return length of function string
'
'
' *****  ExpandFuncString  *****
'
SUB ExpandFuncString
	funcSize = funcSize + expand          ' new maximum string size
	funcTerm = funcSize - 256             ' new maximum starting point
	func$ = func$ + NULL$ (expand)        ' add to function string size
	funcBase = &func$                     ' new address of function string
END SUB
'
'
' ****************************************************************
' *****  Subroutines to deparse different "kinds" of tokens  *****
' ****************************************************************
'
SUB SystemSymbols
	sourceAddr  = &tab_sys$[tt]
	GOSUB AppendString
	GOSUB AppendSpace
END SUB
'
SUB UserSymbols
	sourceAddr  = &tab_sym$[tt]
	GOSUB AppendString
	GOSUB AppendSpace
END SUB
'
SUB FunctionSymbols
	sourceAddr  = &funcSymbol$[tt]
	GOSUB AppendString
	GOSUB AppendSpace
END SUB
'
SUB UserLabels
	s$ = MID$(tab_lab$[tt], 4)
' suffix = RINSTR (s$, ".")               ' gas ?
	suffix = RINSTR (s$, $$ulpc$)               ' unspas
	s$ = LEFT$(s$, suffix - 1)
	IF (count = 1) THEN s$ = s$ + ":"
	sourceAddr  = &s$
	GOSUB AppendString
	GOSUB AppendSpace
END SUB
'
SUB SystemStarts
	errorIndex = token.ti.errno                       ' errno is BYTE1
	IF errorIndex THEN
		errno$ = RIGHT$("000" + STRING(errorIndex), 3)
		sourceAddr = &errno$: GOSUB AppendString
	END IF
	SELECT CASE token.ti.bpexe
		CASE $$BPEXECLR:
		CASE $$BP      : sourceAddr = &":"  : GOSUB AppendString
		CASE $$EXE     : sourceAddr = &">"  : GOSUB AppendString
		CASE $$BPEXE   : sourceAddr = &">:" : GOSUB AppendString
		CASE ELSE      : PRINT "XxxDeparseFunction(131):Invalid .bpexe"
	END SELECT
'
	IF spaces THEN
		GOSUB AppendSpace
	END IF
END SUB
'
SUB SystemWhites
	IF spaces THEN
		GOSUB AppendSpace
	END IF
END SUB
'
SUB SystemComments
	charCount   = token.tp.type           ' number of bytes following '
	sourceAddr  = &"'"                    ' address of '
	GOSUB AppendString                    ' append ' to function string
	IFZ charCount THEN EXIT SUB           ' nothing following the '
	INC count                             ' 1st token of comment text
'
	IF (charCount = 255) THEN             ' charCount = 255 means ...
		charCount = tok[count].tindex       ' charCount in next 32-bit token
		INC count                           ' point to next token
	END IF                                '
	commentAddr = &tok[count].tindex              ' address of comment text
'
	IF (funcSize <= (offset + charCount + 16)) THEN
		expand = offset + charCount + 256
		GOSUB ExpandFuncString
	END IF
'
	FOR x = 0 TO charCount-1              ' for every comment character
		n = UBYTEAT (commentAddr)           ' n = next comment character
		UBYTEAT (funcBase, offset) = n      ' append character to function string
		INC commentAddr                     ' INC offset into comment tokens
		INC offset                          ' INC offset into function string
	NEXT                                  ' next comment character
	done = $$TRUE                         ' done deparsing this line
END SUB
'
SUB UserTypes
	sourceAddr  = &typeSymbol$[tt]
	GOSUB AppendString
	GOSUB AppendSpace
END SUB
'
SUB BogusToken
	PRINT "*****  DEPARSEFUNCTION:  BOGUS TOKEN  *****"
END SUB
'
SUB AppendString                        ' sourceAddr = addr of string to append
	IFZ sourceAddr THEN EXIT SUB          ' null string (shouldn't happen ???)
	shead   = sourceAddr - 0x0010         ' address of source string header
	scount  = XLONGAT (shead)             ' number of bytes to append
	IFZ scount THEN EXIT SUB              ' zero length string
'
	IF (funcSize <= (offset + scount + 16)) THEN
		expand = offset + scount + 256
		GOSUB ExpandFuncString
	END IF
'
	FOR i = 0 TO scount-1                 ' for every character in source
		schar   = UBYTEAT (sourceAddr)      ' get source character
		UBYTEAT (funcBase, offset) = schar  ' append character to function string
		INC sourceAddr                      ' INC offset past source character
		INC offset                          ' INC offset past function character
	NEXT i
END SUB
'
SUB AppendSpace
	IFZ spaces THEN EXIT SUB                  ' no white spaces to append
	FOR i = 1 TO spaces
		UBYTEAT (funcBase, offset) = whiteChar  ' append white character
		INC offset
	NEXT i
END SUB
'
SUB AppendNewline
	IF (flags AND 0x02) THEN
		UBYTEAT (funcBase, offset) = '\r'       ' CRLF for WindowsNT and Win32s
		INC offset                              ' enable these lines for Windows
	END IF
	UBYTEAT (funcBase, offset) = '\n'
	INC offset
END SUB
'
SUB LoadKindDeparse
	DIM kindDeparse[31]
	FOR i = 0 TO 31
		kindDeparse[i] = SUBADDRESS (BogusToken)
	NEXT i
	kindDeparse[ $$KIND_TERMINATORS   ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_STATE_INTRIN  ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_STATEMENTS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_INTRINSICS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_SEPARATORS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_CHARACTERS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_BINARY_OPS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_UNARY_OPS     ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_ADDR_OPS      ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_LPARENS       ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_RPARENS       ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_SYMBOLS       ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_ARRAY_SYMBOLS ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_VARIABLES     ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_ARRAYS        ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_LITERALS      ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_CONSTANTS     ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_CHARCONS      ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_SYSCONS       ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_LABELS        ] = SUBADDRESS (UserLabels)
	kindDeparse[ $$KIND_TYPES         ] = SUBADDRESS (UserTypes)
	kindDeparse[ $$KIND_STARTS        ] = SUBADDRESS (SystemStarts)
	kindDeparse[ $$KIND_WHITES        ] = SUBADDRESS (SystemWhites)
	kindDeparse[ $$KIND_COMMENTS      ] = SUBADDRESS (SystemComments)
	kindDeparse[ $$KIND_FUNCTIONS     ] = SUBADDRESS (FunctionSymbols)
END SUB
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
END FUNCTION
'
'
' ############################
' #####  XxxDeparser ()  #####
' ############################
'
FUNCTION  XxxDeparser (TOKEN tok[], deparsed$)
	TOKEN   token
	SHARED  funcSymbol$[],  tab_lab$[],  tab_sym$[],  tab_sys$[]
	SHARED  typeSymbol$[]
	STATIC SUBADDR kindDeparse[]
'
	IFZ kindDeparse[] THEN GOSUB LoadKindDeparse
'
'	IF deparsed$ THEN
'		IF (ULONGAT(&deparsed$-4) != 0xF0F0F0) THEN
'		IF (LEFT$(deparsed$, 2) == "v$") THEN
'			PRINT "XxxDeparser(17)", deparsed$
'		END IF
'	END IF
'
	deparsed$ = ""
	topToken  = UBOUND(tok[])
	IFZ topToken THEN INC topToken        ' Always do start token
	DO WHILE (tokPtr < topToken)
		token   = tok[tokPtr]
		tt      = token.tindex
		kind    = token.tp.kind
		spaces  = token.tp.stsp
		IF (spaces >= 0) THEN
			whiteChar = 32      ' spaces
		ELSE
			whiteChar = 9       ' tabs
			spaces = -spaces
		END IF
		GOSUB @kindDeparse[kind]  ' dispatch deparse based on kind of token
		INC tokPtr
	LOOP
	RETURN
'
'
' ****************************************************************
' *****  Subroutines to deparse different "kinds" of tokens  *****
' ****************************************************************
'
SUB SystemSymbols
	deparsed$ = deparsed$ + tab_sys$[tt] + CHR$(whiteChar, spaces)
END SUB
'
SUB UserSymbols
	deparsed$ = deparsed$ + tab_sym$[tt] + CHR$(whiteChar, spaces)
END SUB
'
SUB FunctionSymbols
	deparsed$ = deparsed$ + funcSymbol$[tt] + CHR$(whiteChar, spaces)
END SUB
'
SUB UserLabels
	s$ = MID$(tab_lab$[tt], 4)
' suffix = RINSTR (s$, ".")               ' gas ?
	suffix = RINSTR (s$, $$ulpc$)               ' unspas
	s$ = LEFT$(s$, suffix - 1)
	IF (tokPtr = 1) THEN s$ = s$ + ":"
	deparsed$ = deparsed$ + s$ + CHR$(whiteChar, spaces)
END SUB
'
SUB SystemStarts
	errorIndex = token.ti.errno                         ' errno is BYTE1
	IF errorIndex THEN
		deparsed$ = deparsed$ + RIGHT$("000" + STRING(errorIndex), 3)
	END IF
	SELECT CASE token.ti.bpexe
		CASE $$BPEXECLR:
		CASE $$BP      : deparsed$ = deparsed$ + ":"
		CASE $$EXE     : deparsed$ = deparsed$ + ">"
		CASE $$BPEXE   : deparsed$ = deparsed$ + ">:"
		CASE ELSE      : PRINT "XxxDeparser(72):Invalid .bpexe"
	END SELECT
'
	IF spaces THEN
		deparsed$ = deparsed$ + CHR$(whiteChar, spaces)
	END IF
END SUB
'
SUB SystemWhites
	IF spaces THEN
		deparsed$ = deparsed$ + CHR$(whiteChar, spaces)
	END IF
END SUB
'
SUB SystemComments
	count  = token.tp.type                           ' .type has count for $$KIND_COMMENTS token
	IF (count = 255) THEN
		INC tokPtr
		count = tok[tokPtr].tindex
	END IF
	deparsed$ = deparsed$ + "'"
	pw$ = NULL$(8)
	o = &pw$
	x = 1
	DO UNTIL (x > count)
		INC tokPtr
		token = tok[tokPtr]
		XLONGAT (o) = token.tindex
		XLONGAT (o+4) = token.tproto
		deparsed$ = deparsed$ + pw$
		x = x + 8
	LOOP
	deparsed$ = RTRIM$(deparsed$)
END SUB
'
SUB UserTypes
	deparsed$ = deparsed$ + typeSymbol$[tt] + CHR$(whiteChar, spaces)
END SUB
'
SUB BogusToken
	PRINT "*****  DEPARSER:  BOGUS TOKEN  *****"
END SUB
'
SUB LoadKindDeparse
	DIM kindDeparse[31]
	FOR i = 0 TO 31
		kindDeparse[i] = SUBADDRESS (BogusToken)
	NEXT i
	kindDeparse[ $$KIND_TERMINATORS   ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_STATE_INTRIN  ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_STATEMENTS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_INTRINSICS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_SEPARATORS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_CHARACTERS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_BINARY_OPS    ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_UNARY_OPS     ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_ADDR_OPS      ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_LPARENS       ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_RPARENS       ] = SUBADDRESS (SystemSymbols)
	kindDeparse[ $$KIND_SYMBOLS       ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_ARRAY_SYMBOLS ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_VARIABLES     ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_ARRAYS        ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_LITERALS      ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_CONSTANTS     ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_CHARCONS      ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_SYSCONS       ] = SUBADDRESS (UserSymbols)
	kindDeparse[ $$KIND_LABELS        ] = SUBADDRESS (UserLabels)
	kindDeparse[ $$KIND_TYPES         ] = SUBADDRESS (UserTypes)
	kindDeparse[ $$KIND_STARTS        ] = SUBADDRESS (SystemStarts)
	kindDeparse[ $$KIND_WHITES        ] = SUBADDRESS (SystemWhites)
	kindDeparse[ $$KIND_COMMENTS      ] = SUBADDRESS (SystemComments)
	kindDeparse[ $$KIND_FUNCTIONS     ] = SUBADDRESS (FunctionSymbols)
END SUB
END FUNCTION
'
'
' #####################################
' #####  XxxEmitXProfilerCall ()  #####
' #####################################
'
FUNCTION  XxxEmitXProfilerCall (func, line)
	Code ($$push, $$imm, line, 0, 0, $$XLONG, "", $$rmk$+"1207")
	Code ($$push, $$imm, func, 0, 0, $$XLONG, "", $$rmk$+"1208")
	Code ($$call, $$rel, 0, 0, 0, 0, $$flead$+"XxxXProfilerLog"+$$ftrail$+"8", $$rmk$+"1210")
END FUNCTION
'
'
' #############################
' #####  XxxErrorInfo ()  #####
' #############################
'
' Return error information for XIT:
'   - rawPtr = insertion pointer offset to error in RAW source line
'   - srcPtr = pointer offset to error for source line (1 = first character)
'   - srcLine = Deparsed (tab --> 2 spaces) source line
'
FUNCTION  XxxErrorInfo (err, rawPtr, srcPtr, srcLine$)
	TOKEN   token
	SHARED  charpos[]
	SHARED  XERROR,  rawLength,  rawline$,  tokenPtr,  uerror
	SHARED  a0,  a0_type,  a1,  a1_type,  toes,  toms,  oos
	SHARED UBYTE oos[]
'
	IF (err <= 0) THEN XcowlErr (1330019): GOTO eeeErrorInfo
	IF (err > uerror) THEN XcowlErr (1330020): GOTO eeeErrorInfo
	rawPtr = 0
	srcPtr = 0
	srcLine$ = ""
	tp = tokenPtr
	rawline$ = Deparse$("")
	IF TRIM$(rawline$) THEN
		rawPtr = charpos[tp]                  ' location of error, offset 0
		i = 0
		srcPtr = -1
		rawLength = LEN(rawline$)
		DO WHILE (i < rawLength)
			INC srcPtr
			IF (rawline${i} = '\t') THEN ' tabs (at 2) --> spaces
				IF (srcPtr AND 1) THEN            '   odd:  add 2 spaces
					INC srcPtr
					srcLine$ = srcLine$ + "  "
				ELSE
					srcLine$ = srcLine$ + " "
				END IF
			ELSE
				srcLine$ = srcLine$ + CHR$(rawline${i})
			END IF
			IF (i <= rawPtr) THEN tokenPointer = srcPtr
			INC i
		LOOP
	END IF
'
' Trim leading spaces from srcLine$
'
	srcPtr = tokenPointer                   ' point to error position
	lenFatSrc = LEN(srcLine$)
	srcLine$ = LTRIM$(srcLine$)
	lenSrc = LEN(srcLine$)
	srcPtr = srcPtr - (lenFatSrc - lenSrc)
	IF (srcPtr < 0) THEN srcPtr = 0
	INC srcPtr
	ParseOutError (@token)
	XERROR  = 0
	toes    = 0
	toms    = 0
	oos     = 0
	oos[0]  = 0
	a0      = 0
	a1      = 0
	a0_type = 0
	a1_type = 0
	RETURN
'
eeeErrorInfo:
	XERROR = 0
	EXIT FUNCTION
END FUNCTION
'
'
' ################################
' #####  XxxFunctionName ()  #####
' ################################
'
FUNCTION  XxxFunctionName (command, funcName$, funcNumber)
	SHARED  funcSymbol$[]
'
	theFuncNumber = funcNumber
	ufunc = UBOUND(funcSymbol$[])
	SELECT CASE command
		CASE $$XGET:    SELECT CASE TRUE
											CASE ((theFuncNumber > 0) AND (theFuncNumber <= ufunc))
													funcName$ = funcSymbol$[theFuncNumber]
											CASE (theFuncNumber = 0)
													funcName$ = "PROLOG"
											CASE ELSE
													funcName$ = ""
										END SELECT
'                   PRINT "XxxFunctionName()", funcNumber, funcName$, ufunc
		CASE $$XSET:    IF ((theFuncNumber > 0) AND (theFuncNumber <= ufunc)) THEN
											IF funcSymbol$[theFuncNumber] THEN
												funcSymbol$[theFuncNumber] = funcName$
											END IF
										END IF
		CASE ELSE:      PRINT "Bogus command to XxxFunctionName$() = "; command
	END SELECT
END FUNCTION
'
'
' ##################################
' #####  XxxFunctionNumber ()  #####
' ##################################
'
' funcNum = XxxFunctionNumber (funcName$)
'
FUNCTION  XxxFunctionNumber (funcName$)
	SHARED  funcSymbol$[]
'
	FOR funcNumber = UBOUND(funcSymbol$[]) TO 1 STEP -1
		IF (funcName$ == funcSymbol$[funcNumber]) THEN EXIT FOR
	NEXT funcNumber
'
	RETURN funcNumber
'
END FUNCTION
'
'
' ########################################
' #####  XxxGetAddressGivenLabel ()  #####
' ########################################
'
FUNCTION  XxxGetAddressGivenLabel (label$)
	SHARED  labaddr[],  tab_lab$[]
	SHARED  labelPtr
'
	IFZ label$ THEN RETURN (0)
	FOR i = 0 TO labelPtr
		IF (tab_lab$[i] = label$) THEN RETURN (labaddr[i])
	NEXT i
'
' No match
'   append "$##" (where ## is a decimal number) to STDCALL function names.
'   IF label${0} = "_", try to find a match with "$##" stripped from tab_lab$
'
	length = LEN(label$)                          ' label length = offset to "$" in STDCALL symbol
' IF (label${0} != '_') THEN RETURN (0)         ' SCO del from NT
	FOR i = 0 TO labelPtr
		IFZ tab_lab$[i] THEN DO NEXT
'   IF (tab_lab$[i]{0} != '_') THEN DO NEXT     ' SCO del from NT
'   iat = RINSTR (tab_lab$[i], "@")             ' SCO and Windows
		iat = RINSTR (tab_lab$[i], $$ftrail$)       ' Linux
		IF (iat != (length+1)) THEN DO NEXT         ' no "_" (or "@") at appropriate location in label symbol
		upper = UBOUND(tab_lab$[i])                 ' last offset in label symbol
		IF (upper <= length) THEN DO NEXT           ' label symbol not long enough to have $ + digit
		one = INSTR(tab_lab$[i], label$)            ' do symbol and label start the same?
		IF (one != 1) THEN DO NEXT                  ' nope
		IF (LEFT$(tab_lab$[i],iat-1) = label$) THEN ' symbol left of $ is the same as label$
			ok = $$TRUE                               ' found label symbol = default
			FOR o = length+1 TO upper                 ' for all characters after the $
				byte = tab_lab$[i]{o}                   ' get digit following the $
				IF (byte < '0') THEN ok = 0: EXIT FOR  ' not decimal digit after $
				IF (byte > '9') THEN ok = 0: EXIT FOR  ' ditto
			NEXT o
			IF ok THEN RETURN (labaddr[i])            ' found symbol + $## that matches label$
		END IF
	NEXT i
END FUNCTION
'
'
' ########################################
' #####  XxxGetFunctionVariables ()  #####
' ########################################
'
'  Fill token, symbol, location arrays for function # funcNumber.
'     - match only kinds[], toss internal symbols starting with ".",
'       like .for.limit.0001, etc.
'  Return number of variables
'
FUNCTION  XxxGetFunctionVariables (funcNumber, kinds[], TOKEN tok[], symbol$[], reg[], addr[])
	TOKEN   token
	SHARED  TOKEN tab_sym[]
	SHARED  hash%[], tab_sym$[],  m_reg[],  m_addr[]
'
'	IFZ kinds[] THEN RETURN (0)  '*cw* 230314-
	IFZ kinds[] THEN             '*cw* 230314+
		GOSUB SetAllKinds          '*cw* 230314+
	END IF                       '*cw* 230314+
	numKinds = UBOUND(kinds[])
'
	uhash = UBOUND(hash%[])
	IF ((funcNumber < 0) OR (funcNumber > uhash)) THEN RETURN (0)
	IFZ hash%[funcNumber, ] THEN RETURN (0)
'
	utok    = 15
	DIM tok[utok]
	DIM reg[utok]
	DIM addr[utok]
	DIM symbol$[utok]
	index   = -1
'
	i = 0
	ATTACH hash%[funcNumber, ] TO func%[]
	DO UNTIL (i > 255)
		IFZ func%[i, ] THEN INC i: DO DO
		ATTACH func%[i, ] TO vars%[]
		numVars   = vars%[0]
		IFZ numVars THEN
			ATTACH vars%[] TO func%[i, ]
			INC i
			DO DO
		END IF
		IF ((numVars + index) > utok) THEN
			utok  = utok + numVars
			utok  = utok + (utok >> 1)
			REDIM tok[utok]
			REDIM symbol$[utok]
			REDIM reg[utok]
			REDIM addr[utok]
		END IF
		j = 1
		DO UNTIL (j > numVars)
			symbolPtr = vars%[j]
			token     = tab_sym[symbolPtr]
			tk        = token.tp.kind
			k         = 0
			DO UNTIL (k > numKinds)
				IF (tk = kinds[k]) THEN EXIT DO
				INC k
			LOOP
			IF (k > numKinds) THEN
				INC j
				DO DO
			END IF
			symbol$ = tab_sym$[symbolPtr]
			IF (tk = $$KIND_VARIABLES) THEN
				IF (symbol${0} = '.') THEN
					INC j
					DO DO
				END IF
			END IF
			IFZ m_reg[symbolPtr] THEN
				IFZ m_addr[symbolPtr] THEN
					INC j                         ' not currently being used in program
					DO DO
				END IF
			END IF
			INC index                         ' add it in...
			tok[index] = token
			IF (tk = $$KIND_ARRAYS) THEN
				symbol$[index] = symbol$ + "[]"
			ELSE
				symbol$[index] = symbol$
			END IF
			reg[index]  = m_reg[symbolPtr]
			addr[index] = m_addr[symbolPtr]
			INC j
		LOOP
		ATTACH vars%[] TO func%[i, ]
		INC i
	LOOP
	ATTACH func%[] TO hash%[funcNumber, ]
	IF (index < 0) THEN
		DIM tok[]
		DIM symbol$[]
		DIM reg[]
		DIM addr[]
		RETURN (0)
	ELSE
		REDIM tok[index]
		REDIM symbol$[index]
		REDIM reg[index]
		REDIM addr[index]
		RETURN (index + 1)
	END IF
'
'
' *****  SetAllKinds  *****                 '*cw* 230314+
'
' All possible kinds are 1 to 4 and 6 to 15
'
SUB SetAllKinds
	DIM kinds[13]
	k = 1
	FOR i = 0 TO 13
		kinds[i] = k
		INC k
		IF (k = 5) THEN
			INC k
		END IF
	NEXT i
END SUB
END FUNCTION
'
'
' ########################################
' #####  XxxGetLabelGivenAddress ()  #####
' ########################################
'
FUNCTION  XxxGetLabelGivenAddress (address, labels$[])
	SHARED  labaddr[],  tab_lab$[]
	SHARED  labelPtr
'
	DIM labels$[]
	IFZ labaddr[] THEN XxxInitAll ()      ' load function labels
	IFZ labaddr[] THEN RETURN ($$FALSE)   ' labels unavailable - give up
'
	i = 0
	entry = 0
	DIM labels$[7]
'
	DO WHILE (i <= labelPtr)
		IF (address = labaddr[i]) THEN
			labels$[entry] = tab_lab$[i]
			INC entry
			IF (entry >= 8) THEN EXIT DO
		END IF
	INC i
	LOOP
	RETURN (entry)
END FUNCTION
'
'
' ##################################
' #####  XxxGetPatchErrors ()  #####
' ##################################
'
FUNCTION  XxxGetPatchErrors (symbol$[], TOKEN token[], addr[])
	SHARED  errSymbol$[],  errAddr[]
	SHARED  TOKEN errToken[]
'
	DIM symbol$[]
	DIM token[]
	DIM addr[]
	IFZ errAddr[] THEN RETURN (0)
'
	count = UBOUND (errAddr[]) + 1
	SWAP symbol$[], errSymbol$[]
	SWAP token[], errToken[]
	SWAP addr[], errAddr[]
	RETURN (count)
END FUNCTION
'
'
' ##################################
' #####  XxxGetProgramName ()  #####
' ##################################
'
FUNCTION  XxxGetProgramName (name$)
	SHARED  programName$
	SHARED  program$
'
	name$ = programName$
	IFZ name$ THEN name$ = program$
END FUNCTION
'
'
' #################################
' #####  XxxGetSymbolInfo ()  #####
' #################################
'
'  Input: tokNumber
' Output: token, theType, symbol$, r_addr$, m_addr$
'
FUNCTION  XxxGetSymbolInfo (tokNumber, TOKEN token, theType, symbol$, r_addr$, m_addr$)
	SHARED  tab_sym$[],  m_reg[],  m_addr[]
	SHARED  TOKEN tab_sym[]
	SHARED  r_addr[]
	SHARED  r_addr$[]
	SHARED  m_addr$[]
'
	uToken = UBOUND(tab_sym[])
	IF (tokNumber < 0) THEN RETURN (uToken)
	IF (tokNumber > uToken) THEN RETURN ($$TRUE)
'
	token   = tab_sym[tokNumber]
	theType = TheType (token)
	symbol$ = tab_sym$[tokNumber]
	m_reg     = m_reg[tokNumber]
	m_addr    = m_addr[tokNumber]

	r_addr    = r_addr[tokNumber]
	m_addr$   = m_addr$[tokNumber]
	r_addr$   = r_addr$[tokNumber]
'
END FUNCTION
'
'
' ################################
' #####  XxxGetUserTypes ()  #####
' ################################
'
' Used by Xit to fill in current composite type names  (type 0x22 and up)
'
FUNCTION  XxxGetUserTypes (varTypes$[])
	SHARED  typeSymbol$[],  uType
'
	IF (uType < 0x22) THEN RETURN           ' No user composites
	FOR lastType = uType TO 0x22 STEP -1
		IF typeSymbol$[lastType] THEN EXIT FOR
	NEXT lastType
	IF (lastType < 0x22) THEN RETURN        ' No user composites
	IF (lastType != UBOUND(varTypes$[])) THEN
		REDIM varTypes$[lastType]
	END IF
	FOR i = 0x22 TO lastType
		varTypes$[i] = typeSymbol$[i]
	NEXT i
END FUNCTION
'
'
' ##############################
' #####  XxxGetXerror$ ()  #####
' ##############################
'
FUNCTION  XxxGetXerror$ (err)
	SHARED  xerror$[]
	SHARED  uerror
'
	IF ((err <= 0) OR (err > uerror)) THEN
		RETURN ("Unknown error number:  " + STRING(err))
	END IF
	RETURN (xerror$[err])
END FUNCTION
'
'
' ###########################
' #####  XxxInitAll ()  #####
' ###########################
'
FUNCTION  XxxInitAll ()
	InitArrays ()
	InitEntry ()
	InitErrors ()
	XxxInitParse ()
	InitProgram ()
	InitVariables ()
	TokensDefined ()
	InitComplex ()
END FUNCTION
'
'
' #############################
' #####  XxxInitParse ()  #####
' #############################
'
FUNCTION  XxxInitParse ()
	SHARED  got_function,  parse_got_function,  func_number
	got_function        = $$FALSE
	parse_got_function  = $$FALSE
	func_number         = 0
END FUNCTION
'
'
' ######################################
' #####  XxxInitVariablesPass1 ()  #####
' ######################################
'
FUNCTION  XxxInitVariablesPass1 ()
	EXTERNAL /xxx/  xpc,  errorCount
	SHARED  export$[]
	SHARED  import$[]
	SHARED  declare$[]
	SHARED  exportCount
	SHARED  importCount
	SHARED  declareCount
	SHARED  defaultType[]
	SHARED  libraryCode$[]
	SHARED  libraryName$[]
	SHARED  libraryHandle[]
	SHARED  XERROR
	SHARED  charPtr,  defaultType
	SHARED  end_program,  func_number
	SHARED  got_declare,  got_executable,  got_export,  got_function
	SHARED  got_import,  got_object_declaration,  got_program,  got_type
	SHARED  ofile
	SHARED  export
	SHARED  version$
	SHARED  program$
	SHARED  programName$
	SHARED  programPath$
	SHARED  hfn$,  ifLine, inlevel,  insub,  oos
	SHARED  labelNumber,  lineNumber,  prologCode,  preExports
	SHARED  patchPtr,  nestCount,  nestLevel
	SHARED  section,  subCount,  tokenPtr
	SHARED  externalAddr,  pass,  pass2errors
	SHARED  stopComment
	SHARED  asmFile$
	SHARED  TOKEN  backToken
	SHARED  TOKEN  lastToken
	SHARED  TOKEN  programToken
	SHARED  TOKEN  versionToken
'
	DIM export$[]
	DIM import$[]
	DIM declare$[]
	DIM libraryCode$[]
	DIM libraryName$[]
	DIM libraryHandle[]
'
	XERROR          = 0
	pass            = 1
	pass2errors     = 0
	prologCode      = 0
	preExports      = 0
	exportCount     = 0
	importCount     = 0
	declareCount    = 0
	oos             = 0
	insub           = 0
	inlevel         = 0
	ifLine          = 0
	charPtr         = 0
	subCount        = 0
	tokenPtr        = 0
	nestCount       = 0
	nestLevel       = 0
	backToken       = #T_ZERO
	lastToken       = #T_ZERO
	programToken   = #T_ZERO
	versionToken   = #T_ZERO
	stopComment     = 0
	xpc             = ##UCODE
	##GLOBAL        = ##GLOBAL0
	##GLOBALX       = ##GLOBAL0
	externalAddr    = ##GLOBAL0
'	PRINT "XxxInitVariablesPass1(75)", HEX$(##GLOBAL), HEX$(##GLOBALX), HEX$(externalAddr)
	errorCount      = 0
	patchPtr        = 0
	lineNumber      = 0
	func_number     = 0
	labelNumber     = 0
	version$        = ""
	program$        = ""
	programName$    = ""
	programPath$    = ""
	asmFile$        = ""
	hfn$            = "0"
	defaultType     = $$XLONG
	section         = $$TEXTSECTION
'
	IF (ofile > 2) THEN CLOSE (ofile)
	ofile = 0
'
	export                    = $$FALSE
	got_declare               = $$FALSE
	got_export                = $$FALSE
	got_executable            = $$FALSE
	got_function              = $$FALSE
	got_import                = $$FALSE
	got_object_declaration    = $$FALSE
	got_program               = $$FALSE
	got_type                  = $$FALSE
	end_program               = $$FALSE
	IFZ defaultType[] THEN
		DIM defaultType[63]
	END IF
	defaultType[func_number]  = defaultType
'
END FUNCTION
'
'
' ##############################
' #####  XxxLibraryAPI ()  #####
' ##############################
'
FUNCTION  XxxLibraryAPI (lib$)
	STATIC  lib$[]
'
	IFZ lib$ THEN RETURN
	IFZ lib$[] THEN XstLoadStringArray ("\\xb\\xxx\\syslib.xxx", @lib$[])
	IFZ lib$[] THEN RETURN
'
	upper = UBOUND (lib$)
	IF (lib${upper} = '"') THEN lib$ = RCLIP$(lib$,1)
	IF (lib${0} = '"') THEN lib$ = LCLIP$(lib$,1)
'
	FOR i = 0 TO UBOUND (lib$[])
		IF (lib$ = lib$[i]) THEN RETURN ($$TRUE)
	NEXT i
END FUNCTION
'
'
' ###############################
' #####  XxxLoadLibrary ()  #####
' ###############################
'
FUNCTION  XxxLoadLibrary (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  library,  xpc
	TOKEN   tok[], bs[]
	SHARED  TOKEN tokens[]
	SHARED  a0,  a0_type,  a1,  a1_type
	SHARED  xerror$[]
	SHARED  libraryCode$[]
	SHARED  libraryName$[]
	SHARED  libraryHandle[]
	SHARED  programName$
	SHARED  program$
	SHARED  prologCode
	SHARED  inTYPE,  labelNumber,  lineNumber,  parse_got_function
	SHARED  tab_sym$[],  tokenPtr,  tokenCount,  stopComment
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_FILE_NOT_FOUND
	SHARED  fileName$
	SHARED  programPath$
	FUNCADDR  TOKEN addr ()
'
	handle = 0
	##ERROR = $$FALSE
	IFZ program$ THEN program$ = programName$
	IFZ programName$ THEN programName$ = program$
'
	libname$ = tab_sym$[token.tindex]
	libname$ = TRIM$(MID$(libname$,2,LEN(libname$)-2))
	IFZ libname$ THEN PRINT "XxxLoadLibrary(): Error: (empty libname$)": XcowlErr (1480033): GOTO eeeCompiler
'
' Don't remove anything after a dot (some libraries have a dot in their name)
' dot = INSTR (libname$, ".")
' IF dot THEN libname$ = LEFT$(libname$, dot-1)
'
	library$ = libname$ + ".dec"
' dllname$ = libname$ + ".dll"
'
	soname$  = "lib" + libname$ + ".so"    'linux shared or dynamic library name
'
	IF libraryName$[] THEN
		upper = UBOUND (libraryName$[])
		FOR i = 0 TO upper
			IF (libname$ = libraryName$[i]) THEN
				IF libraryHandle[i] THEN RETURN     ' library already compiled
				IF libraryCode$[i,] THEN parsed = $$TRUE
				EXIT FOR
			END IF
		NEXT i
		libraryNumber = i
	ELSE
		libraryNumber = 0
	END IF
'
	IF parsed THEN
		SWAP lib$[], libraryCode$[i,]
	ELSE
		' First try to read the .dec file from the same directory as the program,
		' then the current directory, and then the XBasic system "/include/" directory
		'
'		XstGetPathComponents (programPath$, @fileDir$, s$, s$, s$, 0)
'		fileLib$ = fileDir$ + library$
'		IF XstGetFileAttributes (fileLib$, 0) THEN ifile = OPEN (fileLib$, $$RD)
'			IF (ifile >= 3) THEN
'				library$ = fileLib$
'		ELSE
'			IF XstGetFileAttributes (library$, 0) THEN ifile = OPEN (library$, $$RD)
'		END IF
		'
		argCount = -1  ' request original command arguments '*cw* 220301+ for testing
		XstGetCommandLineArguments (@argCount, @argv$[])    '*cw* 220301+ for testing
		IF (argv$[0] == "./src/bin/xb64") THEN              '*cw* 220301+ for testing
			XstGetCurrentDirectory (@curDir$)                 '*cw* 220301+ for testing
		END IF                                              '*cw* 220301+ for testing
		IF (ifile <= 0) THEN
			XB64Dir$ = curDir$ + "/src/shared/"
			library$ = XB64Dir$ + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		IF (ifile <= 0) THEN
			XB64Dir$ = curDir$ + "/src/linux/"
			library$ = XB64Dir$ + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		IF (ifile <= 0) THEN
			XB64Dir$ = curDir$
			library$ = XB64Dir$ + "/include/" + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		IF (ifile <= 0) THEN
			XB64Dir$ = "/usr/xb64"
			library$ = XB64Dir$ + "/include/" + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		'
		IF (ifile <= 0) THEN PRINT library$; " not found": XcowlErr (14800107): GOTO eeeFileNotFound
		length = LOF (ifile)
		lib$ = NULL$ (length)
		READ [ifile], lib$
		CLOSE (ifile)
		XstStringToStringArray (@lib$, @lib$[])   ' lib$[] = file "libname.DEC"
		IFZ lib$[] THEN PRINT library$; " is empty": XcowlErr (14800113): GOTO eeeFileNotFound
	END IF
'
	upperLib = UBOUND (lib$[])                ' last line in file "libname.DEC"
	holdLine = lineNumber                     ' hold line number
	holdTokenPtr = tokenPtr                   ' hold current token pointer
	holdTokenCount = tokenCount               ' hold current token count
	holdParseFunc = parse_got_function        ' hold parse_got_function variable
	DIM bs[255]: SWAP bs[], tokens[]         ' hold compiling line of tokens[]
	tokenPtr = 0                              ' pretend it's token 0
	tokenCount = 0                            ' pretend it's token 0
	lineNumber = 0                            ' pretend it's line 0
	parse_got_function = 0                    ' pretend it's PROLOG
'
'
' NOTE: The following code is different in the Windows version.
' NOTE: Modify the following to make Linux version support true DLLs.
'
	SELECT CASE TRUE
		CASE i486asm
					SELECT CASE LCASE$(libname$)
						CASE "xlib", "xdis", "xst", "xin", "xma", "xcm", "xit", "xcol", "xgr", "xui", "gdi32", "kernel32", "user32"
						CASE "xut", "xutpde", "xwin", "clib", "elf32"
						CASE ELSE
									INC labelNumber: d1$ = $$ulpc$ + HEX$(labelNumber, 4)
									INC labelNumber: d2$ = $$ulpc$ + HEX$(labelNumber, 4)
									IFZ prologCode THEN
										EmitText ()
										SELECT CASE TRUE
											CASE library :  Code ($$jmp, $$rel, 0, 0, 0, 0, $$ulpc$+"_StartLibrary_" + program$, $$rmk$+"1211")
											CASE ELSE    :  Code ($$jmp, $$rel, 0, 0, 0, 0, $$ulpc$+"_StartApplication", $$rmk$+"1212")
										END SELECT
										prologCode = $$TRUE
										EmitLabel ("PrologCode")
										Code ($$push, $$reg, $$rbp, 0, 0, $$XLONG, "", $$rmk$+"1213")
										Code ($$mov, $$regreg, $$rbp, $$rsp, 0, $$XLONG, "", $$rmk$+"1214")
										Code ($$sub, $$regimm, $$rsp, 256, 0, $$XLONG, "", $$rmk$+"1215")
										EmitNull ($$rmk1$)
									END IF
									Move ($$rax, $$XLONG, token.tindex, $$XLONG)
									Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1216")
									Code ($$call, $$rel, 0, 0, 0, 0, "LoadLibraryA_8", $$rmk$+"1218")     ' unspas
									Code ($$or, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"1219")
									Code ($$jz, $$rel, 0, 0, 0, 0, @d2$, $$rmk$+"1220")
									Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1221")
									Code ($$mov, $$regimm, $$rax, 0, 0, $$XLONG, $$ulpc2$+"string.StartLibrary", $$rmk$+"1222")
									Move ($$rbx, $$XLONG, token.tindex, $$XLONG)
									Code ($$call, $$rel, 0, 0, 0, 0, $$ulpc$+"_concat.string.a0.eq.a0.plus.a1.vv", $$rmk$+"1223")
									Code ($$pop, $$reg, $$rbx, 0, 0, $$XLONG, "", $$rmk$+"1224")
									Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1225")
									Code ($$push, $$reg, $$rax, 0, 0, $$XLONG, "", $$rmk$+"1226")
									Code ($$push, $$reg, $$rbx, 0, 0, $$XLONG, "", $$rmk$+"1227")
									Code ($$call, $$rel, 0, 0, 0, 0, "GetProcAddress_16", $$rmk$+"1229")   ' unspas
									Code ($$or, $$regreg, $$rax, $$rax, 0, $$XLONG, "", $$rmk$+"1230")
									Code ($$jz, $$rel, 0, 0, 0, 0, @d1$, $$rmk$+"1231")
									Code ($$call, $$reg, $$rax, 0, 0, 0, "", $$rmk$+"1232")
									EmitLabel (@d1$)
									Code ($$pop, $$reg, $$rdi, 0, 0, $$XLONG, "", $$rmk$+"1233")
									Code ($$call, $$rel, 0, 0, 0, 0, "xb_5_free", $$rmk$+"1234")
									EmitLabel (@d2$)
									EmitNull ($$rmk1$)
									a0 = 0: a0_type = 0
									a1 = 0: a1_type = 0
					END SELECT
		CASE i486bin
					SELECT CASE LCASE$(libname$)
						CASE "xin", "xma", "xcm", "xit", "xcol", "xgr", "xst", "xui"
						CASE "xlib", "xdis", "gdi32", "kernel32", "user32"
						CASE "xut", "xutpde"
						'
						' ***  XBasic developer only  ***
						'
						CASE "clib" : soname$ = "libc.so"     : NEXT CASE
						CASE "elf32": soname$ = "libelf.so.1" : NEXT CASE
						CASE "xwin" : soname$ = "libX11.so.6" : NEXT CASE
						CASE ELSE
'             handle = LoadLibraryA (&dllname$)   ' libname.DLL handle
'             handle = LoadLibraryA (&soname$)    ' libname.so handle
'
' Try loading the library from the directory that the program is in first
'
							IF fileName$ THEN                                           '*cw* 120328+ 220405-+
								XstGetPathComponents (fileName$, @fileDir$, s$, s$, s$, 0)
								fileSo$ = fileDir$ + soname$                              '*cw* 120328+
								handle = LoadLibraryA (&fileSo$)                          '*cw* 120328+
							END IF                                                      '*cw* 120328+
							IFZ handle THEN handle = LoadLibraryA (&soname$)            ' libname.so handle
							IF handle THEN
'               PRINT "Got library <"; dllname$; "> ... handle = "; HEX$ (handle, 8)
'               PRINT "xcol.x XxxLoadLibrary() Got library <"; soname$; "> ... handle = "; HEX$ (handle, 8)
'
								startLibrary$ = $$ulpc$+"_StartLibrary_" + libname$
								addr = GetProcAddress (handle, &startLibrary$)
								@addr ()
'               PRINT startLibrary$; " = "; HEX$ (addr,8)
							ELSE
								PRINT "xcol.x XxxLoadLibrary() Failed to get library <"; soname$; "> ... handle = "; HEX$ (handle, 8)
							END IF
					END SELECT
	END SELECT
'
	upper = UBOUND (libraryName$[])
	IF (libraryNumber > upper) THEN
		REDIM libraryCode$[libraryNumber, ]     ' libname.DEC source code arrays
		REDIM libraryName$[libraryNumber]       ' libname string array
		REDIM libraryHandle[libraryNumber]      ' libname.DLL handle array
		libraryName$[libraryNumber] = libname$  ' save libname string (no extent)
	END IF
	libraryHandle[libraryNumber] = handle     ' save libname.DLL handle
'
	stopComment = $$TRUE                      ' don't emit asm for library comments
	i = 0
	DO
		line$ = TRIM$ (lib$[i])
		t = INSTR (line$, "TYPE")
		IF (t = 1) THEN GOSUB GetType: INC i: DO LOOP
		t = INSTR (line$, "PACKED")
		IF (t = 1) THEN GOSUB GetType: INC i: DO LOOP
		c = INSTR (line$, "$$")
		IF (c = 1) THEN GOSUB GetConstant: INC i: DO LOOP
		INC i
	LOOP WHILE (i <= upperLib)
'
	stopComment = $$FALSE
	lineNumber = holdLine                     ' restore line number
	tokenPtr = holdTokenPtr                   ' restore current token pointer
	tokenCount = holdTokenCount               ' restore current token count
	parse_got_function = holdParseFunc        ' restore parse_got_function variable
	SWAP bs[], tokens[]: DIM bs[]            ' restore compiling line of tokens[]
	ATTACH lib$[] TO libraryCode$[libraryNumber, ]  ' keep "libname.DEC" for future reference
	RETURN
'
'
' *****  GetType  *****
'
SUB GetType
	DO
		line$ = TRIM$(lib$[i])                  ' next source line string
		XxxParseSourceLine (line$, @tok[])      ' type declaration line to tokens
		IF tok[] THEN XxxCheckLine (0, @tok[])  ' compile the tokens
		IFZ inTYPE THEN EXIT DO                 ' processed END TYPE
		IF XERROR THEN GOSUB PrintXerror
		INC i                                   ' next source line index
	LOOP WHILE (i < upperLib)
END SUB
'
'
' *****  GetConstant  *****
'
SUB GetConstant
	XxxParseSourceLine (line$, @tok[])
	IF tok[] THEN XxxCheckLine (0, @tok[])
	IF XERROR THEN GOSUB PrintXerror
END SUB
'
'
' *****  PrintXerror  *****
'
SUB PrintXerror
	IFZ ##XBDV THEN EXIT SUB  ' don't print XERROR message
	token = tok[tokenPtr]
	tt = token.tindex
	symbol$ = tab_sym$[tt]
	PRINT library$; ":"; i+1, xerror$[XERROR], symbol$
END SUB
'
'
' *****  Errors  *****
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeFileNotFound:
	XERROR = ERROR_FILE_NOT_FOUND
	EXIT FUNCTION
END FUNCTION
'
'
' ################################
' #####  XxxParseLibrary ()  #####
' ################################
'
' The TYPE statements in IMPORT libraries have to be parsed before
' the body of the main program because otherwise type names defined
' in IMPORT libraries are parsed into $$KIND_SYMBOLS tokens in the
' main program instead of the correct $$KIND_TYPES tokens.  This
' causes errors in the main program compilation because type names
' are treated as symbols, not types.
'
FUNCTION  XxxParseLibrary (TOKEN token)
	EXTERNAL /xxx/  i486asm,  i486bin,  library,  xpc
	TOKEN   bs[], tok[]
	SHARED  TOKEN tokens[]
	SHARED  libraryCode$[]
	SHARED  libraryName$[]
	SHARED  libraryHandle[]
	SHARED  lineNumber,  parse_got_function
	SHARED  tab_sym$[],  tokenPtr,  tokenCount,  stopComment
	SHARED  XERROR,  ERROR_COMPILER,  ERROR_FILE_NOT_FOUND
	SHARED  programPath$
'
	##ERROR = $$FALSE
	libname$ = tab_sym$[token.tindex]
	libname$ = TRIM$(MID$(libname$,2,LEN(libname$)-2))
'
	IFZ libname$ THEN
		PRINT "XxxParseLibrary(): Error: (empty libname$)"
		XcowlErr (1490032): GOTO eeeFileNotFound
	END IF
'
' Some libraries have a dot in their name so don't remove what is after it
' dot = INSTR (libname$, ".")
' IF dot THEN libname$ = LEFT$(libname$, dot-1)
	library$ = libname$ + ".dec"
' dllname$ = libname$ + ".dll"
'
	IF libraryName$[] THEN
		upper = UBOUND (libraryName$[])
		FOR i = 0 TO upper
			IF (libname$ = libraryName$[i]) THEN
				IF libraryCode$[i,] THEN RETURN       ' library already parsed
				EXIT FOR
			END IF
		NEXT i
		libraryNumber = i
	ELSE
		libraryNumber = 0
	END IF
'
' First try to read the .dec file from the same directory as the program,
' then the current directory, and then the XBasic system "/include/" directory
'
'	XstGetPathComponents (programPath$, @fileDir$, s$, s$, s$, 0)
'	fileLib$ = fileDir$ + library$
'	IF XstGetFileAttributes (fileLib$, 0) THEN ifile = OPEN (fileLib$, $$RD)
'	IF (ifile >= 3) THEN
'		library$ = fileLib$
'	ELSE
'		IF XstGetFileAttributes (fileLib$, 0) THEN ifile = OPEN (fileLib$, $$RD)
'	END IF
		'
		argCount = -1  ' request original command arguments
		XstGetCommandLineArguments (@argCount, @argv$[])
		IF (argv$[0] == "./src/bin/xb64") THEN
			XstGetCurrentDirectory (@curDir$)
		END IF
		IF (ifile <= 0) THEN
			XB64Dir$ = curDir$ + "/src/shared/"
			library$ = XB64Dir$ + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		IF (ifile <= 0) THEN
			XB64Dir$ = curDir$ + "/src/linux/"
			library$ = XB64Dir$ + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		IF (ifile <= 0) THEN
			XB64Dir$ = curDir$
			library$ = XB64Dir$ + "/include/" + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		IF (ifile <= 0) THEN
			XB64Dir$ = "/usr/xb64"
			library$ = XB64Dir$ + "/include/" + libname$ + ".dec"
			IF XstGetFileAttributes (library$, 0) THEN
				ifile = OPEN (library$, $$RD)
			END IF
		END IF
		'
	IF (ifile <= 0) THEN PRINT library$; " not found": XcowlErr (14900100): GOTO eeeFileNotFound
	length = LOF (ifile)
	lib$ = NULL$ (length)
	READ [ifile], lib$
	CLOSE (ifile)
'
	XstStringToStringArray (@lib$, @lib$[])   ' lib$[] = file "libname.DEC"
	IFZ lib$[] THEN PRINT library$; " is empty": XcowlErr (14900107): GOTO eeeFileNotFound
	upperLib = UBOUND (lib$[])                ' last line in file "libname.DEC"
'
	holdLine = lineNumber                     ' hold line number
	holdTokenPtr = tokenPtr                   ' hold current token pointer
	holdTokenCount = tokenCount               ' hold current token count
	holdParseFunc = parse_got_function        ' hold parse_got_function variable
	DIM bs[255]: SWAP bs[], tokens[]       ' hold compiling line of tokens[]
	tokenPtr = 0                              ' pretend it's token 0
	tokenCount = 0                            ' pretend it's token 0
	lineNumber = 0                            ' pretend it's line 0
	parse_got_function = 0                    ' pretend it's PROLOG
'
	upper = UBOUND (libraryName$[])
	IF (libraryNumber > upper) THEN
		REDIM libraryCode$[libraryNumber, ]     ' libname.DEC source code arrays
		REDIM libraryName$[libraryNumber]       ' libname string array
		REDIM libraryHandle[libraryNumber]      ' libname.DLL handle array
		libraryName$[libraryNumber] = libname$  ' save libname string (no extent)
	END IF
'
	stopComment = $$TRUE                      ' don't emit asm for library comments
	i = 0
	DO
		line$ = TRIM$ (lib$[i])
		t = INSTR (line$, "TYPE")
		IF (t = 1) THEN XxxParseSourceLine (line$, @tok[])
		INC i
	LOOP WHILE (i <= upperLib)
'
	stopComment = $$FALSE
	lineNumber = holdLine                     ' restore line number
	tokenPtr = holdTokenPtr                   ' restore current token pointer
	tokenCount = holdTokenCount               ' restore current token count
	parse_got_function = holdParseFunc        ' restore parse_got_function variable
	SWAP bs[], tokens[]: DIM bs[]            ' restore compiling line of tokens[]
	ATTACH lib$[] TO libraryCode$[libraryNumber, ]  ' keep "libname.DEC" for pass 1
	RETURN
'
'
' *****  Errors  *****
'
eeeCompiler:
	XERROR = ERROR_COMPILER
	EXIT FUNCTION
'
eeeFileNotFound:
	XERROR = ERROR_FILE_NOT_FOUND
	EXIT FUNCTION
END FUNCTION
'
'
' ###################################
' #####  XxxParseSourceLine ()  #####
' ###################################
'
FUNCTION  XxxParseSourceLine (sourceLine$, TOKEN tok[])
	SHARED  rawLength,  rawline$
'
	rawline$ = sourceLine$
	rawLength = LEN(rawline$)
	IF (RIGHT$(sourceLine$) == "\0") THEN
		PRINT "XxxParseSourceLine(13)", sourceLine$
	END IF
	ParseLine (@tok[])
'
END FUNCTION
'
'
' ######################################
' #####  XxxPassFunctionArrays ()  #####
' ######################################
'
FUNCTION  XxxPassFunctionArrays (command, symbol$[], TOKEN token[], scope[])
	SHARED  funcSymbol$[],  funcScope[]
	SHARED  TOKEN funcToken[]
'
	IF ##WHOMASK THEN              ' If running xcol.x in pde mode
		IF (command == $$XGET) THEN
			u = UBOUND(funcSymbol$[])
			DIM symbol$[u]
			DIM token[u]
			DIM scope[u]
			FOR i = 0 TO u
				symbol$[i] = funcSymbol$[i]
				token[i]   = funcToken[i]
				scope[i]   = funcScope[i]
			NEXT i
		END IF
		RETURN
	END IF
'
	SELECT CASE command
		CASE $$XGET:  ATTACH funcSymbol$[] TO symbol$[]
									ATTACH funcToken[] TO token[]
									ATTACH funcScope[] TO scope[]
									RETURN (0)
		CASE $$XSET:  ATTACH symbol$[] TO funcSymbol$[]
									ATTACH token[] TO funcToken[]
									ATTACH scope[] TO funcScope[]
									RETURN (0)
		CASE  ELSE:   RETURN (-1)
	END SELECT
END FUNCTION
'
'
' ##################################
' #####  XxxPassTypeArrays ()  #####
' ##################################
'
' Used by Xit to display composite information in Variables box
'
FUNCTION  XxxPassTypeArrays (command, pSize[], pSize$[], pAlias[], pAlign[], pSymbol$[], TOKEN pToken[], pEleCount[], pEleSymbol$[], TOKEN pEleToken[], pEleAddr[], pEleSize[], pEleType[], pEleStringSize[], pEleUBound[])
	SHARED TOKEN typeToken[]    ' #T_TYPE token, low word = type #
	SHARED TOKEN typeEleToken[] ' token for each n elements
'
	SHARED typeSize[]           ' size in bytes
	SHARED typeSize$[]          ' "1", "2", "4", "8", "16"...
	SHARED typeAlias[]          ' normal type that user-type is alias for
	SHARED typeAlign[]          ' alignment for this type
	SHARED typeSymbol$[]        ' SBYTE, UBYTE...  SCOMPLEX, DCOMPLEX, USERTYPE...
	SHARED typeEleCount[]       ' # of elements in this type
	SHARED typeEleSymbol$[]     ' symbol for each n elements
	SHARED typeEleAddr[]        ' offset address of each n elements
	SHARED typeEleSize[]        ' size of each n elements ([]: typesize*(dim+1))
	SHARED typeEleType[]        ' type of each n elements
	SHARED typeEleStringSize[]  ' # bytes in fixed string for element n
	SHARED typeEleUBound[]      ' Upper bound of 1D array for element n
'
	SELECT CASE command
		CASE $$XGET:  ATTACH typeSize[]           TO pSize[]
									ATTACH typeSize$[]          TO pSize$[]
									ATTACH typeAlias[]          TO pAlias[]
									ATTACH typeAlign[]          TO pAlign[]
									ATTACH typeSymbol$[]        TO pSymbol$[]
									ATTACH typeToken[]          TO pToken[]
									ATTACH typeEleCount[]       TO pEleCount[]
									ATTACH typeEleSymbol$[]     TO pEleSymbol$[]
									ATTACH typeEleToken[]      TO pEleToken[]
									ATTACH typeEleAddr[]        TO pEleAddr[]
									ATTACH typeEleSize[]        TO pEleSize[]
									ATTACH typeEleType[]        TO pEleType[]
									ATTACH typeEleStringSize[]  TO pEleStringSize[]
									ATTACH typeEleUBound[]      TO pEleUBound[]
									RETURN (0)
		CASE $$XSET:  ATTACH pSize[]              TO typeSize[]
									ATTACH pSize$[]             TO typeSize$[]
									ATTACH pAlias[]             TO typeAlias[]
									ATTACH pAlign[]             TO typeAlign[]
									ATTACH pSymbol$[]           TO typeSymbol$[]
									ATTACH pToken[]             TO typeToken[]
									ATTACH pEleCount[]          TO typeEleCount[]
									ATTACH pEleSymbol$[]        TO typeEleSymbol$[]
									ATTACH pEleToken[]          TO typeEleToken[]
									ATTACH pEleAddr[]           TO typeEleAddr[]
									ATTACH pEleSize[]           TO typeEleSize[]
									ATTACH pEleType[]           TO typeEleType[]
									ATTACH pEleStringSize[]     TO typeEleStringSize[]
									ATTACH pEleUBound[]         TO typeEleUBound[]
									RETURN (0)
		CASE  ELSE:   RETURN (-1)
	END SELECT
END FUNCTION
'
'
' ##################################
' #####  XxxSetProgramName ()  #####
' ##################################
'
FUNCTION  XxxSetProgramName (name$)
	SHARED  programName$
	SHARED  programPath$
'
	pathname$ = name$
	XstDecomposePathname (@pathname$, @path$, @parent$, @filename$, @file$, @extent$)
	IFZ filename$ THEN RETURN
	IF (extent$ != ".x") THEN
		filename$ = file$ + ".x"
		extent$ = ".x"
	END IF
	programName$ = file$
	programPath$ = path$ + $$PathSlash$ + filename$
END FUNCTION
'
'
' ###########################
' #####  XxxTheType ()  #####
' ###########################
'
FUNCTION  XxxTheType (TOKEN token, funcNumber)
	SHARED  func_number
'
	save_func_number  = func_number
	func_number       = funcNumber
	tt                = TheType (token)
	func_number       = save_func_number
	RETURN (tt)
END FUNCTION
'
'
' ######################################
' #####  XxxUndeclaredFunction ()  #####
' ######################################
'
FUNCTION  TOKEN XxxUndeclaredFunction (TOKEN funcToken)
	EXTERNAL /xxx/  i486asm,  i486bin,  library,  xpc
	TOKEN   token, tok, tok[], bs[]
	SHARED  TOKEN tokens[]
	SHARED  UBYTE  charsetSymbol[]
	SHARED  funcSymbol$[]
	SHARED  labaddr[]
	SHARED  libraryCode$[]
	SHARED  libraryName$[]
	SHARED  libraryHandle[]
	SHARED  libraryFunctionLabel$
	SHARED  parse_got_function
	SHARED  got_function
	SHARED  func_number
	SHARED  lineNumber
	SHARED  tokenCount
	SHARED  tokenPtr

	SHARED  TOKEN funcToken[]
	SHARED  XERROR,  ERROR_DUP_LABEL,  ERROR_PROGRAM_NOT_NAMED
'
	match = $$FALSE                           ' funcName not found yet
	funcNumber = funcToken.tindex             ' function number
	funcSymbol$ = funcSymbol$[funcNumber]     ' function symbol
	length = LEN(funcSymbol$)                 ' length of function symbol
	IFZ libraryCode$[] THEN RETURN            ' no libraries
	IFZ libraryName$[] THEN RETURN            ' ditto
	IFZ libraryHandle[] THEN RETURN           ' ditto
'
	lastLibrary = UBOUND (libraryName$[])     ' last library number
	FOR lib = 0 TO lastLibrary                ' look through all libraries
		IFZ libraryCode$[lib,] THEN DO NEXT     ' no libname.DEC source code
		libraryName$ = libraryName$[lib]        ' get libname string
		IFZ libraryName$ THEN DO NEXT           ' no libname string
		handle = libraryHandle[lib]             ' get library handle
		ATTACH libraryCode$[lib,] TO library$[] ' get library source
		upperLine = UBOUND (library$[])         ' last line in this library
		FOR i = 0 TO upperLine                  ' look through entire library
			n = INSTR(library$[i], funcSymbol$)   ' match function name
			IFZ n THEN DO NEXT                    ' no match
			f = INSTR(library$[i], "FUNCTION")    ' find FUNCTION keyword
			IFZ f THEN DO NEXT                    ' no match
			e = INSTR(library$[i], "EXTERNAL")    ' find EXTERNAL keyword
			IFZ e THEN DO NEXT                    ' no match
			l = INSTR(library$[i], "(")           ' find left parenthesis
			IFZ l THEN DO NEXT                    ' no match
			IF (e > f) THEN DO NEXT               ' EXTERNAL before FUNCTION
			IF (f > n) THEN DO NEXT               ' FUNCTION before funcName
			IF (n > l) THEN DO NEXT               ' funcName before "("
			library$ = library$[i]                ' library$ = library source line
			before = ASC(library$,n-1)            ' byte before funcName
			after = ASC(library$,n+length)        ' byte after funcName
			IF charsetSymbol[before] THEN DO NEXT ' funcName inside funcName
			IF charsetSymbol[after] THEN DO NEXT  ' funcName inside funcName
			match = $$TRUE                        ' found desired function declaraction
			holdLine = lineNumber                 ' hold line number
			holdFunc = func_number                ' hold current func number
			holdTokenPtr = tokenPtr               ' hold current token pointer
			holdTokenCount = tokenCount           ' hold current token count
			holdGotFunc = got_function            ' hold got_function variable
			holdParseFunc = parse_got_function    ' hold parse_got_function variable
			DIM bs[255]: SWAP bs[], tokens[]   ' hold compiling line of tokens[]
			tokenPtr = 0                          ' pretend it's token 0
			tokenCount = 0                        ' pretend it's token 0
			lineNumber = 0                        ' pretend it's line 0
			func_number = 0                       ' pretend it's PROLOG
			got_function = 0                      ' pretend it's PROLOG
			parse_got_function = 0                ' pretend it's PROLOG
			XxxParseSourceLine (library$, @tok[]) ' library source line to tokens
			IF tok[] THEN                         ' collect new PROLOG tokens
				tokenPtr = 0                        ' pretend it's line start
				lineNumber = 0                      ' pretend it's line 0
				func_number = 0                     ' pretend it's PROLOG
				got_function = 0                    ' pretend it's PROLOG
				parse_got_function = 0              ' pretend it's PROLOG
				XxxCheckLine (0, @tok[])            ' compile the tokens
				SELECT CASE TRUE
					CASE i486asm
'               SELECT CASE LCASE$(libraryName$)
'                 CASE "xlib", "xdis", "xst", "xin", "xma", "xcm", "xit", "xcol", "xgr", "xui", "gdi32", "kernel32", "user32"
'                       dll$ = "xb"
'                 CASE ELSE
'                       dll$ = libraryName$
'               END SELECT
								string$ = "IMPORTS  " + libraryName$ + "." + funcSymbol$
								WriteDefinitionFile (@string$)
					CASE i486bin
								IF handle THEN              ' libname.DLL exists
									'
									' If symbol already defined in xb by GetExternalAddresses(), or previous IMPORT, use first one.
									'
									tok = AddLabel (@libraryFunctionLabel$, $$KIND_LABELS, 0, $$XGET)
									IF TokenMatch (@tok, @#T_ZERO) THEN
										tok = AddLabel (@libraryFunctionLabel$, $$KIND_LABELS, 0, $$XNEW)
									END IF
									IF XERROR THEN PRINT "XxxGetUndeclaredFunction(99)", libraryFunctionLabel$
									IF XERROR THEN EXIT FOR
									tt = tok.tindex
									IFZ labaddr[tt] THEN
										addr = GetProcAddress (handle, &libraryFunctionLabel$)
										IF (libraryFunctionLabel$ == "malloc") THEN
											PRINT "XxxGetUndeclaredFunction(108)", tt, HEX$(addr), funcSymbol$, libraryFunctionLabel$
										END IF
										IF addr THEN labaddr[tt] = addr
									END IF
								END IF
				END SELECT
				parse_got_function = holdParseFunc  ' restore real parse_got_function
				got_function = holdGotFunc          ' restore real got_function
				func_number = holdFunc              ' restore real func number
				lineNumber = holdLine               ' restore real line number
				tokenPtr = holdTokenPtr             ' restore real token pointer
				tokenCount = holdTokenCount         ' restore real token count
				SWAP bs[], tokens[]: DIM bs[]       ' restore compiling line tokens[]
			END IF                                '
			EXIT FOR                              ' done... got library declaration
		NEXT i                                  ' next source line in this library
		ATTACH library$[] TO libraryCode$[lib,] ' replace libname.DEC source
		IF XERROR THEN EXIT FUNCTION            ' AddLabel error
		IF match THEN EXIT FOR                  ' found declaration - skip rest of libraries
	NEXT lib                                  ' next library
'
	token = funcToken[funcNumber]            ' get updated func token
	RETURN (token)                            ' return updated func token
'
'
eeeDupLabel:
	XERROR = ERROR_DUP_LABEL
	RETURN (#T_STARTS)
'
eeeProgramNotNamed:
	XERROR = ERROR_PROGRAM_NOT_NAMED
	RETURN (#T_STARTS)
END FUNCTION
'
'
' ##################################
' #####  XxxXBasicVersion$ ()  #####
' ##################################
'
' version$ = XxxXBasicVersion$ ()
'
FUNCTION  XxxXBasicVersion$ ()
	xxxVersion$ = VERSION$ (0)
	RETURN (xxxVersion$)
END FUNCTION
'
'
' ###############################
' #####  XxxXntBlowback ()  #####
' ###############################
'
FUNCTION  XxxXntBlowback ()
	SHARED  libraryHandle[]
	SHARED  libraryName$[]
	SHARED  libraryCode$[]
	FUNCADDR  addr ()
'
' Must enable the Windows code below to make true DLLs work.
'
	upper = UBOUND (libraryCode$[])
	FOR i = 0 TO upper
		IF libraryCode$[i,] THEN
			libname$ = libraryName$[i]
			IF libname$ THEN
				SELECT CASE LCASE$(libname$)
					CASE "xlib", "xdis", "xst", "xin", "xma", "xcm", "xit", "xcol", "xgr", "xui", "gdi32", "kernel32", "user32"
					CASE "xut", "xutpde", "xwin", "clib", "elf64"
					CASE ELSE
								handle = libraryHandle[i]
								IF handle THEN
									blowback$ = "Blowback"
										addr = GetProcAddress (handle, &blowback$)
'                   PRINT blowback$; " = "; HEX$ (addr,8)
										@addr ()
'
										blowback$ = $$ulpc4$ + "blowback_" + libname$
										addr = GetProcAddress (handle, &blowback$)
'                   PRINT blowback$; " = "; HEX$ (addr,8)
										@addr ()
								END IF
				END SELECT
			END IF
		END IF
	NEXT i
	##ENTERED = $$FALSE
END FUNCTION
'
'
' ####################################
' #####  XxxXntFreeLibraries ()  #####
' ####################################
'
FUNCTION  XxxXntFreeLibraries ()
	SHARED  libraryHandle[]
	SHARED  libraryName$[]
	SHARED  libraryCode$[]
	FUNCADDR  addr ()
'
	upper = UBOUND (libraryCode$[])
	FOR i = 0 TO upper
		IF libraryCode$[i,] THEN
			libname$ = libraryName$[i]
			IF libname$ THEN
				SELECT CASE LCASE$(libname$)
					CASE "xlib", "xdis", "xst", "xin", "xma", "xcm", "xit", "xcol", "xgr", "xui", "gdi32", "kernel32", "user32"
					CASE "xut", "xutpde", "xwin", "clib", "elf64"
					CASE ELSE
								handle = libraryHandle[i]
								IF handle THEN
									free = FreeLibrary (handle)
									PRINT "FreeLibrary ("; HEX$(handle,8); " = "; free
									ATTACH libraryCode$[i,] TO temp$[]
									libraryHandle[i] = 0
									libraryName$[i] = ""
									DIM temp$[]
								END IF
				END SELECT
			END IF
		END IF
	NEXT i
	DIM libraryCode$[]
	DIM libraryName$[]
	DIM libraryHandle[]
END FUNCTION
END PROGRAM

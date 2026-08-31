'
'
' ####################  Max Reason
' #####  PROLOG  #####  copyright 1988-2000
' ####################  Linux XBasic development environment
'
' subject to GPL license - see COPYING
'
' maxreason@maxreason.com
'
' for Linux XBasic
'
'
PROGRAM  "xit"
VERSION  "6.4.5"
'
IMPORT  "xst"
IMPORT  "xin"
IMPORT  "xma"
IMPORT  "xcm"
IMPORT  "xgr"
IMPORT  "xui"
IMPORT  "clib"
IMPORT  "xut"
IMPORT  "xutpde"
'
'
' *********************************
' *****  Xit COMPOSITE TYPES  *****
' *********************************
'
TYPE CURSORLOCATION
	XLONG   .pos            ' cursor position
	XLONG   .line           ' cursor line
	XLONG   .indent         ' indent from left
	XLONG   .topLine        ' top line
END TYPE
'
TYPE MEMORY               ' for SharedMemory()
	XLONG    .id            ' shmid
	XLONG    .addr          ' base address
	XLONG    .size          ' byte size
	XLONG    .state         ' read/write/execute
END TYPE
'
TYPE FRAMEINFO
	XLONG    .frameAddr     ' base frame pointer
	XLONG    .funcAddr      ' execution address
	XLONG    .funcNumber    ' function number / -1
	XLONG    .funcLine      ' line number in function
END TYPE
'
TYPE SIGFRAME
	XLONG   .retaddr        ' return address
	XLONG   .signo          ' signal number
	XLONG   .reg[18]        ' registers
	XLONG   .sigmask        ' signal mask
END TYPE
'
'TYPE CPUCONTEXT
'	XLONG   .gs
'	XLONG   .fs
'	XLONG   .es
'	XLONG   .ds
'	XLONG   .rdi
'	XLONG   .rsi
'	XLONG   .rbp
'	XLONG   .rsp
'	XLONG   .rbx
'	XLONG   .rdx
'	XLONG   .rcx
'	XLONG   .rax
'	XLONG   .trap
'	XLONG   .err
'	XLONG   .rip
'	XLONG   .cs
'	XLONG   .efl
'	XLONG   .ursp
'	XLONG   .ss
'	XLONG   .addrFPU
'	XLONG   .sigmask
'END TYPE
'
TYPE CPUCONTEXT
	XLONG   .ct0
	XLONG   .ct1
	XLONG   .ct2
	XLONG   .ct3
	XLONG   .ct4
	XLONG   .r8
	XLONG   .r9
	XLONG   .r10
	XLONG   .r11
	XLONG   .r12
	XLONG   .r13
	XLONG   .r14
	XLONG   .r15
	XLONG   .rdi
	XLONG   .rsi
	XLONG   .rbp
	XLONG   .rbx
	XLONG   .rdx
	XLONG   .rax
	XLONG   .rcx
	XLONG   .rsp
	XLONG   .rip
	XLONG   .rflags
	XLONG   .cs
	XLONG   .ss
	XLONG   .trap        '????????
END TYPE
'
'
' *****  TOKEN Information  *****
'
TYPE TOKIX
	UBYTE  .ndex
	UBYTE  .errno
	UBYTE  .byte2
	UBYTE  .bpexe
END TYPE
'
TYPE TAKS
	UBYTE  .type
	UBYTE  .allo
	UBYTE  .kind
	SBYTE  .stsp
END TYPE
'
TYPE TOKEN
	UNION
		ULONG  .tindex
		TOKIX  .ti
	END UNION
	UNION
		ULONG  .tproto
		TAKS   .tp
	END UNION
END TYPE
'
'
' *****************************
' *****  Entry and Setup  *****
' *****************************
'
' XxxXitMain() has to be a CFUNCTION because its the signal handler
' function, which the system expects is a C function.
'
DECLARE  FUNCTION  XxxXit                     (argc, argv, envp)
DECLARE CFUNCTION  XxxXitMain                 (signal, siginfo, ucontext)
DECLARE CFUNCTION  XxxXitSigAlrm              (signal)
INTERNAL FUNCTION  XitVersion$                ()
INTERNAL FUNCTION  Welcome                    ()
INTERNAL FUNCTION  WelcomeCode                (grid, message, v0, v1, v2, v3, kid, r1)
'
INTERNAL FUNCTION  CaptureExceptionContext    (context, base, oldrbp, retaddr, signo, CPUCONTEXT cpu)
INTERNAL FUNCTION  ReplaceExceptionContext    (context, base, oldrbp, retaddr, signo, CPUCONTEXT cpu)
INTERNAL FUNCTION  PrintExceptionContext      (rbp, base, oldrbp, retaddr, signal, exception, CPUCONTEXT cpu)
INTERNAL FUNCTION  InitGui                    ()
INTERNAL FUNCTION  InitProgram                ()
INTERNAL FUNCTION  FindAliensCfunc            ()
INTERNAL FUNCTION  FreeAliens                 ()
INTERNAL FUNCTION  Message                    (message$)
INTERNAL FUNCTION  PrintMenu                  ()
INTERNAL FUNCTION  PrintStack                 ()
INTERNAL FUNCTION  SharedMemory               (command, address, size, ANY)
INTERNAL FUNCTION  XitBlowback                ()
INTERNAL FUNCTION  UserBlowback               ()
INTERNAL FUNCTION  XxxXitQuit                 (status)
INTERNAL FUNCTION  EstablishSignals           ()
EXTERNAL FUNCTION  Xio                        ()
INTERNAL FUNCTION  XitGetPDEPrefWindowPositionAndSize (grid, name$)
INTERNAL FUNCTION  XitLoadPDEPref             ()
INTERNAL FUNCTION  XitSetPDEPrefWindowPositionAndSize (grid, name$)
INTERNAL FUNCTION  XitSavePDEPref             ()
'
DECLARE FUNCTION  SystemErrorSetError         ()
DECLARE FUNCTION  PrintError                  ()
DECLARE FUNCTION  PrintSystemError            ()
DECLARE FUNCTION  PrintSystemErrorNativeError ()
'
'
' *****************************
' *****  Debug Functions  *****
' *****************************
'
DECLARE FUNCTION  Asm                 (addr$, length$, asm$[])
DECLARE FUNCTION  DisplayAssembly     (addr$, length$)
DECLARE FUNCTION  DisplayLocate       (value$)
DECLARE FUNCTION  DisplayRegisters    (CPUCONTEXT cpu)
DECLARE FUNCTION  DisplayTestHeaders  ()
DECLARE FUNCTION  Dump$               (addr$, xsize$)
DECLARE FUNCTION  DumpLong$           (addr$, xsize$)
DECLARE FUNCTION  DumpXlong$          (addr$, xsize$)
DECLARE FUNCTION  DynoLinkCheck       ()
DECLARE FUNCTION  Fill                (start$, xsize$, value$)
DECLARE FUNCTION  Frames$             ()
DECLARE FUNCTION  G                   (addr$)
DECLARE FUNCTION  Go                  ()
DECLARE FUNCTION  Locate              (value$, line$[])
DECLARE FUNCTION  MemoryMap$          ()
DECLARE FUNCTION  Substitute          (addr$)
DECLARE FUNCTION  UserGo              ()
'
' *************************************
' *****  Debug Utility Functions  *****
' *************************************
'
INTERNAL FUNCTION  AddressOk          (addr)
INTERNAL FUNCTION  ChangeRegister     (reg[], arg0$, arg1$)
INTERNAL FUNCTION  ClearRegisters     ()
INTERNAL FUNCTION  ParseLine$         (command$, args$[])
INTERNAL FUNCTION  RegisterString$    ()
INTERNAL FUNCTION  Xarg               (arg$)
INTERNAL FUNCTION  XXfree             (addr)
INTERNAL FUNCTION  XXmalloc           (bytes)
INTERNAL FUNCTION  XXcalloc           (bytes)
INTERNAL FUNCTION  XXrealloc          (oldAddr, newSize)
'
' *******************************
' *****  Testing Functions  *****
' *******************************
'
INTERNAL FUNCTION  CountHeaders       ()
INTERNAL FUNCTION  Headers            (pointersBaseAddr, headersBaseAddr)
INTERNAL FUNCTION  MissingHeader      (addr, headers[], limit)
INTERNAL FUNCTION  PrintHeader        (addr, ua, da, ul, dl)
INTERNAL FUNCTION  TestHeaders        ()
'
' **********************************
' *****  Breakpoint Functions  *****
' **********************************
'
INTERNAL FUNCTION  Break              (command, addr)
INTERNAL FUNCTION  BreakContinuePrep  (command, func, continueAddr)
INTERNAL FUNCTION  BreakPatch         ()
INTERNAL FUNCTION  BreakPatchAll      (startAddr)
INTERNAL FUNCTION  BreakPatchLog      (patchAddr, patchCode)
'
'
' **************************************
' *****  Error Reporting Functions *****
' **************************************
'
INTERNAL FUNCTION  GetRuntimeError    (runtimeInfo$, runtimeMsg$)
INTERNAL FUNCTION  WarningResponse    (message$, okButton$, optionButton$)
'
'
' ********************************
' *****  INTERNAL Utilities  *****
' ********************************
'
INTERNAL FUNCTION  XitCrash           (signal, sxip, fatal)
INTERNAL FUNCTION  AssemblyString$    (funcNumber, lineNumber)
'
INTERNAL FUNCTION  MainLoop           (exitFlagAddr)
INTERNAL FUNCTION  ClearMessageQueue  ()
INTERNAL FUNCTION  AddDispatch        (funcAddress, arg)
INTERNAL FUNCTION  Dispatch           ()
INTERNAL FUNCTION  EnableAbortSignals ()
'
'
' ********************************
' *****  Breakpoint Control  *****
' ********************************
'
INTERNAL FUNCTION  BreakClearArrays   ()
INTERNAL FUNCTION  BreakInternal      (command, func, line, addr)
INTERNAL FUNCTION  BreakProgrammer    (command, addr, func)
INTERNAL FUNCTION  GetFuncAndLineNumberAtThisAddress (addr)
'
'
' *******************************************
' *******************************************
' *****  Xit Environment GUI Functions  *****
' *******************************************
' *******************************************
'
INTERNAL FUNCTION  XitExecute         ()
INTERNAL FUNCTION  CreateWindows      ()
INTERNAL FUNCTION  InitWindows        ()
INTERNAL FUNCTION  AlignWindow        (grid, align)
INTERNAL FUNCTION  HideWindow         (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  Environment        (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  EnvironmentCode    (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  WelcomeWindowCode  (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitCEO             (grid, message, v0, v1, v2, v3, r0, ANY)
'
' Xit Custom Grid Types
'
INTERNAL FUNCTION  XitArray           (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitAssembly        (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitComposite       (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  Xit2LineDialog     (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  Xit3LineDialog     (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitErrorCompile    (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitErrorRuntime    (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitFind            (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitFrames          (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitMemory          (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitOptionMisc      (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitRegisters       (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitString          (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitTextCursor      (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  XitVariables       (grid, message, v0, v1, v2, v3, r0, ANY)
'
' ********************************
' *****  Xit Menu Functions  *****
' ********************************
'
INTERNAL FUNCTION  AddCommandItem     (text$)
INTERNAL FUNCTION  ImmediateMode      (keyState)
'
INTERNAL FUNCTION  FileNew            (mode)
INTERNAL FUNCTION  FileTextLoad       (skipUpdate)
INTERNAL FUNCTION  FileLoad           (skipUpdate)
INTERNAL FUNCTION  FileRecentLoad     (index)
INTERNAL FUNCTION  FileSave           (skipUpdate)
INTERNAL FUNCTION  FileMode           (mode)
INTERNAL FUNCTION  FileRename         (skipUpdate)
INTERNAL FUNCTION  FileQuit           ()
INTERNAL FUNCTION  FileListFuncSet    ()
'
INTERNAL FUNCTION  EditFind           (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  FindSearch         ()
INTERNAL FUNCTION  ReplaceSearch      ()
INTERNAL FUNCTION  EditRead           (skipUpdate)
INTERNAL FUNCTION  EditWrite          (skipUpdate, bufferNumber)
INTERNAL FUNCTION  EditAbandon        ()
INTERNAL FUNCTION  EditCleanBackup    (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  EditLoadBackup     (grid, message, v0, v1, v2, v3, r0, ANY)
'
INTERNAL FUNCTION  ViewFunc           (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  ViewPriorFunc      ()
INTERNAL FUNCTION  ViewNewFunc        (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  ViewDeleteFunc     (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  ViewRenameFunc     (skipUpdate)
INTERNAL FUNCTION  ViewCloneFunc      (skipUpdate)
INTERNAL FUNCTION  ViewLoadFunc       (skipUpdate)
INTERNAL FUNCTION  ViewSaveFunc       (skipUpdate)
INTERNAL FUNCTION  ViewMergePROLOG    (skipUpdate)
INTERNAL FUNCTION  ViewImportFunctionFromProgram  (skipUpdate)
'
INTERNAL FUNCTION  XitHelpIndexCode   (grid, message, v0, v1, v2, v3, r0, r1)
INTERNAL FUNCTION  XitOptionMiscCode  (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  OptionTabWidth     (width)
INTERNAL FUNCTION  OptionTextCursor   (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  OptionFont         ()
'
INTERNAL FUNCTION  ClearForCompile    ()
INTERNAL FUNCTION  CompileAssembly    ()
INTERNAL FUNCTION  CompileProgram     ()
INTERNAL FUNCTION  RunAssembler        ()
INTERNAL FUNCTION  RunContinue        ()
INTERNAL FUNCTION  RunJump            ()
INTERNAL FUNCTION  RunKill            ()
INTERNAL FUNCTION  RunLibrary         ()
INTERNAL FUNCTION  RunMake            ()
INTERNAL FUNCTION  RunPause           ()
INTERNAL FUNCTION  RunRecompile       ()
INTERNAL FUNCTION  RunStandalone      ()
INTERNAL FUNCTION  RunStart           ()
'
INTERNAL FUNCTION  BPTraceOff         ()
INTERNAL FUNCTION  BPTraceOn          ()
INTERNAL FUNCTION  DebugToggle        ()
INTERNAL FUNCTION  DebugClear         ()
INTERNAL FUNCTION  DebugErase         ()
INTERNAL FUNCTION  DebugMemory        (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  DebugAssembly      (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  DebugRegisters     (grid, message, v0, v1, v2, v3, r0, ANY)
'
INTERNAL FUNCTION  ClearErrors        ()
INTERNAL FUNCTION  UpdateErrors       (func, line)
INTERNAL FUNCTION  WizardCompErrors   (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  WizardRunErrors    (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  ClearRuntimeError  ()
INTERNAL FUNCTION  UpdateRuntimeError ()
'
INTERNAL FUNCTION  HelpIndex          ()
INTERNAL FUNCTION  HelpContents       ()
INTERNAL FUNCTION  HelpHighlight      ()
INTERNAL FUNCTION  HelpAbout          (display)
'
' Xit Hot Button Functions
'
INTERNAL FUNCTION  HotToCursor                ()
INTERNAL FUNCTION  HotStepLocal               ()
INTERNAL FUNCTION  HotStepGlobal              ()
INTERNAL FUNCTION  HotVariables               (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  UpdateVariables            ()
INTERNAL FUNCTION  VariablesFind              ()
INTERNAL FUNCTION  VariablesNewValue          ()
INTERNAL FUNCTION  VariablesDetail            ()
INTERNAL FUNCTION  VariablesArray             (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  VariablesArrayDisplay      (action)
INTERNAL FUNCTION  VariablesArrayIndex        ()
INTERNAL FUNCTION  VariablesArrayElement      ()
INTERNAL FUNCTION  VariablesArrayDetail       ()
INTERNAL FUNCTION  VariablesString            (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  VariablesComposite         (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  VariablesCompositeDisplay  (action)
INTERNAL FUNCTION  VariableSort               (TOKEN tok[], symbol$[], reg[], addr[], Low, High)
INTERNAL FUNCTION  HotFrames                  (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  UpdateFrames               ()
INTERNAL FUNCTION  Pop16Frames                (signal, exeption)
'
' ***********************************************
' *****  APPLICATION DEVELOPMENT FUNCTIONS  *****
' ***********************************************
'
DECLARE FUNCTION  XitGetDECLARE               (func$, declare$)
DECLARE FUNCTION  XitGetDisplayedFunction     (text$)
DECLARE FUNCTION  XitGetFunction              (funcName$, text$[])
DECLARE FUNCTION  XitLoadFunction             (funcName$, fileName$)
DECLARE FUNCTION  XitMergePROLOG              (fileName$)
DECLARE FUNCTION  XitNewProgram               ()
DECLARE FUNCTION  XitQueryFunction            (funcName$, exists)
DECLARE FUNCTION  XitQueryProgram             (status)
DECLARE FUNCTION  XitSetDECLARE               (func$, declare$)
DECLARE FUNCTION  XitSetDisplayedFunction     (text$)
DECLARE FUNCTION  XitSetFunction              (funcName$, text$[])
DECLARE FUNCTION  XitSaveFunction             (funcName$, fileName$)
DECLARE FUNCTION  XitSoftBreak                ()
DECLARE FUNCTION  XxxAsm$                     (addr, length)
DECLARE FUNCTION  XxxAnyAsm$                  (addr, length)
DECLARE FUNCTION  XxxGetFuncNumGivenAddress   (addr)
DECLARE FUNCTION  XxxSetBlowback              ()
DECLARE FUNCTION  XxxXitGetUserProgramName    (@program$)
DECLARE FUNCTION  XxxXitExit                  (status)
'
' *******************************************
' *******************************************
' *****  Xit Generic Support Functions  *****
' *******************************************
' *******************************************
'
INTERNAL FUNCTION  CheckDECLARE               (TOKEN tok[], declareFuncNumber)
INTERNAL FUNCTION  CloneDECLARE               (srcFuncNumber, newFuncNumber)
INTERNAL FUNCTION  CompileLine                (funcNumber, lineNumber, TOKEN tok[])
INTERNAL FUNCTION  ConvertProgToText          (mode, crlf, abortAllowed, ANY)
INTERNAL FUNCTION  ConvertTextToProg          (mode, ANY, abortAllowed)
INTERNAL FUNCTION  DefaultFunctionText        (funcNumber, text$[])
INTERNAL FUNCTION  Display                    (funcNumber, cursorLine, cursorPos, topLine, topIndent)
INTERNAL FUNCTION  FindArray                  (mode, text$[], find$, line, pos, reps, skip, matches[])
INTERNAL FUNCTION  FunctionNameToNumber       (funcName$, funcNumber)
INTERNAL FUNCTION  GetFuncNumberGivenAddress  (addr)
INTERNAL FUNCTION  InitializeCompiler         ()
INTERNAL FUNCTION  LoadLineCodeArray          ()
INTERNAL FUNCTION  MakeStringHex              (numstr$)
INTERNAL FUNCTION  NextXitToken               (TOKEN tok[], tokPtr, lastTok, TOKEN token)
INTERNAL FUNCTION  RemoveExeLinePtr           ()
INTERNAL FUNCTION  ReplaceArray               (mode, text$[], find$, replace$, line, pos, reps, skip)
INTERNAL FUNCTION  ResetDataDisplays          (action)
INTERNAL FUNCTION  RestoreTextToProg          (redisplay, reportBogusRename)
INTERNAL FUNCTION  SetCurrentStatus           (status, line)
INTERNAL FUNCTION  SetCursor                  (cursor)
INTERNAL FUNCTION  SetDataDisplays            ()
INTERNAL FUNCTION  SetEntryFunction           ()
INTERNAL FUNCTION  SetExeLinePtr              ()
INTERNAL FUNCTION  SortFunctionNames          (name$[], includePROLOG)
INTERNAL FUNCTION  TextHasNonWhites           (mode, ANY)
INTERNAL FUNCTION  TextToTokenArray           (text$[], TOKEN func[], funcNumber, freeze)
INTERNAL FUNCTION  TokenArrayToText           (funcNumber, text$[])
INTERNAL FUNCTION  TokenMatch                 (TOKEN token1, TOKEN token2)
INTERNAL FUNCTION  UpdateFileFuncLabels       (updateFile, updateFunc)
INTERNAL FUNCTION  VariableTypeToValue        (tt, sizeExact, wordAdd, hexValue$, value$)
INTERNAL FUNCTION  HotStepOut                 ()
INTERNAL FUNCTION  GetStepOutFunc             ()
INTERNAL FUNCTION  AddFileToBackupDir         (skipUpdate)
INTERNAL FUNCTION  XitSystemExceptionToException (signal, exception)
INTERNAL FUNCTION  L                          (id)
DECLARE FUNCTION  XitF7 ()
'
' xlib.s functions
'
EXTERNAL FUNCTION  XxxBreakpoint              ( )
EXTERNAL FUNCTION  XxxG                       ( )
EXTERNAL FUNCTION  XxxGetRbpRsp               (@rbp, @rsp)
EXTERNAL FUNCTION  XxxSetRbpRsp               (rbp, rsp)
EXTERNAL FUNCTION  XxxSetFrameAddr            (addr)
EXTERNAL CFUNCTION xb_5_free                  (addr)
'
' compiler functions
'
EXTERNAL FUNCTION  Xnt                        ()
EXTERNAL FUNCTION  XxxCheckLine               (lineNumber, TOKEN @tok[])
EXTERNAL FUNCTION  XxxCompilePrep             ()
EXTERNAL FUNCTION  XxxCreateCompileFiles      ()
EXTERNAL FUNCTION  XxxDeleteFunction          (funcNumber)
EXTERNAL FUNCTION  XxxDeparser                (TOKEN @tok[], @asm$)
EXTERNAL FUNCTION  XxxDeparseFunction         (@text$, TOKEN @func[], lastLine, flags)
EXTERNAL FUNCTION  XxxErrorInfo               (xerror, @rawPtr, @srcPtr, @srcLine$)
EXTERNAL FUNCTION  XxxFunctionName            (command, @funcName$, editFunction)
EXTERNAL FUNCTION  XxxFunctionNumber          (funcName$)
EXTERNAL FUNCTION  XxxGetAddressGivenLabel    (label$)
EXTERNAL FUNCTION  XxxGetFunctionVariables    (showFuncNumber, @kinds[], TOKEN @varTok[], @varSymbol$[], @varReg[], @varAddr[])
EXTERNAL FUNCTION  XxxGetLabelGivenAddress    (addr, @labels$[])
EXTERNAL FUNCTION  XxxGetPatchErrors          (@symbol$[], @token[], @addr[])
EXTERNAL FUNCTION  XxxGetProgramName          (program$)
EXTERNAL FUNCTION  XxxGetUserTypes            (varTypes$[])
EXTERNAL FUNCTION  XxxGetXerror$              (error)
EXTERNAL FUNCTION  XxxInitAll                 ()
EXTERNAL FUNCTION  XxxInitParse               ()
EXTERNAL FUNCTION  XxxInitVariablesPass1      ()
EXTERNAL FUNCTION  XxxParseSourceLine         (@token$, TOKEN @tok[])
EXTERNAL FUNCTION  XxxPassFunctionArrays      (command, @funcSymbol$[], @funcToken[], @funcScope[])
EXTERNAL FUNCTION  XxxPassTypeArrays          (command, @pSize[], @pSize$[], @pAlias[], @pAlign[], @pSymbol$[], TOKEN @pToken[], @pEleCount[], @pEleSymbol$[], TOKEN @pEleToken[], @pEleAddr[], @pEleSize[], @pEleType[], @pEleStringSize[], @pEleUBound[])
EXTERNAL FUNCTION  XxxSetProgramName          (program$)
EXTERNAL FUNCTION  XxxTheType                 (TOKEN token, funcNumber)
EXTERNAL FUNCTION  XxxXBasic                  ()
EXTERNAL FUNCTION  XxxXBasicVersion$          ()
EXTERNAL FUNCTION  XxxXntBlowback             ()
'
' standard library functions
'
EXTERNAL FUNCTION  XxxXstBlowback             ()
EXTERNAL FUNCTION  XxxXstFreeLibrary          (lib$, handle)
EXTERNAL FUNCTION  XxxXstLoadLibrary          (lib$)
EXTERNAL FUNCTION  XxxXstLog                  (text$)
EXTERNAL FUNCTION  XxxLog                     (text$)
EXTERNAL FUNCTION  XxxLog2                    (text$, int)
EXTERNAL FUNCTION  XxxLog10                   (logMessage$, window, grid, message, v0, v1, v2, v3, r0, r1)
EXTERNAL FUNCTION  XxxXstTimer                (command, grid, timer, count, msec, func)
EXTERNAL FUNCTION  XxxCloseAllUser            ()
'
' sockets library functions
'
EXTERNAL FUNCTION  XxxXinBlowback             ()
'
' disassembler functions
'
EXTERNAL FUNCTION  Xdis                       ()
EXTERNAL FUNCTION  XxxDisassemble64$          (addr, mode)
'
' GraphicsDesigner designer functions
'
EXTERNAL FUNCTION  XxxXgrSysMessages          ()
EXTERNAL FUNCTION  XxxDispatchEvents          (sync, wait)
EXTERNAL FUNCTION  XxxXgrBlowback             ()
EXTERNAL FUNCTION  XxxXgrQuit                 ()
EXTERNAL FUNCTION  XxxXgrResetUserMode        ()
EXTERNAL FUNCTION  XxxXgrSetHuh               (ghuh)
'
' GuiDesigner library functions
'
EXTERNAL FUNCTION  XxxGuiDesignerOnOff        (state)
EXTERNAL FUNCTION  XxxXuiBlowback             ()
EXTERNAL FUNCTION  XxxXuiTextCursor           (color)
'
'
' ***********************
'  *****  Constants  *****
' ***********************
'
	$$RecentUpper           = 11             ' upper dimension of recent file list array
'
' for SharedMemory ()
'
	$$MemoryCreate          = 1              ' command
	$$MemoryDestroy         = 2              ' command
	$$MemoryDestroyAll      = 3              ' command
	$$MemoryEnumerate       = 4              ' command
	$$MemorySetMode         = 5              ' command ???
	$$Read                  = 0b100100100    ' mode (in $$Create)
	$$Write                 = 0b010010010    ' mode
	$$Execute               = 0b001001001    ' mode
	$$ReadWrite             = 0b110110110    ' mode
	$$ReadExecute           = 0b101101101    ' mode
	$$ReadWriteExecute      = 0b111111111    ' mode
	$$OwnerRead             = 0b100000000    ' mode
	$$OwnerWrite            = 0b010000000    ' mode
	$$OwnerReadWrite        = 0b110000000    ' mode
	$$OwnerReadWriteExecute = 0b111000000    ' mode
'
' for lseek ()
'
	$$U_SEEK_SET          = 0
	$$U_SEEK_CUR          = 1
	$$U_SEEK_END          = 2
'
' fatal signals
'
	$$FatalSignalInEnv    = 1
	$$FatalSigQuitInAllo  = 2
'
' active file type
'
	$$Unspecified         = 0
	$$Text                = 1
	$$Program             = 2              ' See XitQueryProgram()
	$$GuiProgram          = 3              ' See FileNew()
'
	$$TextString          = 0              ' text <-> prog conversion
	$$TextArray           = 1
	$$AbortAllowed        = $$TRUE
	$$AbortNotAllowed     = $$FALSE
'
	$$Breakpoint          = 0xCC          ' int 3 "breakpoint" opcode on 80386+
'
' for BreakProgrammer() and BreakInternal()
'
	$$BreakRemoveAll          =  0
	$$BreakRemoveOne          =  1
	$$BreakInstallAll         =  2
	$$BreakInstallFunc        =  3
	$$BreakInstallOne         =  4
	$$BreakGetFuncLineOpcode  =  5
	$$BreakGetOpcode          =  6
	$$BreakClearAll           =  7
	$$BreakClearFunc          =  8
	$$BreakClearOne           =  9
	$$BreakSetOne             = 10
	$$BreakCheckOne           = 11
'
	$$BreakContinueRunning    =  0
	$$BreakContinueStepLocal  =  1
	$$BreakContinueStepGlobal =  2
	$$BreakContinueToCursor   =  3
	$$BreakContinueStepOut    =  4
'
	$$IPC_PRIVATE  =  0                    ' shmget (private page)
	$$SC_SHMMAXSZ  = 16                    ' sysconf: max size of shared segment
	$$SC_SHMSEGS   = 17                    ' sysconf: max number of attached segs
'
	$$StatusAssembling    = 0              ' environment status
	$$StatusCompiled      = 1
	$$StatusCompiling     = 2
	$$StatusDecoding      = 3
	$$StatusDeparsing     = 4
	$$StatusEditing       = 5
	$$StatusFormatting    = 6
	$$StatusInitializing  = 7
	$$StatusLoading       = 8
	$$StatusParsing       = 9
	$$StatusPaused        = 10
	$$StatusQuitting      = 11
	$$StatusRecompiling   = 12
	$$StatusRunning       = 13
	$$StatusSaving        = 14
	$$StatusSearching     = 15
	$$StatusText          = 16
	$$StatusXit           = 17
	$$StatusInline        = 18            ' User program is waiting in INLINE$()
'
	$$WarningProceed      =  1            ' for warning response
	$$WarningOption       =  2
	$$WarningCancel       =  3
'
	$$ResetAssembly       =  1            ' For ResetDataDisplays()
	$$InitiatingRun       =  2            '            "
'
	$$XGET                =  0            ' compiler function commands
	$$XSET                =  1
'
	$$NUMBER   = BITFIELD (16, 0)
	$$WORD0    = BITFIELD (16, 0)
	$$WORD1    = BITFIELD (16, 16)
	$$BYTE0    = BITFIELD (8, 0)
	$$BYTE1    = BITFIELD (8, 8)
	$$BYTE2    = BITFIELD (8, 16)
	$$BYTE3    = BITFIELD (8, 24)
'
' *****************************
' *****  Xit Error Codes  *****
' *****************************
'
	$$XitEnvironmentInactive  = 1        ' Application management errors
	$$XitTextMode             = 2
	$$XitProgramRunning       = 3
	$$XitInvalidFunctionName  = 4
	$$XitFunctionUndefined    = 5
	$$XitMismatchedArguments  = 6        ' Last error < ##ERROR: file errors
'
' ********************************
' *****  Compiler Constants  *****
' ********************************
'
	$$KIND_VARIABLES      = 0x01
	$$KIND_ARRAYS         = 0x02
	$$KIND_CONSTANTS      = 0x04
	$$KIND_FUNCTIONS      = 0x07
	$$KIND_ARRAY_SYMBOLS  = 0x08
	$$KIND_SYSCONS        = 0x0C
	$$KIND_STATEMENTS     = 0x0D
	$$KIND_TYPES          = 0x10
	$$KIND_STARTS         = 0x11
	$$KIND_COMMENTS       = 0x19
	$$KIND_WHITES         = 0x1B
'
'
' *******************************
' *****  Xit ()  CONSTANTS  *****
' *******************************
'
	$$NOT_LOWEST_DIM      = BITFIELD (1, 29)
	$$ELESIZE             = BITFIELD (16, 0)
'
	$$BPEXECLR     = 0
	$$EXE          = 1
	$$BP           = 2
	$$BPEXE        = 3
'
'
'  ***************************
'  *****  Kid Constants  *****
'  ***************************
'
	$$FindLocalToggle   = 1        ' XitFind kids
	$$FindCaseToggle    = 2
	$$FindReverseToggle = 3
	$$FindWordToggle    = 4
	$$FindFindLabel     = 5
	$$FindFindText      = 6
	$$FindReplaceLabel  = 7
	$$FindReplaceText   = 8
	$$FindRepsLabel     = 9
	$$FindRepsText      = 10
	$$FindFindButton    = 11
	$$FindReplaceButton = 12
	$$FindCancelButton  = 13
'
'  environment kids (xitGrid)
'
	$$xitFileLabel        =  3
	$$xitStatusLabel      =  4
	$$xitErrorLabel       =  4
	$$xitHotSave          =  7
	$$xitHotFind          = 14
	$$xitHotReplace       = 15
	$$xitCommand          = 34
	$$xitFunction         = 19
	$$xitTextLower        = 35
'
'  other kids
'
	$$DialogText        = 2
'
	$$SourceVariables   = 1
	$$SourceArrays      = 2
	$$SourceComposites  = 3
'
' ******************************
' *****  Cursor CONSTANTS  *****  *****  ??? Windows Specific ???  *****
' ******************************
'
	$$CursorReady        =   0
	$$CursorWarning      =  60        ' Hand 2 shapeID (see cursorfont.h)
	$$CursorWait         = 150        ' Watch
'
' kernel Interrupt Descriptor Table (IDT) indexes
' in TYPE CPUCONTEXT.trap
'
$$TrapDivideError =  0  ' Divide error
$$TrapDebug       =  1  ' Debug exception
$$TrapNMI         =  2  ' Non-maskable interrupt
$$TrapBreakpoint  =  3  ' Breakpoint
$$TrapOverflow    =  4  ' Overflow
$$TrapBounds      =  5  ' Bounds check
$$TrapInvalidOp   =  6  ' Invalid opcode
$$TrapDevice      =  7  ' Coprocessor not available
$$TrapDoubleFault =  8  ' Double fault
$$TrapOverrun     =  9  ' Coprocessor segment overrun
$$TrapInvalidTSS  = 10  ' Invalid TSS
$$TrapSegment     = 11  ' Segment not present
$$TrapStack       = 12  ' Stack exception
$$TrapProtection  = 13  ' General protection fault
$$TrapPageFault   = 14  ' Page fault
$$TrapSpurious    = 15  ' Spurious interrup bug
$$TrapCoprocessor = 16  ' Coprocessor error
$$TrapAlignment   = 17  ' Alignment error (80486)
$$TrapMachine     = 18  ' Machine check
'                   19-31  (reserved)
'                   32-255  External (HW) interrupts
'
'
' dimension some shared arrays before the program begins
'
	SHARED  sigs[15]
	SHARED  tempo[31]
	SHARED  jump[25,1]
	SHARED  regTemp[39]
	SHARED  dispatch[7,1]
	SHARED  breakAddr[7]
	SHARED  breakCode[7]
	SHARED  breakPatchAddr[63]
	SHARED  breakPatchCode[63]
	SHARED  lineAddr[255,15]
	SHARED  lineCode@@[255,15]
	SHARED  lineLast[255]
	SHARED  lineUpper[255]
	SHARED  funcFirstAddr[255]
	SHARED  funcAfterAddr[255]
	SHARED  arrayViewIndices[7]
	SHARED  FRAMEINFO  frameInfo[31]
	EXTERNAL /xxx/  autoUpperCase
'
'
'
	TOKEN  #T_AUTO
	TOKEN  #T_AUTOX
	TOKEN  #T_CFUNCTION
	TOKEN  #T_COLON
	TOKEN  #T_COMMENT
	TOKEN  #T_DECLARE
	TOKEN  #T_DIV
	TOKEN  #T_DOUBLE
	TOKEN  #T_END
	TOKEN  #T_EXTERNAL
	TOKEN  #T_FUNCTION
	TOKEN  #T_GIANT
	TOKEN  #T_INTERNAL
	TOKEN  #T_PROGRAM
	TOKEN  #T_SBYTE
	TOKEN  #T_SFUNCTION
	TOKEN  #T_SHARED
	TOKEN  #T_SINGLE
	TOKEN  #T_SLONG
	TOKEN  #T_SSHORT
	TOKEN  #T_STARTS
	TOKEN  #T_STATIC
	TOKEN  #T_STRING
	TOKEN  #T_TYPE
	TOKEN  #T_UBYTE
	TOKEN  #T_USHORT
	TOKEN  #T_ULONG
	TOKEN  #T_VOID
	TOKEN  #T_XLONG
	TOKEN  #T_ZERO
'
'
'  ######################
'  #####  XxxXit()  #####
'  ######################
'
FUNCTION  XxxXit (uargc, uargv, uenvp)
	SHARED  about$
	SHARED  aboutFont
	SHARED  argc
	SHARED  argv$[]
	SHARED  buttonFont
	SHARED  comicBigFont
	SHARED  comicFont
	SHARED  consoleFont
	SHARED  courierFont
	SHARED  dbase
	SHARED  dbase$
	SHARED  dyno$
	SHARED  graphicsInitialized
	SHARED  hideAbout
	SHARED  labelFont
	SHARED  mainTitle$
	SHARED	messageFont
	SHARED  prefFileNumber
	SHARED  romanFont
	SHARED  verdanaFont
'
	STATIC  entry
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "Linux XBasic development environment"
	a$ = "maxreason@maxreason.com"
	a$ = ""
'
' Note: Linux is currently the only OS supported by this source.
	##XBSystem = $$XBSysLinux
	IFZ entry THEN
		entry = $$TRUE
		EstablishSignals ()
	END IF
'
	argc = uargc
	argv = uargv
	envp = uenvp
'
	dbase = ##DATA
	dbase$ = HEX$ (dbase)
	dyno$ = HEX$ (##DYNO)
'
' need to initialize "xst" before anything else to set up $HOME directory stuff
'
	est = Xst ()
'
	XutInit()
	InitProgram ()
 	XutPDEInit()
	Xio ()          ' Xio also calls Xgr ()
	InitGui ()
'
' If there is a pref file, create a console in the position, color and font specified.
'
	homepath$ = XstGetHomePath$()
	IF homepath$ THEN
		IFZ prefFileNumber THEN
			prefFileNumber = XstOpenPref(homepath$ + "/.xb64rc")
		END IF
	END IF
	IF prefFileNumber THEN
		XstSetPrefSection (prefFileNumber, "PDE-WindowPositionsAndSizes")
		name$ = "Console"
		XstGetPrefXLONG (prefFileNumber, name$ + "-X", 0, @x)
		XstGetPrefXLONG (prefFileNumber, name$ + "-Y", 0, @y)
		XstGetPrefXLONG (prefFileNumber, name$ + "-W", 0, @w)
		XstGetPrefXLONG (prefFileNumber, name$ + "-H", 0, @h)
		XstGetPrefXLONG (prefFileNumber, name$ + "-BW", 1, @bw)
		XstGetPrefXLONG (prefFileNumber, name$ + "-TH", 20, @th)
		'
		IF ((w == 0) || (h == 0)) THEN   ' If saved console size not valid then
			XstDisplayConsole()            ' Create and show default location console
		ELSE
			'
			' This should be the first time that a window is being created.
			' The border width and title height will not be calculated yet.
			' So adjust the position by what these values were
			' the last time xbasic saved them in .xb64rc
			'
			XgrGetDisplaySize ("", @width, @height, @borderwidth, @titleHeight)
			XstCreateConsole (x-bw+borderwidth, y-bw-th+borderwidth+titleHeight, w, h)
			'
			XstGetConsoleGrid (@console)
			'
			' Capture the font that might be set by templates/property.xxx
			'
			XuiSendMessage (console, #GetFontNumber, @consoleFont, 0, 0, 0, 0, 0)
			XstSetPrefSection (prefFileNumber, "PDE-Option-Misc")
			XstGetPrefXLONG (prefFileNumber, "consoleDarkColor", $$FALSE, @value)
			IF value THEN XuiSendMessage (console, #SetColor, $$Black, $$White, -1, -1, 1, 0)
			'
			XstGetPrefXLONG (prefFileNumber, "consoleLargeFont", $$FALSE, @value)
			IF value THEN	XuiSendMessage (console, #SetFont, 0, 0, 0, 0, 0, @"9x15bold")
			'
			XstGetPrefXLONG (prefFileNumber, "consoleLargeBars", $$FALSE, @value)
			IF value THEN XuiSendMessage (console, #SetStyle, 4, 0, 0, 0, 0, 0)
			XstShowConsole()
			'
		END IF
	ELSE
		XstDisplayConsole()                                                   ' Create default console
	END IF
	XxxXgrSysMessages ()                                                    ' process system messages
	'
	' Don't initialize Xin; this can lead to problems on badly configured
	' systems.
	' Note that Xin() must initialized in the PDE, even if it's not used.
	' Otherwise it's shared variables can be initialized in 'user mode' which
	' causes all kinds of horrors if it *is* used.
	'
	' variables can be initialized properly in 'usr mode'                    '*cw* 160812-
	'
'	XstSetPrefSection (prefFileNumber, "")                                   '*cw* 150608+ 160812-
'	XstGetPrefSTRING (prefFileNumber, "Xin", "false", @result$)              '*cw* 150608+ 160812-
'	result$ = LCASE$(result$)                                                '*cw* 150608+ 160812-
'	IF (result$ != "false") THEN                                             '*cw* 150608+ 160812-
'		est = Xin ()                                                                         160812-
'	END IF                                                                   '*cw* 150608+ 160812-
	ema = Xma ()
	ecm = Xcm ()
	ent = Xnt ()
	rdi = Xdis ()
'
	IFZ egr THEN
		graphicsInitialized = $$TRUE
	ELSE
		graphicsInitialized = $$FALSE
		PRINT "XxxXit() : GraphicsDesigner initialize error"
	END IF
'
	XstGetCommandLineArguments (@argc, @argv$[])
'
	upper = argc-1
	tops = UBOUND (argv$[])
	IF (tops > upper) THEN upper = tops
'
' create and clear user code space
'
'
	size = 0x40000
	addr = 0x10000000
'	addr = 0x200000000                                                            '*cw* 230302+-
'	addr = 0x80000000                                                            '*cw* 180507-
	error = SharedMemory ($$MemoryCreate, @addr, @size, $$OwnerReadWriteExecute)
'
	IF ((error = 0) OR (error = -1)) THEN
		PrintError ()
	ELSE
		##UCODE0 = addr
		##UCODE = addr + 0x0100
		##UCODEX = addr + 0x0100
		##UCODEZ = addr + size
		a = addr
		z = addr + size
		DO WHILE (a < z)
			ULONGAT (a) = 0x00000000
			a = a + 4
		LOOP
	END IF
'	PRINT "XxxXit(169)", HEXX$(##UCODE0), HEXX$(##UCODE), HEXX$(##UCODEX), HEXX$(##UCODEZ)
'
' create the basic set of fonts
'
'	XgrCreateFont (@aboutFont, @"Comic Sans MS", 320, 400, 0, 0)
'	XgrCreateFont (@romanFont, @"times new roman", 400, 400, 0, 0)
'	XgrCreateFont (@romanBigFont, @"times new roman", 480, 400, 0, 0)
	XgrCreateFont (@messageFont, @"courier", 640, 700, 0, 0)
	XgrCreateFont (@courierFont, @"courier", 240, 400, 0, 0)
'	XgrCreateFont (@comicBigFont, @"Comic Sans MS", 320, 400, 0, 0)
'	XgrCreateFont (@comicFont, @"Comic Sans MS", 260, 400, 0, 0)
'	XgrCreateFont (@verdanaFont, @"verdana", 320, 400, 0, 0)
'
'	PRINT "aboutFont = "; aboutFont
'	PRINT "romanFont = "; romanFont
'	PRINT "comicFont = "; comicFont
'	PRINT "courierFont = "; courierFont
'	PRINT "verdanaFont = "; verdanaFont
'	PRINT "messageFont = "; messageFont
'	PRINT "romanBigFont = "; romanBigFont
'	PRINT "comicBigFont = "; comicBigFont
'
	SELECT CASE TRUE
		CASE comicBigFont	: messageFont = comicBigFont
		CASE comicFont		: messageFont = comicFont
		CASE verdanaFont	: messageFont = verdanaFont
		CASE romanBigFont	: messageFont = romanBigFont
		CASE aboutFont		: messageFont = aboutFont
		CASE romanFont		: messageFont = romanFont
	END SELECT
'
'	PRINT "aboutFont = "; aboutFont
'	PRINT "romanFont = "; romanFont
'	PRINT "comicFont = "; comicFont
'	PRINT "courierFont = "; courierFont
'	PRINT "verdanaFont = "; verdanaFont
'	PRINT "messageFont = "; messageFont
'	PRINT "romanBigFont = "; romanBigFont
'	PRINT "comicBigFont = "; comicBigFont
'
	SELECT CASE TRUE
		CASE aboutFont		: aboutFont = aboutFont
		CASE comicFont		: aboutFont = comicFont
		CASE comicBigFont	: aboutFont = comicBigFont
		CASE verdanaFont	: aboutFont = verdanaFont
		CASE romanFont		: aboutFont = romanFont
	END SELECT
'
'	PRINT "aboutFont = "; aboutFont
'	PRINT "romanFont = "; romanFont
'	PRINT "comicFont = "; comicFont
'	PRINT "courierFont = "; courierFont
'	PRINT "verdanaFont = "; verdanaFont
'	PRINT "messageFont = "; messageFont
'	PRINT "romanBigFont = "; romanBigFont
'	PRINT "comicBigFont = "; comicBigFont
'
	SELECT CASE TRUE
		CASE comicFont		: labelFont = comicFont
												buttonFont = comicFont
	END SELECT
'
	XstLoadString (@"$XBDIR/templates/first.xxx", @first$)
'
	XstSleep (50)
'
'	XstLog ("     PASS 5     : ")
'	XstLog ("           dir$ : " + dir$)
'	XstLog ("          home$ : " + home$)
'	XstLog ("         xbdir$ : " + xbdir$)
'	XstLog ("         xbnew$ : " + xbnew$)
'
	XstLoadString (@"$XBDIR/templates/start.xxx", @start$)
	version$ = VERSION$(0)
	mainTitle$ = "PDE : XBasic-" + version$
'
	about$ = start$
	hideAbout = $$FALSE
	IFZ start$ THEN about$ = " \n Linux  XBasic \n initializing ... please wait "
'
' establish backslash array for text-line input
'
	upper = 255
	DIM #backslash[upper]
'
	FOR i = 0 TO upper
		SELECT CASE TRUE
			CASE (i == 0x09)	: #backslash[i] = 1          ' no backslash \t tab character
			CASE (i == 0x0A)	: #backslash[i] = 1          ' no backslash \n newline character
			CASE (i == 0x0D)	: #backslash[i] = 1          ' no backslash \r return character
			CASE (i <= 0x1F)	: #backslash[i] = 1          ' do backslash other control characters
			CASE (i == 0x22)	: #backslash[i] = 1          ' do backslash "" double-quote characters
			CASE (i == 0x5C)	: #backslash[i] = 1          ' do backslash \\ backslash characters
			CASE (i <= 0x7F)	: #backslash[i] = 0          ' display all English characters
'			CASE (i >= 0x80)	: #backslash[i] = 0          ' display non-English characters
		END SELECT
	NEXT i
'
	XitBlowback ()          ' calls XxxXitMain() which never returns here
	XstLog("XxxXit(267)")
	XxxXitQuit (0)          ' should never execute
END FUNCTION
'
'
' ########################
' #####  XxxXitMain  #####  Invoked on program startup and all SIGNALs
' ########################  (bus error, math errors, break key, etc.)
'
'
' from UNIX debug version
'
' See: EstablishSignals()
'
CFUNCTION  XxxXitMain (signal, siginfo, ucontext)
	EXTERNAL  /xxx/  checkBounds,  library
	SHARED  dbase,  dbase$,  dyno$,  teston,  testdibs
	SHARED  CPUCONTEXT  cpu
	SHARED  CPUCONTEXT  cpuSys
	SHARED  CPUCONTEXT  cpuUser
	SHARED  CPUCONTEXT  cpuOrig
	SHARED  CPUCONTEXT  cpuZero
	SHARED  argc
	SHARED  argv$[]
'
	SHARED  about$
	SHARED  aboutGrid
	SHARED  aboutFont
	SHARED  hideAbout
	SHARED  romanFont
	SHARED  messageFont
	SHARED  courierFont
	SHARED  verdanaFont
	SHARED	comicFont
	SHARED  labelFont
	SHARED	buttonFont
	SHARED  comicBigFont
'
	SHARED  environmentEntered
	SHARED  environmentActive
	SHARED  userContinue
	SHARED  userStepType
	SHARED  editFunction
	SHARED  exception
	SHARED  fileType
	SHARED  userRun
	SHARED  breakAddr[]
	SHARED  breakCode[]
	SHARED  lineAddr[]
	SHARED  lineLast[]
	SHARED  funcAfterAddr[]
	SHARED  xitGrid, fileBox
	SHARED  blowback
	SHARED  haltedByEdit
	SHARED  programAltered, textAlteredSinceSave
	SHARED  exeLine
	SHARED  exeFunction
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[]
	SHARED  processingCrash
	SHARED  lockOutEnvironment
	SHARED  userCursor
	SHARED  userCursorOverride
	SHARED  prefFileNumber
	SHARED  reloadLastFile
	SHARED  saveBeforeCompile, saveBeforeRun
	SHARED  optionMiscBox
	SHARED  huh
	SHARED  breakPatches
'
	STATIC  poppingFrames
	STATIC  notFirstEntry
	STATIC  signalEntry
	STATIC  initialized
	STATIC  rbpStart
	STATIC  rspStart
	STATIC  arg$[]
	STATIC  entry
	STATIC  ghuh
	STATIC  gd
	STATIC  calledRuntimeError
'
	signalActive = ##SIGNALACTIVE
	whomask = ##WHOMASK
	##WHOMASK = 0
'
	lockout = ##LOCKOUT
	IF lockout THEN
		##LOCKOUT = 0
		PRINT "XxxXitMain(94):lockout", lockout
	END IF
'
	IFZ entry THEN
		INC entry 'Add by technicorn
		XxxGetRbpRsp (@rbpStart, @rspStart)
		IF huh THEN PRINT "XxxXitMain(100) : rbpStart rspStart = "; HEX$(rbpStart,16);" "; HEX$(rspStart)
'		PRINT "XxxXitMain(101) : rbpStart rspStart = "; HEX$(rbpStart,16);" "; HEX$(rspStart)
	ELSE
'		XxxGetRbpRsp (@rbp_test, @rsp_test)
'		PRINT "XxxXitMain(104) : rbp_test rsp_test = "; HEX$(rbp_test);" "; HEX$(rsp_test)
'		FOR i = 0 TO 49
'			rsp_test_0 = XLONGAT(rbp_test+(i*8))
'			PRINT HEX$(rsp_test_0)
'		NEXT i
		IF entry < 2147483646 THEN INC entry
	END IF
'
	exception = 0
	IF signal THEN
		IF ##INEXIT THEN XxxXitExit (0) : RETURN
		XstSystemExceptionToException (signal, @exception)
		XstExceptionNumberToName (exception, @exception$)
		IF (signal <> 5) THEN
			PRINT "XxxXitMain(118) : ", signal, HEX$(siginfo), signal$, exception$
		END IF
'		IF ##XBDV THEN XstLog ("XxxXitMain() : " + STRING$(signal) + " " + signal$ + " : " + STRING$(exception) + " " + exception$)
'		IF ##CAPSLOCK THEN PRINT "XxxXitMain(b) : ", exception, exception$, signal, signal$
		IF (signal = $$SIGFPE) THEN
			IF ##XBDV THEN XstLog ("XxxXitMain(123) : " + STRING$(signal) + " " + signal$ + " : " + STRING$(exception) + " " + exception$)
		END IF
	END IF
	IFZ arg$[] THEN DIM arg$[31] : cpuSys = cpuZero : cpuUser = cpuZero
	IF (signal = $$SIGALRM) THEN skip = $$TRUE
	IFZ skip THEN
		IF huh THEN XstExceptionNumberToName (exception, @exception$)
		IF huh THEN PRINT "XxxXitMain(130) :  signal  exception   whomask    exception$  ...  signalEntry"
		IF huh THEN PRINT "####======>> : "; HEX$(signal,8);;; HEX$(exception,8);;; HEX$(whomask,8);;; exception$;;; signalEntry
	END IF
	IFZ signal THEN signalEntry = 0
	##EXCEPTION = exception
	##OSEXCEPTION = signal
	##SIGNAL = signal
'
'	if (signal != 0) this is an exception, not program startup
'
	IF huh THEN PRINT "a";
	IF signal THEN
		IF huh THEN PRINT "b";
'		XxxClearFPException ()
'
		##SIGNALACTIVE = $$TRUE
		addrreg = XxxGetRbpRsp (@rbp, @rsp)
		CaptureExceptionContext (ucontext, @base, @oldrbp, @retaddr, @signo, @cpu)
'		PRINT "XxxXitMain(141)", HEXX$(addrreg), HEXX$(rbp), HEXX$(rsp), signal
'		PrintExceptionContext (rbp, base, oldrbp, retaddr, signo, exception, @cpu)
		SELECT CASE exception
			CASE $$ExceptionBreakpoint
						IF huh THEN PRINT "c";
'						PRINT "c1", HEXX$(XLONGAT(rbp)), HEXX$(XLONGAT(rbp+8)), HEXX$(XLONGAT(rbp+16)), HEXX$(XLONGAT(rbp+24))
'						PRINT "c2", HEXX$(XLONGAT(rbp+32)), HEXX$(XLONGAT(rbp+40)), HEXX$(XLONGAT(rbp+48)), HEXX$(XLONGAT(rbp+56))
						DEC cpu.rip
						IF huh THEN PRINT "XxxXitMain(159) : decrement cpu.rip on breakpoint exceptions..."
		ReplaceExceptionContext (ucontext, base, oldrbp, retaddr, signo, @cpu)
		END SELECT
		IF whomask THEN cpuUser = cpu ELSE cpuSys = cpu
		sxip = cpu.rip
		rip = cpu.rip
'
' process exceptions that are handled the same whether from user/system
'
		IF huh THEN PRINT ";", exception
		SELECT CASE exception
			CASE $$ExceptionNone, $$ExceptionUnknown
						IF ((signal == $$SIGHUP) || (signal == $$SIGTERM)) THEN
							XgrAddMessage (xitGrid, #CloseWindow, 0, 0, 0, 0, 0, 0)
							RETURN ($$FALSE)
						END IF
'
						PRINT "XxxXitMain(176) can't handle signal,exception,rip : "; HEXX$ (signal,8), HEXX$ (exception,8), HEXX$ (cpu.rip,8)
						XstSleep (3000)
						##SIGNALACTIVE = signalActive
						##WHOMASK = whomask
						IF huh THEN PRINT "d"
						RETURN ($$FALSE)
'			CASE $$ExceptionStackOverflow
'						PRINT "XxxXitMain() can't handle stack overflows properly yet"
'						IFZ poppingFrames THEN
'							poppingFrames = $$TRUE
'							##SIGNALACTIVE = signalActive
'							##WHOMASK = whomask
'							Pop16Frames (signal, exception)			' xxx fix xxx
'						END IF
'						poppingFrames = $$FALSE
'
			CASE $$ExceptionStackOverflow
						Message (" call-stack almost full \n\n use 'F9' to display function call-stack")
						##SIGNALACTIVE = $$FALSE
						XitSoftBreak ()
						##SIGNALACTIVE = signalActive
						##WHOMASK = whomask
						RETURN ($$FALSE)
'
			CASE $$ExceptionBreakKey  'linux terminal Ctrl + C
						XxxXitExit (0)
						RETURN ($$FALSE)  ' should not get here

'						PRINT "XxxXitMain(A):$$ExceptionBreakKey"
						IF environmentEntered THEN
							IF ((NOT ##USERRUNNING) || signalEntry) THEN
								##SIGNALACTIVE = signalActive
								##WHOMASK = whomask
								IF huh THEN PRINT "e"
'								PRINT "XxxXitMain(B):$$ExceptionBreakKey"
								XxxLog2 ("XxxXitMain(211):$$ExceptionBreakKey B", signalEntry)
								RETURN ($$FALSE)
							END IF
						END IF
						IF huh THEN PRINT "f"
'						PRINT "XxxXitMain(C):$$ExceptionBreakKey"
						XitSoftBreak ()
						##SIGNALACTIVE = signalActive
						##WHOMASK = whomask
						RETURN ($$FALSE)
			CASE $$ExceptionTimer
						'
						' Timer exceptions should not come here. They are now processed by XxxXitSigAlrm()
						'
						PRINT "XxxXitMain(225):ExceptionTimer should not come here"
						##SIGNALACTIVE = signalActive
						##WHOMASK = whomask
						IF huh THEN PRINT "g";
						RETURN ($$FALSE)
		END SELECT
'
' adjust .rip if RuntimeError
'
		IF huh THEN PRINT "h";
		IF (exception = $$ExceptionBreakpoint) THEN
			labels = XxxGetLabelGivenAddress (sxip, @labels$[])
			IF (labels > 0) THEN
				FOR i = 0 TO labels-1
					SWAP labels$[i], label$
					SELECT CASE label$
						CASE "XxxRuntimeError", "XxxRuntimeError2"
							sxip = XLONGAT (rsp)
							IF huh THEN PRINT "i";
							rip = sxip
'							PRINT "XxxXitMain() : rip : "; HEX$(rsp,8);; HEX$(sxip,8), i, label$, HEXX$(cpu.rsp), HEXX$(cpu.ursp), ##ERROR
							reg$ = RegisterString$ ()
							PRINT reg$
							UpdateRuntimeError ()
							calledRuntimeError = $$TRUE
							GetFuncAndLineNumberAtThisAddress (sxip)
							IF exeLine THEN
								lineAddr = lineAddr[editFunction, exeLine]
'								PRINT "XxxXitMain(243)", exeLine, HEXX$(lineAddr), HEXX$(sxip)
								IF (lineAddr < sxip) THEN
									cpu.rip = lineAddr
								END IF
							END IF
'
							ReplaceExceptionContext (ucontext, base, oldrbp, retaddr, signo, @cpu)
							##SIGNALACTIVE = $$FALSE
							XitSoftBreak ()
							##SIGNALACTIVE = signalActive
							##WHOMASK = whomask
							RETURN ($$FALSE)
'
							EXIT FOR
					END SELECT
				NEXT i
			END IF
		END IF
	END IF
'
'
' check for fatal exceptions
'		1: exception during exception processing
'		2: user code not running
'		3: quit signal when user running and in allocation code
'
	IF huh THEN PRINT "=";
	fatal = $$FALSE
	reEntry = exception
	IF (exception AND (exception != $$ExceptionBreakKey)) THEN
		IF huh THEN PRINT "reEntry, signalEntry = "; reEntry, signalEntry, fatal
		SELECT CASE TRUE
			CASE (reEntry && signalEntry)						: fatal = $$FatalSignalInEnv
						IF huh THEN PRINT "j";
			CASE (reEntry && (NOT ##USERRUNNING))		: fatal = $$FatalSignalInEnv
						IF huh THEN PRINT "k";
			CASE (exception = $$ExceptionBreakKey)	:
						IF huh THEN PRINT "l";
						IF (rip >= ##BEGINALLOCODE) AND (rip <= ##ENDALLOCODE) THEN
							fatal = $$FatalSigQuitInAllo
							IF huh THEN PRINT "m";
						END IF
		END SELECT
'
		IF fatal THEN
			IF huh THEN PRINT "n";
			XstExceptionNumberToName (exception, @exception$)
'			Message ("reEntry, signalEntry, ##USERRUNNING, whomask, rip, exception$")
'			Message (HEX$(reEntry) + "  " + HEX$(signalEntry) + "  " + HEX$(##USERRUNNING) + "  " + HEX$(whomask,8) + "  " + HEX$(rip,8) + "  " + exception$)
			PRINT reEntry, signalEntry, ##USERRUNNING, whomask, rip, exception$
			PRINT HEX$(reEntry) + "  " + HEX$(signalEntry) + "  " + HEX$(##USERRUNNING) + "  " + HEX$(whomask,8) + "  " + HEX$(rip,8) + "  " + exception$
			IFZ processingCrash THEN
				IF huh THEN PRINT "o";
				XitCrash (exception, sxip, fatal)
			ELSE
				IF huh THEN PRINT "p";
				PRINT "*****  fatal error during crash processing  *****"
				' An exception occurred while we were processing the previous one ->
				' exit immediately, otherwise we enter an endless loop.
				INLINE$ ("press enter to terminate...")
'				XxxXitQuit (1)
				exit(0)
			END IF
		END IF
	END IF
	signalEntry = reEntry
'
' hit patch breakpoints when PDE wants program at source line boundary
'
	IF huh THEN PRINT "q";
	##SOFTBREAK = $$FALSE
	##USERABORT = $$FALSE
	IF signalEntry THEN
		IF huh THEN PRINT "r";
		topLevel = $$FALSE
		breakPatches = BreakPatch ()									' remove patch bkpts
		IF (exception = $$ExceptionBreakpoint) THEN
			IF huh THEN PRINT "s";
			IF breakPatches THEN
				IF huh THEN PRINT "t"
				exception = 0
				signalEntry = $$FALSE
				##SIGNALACTIVE = signalActive
				##WHOMASK = whomask
				RETURN ($$FALSE)
			END IF
		END IF
		BreakInternal ($$BreakRemoveAll, 0, 0, 0)
'
		IF huh THEN PRINT "u";
		IF (fileType = $$Program) THEN
			IF huh THEN PRINT "v";
			RemoveExeLinePtr ()
			IF environmentEntered THEN
				IF huh THEN PRINT "w";
				IFZ haltedByEdit THEN UpdateFrames ()
			ELSE
				IF huh THEN PRINT "x";
				GetFuncAndLineNumberAtThisAddress (rip)
			END IF
			IF exeFunction THEN
				IF huh THEN PRINT "y";
				IF huh THEN PRINT " found breakpoint on line"; exeLine; " of func"; exeFunction
				IF environmentActive THEN
					IFZ haltedByEdit THEN Display (exeFunction, exeLine, 0, -1, -1)
					SetExeLinePtr ()
					AddCommandItem ("breakpoint line " + STRING$ (exeLine+1) + " of func " + STRING$ (exeFunction))
				END IF
			ELSE
				IFZ haltedByEdit THEN
					AddCommandItem (" can't find line at breakpoint address " + HEX$ (rip,8) + " ")
				END IF
			END IF
			IF environmentEntered THEN SetDataDisplays ()
		END IF
'
		IF calledRuntimeError THEN
			calledRuntimeError = $$FALSE
		ELSE
			UpdateRuntimeError ()
		END IF
'
' end code for when this function is entered with a signal
'
	ELSE
'
' start code for when this function is entered without a signal (startup)
'
		IF huh THEN PRINT "0";
		cpu = cpuZero
		topLevel = $$TRUE
'
		IFZ notFirstEntry THEN
			IF huh THEN PRINT "1";
			IF (##ARGC > 1) THEN
				IF huh THEN PRINT "2";
				commandCompile = $$FALSE
				checkBounds = $$FALSE
				library = $$FALSE
				start = 1
'
				IF ##ARGV$[1] THEN
					IF (##ARGV$[1]{0} != '-') THEN
						commandCompile = $$TRUE
						INC start
					END IF
				END IF
'
' get command line switch arguments
'
				FOR i = start TO (##ARGC - 1)
					a$ = LCASE$ (TRIM$ (##ARGV$[i]))
					IF a$ THEN
						IF (a${0} = '-') THEN
							short$ = LEFT$ (a$, 4)
							IF huh THEN PRINT "arg$, short$ = "; "|"; arg$; "|  |"; short$; "|"
							SELECT CASE TRUE
								CASE (short$ = "-ver")
											PRINT
											PRINT "Versions"
											PRINT "  Environment      : "; XitVersion$ ()
											PRINT "  Compiler         : "; XxxXBasicVersion$ ()
											PRINT "  MathLibrary      : "; XmaVersion$ ()
											PRINT "  ComplexLibrary   : "; XcmVersion$ ()
											PRINT "  StandardLibrary  : "; XstVersion$ ()
											PRINT "  GraphicsDesigner : "; XgrVersion$ ()
											PRINT "  GuiDesigner      : "; XuiVersion$ ()
											PRINT
											a$ = INLINE$ ("press enter to terminate...")
											XxxXitQuit (0)
								CASE (short$ = "-huh")
											huh = $$TRUE
								CASE (short$ = "-lib")
											library = $$TRUE
								CASE (short$ = "-bc")
											checkBounds = $$TRUE
								CASE (short$ = "-xit")
											doXit = $$TRUE
											EXIT FOR
								CASE (short$ = "-h"), (short$ = "-hel"), (short$ = "-?")
											PRINT
											PRINT "  xb                      - start program development environment"
											PRINT "  xb filename [switches]  - command line compiler"
											PRINT "     -bc                  - bounds checking on"
											PRINT "     -lib                 - compile as a library"
											PRINT "  xb -version             - display versions of components"
											PRINT "  xb -xit                 - enter primitive debugger"
											PRINT "  xb -h                   - this help message"
											PRINT
											a$ = INLINE$ ("press enter to continue...")
											XxxXitQuit (0)
							END SELECT
						END IF
					END IF
				NEXT i
'
				IF commandCompile THEN
					EnableAbortSignals ()
					Go ()
					XxxXitQuit (0)
				END IF
			END IF
'
			checkBounds = $$TRUE
			IF doXit THEN
				PrintMenu ()
			ELSE
				IF huh THEN PRINT "3";
				IFZ environmentEntered THEN
					IF huh THEN PRINT "4";
'
'
' #####  begin : added v6.0021
'
' "about=false" and "about=0" mean "never display the startup window"
' "about=true" and "about=-1" mean "always display the startup window"
'
					homepath$ = XstGetHomePath$()
					IF homepath$ THEN
						IFZ prefFileNumber THEN
							prefFileNumber = XstOpenPref(homepath$ + "/.xb64rc")
						END IF
					END IF
					IF prefFileNumber THEN
						XstSetPrefSection (prefFileNumber, "")
						IF XstGetPrefSTRING (prefFileNumber, "Xin", "", @xinState$) THEN
							XstSetPrefSTRING (prefFileNumber, "Xin", "false")
						END IF
						XstGetPrefSTRING (prefFileNumber, "about", "1", @times$)
						SELECT CASE LCASE$(times$)
							CASE "false"	: times = 0
							CASE "true"		: times = -1
							CASE ELSE			: times = SLONG (times$)
						END SELECT
						SELECT CASE TRUE
							CASE (times == 0)	: display = $$FALSE	: update = $$FALSE	: add = 0
							CASE (times <  0)	: display = $$TRUE	: update = $$FALSE	: add = 0
							CASE (times <  4)	: display = $$TRUE	: update = $$TRUE		: add = 1
							CASE ELSE					: display = $$FALSE	: update = $$TRUE		: add = 1
						END SELECT
						times = times + add
						IF update THEN
							times$ = STRING$ (times)
							XstSetPrefSTRING (prefFileNumber, "about", times$)
						END IF
						HelpAbout (display)
					END IF
' why the following is needed to stop some main window icons from
' appearing black and without images is totally beyond my feeble mind
'
' #####  end : added v6.0021
'
					failed = CreateWindows ()
					IF hideAbout THEN XuiSendMessage ( aboutGrid, #HideWindow, 0, 0, 0, 0, 0, 0)
					XxxXgrSysMessages ()                       ' process system messages
					IF failed THEN
						PRINT "cannot start environment : window system not running?"
						a$ = INLINE$ ("press enter to terminate...")
						XxxXitQuit (0)
					ELSE
						IF huh THEN PRINT "5";
						environmentActive = $$TRUE
						XitLoadPDEPref ()
'
					END IF
				END IF
			END IF
		END IF
'
		IF environmentActive THEN
			ResetDataDisplays ($$ResetAssembly)
		END IF
	END IF
'
'
' this is where the code signals and no signals get back together
'
'
	notFirstEntry = $$TRUE
	haltedByEdit = $$FALSE
'
	IF huh THEN PRINT "A";
	DO
		IF huh THEN PRINT "B";
		IF environmentActive THEN
			IF huh THEN PRINT "C";
			IF blowback THEN
				IF huh THEN PRINT "D";
				command$	= ""		' Free local allocation
				a$				= ""		'	missing:  SELECT CASE command$ internal string
				arg0$			= ""
				arg1$			= ""
				arg2$			= ""
				arg3$			= ""
				arg4$			= ""
				arg5$			= ""
				arg6$			= ""
'
				IF huh THEN PRINT "E";
				IF exception THEN
					IF huh THEN PRINT "F"
						cpu.rip = &XitBlowback ()
					IF huh THEN PRINT "Set rip to XitBlowback() : ##WHOMASK, whomask = ", HEX$(##WHOMASK,8), HEX$(whomask,8)
					ReplaceExceptionContext (ucontext, base, oldrbp, retaddr, signo, @cpu)
					exception = 0
					##SIGNALACTIVE = $$FALSE
					##WHOMASK = whomask
					RETURN ($$FALSE)
				ELSE
					IF huh THEN PRINT "G";
					XitBlowback ()
				END IF
			END IF
'
			IF huh THEN PRINT "H";
			IF userContinue THEN
				IF huh THEN PRINT "I";
				userContinue = $$FALSE
				IF (fileType != $$Program) THEN
					Message (" can't continue \n\n not in PROGRAM mode ")
					DO DO
				END IF
				IFZ ##USERRUNNING THEN
					Message (" program not running ")
					DO DO
				END IF
				IF programAltered THEN
					Message (" can't continue \n\n not in PROGRAM mode ")
					DO DO
				END IF
				SELECT CASE userStepType
					CASE $$BreakContinueToCursor
								IF huh THEN PRINT "J";
								continueCommand = $$BreakContinueToCursor
								func = editFunction
								IFZ func
									Message (" ToCursor \n\n invalid in PROLOG ")
									DO DO
								END IF
					CASE $$BreakContinueStepLocal
								IF huh THEN PRINT "K";
								continueCommand = $$BreakContinueStepLocal
								func = editFunction
								IFZ func
									Message (" StepLocal \n\n invalid in PROLOG ")
									DO DO
								END IF
					CASE $$BreakContinueStepGlobal
								IF huh THEN PRINT "L";
								continueCommand = $$BreakContinueStepGlobal
					CASE $$BreakContinueStepOut
								continueCommand = $$BreakContinueStepOut
								func = GetStepOutFunc ()
								IFZ func
									Message (" StepOut \n\n invalid to PROLOG ")
									DO DO
								END IF
					CASE ELSE
								IF huh THEN PRINT "M";
								continueCommand = $$BreakContinueRunning
				END SELECT
				userStepType = $$BreakContinueRunning
				IF huh THEN PRINT "N";
				GOSUB UserContinue
				IF huh THEN PRINT "O";
				DO DO
			END IF
'
			IF huh THEN PRINT "P";
			IF userRun THEN
				IF huh THEN PRINT "Q";
				IF (fileType != $$Program) THEN
					Message (" can't run \n\n not in program mode ")
					IF huh THEN PRINT "R";
					DO DO
				END IF
				IF huh THEN PRINT "S";
				userRun = $$FALSE
				IF saveBeforeCompile && textAlteredSinceSave THEN
					IF FileSave ($$TRUE) THEN DO DO
				END IF
				compilationError = CompileProgram ()
				IF compilationError THEN
					ResetDataDisplays ($$ResetAssembly)			' still altered..
					IF huh THEN PRINT "T";
					DO DO
				END IF
				IF saveBeforeRun && textAlteredSinceSave THEN
					IF FileSave ($$TRUE) THEN DO DO
				END IF
				IF huh THEN PRINT "U";
				SELECT CASE userStepType
					func = editFunction
					CASE $$BreakContinueToCursor
								IF huh THEN PRINT "V";
								XuiSendMessage (xitGrid, #GetTextCursor, 0, @line, 0, 0, $$xitTextLower, 0)
								BreakInternal ($$BreakInstallOne, func, line, 0)
					CASE $$BreakContinueStepLocal
								IF huh THEN PRINT "W";
								BreakInternal ($$BreakInstallFunc, func, 0, 0)
					CASE $$BreakContinueStepGlobal
								IF huh THEN PRINT "X";
								BreakInternal ($$BreakInstallAll, 0, 0, 0)
					CASE $$BreakContinueStepOut
								func = GetStepOutFunc ()
								BreakInternal ($$BreakInstallFunc, func, 0, 0)
				END SELECT
				##USERABORT = $$FALSE
				userStepType = $$BreakContinueRunning
				IF huh THEN PRINT "Y";
				UserGo ()
				IF huh THEN PRINT "Z";
				DO DO
			END IF
			IF huh THEN PRINT ":"
			XitExecute ()
			IF huh THEN PRINT "."
			DO DO
		END IF
'
		IF huh THEN PRINT "*";
		EnableAbortSignals ()
		IF environmentEntered THEN SetCurrentStatus ($$StatusXit, 0)
'
		a$ = INLINE$ ("command > ")
		a$ = TRIM$ (a$)
		command$ = ParseLine$ (a$, @arg$[])
		IFZ command$ THEN
			PrintMenu()
			DO DO
		END IF
'
		firstChar = command${0}
'
		IF arg$[] THEN
			upper = UBOUND (arg$[])
			top = MAX (upper, 3)
			DIM arg[top]
			FOR i = 0 TO upper
				arg[i] = XLONG ("0x" + arg$[i])
			NEXT i
		END IF
'
		SELECT CASE command$
			CASE "hu":  huh = NOT huh
			CASE "gh":	ghuh = NOT ghuh : XxxXgrSetHuh (ghuh)
			CASE "xm":  IFZ lockOutEnvironment THEN XitExecute () ELSE PRINT "no can do"
			CASE ""  :  PrintMenu ()                      ' print menu
			CASE "c" :  continueCommand = $$BreakContinueRunning
									GOSUB UserContinue
			CASE "sl":  continueCommand = $$BreakContinueStepLocal
									GOSUB UserContinue
			CASE "sg":  continueCommand = $$BreakContinueStepGlobal
									GOSUB UserContinue
			CASE "q" :  FileQuit () : RETURN							' quit the PDE
			CASE "qq":  XxxXitExit (0) : RETURN						' hard exit code
			CASE "m" :  PRINT MemoryMap$ ()               ' display memory map
			CASE "h" :  Headers (dbase, ##DYNO)           ' display dyno headers
			CASE "th":  DisplayTestHeaders ()							' display dyno headers test
			CASE "x" :  DisplayRegisters (cpuSys)					' display system registers
			CASE "r" :  DisplayRegisters (cpuUser)				' display user registers
			CASE "t" :  PRINT Dump$ (dbase$, "0100")			' dump dyno table, etc...
			CASE "b" :  Break ($$BreakSetOne, arg[1])			'
			CASE "u" :  Break ($$BreakClearOne, arg[1])		'
			CASE "uu":  Break ($$BreakClearAll, 0)				'
			CASE "g" :  G (arg$[1])												' go to machine address
			CASE "go":  library = $$FALSE : Go ()					' go execute compiler
			CASE "a" :  DisplayAssembly (arg$[1],arg$[2])	' display assembly
			CASE "d" :  PRINT Dump$ (arg$[1], arg$[2])		' dump specified memory
			CASE "f" :  Fill (arg$[1], arg$[2], arg$[3])	' fill memory
			CASE "l" :  DisplayLocate (arg$[1])						' locate value
			CASE "s" :  Substitute (arg$[1])							' substitute into memory
			CASE "fr":  XXfree (arg[1])										' free memory
			CASE "ma":  XXmalloc (arg[1])									' malloc memory
			CASE "ca":  XXcalloc (arg[1])									' calloc memory
			CASE "ra":  XXrealloc (arg[1], arg[2])				' realloc memory
			CASE "gd":  gd = NOT gd : XgrSetDebug (gd)
			CASE "gg":  Xgr ()														' GraphicsDesigner
			CASE "fp":  b# = 0 : c# = 0 : a# = b# / c#		' cause SIGFPU
			CASE "sv":  a = XLONGAT(##STACKZ+0x00010000)	' cause SIGSEGV
			CASE "st":  PrintStack ()											'
			CASE ELSE:  PrintMenu ()											' unknown command
		END SELECT
	LOOP
'
	IF huh THEN PRINT "#"
	exception = 0
	##SIGNALACTIVE = signalActive
	##WHOMASK = whomask
	RETURN ($$FALSE)
'
'
' **************************
' *****  UserContinue  *****
' **************************
'
SUB UserContinue
	IF huh THEN PRINT "UserContinue.A : "; topLevel;; HEX$(cpu.rip,8); exeFunction; lineLast[exeFunction]; continueCommand
	IF topLevel THEN EXIT SUB
	entryAddress = cpu.rip
	addr = AddressOk (entryAddress)
'
	IF (addr != ##UCODEZ) THEN
		a$ = " can't resume execution\n\n address not in user code space \n\n" + HEXX$(entryAddress,8) + " : " + HEX$(addr, 8) + " : " + HEX$ (##UCODE0,8) + " : " + HEX$ (##UCODEZ,8) + " "
		Message (@a$)
		EXIT SUB
	END IF
'
	newSXIP = cpu.rip
	upper = UBOUND (lineAddr[])
	IF ((exeFunction <= 0) OR (exeFunction > upper)) THEN
		Message (" RunContinue \n\n internal error \n\n invalid exeFunction \n\n" + STRING$(exeFunction) + " ")
		EXIT SUB
	END IF
'
	lineLast = lineLast[exeFunction]
	IF (newSXIP < lineAddr[exeFunction,0]) THEN
		Message (" XxxXitMain(778) \n\n UserContinue \n\n invalid return address \n\n " + HEX$ (sxip,8) + " ")
		EXIT SUB
	END IF
'
	IF lineLast THEN
		FOR line = 1 TO lineLast
			IF (newSXIP < lineAddr[exeFunction,line]) THEN
				DEC line
				EXIT FOR
			END IF
		NEXT line
		IF (line >= lineLast) THEN
			IF (newSXIP >= funcAfterAddr[exeFunction]) THEN
				Message (" XxxXitMain(791) \n\n UserContinue \n\n invalid return address \n\n " + HEX$ (sxip,8) + " ")
				EXIT SUB
			END IF
			line = lineLast
		END IF
	END IF
'
	sxip = lineAddr[exeFunction, line]
	cpu.rip = sxip
	rip = sxip
'
' If the last opcode in a line is a $$Breakpoint
' indicating a "STOP" instruction,
' continue at the next line.
'
	IF (line < lineLast) THEN
		nextSXIP = lineAddr[exeFunction, line+1]
		IF (nextSXIP == newSXIP+1) THEN
			IF (UBYTEAT(newSXIP) == $$Breakpoint) THEN  ' looks like a "STOP"
				INC line
				sxip = nextSXIP
				cpu.rip = sxip
				rip = sxip
			END IF
		END IF
	END IF
'	PRINT "XitMain(799)", HEXX$(sxip,8), HEXX$(newSXIP), HEXX$(nextSXIP)
'
	redisplay = $$TRUE
	reportBogusRename = $$TRUE
	RestoreTextToProg (redisplay, reportBogusRename)
'
	SELECT CASE continueCommand
		CASE $$BreakContinueToCursor
					BreakContinuePrep (continueCommand, func, 0)
		CASE $$BreakContinueStepLocal
					BreakContinuePrep (continueCommand, func, 0)
		CASE $$BreakContinueStepGlobal
					BreakContinuePrep (continueCommand, 0, 0)
		CASE $$BreakContinueRunning
					BreakContinuePrep (continueCommand, 0, 0)
		CASE $$BreakContinueStepOut
					BreakContinuePrep (continueCommand, func, 0)
	END SELECT
'
	ReplaceExceptionContext (ucontext, base, oldrbp, retaddr, signo, @cpu)
	IF huh THEN PRINT "UserContinue.B : "; HEX$(rbp,8);; HEX$(base,8);; HEX$(oldrbp,8);; HEX$(retaddr,8);; signo;; HEX$(cpu.rip,8);; whomask;
'
	signalEntry = $$FALSE
	ClearRuntimeError ()
'
	IF environmentActive THEN
		SetCurrentStatus ($$StatusRunning, 0)
		ResetDataDisplays ($$InitiatingRun)
	END IF
'
	exception = 0
	##TRAPVECTOR = 510							' default trap is normal breakpoint
	##SIGNALACTIVE = signalActive
	##WHOMASK = whomask
	RETURN ($$FALSE)
END SUB
END FUNCTION
'
'
'  ###########################
'  #####  XxxXitSigAlrm  #####
'  ###########################
'
CFUNCTION  XxxXitSigAlrm (signal)
'
	IF ##TIMERLOCKOUT THEN RETURN
'
	xbdv = ##XBDV
	##XBDV = 0                                   'turn off debugging during interrupt handling
	lockout = ##LOCKOUT
	##LOCKOUT = $$FALSE                          'no lockout checking during interrupt handling
	##TIMERLOCKOUT = $$TRUE
	XxxXstTimer ($$TimerExpire, 0, 0, 0, 0, 0)
	##TIMERLOCKOUT = $$FALSE
	##LOCKOUT = lockout
	##XBDV = xbdv
'
END FUNCTION
'
'
' ############################
' #####  XitVersion$ ()  #####
' ############################
'
' version$ = XitVersion$ ()
'
' XitVersion$() returns the current XBasic program development environment version$.
'
FUNCTION  XitVersion$ ()
	version$ = VERSION$ (0)
	RETURN (version$)
END FUNCTION
'
'
' ########################
' #####  Welcome ()  #####
' ########################
'
FUNCTION  Welcome ()
'
	RETURN ($$FALSE)
END FUNCTION
'
'
' ############################
' #####  WelcomeCode ()  #####
' ############################
'
FUNCTION  WelcomeCode (grid, message, v0, v1, v2, v3, kid, r1)
'
	IF (message == #Callback) THEN
		message = r1
	END IF
'
	XgrMessageNumberToName (message, @message$)
	IF (message == #Redrawn) THEN
'		XstLog ("WelcomeCode() : d")
	ELSE
		XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END IF
END FUNCTION
'
'
'
' ########################################
' #####  CaptureExceptionContext ()  #####
' ########################################
'
FUNCTION  CaptureExceptionContext (ucontext, base, oldrbp, retaddr, signo, CPUCONTEXT cpu)
	SHARED  huh
'
	cpu.ct0    = XLONGAT(ucontext, [0])
	cpu.ct1    = XLONGAT(ucontext, [1])
	cpu.ct2    = XLONGAT(ucontext, [2])
	cpu.ct3    = XLONGAT(ucontext, [3])
	cpu.ct4    = XLONGAT(ucontext, [4])
	cpu.r8     = XLONGAT(ucontext, [5])
	cpu.r9     = XLONGAT(ucontext, [6])
	cpu.r10    = XLONGAT(ucontext, [7])
	cpu.r11    = XLONGAT(ucontext, [8])
	cpu.r12    = XLONGAT(ucontext, [9])
	cpu.r13    = XLONGAT(ucontext, [10])
	cpu.r14    = XLONGAT(ucontext, [11])
	cpu.r15    = XLONGAT(ucontext, [12])
	cpu.rdi    = XLONGAT(ucontext, [13])
	cpu.rsi    = XLONGAT(ucontext, [14])
	cpu.rbp    = XLONGAT(ucontext, [15])
	cpu.rbx    = XLONGAT(ucontext, [16])
	cpu.rdx    = XLONGAT(ucontext, [17])
	cpu.rax    = XLONGAT(ucontext, [18])
	cpu.rcx    = XLONGAT(ucontext, [19])
	cpu.rsp    = XLONGAT(ucontext, [20])
	cpu.rip    = XLONGAT(ucontext, [21])
	cpu.rflags = XLONGAT(ucontext, [22])
	cpu.cs     = XLONGAT(ucontext, [23])
	cpu.ss     = XLONGAT(ucontext, 190)

'	PRINT "CaptureExceptionContext"
'	PRINT "rax", HEX$(cpu.rax)
'	PRINT "rbx", HEX$(cpu.rbx)
'	PRINT "rcx", HEX$(cpu.rcx)
'	PRINT "rdx", HEX$(cpu.rdx)
'	PRINT "rsi", HEX$(cpu.rsi)
'	PRINT "rdi", HEX$(cpu.rdi)
'	PRINT "rbp", HEX$(cpu.rbp)
'	PRINT "rsp", HEX$(cpu.rsp)
'	PRINT "r8 ", HEX$(cpu.r8)
'	PRINT "r9 ", HEX$(cpu.r9)
'	PRINT "r10", HEX$(cpu.r10)
'	PRINT "r11", HEX$(cpu.r11)
'	PRINT "r12", HEX$(cpu.r12)
'	PRINT "r13", HEX$(cpu.r13)
'	PRINT "r14", HEX$(cpu.r14)
'	PRINT "r15", HEX$(cpu.r15)
'	PRINT "rip", HEX$(cpu.rip)
'	PRINT "rflags", HEX$(cpu.rflags)
'	PRINT "cs ", HEX$(cpu.cs)
'	PRINT "ss ", HEX$(cpu.ss)
'	PRINT "error", HEX$(cpu.error)
'	PRINT


'FUNCTION  CaptureExceptionContext (rbp, base, oldrbp, retaddr, signo, CPUCONTEXT cpu)
'	base = XLONGAT (rbp)
'	oldrbp = XLONGAT(rbp, [0])
'	retaddr = XLONGAT(rbp, [1])
'	signo = XLONGAT(rbp, [2])
'
'	cpu.gs = XLONGAT (rbp, [3])
'	cpu.fs = XLONGAT (rbp, [4])
'	cpu.es = XLONGAT (rbp, [5])
'	cpu.ds = XLONGAT (rbp, [6])
'	cpu.rdi = XLONGAT (rbp, [7])
'	cpu.rsi = XLONGAT (rbp, [8])
'	cpu.rbp = XLONGAT (rbp, [9])
'	cpu.rsp = XLONGAT (rbp, [10])
'	cpu.rbx = XLONGAT (rbp, [11])
'	cpu.rdx = XLONGAT (rbp, [12])
'	cpu.rcx = XLONGAT (rbp, [13])
'	cpu.rax = XLONGAT (rbp, [14])
'	cpu.trap = XLONGAT (rbp, [15])
'	cpu.err = XLONGAT (rbp, [16])
'	cpu.rip = XLONGAT (rbp, [17])
'	cpu.cs = XLONGAT (rbp, [18])
'	cpu.efl = XLONGAT (rbp, [19])
'	cpu.ursp = XLONGAT (rbp, [20])
'	cpu.ss = XLONGAT (rbp, [21])
'	cpu.addrFPU = XLONGAT (rbp, [22])
'	cpu.sigmask = XLONGAT (rbp, [23])
'	IF (signo != $$SIGALRM) THEN
'		IF huh THEN
'			PRINT "CaptureExceptionContext() : "; HEX$(rbp,8);; HEX$(base,8);; HEX$(oldrbp,8);; HEX$(retaddr,8);; signo;; HEX$(cpu.rip,8);; ##WHOMASK
'		END IF
'	END IF
END FUNCTION
'
'
' ########################################
' #####  ReplaceExceptionContext ()  #####
' ########################################
'
FUNCTION  ReplaceExceptionContext (ucontext, base, oldrbp, retaddr, signo, CPUCONTEXT cpu)
	SHARED  huh
'
	XLONGAT(ucontext, [0])  = cpu.ct0
	XLONGAT(ucontext, [1])  = cpu.ct1
	XLONGAT(ucontext, [2])  = cpu.ct2
	XLONGAT(ucontext, [3])  = cpu.ct3
	XLONGAT(ucontext, [4])  = cpu.ct4
	XLONGAT(ucontext, [5])  = cpu.r8
	XLONGAT(ucontext, [6])  = cpu.r9
	XLONGAT(ucontext, [7])  = cpu.r10
	XLONGAT(ucontext, [8])  = cpu.r11
	XLONGAT(ucontext, [9])  = cpu.r12
	XLONGAT(ucontext, [10]) = cpu.r13
	XLONGAT(ucontext, [11]) = cpu.r14
	XLONGAT(ucontext, [12]) = cpu.r15
	XLONGAT(ucontext, [13]) = cpu.rdi
	XLONGAT(ucontext, [14]) = cpu.rsi
	XLONGAT(ucontext, [15]) = cpu.rbp
	XLONGAT(ucontext, [16]) = cpu.rbx
	XLONGAT(ucontext, [17]) = cpu.rdx
	XLONGAT(ucontext, [18]) = cpu.rax
	XLONGAT(ucontext, [19]) = cpu.rcx
	XLONGAT(ucontext, [20]) = cpu.rsp
	XLONGAT(ucontext, [21]) = cpu.rip
	XLONGAT(ucontext, [22]) = cpu.rflags
	XLONGAT(ucontext, [23]) = cpu.cs
	XLONGAT(ucontext, 190)  = cpu.ss
'
'	XLONGAT (rbp, [ 0]) = oldrbp
'	XLONGAT (rbp, [ 1]) = retaddr
'	XLONGAT (rbp, [ 2]) = signo
'
'	XLONGAT (rbp, [ 3]) = cpu.gs
'	XLONGAT (rbp, [ 4]) = cpu.fs
'	XLONGAT (rbp, [ 5]) = cpu.es
'	XLONGAT (rbp, [ 6]) = cpu.ds
'	XLONGAT (rbp, [ 7]) = cpu.rdi
'	XLONGAT (rbp, [ 8]) = cpu.rsi
'	XLONGAT (rbp, [ 9]) = cpu.rbp
'	XLONGAT (rbp, [10]) = cpu.rsp
'	XLONGAT (rbp, [11]) = cpu.rbx
'	XLONGAT (rbp, [12]) = cpu.rdx
'	XLONGAT (rbp, [13]) = cpu.rcx
'	XLONGAT (rbp, [14]) = cpu.rax
'	XLONGAT (rbp, [15]) = cpu.trap
'	XLONGAT (rbp, [16]) = cpu.err
'	XLONGAT (rbp, [17]) = cpu.rip
'	XLONGAT (rbp, [18]) = cpu.cs
'	XLONGAT (rbp, [19]) = cpu.efl
'	XLONGAT (rbp, [20]) = cpu.ursp
'	XLONGAT (rbp, [21]) = cpu.ss
'	XLONGAT (rbp, [22]) = cpu.addrFPU
'	XLONGAT (rbp, [23]) = cpu.sigmask
'	IF (signo != $$SIGALRM) THEN
'		IF huh THEN
'			PRINT "ReplaceExceptionContext() : "; HEX$(rbp,8);; HEX$(base,8);; HEX$(oldrbp,8);; HEX$(retaddr,8);; signo;; HEX$(cpu.rip,8);; ##WHOMASK
'		END IF
'	END IF
END FUNCTION
'
'
' ######################################
' #####  PrintExceptionContext ()  #####
' ######################################
'
FUNCTION  PrintExceptionContext (rbp, base, oldrbp, retaddr, signal, exception, CPUCONTEXT cpu)
	SHARED  huh
'
'	IFZ huh THEN RETURN ($$FALSE)
	IF (signal = $$SIGALRM) THEN RETURN ($$FALSE)
'
'	PRINT " cpu rbp      base    oldrbp   retaddr    signo  exception   sigmask"
'	PRINT HEX$(rbp,8);;; HEX$(base,8);;; HEX$(oldrbp,8);;; HEX$(retaddr,8);;; HEX$(signal,8);;; HEX$(exception,8);;; HEX$(cpu.sigmask,8)
'	PRINT  "   cs: "; HEX$(cpu.cs,8); "   ds: "; HEX$(cpu.ds,8); "   es: "; HEX$(cpu.es,8)
'	PRINT  "   fs: "; HEX$(cpu.fs,8); "   gs: "; HEX$(cpu.gs,8); "   ss: "; HEX$(cpu.ss,8)
'	PRINT  " trap: "; HEX$(cpu.trap,8); "  err: "; HEX$(cpu.err,8); "  efl: "; HEX$(cpu.efl,8)
'	PRINT  "  rip: "; HEX$(cpu.rip,8); " &fpu: "; HEX$(cpu.addrFPU,8); " mask: "; HEX$(cpu.sigmask,8)
'	PRINT  "  rbp: "; HEX$(cpu.rbp,8); " ursp: "; HEX$(cpu.ursp,8); "  rsp: "; HEX$(cpu.rsp,8)
'	PRINT  "  rax: "; HEX$(cpu.rax,8); "  rbx: "; HEX$(cpu.rbx,8); "  rsi: "; HEX$(cpu.rsi,8)
'	PRINT  "  rdx: "; HEX$(cpu.rdx,8); "  rcx: "; HEX$(cpu.rcx,8); "  rdi: "; HEX$(cpu.rdi,8)
END FUNCTION
'
'
' ########################
' #####  InitGui ()  #####
' ########################
'
' InitGui() initializes cursor, icon, message, and display variables.
' Programs can reference these variables, but must never change them.
'
FUNCTION  InitGui ()
	SHARED  waitCursor
'
' ***************************************
' *****  Register Standard Cursors  *****
' ***************************************
'
	XgrRegisterCursor (@"arrow",			@#defaultCursor)
	XgrRegisterCursor (@"arrow",			@#cursorDefault)
	XgrRegisterCursor (@"arrow",			@#cursorArrow)
	XgrRegisterCursor (@"arrow",			@#cursorArrowNW)
	XgrRegisterCursor (@"n",					@#cursorArrowN)
	XgrRegisterCursor (@"ns",					@#cursorArrowsNS)
	XgrRegisterCursor (@"we",					@#cursorArrowsWE)
	XgrRegisterCursor (@"nwse",				@#cursorArrowsNWSE)
	XgrRegisterCursor (@"nesw",				@#cursorArrowsNESW)
	XgrRegisterCursor (@"all",				@#cursorArrowsAll)
	XgrRegisterCursor (@"crosshair",	@#cursorCrosshair)
	XgrRegisterCursor (@"plus",				@#cursorPlus)
	XgrRegisterCursor (@"wait",				@#cursorHourglass)
	XgrRegisterCursor (@"insert",			@#cursorInsert)
	XgrRegisterCursor (@"no",					@#cursorNo)
'	XgrRegisterCursor (@"hand",				@#cursorHand)						' zzzzz
'	XgrRegisterCursor (@"help",				@#cursorHelp)						' zzzzz
'
	#defaultCursor = #cursorDefault
	waitCursor = #cursorHourglass
'
'
' ********************************************
' *****  Register Standard Window Icons  *****
' ********************************************
'
'	XgrRegisterIcon (@"hand",					@#iconHand)
'	XgrRegisterIcon (@"asterisk",			@#iconAsterisk)
'	XgrRegisterIcon (@"question",			@#iconQuestion)
'	XgrRegisterIcon (@"exclamation",	@#iconExclamation)
'	XgrRegisterIcon (@"application",	@#iconApplication)
'
'	XgrRegisterIcon (@"hand",					@#iconStop)						' alias
'	XgrRegisterIcon (@"asterisk",			@#iconInformation)		' alias
'	XgrRegisterIcon (@"application",  @#iconBlank)					' alias
'
'	XgrRegisterIcon (@"bvqb",					@#iconBvqb)						' custom
	XgrRegisterIcon (@"window",				@#iconWindow)					' custom
'
'
' ******************************
' *****  Register Messages *****  Create message numbers for message names
' ******************************
'
	XgrRegisterMessage (@"Blowback",										@#Blowback)
	XgrRegisterMessage (@"Callback",										@#Callback)
	XgrRegisterMessage (@"Cancel",											@#Cancel)
	XgrRegisterMessage (@"Change",											@#Change)
	XgrRegisterMessage (@"CloseWindow",									@#CloseWindow)
	XgrRegisterMessage (@"ContextChange",								@#ContextChange)
	XgrRegisterMessage (@"Create",											@#Create)
	XgrRegisterMessage (@"CreateValueArray",						@#CreateValueArray)
	XgrRegisterMessage (@"CreateWindow",								@#CreateWindow)
	XgrRegisterMessage (@"CursorH",											@#CursorH)
	XgrRegisterMessage (@"CursorV",											@#CursorV)
	XgrRegisterMessage (@"Deselected",									@#Deselected)
	XgrRegisterMessage (@"Destroy",											@#Destroy)
	XgrRegisterMessage (@"Destroyed",										@#Destroyed)
	XgrRegisterMessage (@"DestroyWindow",								@#DestroyWindow)
	XgrRegisterMessage (@"Disable",											@#Disable)
	XgrRegisterMessage (@"Disabled",										@#Disabled)
	XgrRegisterMessage (@"Displayed",										@#Displayed)
	XgrRegisterMessage (@"DisplayWindow",								@#DisplayWindow)
	XgrRegisterMessage (@"Enable",											@#Enable)
	XgrRegisterMessage (@"Enabled",											@#Enabled)
	XgrRegisterMessage (@"Enter",												@#Enter)
	XgrRegisterMessage (@"ExitMessageLoop",							@#ExitMessageLoop)
	XgrRegisterMessage (@"Find",												@#Find)
	XgrRegisterMessage (@"FindForward",									@#FindForward)
	XgrRegisterMessage (@"FindReverse",									@#FindReverse)
	XgrRegisterMessage (@"Forward",											@#Forward)
	XgrRegisterMessage (@"GetAlign",										@#GetAlign)
	XgrRegisterMessage (@"GetBorder",										@#GetBorder)
	XgrRegisterMessage (@"GetBorderOffset",							@#GetBorderOffset)
	XgrRegisterMessage (@"GetCallback",									@#GetCallback)
	XgrRegisterMessage (@"GetCallbackArgs",							@#GetCallbackArgs)
	XgrRegisterMessage (@"GetCan",											@#GetCan)
	XgrRegisterMessage (@"GetCharacterMapArray",				@#GetCharacterMapArray)
	XgrRegisterMessage (@"GetCharacterMapEntry",				@#GetCharacterMapEntry)
	XgrRegisterMessage (@"GetClipGrid",									@#GetClipGrid)
	XgrRegisterMessage (@"GetColor",										@#GetColor)
	XgrRegisterMessage (@"GetColorExtra",								@#GetColorExtra)
	XgrRegisterMessage (@"GetCursor",										@#GetCursor)
	XgrRegisterMessage (@"GetCursorXY",									@#GetCursorXY)
	XgrRegisterMessage (@"GetDisplay",									@#GetDisplay)
	XgrRegisterMessage (@"GetEnclosedGrids",						@#GetEnclosedGrids)
	XgrRegisterMessage (@"GetEnclosingGrid",						@#GetEnclosingGrid)
	XgrRegisterMessage (@"GetFocusColor",								@#GetFocusColor)
	XgrRegisterMessage (@"GetFocusColorExtra",					@#GetFocusColorExtra)
	XgrRegisterMessage (@"GetFont",											@#GetFont)
	XgrRegisterMessage (@"GetFontMetrics",							@#GetFontMetrics)
	XgrRegisterMessage (@"GetFontNumber",								@#GetFontNumber)
	XgrRegisterMessage (@"GetGridFunction",							@#GetGridFunction)
	XgrRegisterMessage (@"GetGridFunctionName",					@#GetGridFunctionName)
	XgrRegisterMessage (@"GetGridName",									@#GetGridName)
	XgrRegisterMessage (@"GetGridNumber",								@#GetGridNumber)
	XgrRegisterMessage (@"GetGridProperties",						@#GetGridProperties)
	XgrRegisterMessage (@"GetGridType",									@#GetGridType)
	XgrRegisterMessage (@"GetGridTypeName",							@#GetGridTypeName)
	XgrRegisterMessage (@"GetGroup",										@#GetGroup)
	XgrRegisterMessage (@"GetHelp",											@#GetHelp)
	XgrRegisterMessage (@"GetHelpFile",									@#GetHelpFile)
	XgrRegisterMessage (@"GetHelpString",								@#GetHelpString)
	XgrRegisterMessage (@"GetHelpStrings",							@#GetHelpStrings)
	XgrRegisterMessage (@"GetHintString",								@#GetHintString)
	XgrRegisterMessage (@"GetImage",										@#GetImage)
	XgrRegisterMessage (@"GetImageCoords",							@#GetImageCoords)
	XgrRegisterMessage (@"GetIndent",										@#GetIndent)
	XgrRegisterMessage (@"GetInfo",											@#GetInfo)
	XgrRegisterMessage (@"GetJustify",									@#GetJustify)
	XgrRegisterMessage (@"GetKeyboardFocus",						@#GetKeyboardFocus)
	XgrRegisterMessage (@"GetKeyboardFocusGrid",				@#GetKeyboardFocusGrid)
	XgrRegisterMessage (@"GetKidArray",									@#GetKidArray)
	XgrRegisterMessage (@"GetKidNumber",								@#GetKidNumber)
	XgrRegisterMessage (@"GetKids",											@#GetKids)
	XgrRegisterMessage (@"GetKind",											@#GetKind)
	XgrRegisterMessage (@"GetMaxMinSize",								@#GetMaxMinSize)
	XgrRegisterMessage (@"GetMenuEntryArray",						@#GetMenuEntryArray)
	XgrRegisterMessage (@"GetMessageFunc",							@#GetMessageFunc)
	XgrRegisterMessage (@"GetMessageFuncArray",					@#GetMessageFuncArray)
	XgrRegisterMessage (@"GetMessageSub",								@#GetMessageSub)
	XgrRegisterMessage (@"GetMessageSubArray",					@#GetMessageSubArray)
	XgrRegisterMessage (@"GetModalInfo",								@#GetModalInfo)
	XgrRegisterMessage (@"GetModalWindow",							@#GetModalWindow)
	XgrRegisterMessage (@"GetParent",										@#GetParent)
	XgrRegisterMessage (@"GetPosition",									@#GetPosition)
	XgrRegisterMessage (@"GetProtoInfo",								@#GetProtoInfo)
	XgrRegisterMessage (@"GetRedrawFlags",							@#GetRedrawFlags)
	XgrRegisterMessage (@"GetSize",											@#GetSize)
	XgrRegisterMessage (@"GetSmallestSize",							@#GetSmallestSize)
	XgrRegisterMessage (@"GetState",										@#GetState)
	XgrRegisterMessage (@"GetStyle",										@#GetStyle)
	XgrRegisterMessage (@"GetTabArray",									@#GetTabArray)
	XgrRegisterMessage (@"GetTabWidth",									@#GetTabWidth)
	XgrRegisterMessage (@"GetTextArray",								@#GetTextArray)
	XgrRegisterMessage (@"GetTextArrayBounds",					@#GetTextArrayBounds)
	XgrRegisterMessage (@"GetTextArrayLine",						@#GetTextArrayLine)
	XgrRegisterMessage (@"GetTextArrayLines",						@#GetTextArrayLines)
	XgrRegisterMessage (@"GetTextCursor",								@#GetTextCursor)
	XgrRegisterMessage (@"GetTextFilename",							@#GetTextFilename)
	XgrRegisterMessage (@"GetTextFlag",									@#GetTextFlag)
	XgrRegisterMessage (@"GetTextPosition",							@#GetTextPosition)
	XgrRegisterMessage (@"GetTextSelection",						@#GetTextSelection)
	XgrRegisterMessage (@"GetTextSpacing",							@#GetTextSpacing)
	XgrRegisterMessage (@"GetTextString",								@#GetTextString)
	XgrRegisterMessage (@"GetTextStrings",							@#GetTextStrings)
	XgrRegisterMessage (@"GetTexture",									@#GetTexture)
	XgrRegisterMessage (@"GetTimer",										@#GetTimer)
	XgrRegisterMessage (@"GetValue",										@#GetValue)
	XgrRegisterMessage (@"GetValueArray",								@#GetValueArray)
	XgrRegisterMessage (@"GetValues",										@#GetValues)
	XgrRegisterMessage (@"GetWindow",										@#GetWindow)
	XgrRegisterMessage (@"GetWindowFunction",						@#GetWindowFunction)
	XgrRegisterMessage (@"GetWindowGrid",								@#GetWindowGrid)
	XgrRegisterMessage (@"GetWindowIcon",								@#GetWindowIcon)
	XgrRegisterMessage (@"GetWindowSize",								@#GetWindowSize)
	XgrRegisterMessage (@"GetWindowTitle",							@#GetWindowTitle)
	XgrRegisterMessage (@"GotKeyboardFocus",						@#GotKeyboardFocus)
	XgrRegisterMessage (@"GrabArray",										@#GrabArray)
	XgrRegisterMessage (@"GrabTextArray",								@#GrabTextArray)
	XgrRegisterMessage (@"GrabTextString",							@#GrabTextString)
	XgrRegisterMessage (@"GrabValueArray",							@#GrabValueArray)
	XgrRegisterMessage (@"HalfPageDown",								@#HalfPageDown)
	XgrRegisterMessage (@"HalfPageUp",									@#HalfPageUp)
	XgrRegisterMessage (@"Help",												@#Help)
	XgrRegisterMessage (@"Hidden",											@#Hidden)
	XgrRegisterMessage (@"HideTextCursor",							@#HideTextCursor)
	XgrRegisterMessage (@"HideWindow",									@#HideWindow)
	XgrRegisterMessage (@"Initialize",									@#Initialize)
	XgrRegisterMessage (@"Initialized",									@#Initialized)
	XgrRegisterMessage (@"Inline",											@#Inline)
	XgrRegisterMessage (@"InquireText",									@#InquireText)
	XgrRegisterMessage (@"KeyboardFocusBackward",				@#KeyboardFocusBackward)
	XgrRegisterMessage (@"KeyboardFocusForward",				@#KeyboardFocusForward)
	XgrRegisterMessage (@"KeyDown",											@#KeyDown)
	XgrRegisterMessage (@"KeyUp",												@#KeyUp)
	XgrRegisterMessage (@"LostKeyboardFocus",						@#LostKeyboardFocus)
	XgrRegisterMessage (@"LostTextSelection",						@#LostTextSelection)
	XgrRegisterMessage (@"Maximized",										@#Maximized)
	XgrRegisterMessage (@"MaximizeWindow",							@#MaximizeWindow)
	XgrRegisterMessage (@"Maximum",											@#Maximum)
	XgrRegisterMessage (@"Minimized",										@#Minimized)
	XgrRegisterMessage (@"MinimizeWindow",							@#MinimizeWindow)
	XgrRegisterMessage (@"Minimum",											@#Minimum)
	XgrRegisterMessage (@"MonitorContext",							@#MonitorContext)
	XgrRegisterMessage (@"MonitorHelp",									@#MonitorHelp)
	XgrRegisterMessage (@"MonitorKeyboard",							@#MonitorKeyboard)
	XgrRegisterMessage (@"MonitorMouse",								@#MonitorMouse)
	XgrRegisterMessage (@"MouseDown",										@#MouseDown)
	XgrRegisterMessage (@"MouseDrag",										@#MouseDrag)
	XgrRegisterMessage (@"MouseEnter",									@#MouseEnter)
	XgrRegisterMessage (@"MouseExit",										@#MouseExit)
	XgrRegisterMessage (@"MouseMove",										@#MouseMove)
	XgrRegisterMessage (@"MouseUp",											@#MouseUp)
	XgrRegisterMessage (@"MouseWheel",									@#MouseWheel)
	XgrRegisterMessage (@"MuchLess",										@#MuchLess)
	XgrRegisterMessage (@"MuchMore",										@#MuchMore)
	XgrRegisterMessage (@"Notify",											@#Notify)
	XgrRegisterMessage (@"OneLess",											@#OneLess)
	XgrRegisterMessage (@"OneMore",											@#OneMore)
	XgrRegisterMessage (@"PageDown",										@#PageDown)
	XgrRegisterMessage (@"PageUp",											@#PageUp)
	XgrRegisterMessage (@"PokeArray",										@#PokeArray)
	XgrRegisterMessage (@"PokeTextArray",								@#PokeTextArray)
	XgrRegisterMessage (@"PokeTextString",							@#PokeTextString)
	XgrRegisterMessage (@"PokeValueArray",							@#PokeValueArray)
	XgrRegisterMessage (@"Print",												@#Print)
	XgrRegisterMessage (@"Redraw",											@#Redraw)
	XgrRegisterMessage (@"RedrawGrid",									@#RedrawGrid)
	XgrRegisterMessage (@"RedrawLines",									@#RedrawLines)
	XgrRegisterMessage (@"Redrawn",											@#Redrawn)
	XgrRegisterMessage (@"RedrawText",									@#RedrawText)
	XgrRegisterMessage (@"RedrawWindow",								@#RedrawWindow)
	XgrRegisterMessage (@"Replace",											@#Replace)
	XgrRegisterMessage (@"ReplaceForward",							@#ReplaceForward)
	XgrRegisterMessage (@"ReplaceReverse",							@#ReplaceReverse)
	XgrRegisterMessage (@"Reset",												@#Reset)
	XgrRegisterMessage (@"Resize",											@#Resize)
	XgrRegisterMessage (@"Resized",											@#Resized)
	XgrRegisterMessage (@"ResizeNot",										@#ResizeNot)
	XgrRegisterMessage (@"ResizeWindow",								@#ResizeWindow)
	XgrRegisterMessage (@"ResizeWindowToGrid",					@#ResizeWindowToGrid)
	XgrRegisterMessage (@"RestoreWindow",								@#RestoreWindow)
	XgrRegisterMessage (@"Reverse",											@#Reverse)
	XgrRegisterMessage (@"ScrollH",											@#ScrollH)
	XgrRegisterMessage (@"ScrollV",											@#ScrollV)
	XgrRegisterMessage (@"Select",											@#Select)
	XgrRegisterMessage (@"Selected",										@#Selected)
	XgrRegisterMessage (@"Selection",										@#Selection)
	XgrRegisterMessage (@"SelectWindow",								@#SelectWindow)
	XgrRegisterMessage (@"SetAlign",										@#SetAlign)
	XgrRegisterMessage (@"SetBorder",										@#SetBorder)
	XgrRegisterMessage (@"SetBorderOffset",							@#SetBorderOffset)
	XgrRegisterMessage (@"SetCallback",									@#SetCallback)
	XgrRegisterMessage (@"SetCan",											@#SetCan)
	XgrRegisterMessage (@"SetCharacterMapArray",				@#SetCharacterMapArray)
	XgrRegisterMessage (@"SetCharacterMapEntry",				@#SetCharacterMapEntry)
	XgrRegisterMessage (@"SetClipGrid",									@#SetClipGrid)
	XgrRegisterMessage (@"SetColor",										@#SetColor)
	XgrRegisterMessage (@"SetColorAll",									@#SetColorAll)
	XgrRegisterMessage (@"SetColorExtra",								@#SetColorExtra)
	XgrRegisterMessage (@"SetColorExtraAll",						@#SetColorExtraAll)
	XgrRegisterMessage (@"SetCursor",										@#SetCursor)
	XgrRegisterMessage (@"SetCursorXY",									@#SetCursorXY)
	XgrRegisterMessage (@"SetDisplay",									@#SetDisplay)
	XgrRegisterMessage (@"SetFocusColor",								@#SetFocusColor)
	XgrRegisterMessage (@"SetFocusColorExtra",					@#SetFocusColorExtra)
	XgrRegisterMessage (@"SetFont",											@#SetFont)
	XgrRegisterMessage (@"SetFontNumber",								@#SetFontNumber)
	XgrRegisterMessage (@"SetGridFunction",							@#SetGridFunction)
	XgrRegisterMessage (@"SetGridFunctionName",					@#SetGridFunctionName)
	XgrRegisterMessage (@"SetGridName",									@#SetGridName)
	XgrRegisterMessage (@"SetGridProperties",						@#SetGridProperties)
	XgrRegisterMessage (@"SetGridType",									@#SetGridType)
	XgrRegisterMessage (@"SetGridTypeName",							@#SetGridTypeName)
	XgrRegisterMessage (@"SetGroup",										@#SetGroup)
	XgrRegisterMessage (@"SetHelp",											@#SetHelp)
	XgrRegisterMessage (@"SetHelpFile",									@#SetHelpFile)
	XgrRegisterMessage (@"SetHelpString",								@#SetHelpString)
	XgrRegisterMessage (@"SetHelpStrings",							@#SetHelpStrings)
	XgrRegisterMessage (@"SetHintString",								@#SetHintString)
	XgrRegisterMessage (@"SetImage",										@#SetImage)
	XgrRegisterMessage (@"SetImageCoords",							@#SetImageCoords)
	XgrRegisterMessage (@"SetIndent",										@#SetIndent)
	XgrRegisterMessage (@"SetInfo",											@#SetInfo)
	XgrRegisterMessage (@"SetJustify",									@#SetJustify)
	XgrRegisterMessage (@"SetKeyboardFocus",						@#SetKeyboardFocus)
	XgrRegisterMessage (@"SetKeyboardFocusGrid",				@#SetKeyboardFocusGrid)
	XgrRegisterMessage (@"SetKidArray",									@#SetKidArray)
	XgrRegisterMessage (@"SetMaxMinSize",								@#SetMaxMinSize)
	XgrRegisterMessage (@"SetMenuEntryArray",						@#SetMenuEntryArray)
	XgrRegisterMessage (@"SetMessageFunc",							@#SetMessageFunc)
	XgrRegisterMessage (@"SetMessageFuncArray",					@#SetMessageFuncArray)
	XgrRegisterMessage (@"SetMessageSub",								@#SetMessageSub)
	XgrRegisterMessage (@"SetMessageSubArray",					@#SetMessageSubArray)
	XgrRegisterMessage (@"SetModalWindow",							@#SetModalWindow)
	XgrRegisterMessage (@"SetParent",										@#SetParent)
	XgrRegisterMessage (@"SetPosition",									@#SetPosition)
	XgrRegisterMessage (@"SetRedrawFlags",							@#SetRedrawFlags)
	XgrRegisterMessage (@"SetSize",											@#SetSize)
	XgrRegisterMessage (@"SetState",										@#SetState)
	XgrRegisterMessage (@"SetStyle",										@#SetStyle)
	XgrRegisterMessage (@"SetTabArray",									@#SetTabArray)
	XgrRegisterMessage (@"SetTabWidth",									@#SetTabWidth)
	XgrRegisterMessage (@"SetTextArray",								@#SetTextArray)
	XgrRegisterMessage (@"SetTextArrayLine",						@#SetTextArrayLine)
	XgrRegisterMessage (@"SetTextArrayLines",						@#SetTextArrayLines)
	XgrRegisterMessage (@"SetTextCursor",								@#SetTextCursor)
	XgrRegisterMessage (@"SetTextFilename",							@#SetTextFilename)
	XgrRegisterMessage (@"SetTextFlag",									@#SetTextFlag)
	XgrRegisterMessage (@"SetTextSelection",						@#SetTextSelection)
	XgrRegisterMessage (@"SetTextSpacing",							@#SetTextSpacing)
	XgrRegisterMessage (@"SetTextString",								@#SetTextString)
	XgrRegisterMessage (@"SetTextStrings",							@#SetTextStrings)
	XgrRegisterMessage (@"SetTexture",									@#SetTexture)
	XgrRegisterMessage (@"SetTimer",										@#SetTimer)
	XgrRegisterMessage (@"SetValue",										@#SetValue)
	XgrRegisterMessage (@"SetValueArray",								@#SetValueArray)
	XgrRegisterMessage (@"SetValues",										@#SetValues)
	XgrRegisterMessage (@"SetWindowFunction",						@#SetWindowFunction)
	XgrRegisterMessage (@"SetWindowIcon",								@#SetWindowIcon)
	XgrRegisterMessage (@"SetWindowTitle",							@#SetWindowTitle)
	XgrRegisterMessage (@"ShowTextCursor",							@#ShowTextCursor)
	XgrRegisterMessage (@"ShowWindow",									@#ShowWindow)
	XgrRegisterMessage (@"SomeLess",										@#SomeLess)
	XgrRegisterMessage (@"SomeMore",										@#SomeMore)
	XgrRegisterMessage (@"StartTimer",									@#StartTimer)
	XgrRegisterMessage (@"SystemMessage",								@#SystemMessage)
	XgrRegisterMessage (@"TextDelete",									@#TextDelete)
	XgrRegisterMessage (@"TextEvent",										@#TextEvent)
	XgrRegisterMessage (@"TextInsert",									@#TextInsert)
	XgrRegisterMessage (@"TextModified",								@#TextModified)
	XgrRegisterMessage (@"TextReplace",									@#TextReplace)
	XgrRegisterMessage (@"TimeOut",											@#TimeOut)
	XgrRegisterMessage (@"Update",											@#Update)
	XgrRegisterMessage (@"WindowClose",									@#WindowClose)
	XgrRegisterMessage (@"WindowCreate",								@#WindowCreate)
	XgrRegisterMessage (@"WindowDeselected",						@#WindowDeselected)
	XgrRegisterMessage (@"WindowDestroy",								@#WindowDestroy)
	XgrRegisterMessage (@"WindowDestroyed",							@#WindowDestroyed)
	XgrRegisterMessage (@"WindowDisplay",								@#WindowDisplay)
	XgrRegisterMessage (@"WindowDisplayed",							@#WindowDisplayed)
	XgrRegisterMessage (@"WindowGetDisplay",						@#WindowGetDisplay)
	XgrRegisterMessage (@"WindowGetFunction",						@#WindowGetFunction)
	XgrRegisterMessage (@"WindowGetIcon",								@#WindowGetIcon)
	XgrRegisterMessage (@"WindowGetKeyboardFocusGrid",	@#WindowGetKeyboardFocusGrid)
	XgrRegisterMessage (@"WindowGetSelectedWindow",			@#WindowGetSelectedWindow)
	XgrRegisterMessage (@"WindowGetSize",								@#WindowGetSize)
	XgrRegisterMessage (@"WindowGetTitle",							@#WindowGetTitle)
	XgrRegisterMessage (@"WindowHelp",									@#WindowHelp)
	XgrRegisterMessage (@"WindowHidden",								@#WindowHidden)
	XgrRegisterMessage (@"WindowHide",									@#WindowHide)
	XgrRegisterMessage (@"WindowKeyDown",								@#WindowKeyDown)
	XgrRegisterMessage (@"WindowKeyUp",									@#WindowKeyUp)
	XgrRegisterMessage (@"WindowMaximize",							@#WindowMaximize)
	XgrRegisterMessage (@"WindowMaximized",							@#WindowMaximized)
	XgrRegisterMessage (@"WindowMinimize",							@#WindowMinimize)
	XgrRegisterMessage (@"WindowMinimized",							@#WindowMinimized)
	XgrRegisterMessage (@"WindowMonitorContext",				@#WindowMonitorContext)
	XgrRegisterMessage (@"WindowMonitorHelp",						@#WindowMonitorHelp)
	XgrRegisterMessage (@"WindowMonitorKeyboard",				@#WindowMonitorKeyboard)
	XgrRegisterMessage (@"WindowMonitorMouse",					@#WindowMonitorMouse)
	XgrRegisterMessage (@"WindowMouseDown",							@#WindowMouseDown)
	XgrRegisterMessage (@"WindowMouseDrag",							@#WindowMouseDrag)
	XgrRegisterMessage (@"WindowMouseEnter",						@#WindowMouseEnter)
	XgrRegisterMessage (@"WindowMouseExit",							@#WindowMouseExit)
	XgrRegisterMessage (@"WindowMouseMove",							@#WindowMouseMove)
	XgrRegisterMessage (@"WindowMouseUp",								@#WindowMouseUp)
	XgrRegisterMessage (@"WindowMouseWheel",						@#WindowMouseWheel)
	XgrRegisterMessage (@"WindowRedraw",								@#WindowRedraw)
	XgrRegisterMessage (@"WindowRegister",							@#WindowRegister)
	XgrRegisterMessage (@"WindowResize",								@#WindowResize)
	XgrRegisterMessage (@"WindowResized",								@#WindowResized)
	XgrRegisterMessage (@"WindowResizeToGrid",					@#WindowResizeToGrid)
	XgrRegisterMessage (@"WindowRestore",								@#WindowRestore)
	XgrRegisterMessage (@"WindowSelect",								@#WindowSelect)
	XgrRegisterMessage (@"WindowSelected",							@#WindowSelected)
	XgrRegisterMessage (@"WindowSetFunction",						@#WindowSetFunction)
	XgrRegisterMessage (@"WindowSetIcon",								@#WindowSetIcon)
	XgrRegisterMessage (@"WindowSetKeyboardFocusGrid",	@#WindowSetKeyboardFocusGrid)
	XgrRegisterMessage (@"WindowSetTitle",							@#WindowSetTitle)
	XgrRegisterMessage (@"WindowShow",									@#WindowShow)
	XgrRegisterMessage (@"WindowSystemMessage",					@#WindowSystemMessage)
	XgrRegisterMessage (@"LastMessage",									@#LastMessage)
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
END FUNCTION
'
'
'  ############################
'  #####  InitProgram ()  #####
'  ############################
'
FUNCTION  InitProgram ()
	SHARED  fileType
	SHARED  defaultDirectory$
	SHARED  UBYTE charsetNonWhiteChar[]
'
	fileType = $$Text														' in case of fatal error
	##STANDALONE = $$FALSE											' not running standalone
'
	XstGetCurrentDirectory (@defaultDirectory$)
	GOSUB DefineCharsetArrays
	RETURN
'
'
' ***********************************  0x00 - 0x20  ===>>  0
' *****  charsetNonWhiteChar[]  *****  0x7F - 0xFF  ===>>  0
' ***********************************  (others unchanged)
'
' Printable characters = the character, all others = 0
' NOTE:  tab, newline, space, etc... considered white chars
' NOTE:  backslash is a printable character
' NOTE:  double-quote is a printable character
'
'	*****  DefineCharsetArrays  *****
'
SUB DefineCharsetArrays
	DIM charsetNonWhiteChar[255]
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <=  32):  charsetNonWhiteChar[i] = 0
			CASE (i >= 127):  charsetNonWhiteChar[i] = 0
			CASE ELSE:        charsetNonWhiteChar[i] = i
		END SELECT
	NEXT i
END SUB
END FUNCTION
'
'
' ################################
' #####  FindAliensCfunc ()  #####
' ################################
'
' Find dynamic memory allocated by user CFUNCTION but not freed
'
'
FUNCTION  FindAliensCfunc ()
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
	STATIC heads[]
'
	IFZ heads[] THEN DIM heads[1000]
	headaddr = ##DYNO
	DO
		findcount = 0
		DO
			upLink = XLONGAT (headaddr)
			alloc  = XLONGAT (headaddr, [1])
			checks = XLONGAT (headaddr, [3])
			IF (alloc < 0) THEN
				IF checks{{1,25}} THEN                   'C-function mask
					heads[findcount] = headaddr + 0x0010
					INC findcount
				END IF
			END IF
			headaddr = headaddr + upLink
		LOOP WHILE (upLink AND (findcount <= 1000))
'
		oneMore = $$FALSE
		IF findcount THEN
			DO WHILE upLink										' Point to next allocation before free
				upLink = XLONGAT (headaddr)		'   (unallocated may disappear)
				alloc  = XLONGAT (headaddr, [1])
				checks = XLONGAT (headaddr, [3])
				IF (alloc < 0) THEN
					IFZ upLink THEN oneMore = $$TRUE
					EXIT DO
				END IF
				headaddr = headaddr + upLink
			LOOP
			totalAliens = totalAliens + findcount
			i = 0
			DO
				findaddr = heads[i]
'				PRINT "  Find #"; i;;; HEX$(findaddr, 8)
				PRINT "  Find #"; i;;; HEX$(findaddr, 8); " : "; HEX$(XLONGAT(findaddr-16),8);; HEX$(XLONGAT(findaddr-12),8);; HEX$(XLONGAT(findaddr-8),8);; HEX$(XLONGAT(findaddr-4),8) HEX$(XLONGAT(findaddr),8);; HEX$(XLONGAT(findaddr+4),8);; HEX$(XLONGAT(findaddr+8),8);; HEX$(XLONGAT(findaddr+12),8)
'				free (findaddr)
				INC i
			LOOP UNTIL (i = findcount)
		END IF
	LOOP WHILE (upLink OR oneMore)
'
'	IF (totalAliens <= 0) THEN
'		AddCommandItem (" FindAliensCfunc : found no aliens ")
'	ELSE
	IF (totalAliens > 0) THEN
		AddCommandItem (" FindAliensCfunc : found " + STRING(totalAliens) + " aliens ")
	END IF
END FUNCTION
'
'
' ###########################
' #####  FreeAliens ()  #####
' ###########################
'
FUNCTION  FreeAliens ()
	STATIC heads[]
	$HdrSize = 0x20
'
	IFZ heads[] THEN DIM heads[1000]
	headaddr = ##DYNO
	DO
		freecount = 0
		DO
			upLink = XLONGAT (headaddr)
			alloc  = XLONGAT (headaddr, [1])
			checks = XLONGAT (headaddr, [3])
			IF (alloc < 0) THEN
				IF checks{{1,24}} THEN
					heads[freecount] = headaddr + $HdrSize
					INC freecount
				END IF
			END IF
			headaddr = headaddr + upLink
		LOOP WHILE (upLink AND (freecount <= 1000))
'
		oneMore = $$FALSE
		IF freecount THEN
			DO WHILE upLink										' Point to next allocation before free
				upLink = XLONGAT (headaddr)		'   (unallocated may disappear)
				alloc  = XLONGAT (headaddr, [1])
				checks = XLONGAT (headaddr, [3])
				IF (alloc < 0) THEN
					IFZ upLink THEN oneMore = $$TRUE
					EXIT DO
				END IF
				headaddr = headaddr + upLink
			LOOP
			totalAliens = totalAliens + freecount
			i = 0
			DO
				freeaddr = heads[i]
'				PRINT "  Free #"; i;;; HEX$(freeaddr, 8)
'				PRINT "  Free #"; i;;; HEX$(freeaddr, 8); " : "; HEX$(XLONGAT(freeaddr-16),8);; HEX$(XLONGAT(freeaddr-12),8);; HEX$(XLONGAT(freeaddr-8),8);; HEX$(XLONGAT(freeaddr-4),8) HEX$(XLONGAT(freeaddr),8);; HEX$(XLONGAT(freeaddr+4),8);; HEX$(XLONGAT(freeaddr+8),8);; HEX$(XLONGAT(freeaddr+12),8)
				xb_5_free (freeaddr)
				INC i
			LOOP UNTIL (i = freecount)
		END IF
	LOOP WHILE (upLink OR oneMore)
	IF (headaddr != ##DYNOX) THEN
		PRINT "FreeAliens(52) Error *****************"
		PRINT "last linkage address:", HEXX$(headaddr)
		PRINT " did not match DYNOX:", HEXX$(##DYNOX)
	END IF
'
	IF (totalAliens <= 0) THEN
		AddCommandItem (" FreeAliens : found no aliens ")
	ELSE
		AddCommandItem (" FreeAliens : found " + STRING(totalAliens) + " aliens ")
	END IF
END FUNCTION
'
'
' ########################
' #####  Message ()  #####
' ########################
'
FUNCTION  Message (message$)
	SHARED  environmentActive
'
	IFZ environmentActive THEN
		PRINT "\n" + message$
		RETURN
	END IF
'
	XuiMessage (@message$)
	RETURN
'
END FUNCTION
'
'
' ##########################
' #####  PrintMenu ()  #####
' ##########################
'
FUNCTION  PrintMenu ()
	PRINT "?  = menu          <cr> = menu"
	PRINT "c  = continue        q  = quit xit"
	PRINT "m  = memory map      t  = table dump"
	PRINT "th = test headers    h  = header dump"
	PRINT "r  = registers"
	PRINT "c  = continue        after breakpoint or trap"
	PRINT "b  = breakpoint      b  <hex.address>"
	PRINT "u  = unbreakpoint    u  <hex.address>"
	PRINT "uu = remove all BPs  uu"
	PRINT "a  = assembly        a  [hex.start.addr]  [hex.lines]"
	PRINT "d  = dump memory     d  [hex.start.address] [hex.length]"
	PRINT "f  = fill memory     f  <hex.address>  <hex.length>  <hex.value>"
	PRINT "s  = substitute      s  <hex.address>"
	PRINT "l  = locate word     l  <hex.data>"
	PRINT "g  = go program      g  [hex.address] (default = ##UCODE)"
	PRINT "go = go compiler"
END FUNCTION
'
'
' ###########################
' #####  PrintStack ()  #####
' ###########################
'
FUNCTION  PrintStack ()
'
	rbp = 0
	rsp = 0
	XxxGetRbpRsp (@rbp, @rsp)
	IFZ rbp THEN RETURN ($$TRUE)
	PRINT "  .rbp     return"
'
	DO
		rip = XLONGAT (rbp, 4)
		PRINT HEX$(rbp,16);;; HEX$(rip,16)
		rbp = XLONGAT (rbp)
	LOOP WHILE rbp
END FUNCTION
'
'
' #############################
' #####  SharedMemory ()  #####
' #############################
'
FUNCTION  SharedMemory (command, addr, size, (state, MEMORY enum[]))
	STATIC  MEMORY  memory[]
'
	SELECT CASE command
		CASE $$MemoryCreate			:	GOSUB Create
		CASE $$MemoryDestroy		:	GOSUB Destroy
		CASE $$MemoryDestroyAll	:	GOSUB DestroyAll
		CASE $$MemoryEnumerate	:	GOSUB Enumerate
		CASE ELSE								:	PRINT "UserCodeSpace() : unknown command"
	END SELECT
	RETURN (return)
'
'
' *****  Create  *****
'
' #define PROT_NONE       0x00       '  page can not be accessed
' #define PROT_READ       0x01       '  page can be read
' #define PROT_WRITE      0x02       '  page can be written
' #define PROT_EXEC       0x04       '  page can be executed
'                         0x08       '  reserved for PROT_EXEC_NOFLUSH
' #define PROT_SEM        0x10       '  page may be used for atomic ops
' #define PROT_GROWSDOWN  0x01000000 '  mprotect flag: extend change to start of growsdown vma
' #define PROT_GROWSUP    0x02000000 '  mprotect flag: extend change to end of growsup vma

' /*
' * Flags for mmap
'
' #define MAP_SHARED      0x001      '  Share changes
' #define MAP_PRIVATE     0x002      '  Changes are private
' #define MAP_TYPE        0x00f      '  Mask for type of mapping
' #define MAP_FIXED       0x010      '  Interpret addr exactly

' not used by linux, but here to make sure we don't clash with ABI defines
' #define MAP_RENAME      0x020      '  Assign page to file
' #define MAP_AUTOGROW    0x040      '  File may grow by writing
' #define MAP_LOCAL       0x080      '  Copy on fork/sproc
' #define MAP_AUTORSRV    0x100      '  Logical swap reserved on demand

' These are linux-specific
' #define MAP_NORESERVE   0x0400     '  don't check for reservations
' #define MAP_ANONYMOUS   0x0800     '  don't use a file
' #define MAP_GROWSDOWN   0x1000     '  stack-like segment
' #define MAP_DENYWRITE   0x2000     '  ETXTBSY
' #define MAP_EXECUTABLE  0x4000     '  mark it as an executable
' #define MAP_LOCKED      0x8000     '  pages are locked
' #define MAP_POPULATE    0x10000    '  populate (prefault) pagetables
' #define MAP_NONBLOCK    0x20000    '  do not block on IO
' #define MAP_STACK       0x40000    '  give out an address that is best suited for process/thread stacks
' #define MAP_HUGETLB     0x80000    '  create a huge page mapping
'
SUB Create
	size = size AND 0xFFFF0000										' mod 64KB size only
'	addr = addr AND 0xFFFF0000										' mod 64KB addresses only  '*cw* 230302-
	addr = addr AND ~0xFFFF                       ' mod 64KB addresses only  '*cw* 230302+
	IFZ mode THEN mode = 0x777										' read/write/execute access
'	shmid = shmget ($$IPC_PRIVATE, size, state)		' get memory block
'	return = mmap (addr, size, 7, 0x22, -1, 0)
	return = mmap (addr, size, 7, 0x21, -1, 0)

	rcms = msync (addr, size, 4)                        ' 4 = MS_INVALIDATE
'	PRINT "SharedMemory(66)", HEXX$(return), HEXX$(rcms)
'	IF (shmid = -1) THEN
	IF (return = -1) THEN
		PRINT "SharedMemMap() : Create : mmap() failed : error = "
		XstSystemErrorToError (xb_geterrno(), @error)
		XstSystemErrorNumberToName (xb_geterrno(), @errno$)
		XstErrorNumberToName (error, @error$)
		##ERROR = error
		PRINT "SharedMemory(74)", xb_geterrno();; errno$, error;; error$
		return = -1
		EXIT SUB
	END IF
'
'	return = shmat (shmid, addr, state)						' attach memory block
'	IF (return = -1) THEN
'		PRINT "SharedMemory() : Create : shmat() failed : error = ";
'		XstSystemErrorToError (xb_geterrno(), @error)
'		XstSystemErrorNumberToName (xb_geterrno(), @errno$)
'		XstErrorNumberToName (error, @error$)
'		##ERROR = error
'		PRINT "SharedMemory(86)", xb_geterrno();; errno$, error;; error$
'		EXIT SUB
'	END IF
	slot = -1
	addr = return
	IFZ memory THEN DIM memory[3]
	upper = UBOUND(memory[])
'
	FOR i = 0 TO upper
		IFZ memory[i].id THEN slot = i : EXIT FOR
	NEXT i
'
	IF (slot < 0) THEN
		upper = upper + 4
		REDIM memory[upper]
		slot = i
	END IF
'
	memory[slot].id = shmid
	memory[slot].addr = addr
	memory[slot].size = size
	memory[slot].state = state
END SUB
'
'
' *****  Destroy  *****  new
'
SUB Destroy
	IFZ memory[] THEN
		error = $$ErrorObjectMemory OR $$ErrorNatureNonexistent
		XstErrorNumberToName (error, @error$)
		##ERROR = error
		PRINT "SharedMemory(118)", error$
		return = -1
		EXIT SUB
	END IF
'
	FOR i = 0 TO UBOUND (memory[])
		IF (addr = memory[i].addr) THEN
'			error = shmdt (addr)
			size = memory[i].size
			error = munmap (addr, size)
			IF (error = -1) THEN
				PRINT "SharedMemory() : Destroy : shmdt() failed : error = ";
				XstSystemErrorToError (xb_geterrno(), @error)
				##ERROR = error
				PRINT "SharedMemory(132)", error$
				return = -1
				EXIT SUB
			END IF
			memory[i].id = 0
			memory[i].addr = 0
			memory[i].size = 0
			memory[i].state = 0
			return = 0
			EXIT SUB
		END IF
	NEXT i
	error = $$ErrorObjectMemory OR $$ErrorNatureInvalidAddress
	XstErrorNumberToName (error, @error$)
	##ERROR = error
	PRINT "SharedMemory(147)", error$
	return = -1
END SUB
' -------------------------------------------------------------------------
'
'
' *****  Create  *****
'
SUB Create_OLD
	size = size AND 0xFFFF0000										' mod 64KB size only
	addr = addr AND 0xFFFF0000										' mod 64KB addresses only
	IFZ mode THEN mode = 0x777										' read/write/execute access
	shmid = shmget ($$IPC_PRIVATE, size, state)		' get memory block
	IF (shmid = -1) THEN
		PRINT "SharedMemory() : Create : shmget() failed : error = "
		XstSystemErrorToError (xb_geterrno(), @error)
		XstSystemErrorNumberToName (xb_geterrno(), @errno$)
		XstErrorNumberToName (error, @error$)
		##ERROR = error
		PRINT "SharedMemory(166)", xb_geterrno();; errno$, error;; error$
		return = -1
		EXIT SUB
	END IF
'
	return = shmat (shmid, addr, state)						' attach memory block
	IF (return = -1) THEN
		PRINT "SharedMemory() : Create : shmat() failed : error = ";
		XstSystemErrorToError (xb_geterrno(), @error)
		XstSystemErrorNumberToName (xb_geterrno(), @errno$)
		XstErrorNumberToName (error, @error$)
		##ERROR = error
		PRINT "SharedMemory(178)", xb_geterrno();; errno$, error;; error$
		EXIT SUB
	END IF
	slot = -1
	addr = return
	IFZ memory THEN DIM memory[3]
	upper = UBOUND(memory[])
'
	FOR i = 0 TO upper
		IFZ memory[i].id THEN slot = i : EXIT FOR
	NEXT i
'
	IF (slot < 0) THEN
		upper = upper + 4
		REDIM memory[upper]
		slot = i
	END IF
'
	memory[slot].id = shmid
	memory[slot].addr = addr
	memory[slot].size = size
	memory[slot].state = state
END SUB
'
'
' *****  Destroy  *****
'
SUB Destroy_OLD
	IFZ memory[] THEN
		error = $$ErrorObjectMemory OR $$ErrorNatureNonexistent
		XstErrorNumberToName (error, @error$)
		##ERROR = error
		PRINT "SharedMemory(210)", error$
		return = -1
		EXIT SUB
	END IF
'
	FOR i = 0 TO UBOUND (memory[])
		IF (addr = memory[i].addr) THEN
			error = shmdt (addr)
			IF (error = -1) THEN
				PRINT "SharedMemory() : Destroy : shmdt() failed : error = ";
				XstSystemErrorToError (xb_geterrno(), @error)
				##ERROR = error
				PRINT "SharedMemory(222)", error$
				return = -1
				EXIT SUB
			END IF
			memory[i].id = 0
			memory[i].addr = 0
			memory[i].size = 0
			memory[i].state = 0
			return = 0
			EXIT SUB
		END IF
	NEXT i
	error = $$ErrorObjectMemory OR $$ErrorNatureInvalidAddress
	XstErrorNumberToName (error, @error$)
	##ERROR = error
	PRINT "SharedMemory(237)", error$
	return = -1
END SUB
'
'
' *****  DestroyAll  *****
'
SUB DestroyAll
	err = 0
	IFZ memory[] THEN EXIT SUB
	FOR i = 0 TO UBOUND (memory[])
		addr = memory[i].addr
		IF addr THEN GOSUB Destroy
		IF (return = -1) THEN err = $$TRUE
	NEXT i
	return = err
END SUB
'
'
' *****  Enumerate  *****
'
SUB Enumerate
	DIM enum[]
	IFZ memory[] THEN EXIT SUB
	upper = UBOUND (memory[])
	DIM enum[upper]
	slot = -1
	FOR i = 0 TO upper
		IF memory[i].id THEN
			INC slot
			enum[slot] = memory[i]
		END IF
	NEXT i
	IF (slot < 0) THEN DIM enum[] ELSE REDIM enum[slot]
	return = 0
END SUB
END FUNCTION
'
'
'  ############################
'  #####  XitBlowback ()  #####
'  ############################
'
'	First entry from Xit just sets baseFrameAddr, others execute Blowback
'
'	Blowbacks must be graceful--set the blowback flag
'	Never call XitBlowback from a callback routine !!!
'
'	XxxXntBlowback() must be last because it wastes the libraries
' that user programs have brought in with IMPORT statements.
' These libraries must not be wasted until all calls to these
' libraries due to the other blowback functions are completed.
' For example, XxxXuiBlowback() is gonna send #DestroyWindow
' messages to all remaining library grid functions for which
' a window exists.
'
FUNCTION  XitBlowback ()
	SHARED  blowback
	SHARED  environmentActive
	SHARED  defaultDirectory$
	STATIC  baseFrameAddr
	STATIC  baseEsp
'
	##WHOMASK = 0										' do not processes user messages !!!
	##LOCKOUT = $$FALSE             ' no lockout during XitBlowback()
'
	IFZ baseFrameAddr THEN
		XxxGetRbpRsp (@baseFrameAddr, @baseEsp)
	ELSE
		XstSetCurrentDirectory (@defaultDirectory$)			' reset to original working directory
		XxxCloseAllUser ()						' Close all user file handles
		##BLOWBACK = $$TRUE						' so all libraries know blowback is active
		UserBlowback ()								' call Blowback() in user program if one exists
		XxxXstBlowback ()							' Blowback the standard library (timers)
		XxxXinBlowback ()							' Blowback the sockets library
		XxxXuiBlowback ()							' Blowback the designer package
		XxxXgrBlowback ()							' Blowback the graphics package                      'do xgr after xui
		XxxXntBlowback ()             ' Blowback the compiler (user library blowbacks)
		FreeAliens ()
'		FindAliensCfunc ()         '*cw* 210906-
'
		XxxSetRbpRsp (baseFrameAddr, baseEsp)
'
		##BLOWBACK = $$FALSE
	END IF
'
'	write (1, &"xitbb\n", 6)
	IF environmentActive THEN
		IF ##USERRUNNING THEN ResetDataDisplays (0)
	END IF
'
	##USERRUNNING	= $$FALSE			' user is definitely not running
	##TRAPVECTOR = 510					' default trap is normal breakpoint
	blowback = $$FALSE					' blowback is complete
	XxxXitMain (0, 0, 0)				' XxxXitMain() should never return here
	XstLog("XitBlowback(59)")
	XxxXitQuit (0)							' this should never execute
END FUNCTION
'
'
'  #############################
'  #####  UserBlowback ()  #####
'  #############################
'
FUNCTION  UserBlowback ()
	FUNCADDR  func ()
'
	addr = 0
	IFZ addr THEN addr = XxxGetAddressGivenLabel (@"Blowback")
	IFZ addr THEN addr = XxxGetAddressGivenLabel (@"_Blowback")
	IFZ addr THEN addr = XxxGetAddressGivenLabel (@"Blowback_0")
	IFZ addr THEN addr = XxxGetAddressGivenLabel (@"_Blowback_0")
'
' PRINT "xit.x : UserBlowback() : addr = "; HEX$ (addr, 8)
'
	IF addr THEN
		IF (addr != -1) THEN
			whomask = ##WHOMASK
			##WHOMASK = 0x01000000
			func = addr
			@func ()
			##WHOMASK = whomask
		END IF
	END IF
END FUNCTION
'
'
' ###########################
' #####  XxxXitQuit ()  #####
' ###########################
'
FUNCTION  XxxXitQuit (status)
	SHARED  environmentActive
	SHARED  fileType
	SHARED  prefFileNumber
	SHARED  textAlteredSinceSave
'
' See function  FileQuit()
'
	XstClearConsole ()
	XxxXgrQuit ()
	XxxXitExit (status)
END FUNCTION
'
'
' #################################
' #####  EstablishSignals ()  #####
' #################################
'
' based on UNIX debug version
'
FUNCTION  EstablishSignals ()
	USIGACTION	sig
'
' mask is the signals that should be blocked during execution of the signal handler
'
'	PRINT "EstablishSignals() : Enter"
	mask = 0x00000000
'	mask = mask OR $$SIGMASK_HUP
'	mask = mask OR $$SIGMASK_INT                                       '*cw* 110711+ 150805+
'	mask = mask OR $$SIGMASK_QUIT
'	mask = mask OR $$SIGMASK_ILL			' later comment this one out !!!  *cw* 100722
	mask = mask OR $$SIGMASK_TRAP			' mask $$SIGILL out now because
'	mask = mask OR $$SIGMASK_ABRT			' $$SIGILL is occuring right after
	mask = mask OR $$SIGMASK_IOT			' entry into the XxxXitMain()
	mask = mask OR $$SIGMASK_BUS
'	mask = mask OR $$SIGMASK_FPE			' screws up the frame information.
'	mask = mask OR $$SIGMASK_KILL
	mask = mask OR $$SIGMASK_USR1
	mask = mask OR $$SIGMASK_SEGV     '*cw* 150302- 211217+
	mask = mask OR $$SIGMASK_USR2
	mask = mask OR $$SIGMASK_PIPE
'	mask = mask OR $$SIGMASK_ALRM     'do not mask SIGALRM on breakpoint trap  *cw* 090312
'	mask = mask OR $$SIGMASK_TERM     '*cw* 090314
'	mask = mask OR $$SIGMASK_STKFLT   '*cw* 150302-
	mask = mask OR $$SIGMASK_CHLD
	mask = mask OR $$SIGMASK_CONT
'	mask = mask OR $$SIGMASK_STOP
'	mask = mask OR $$SIGMASK_TSTP
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
	sig.sa_handler = &XxxXitMain()	' signal catching function    '*cw* 210716+
'	sig.sa_handler = &XxxBreakpoint()	' signal catching function  '*cw* 210716-
	sig.sa_mask = mask							' block all signals upon signal catch
	sig.sa_flags = 0								' nothing special
'
	e = xb_sigaction ($$SIGTRAP, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGTRAP"     'do not mask SIGALRM on breakpoint trap  *cw* 090312
	mask = mask OR $$SIGMASK_ALRM                                                   'mask SIGALRM on remaining signals       *cw* 090312
'
	e = xb_sigaction ($$SIGHUP, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGHUG"      '*cw* 100722
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
	e = xb_sigaction ($$SIGSTKFLT, &sig, 0)	: IF (e < 0) THEN PRINT "$$SIGSTKFLT"   '*cw* 111029+
	e = xb_sigaction ($$SIGVTALRM, &sig, 0) : IF (e < 0) THEN PRINT "$$SIGVTALRM"
'
	sig.sa_handler = &XxxXitSigAlrm()                                               '*cw* 090312
	e = xb_sigaction ($$SIGALRM, &sig, 0) : IF (e < 0) THEN PRINT "$$SIGALRM"       '*cw* 090312
'
'	PRINT "EstablishSignals() : Leave", HEXX$(sig.sa_handler,8), HEXX$(sig.sa_mask,8), HEXX$(sig.sa_flags)
END FUNCTION
'
'
'  ################################################
'  #####  XitGetPDEPrefWindowPositionAndSize  #####
'  ################################################
'
FUNCTION  XitGetPDEPrefWindowPositionAndSize (grid, name$)
	SHARED prefFileNumber
'
	IF grid THEN
		error = XstGetPrefXLONG (prefFileNumber, name$ + "-X", 0, @x)
		error = error || XstGetPrefXLONG (prefFileNumber, name$ + "-Y", 0, @y)
		error = error || XstGetPrefXLONG (prefFileNumber, name$ + "-W", 0, @w)
		error = error || XstGetPrefXLONG (prefFileNumber, name$ + "-H", 0, @h)
		IFZ error THEN
			x = MIN (MAX (x, 0), #displayWidth - 64)
			y = MIN (MAX (y, 0), #displayHeight - 64)
			XuiSendMessage (grid, #ResizeWindow, x, y, w, h, 0, 0)
		END IF
	END IF
END FUNCTION
'
'
'  ############################
'  #####  XitLoadPDEPref  #####
'  ############################
'
FUNCTION  XitLoadPDEPref ()
	SHARED prefFileNumber
	SHARED xitGrid
	SHARED fileBox, readBox, writeBox
	SHARED funcBox, deleteFuncBox
	SHARED memoryBox, assemblyBox, registerBox
	SHARED arrayBox, stringBox, compositeBox, variableBox
	SHARED findBox
	SHARED errorBox
	SHARED optionMiscBox
	SHARED xitCursorColor
	SHARED xitCursorLineColor
'
	SHARED xitFileList
	SHARED fileType
	SHARED CURSORLOCATION recentCursor[]
	SHARED recentFunc$[]
	SHARED recentFile$[]
	SHARED reloadLastFile
'
	$XitOptionMisc          =   0  ' kid   0 grid type = XitOptionMisc
	$CheckBounds            =   1  ' kid   1 grid type = XuiCheckBox
	$CheckSaveNewline       =   2  ' kid   2 grid type = XuiCheckBox
	$CheckConsoleDarkColor  =   3  ' kid   3 grid type = XuiCheckBox
	$CheckCompileError      =   4  ' kid   4 grid type = XuiCheckBox
	$CheckConsoleLargeFont  =   5  ' kid   5 grid type = XuiCheckBox
	$CheckProgramLargeFont  =   6  ' kid   6 grid type = XuiCheckBox
	$CheckConsoleLargeBars  =   7  ' kid   7 grid type = XuiCheckBox
	$CheckProgramLargeBars  =   8  ' kid   8 grid type = XuiCheckBox
	$CheckAutoUpperCase     =   9  ' kid   9 grid type = XuiCheckBox
	$CheckProgramLineNumber =  10  ' kid  10 grid type = XuiCheckBox
	$CheckAutoIndent        =  11  ' kid  11 grid type = XuiCheckBox
	$CheckTabBlockIndent    =  12  ' kid  12 grid type = XuiCheckBox
	$CheckMakeBackupFile    =  13  ' kid  13 grid type = XuiCheckBox
	$CheckReloadLastFile    =  14  ' kid  14 grid type = XuiCheckBox
	$CheckSaveBeforeCompile =  15  ' kid  15 grid type = XuiCheckBox
	$CheckSaveBeforeRun     =  16  ' kid  16 grid type = XuiCheckBox
	$CheckProgramRuler      =  17  ' kid  17 grid type = XuiCheckBox
'
	$CheckShowType			= 11
	$CheckShowLocation	= 12
	$CheckShowHex				= 13
'
	IFZ prefFileNumber THEN RETURN
'
' The $$Callback flag in the v1 field tells XuiCheckBox() to generate a Callback as if the
' option were actually selected. Without this flag, the checkbox display is only updated.
'
	XstSetPrefSection (prefFileNumber, "PDE-Option-Misc")
	XstGetPrefXLONG (prefFileNumber, "checkBounds", $$TRUE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckBounds, 0)
	XstGetPrefXLONG (prefFileNumber, "saveWithRN", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckSaveNewline, 0)
	XstGetPrefXLONG (prefFileNumber, "consoleDarkColor", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckConsoleDarkColor, 0)
	XstGetPrefXLONG (prefFileNumber, "stopCompOnErr", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckCompileError, 0)
	XstGetPrefXLONG (prefFileNumber, "consoleLargeFont", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckConsoleLargeFont, 0)
	XstGetPrefXLONG (prefFileNumber, "programLargeFont", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckProgramLargeFont, 0)
	XstGetPrefXLONG (prefFileNumber, "consoleLargeBars", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckConsoleLargeBars, 0)
	XstGetPrefXLONG (prefFileNumber, "programLargeBars", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckProgramLargeBars, 0)
	XstGetPrefXLONG (prefFileNumber, "autoUpperCase", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckAutoUpperCase, 0)
	XstGetPrefXLONG (prefFileNumber, "lineNumber", $$TRUE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckProgramLineNumber, 0)
	XstGetPrefXLONG (prefFileNumber, "autoIndent", $$TRUE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckAutoIndent, 0)
	XstGetPrefXLONG (prefFileNumber, "tabBlockIndent", $$TRUE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckTabBlockIndent, 0)
	XstGetPrefXLONG (prefFileNumber, "makeBackupFile", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckMakeBackupFile, 0)
	XstGetPrefXLONG (prefFileNumber, "reloadLastFile", $$TRUE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckReloadLastFile, 0)
	XstGetPrefXLONG (prefFileNumber, "saveBeforeCompile", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckSaveBeforeCompile, 0)
	XstGetPrefXLONG (prefFileNumber, "saveBeforeRun", $$FALSE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckSaveBeforeRun, 0)
	XstGetPrefXLONG (prefFileNumber, "rulerGrid", $$TRUE, @value)
	XuiSendMessage (optionMiscBox, #SetValue, value, $$Callback, 0, 0, $CheckProgramRuler, 0)
'
	XstSetPrefSection (prefFileNumber, "PDE-Option-Tab")
	XstGetPrefXLONG (prefFileNumber, "tabWidth", 1, @value)
	OptionTabWidth (value)
'
	XstSetPrefSection (prefFileNumber, "PDE-Option-Color")
	XstGetPrefXLONG (prefFileNumber, "cursorColor", 24, @value)
	XxxXuiTextCursor (value)
	xitCursorColor = value
	XstGetPrefXLONG (prefFileNumber, "cursorLineColor", 48, @value)
	XuiSendMessage (xitGrid, #SetColorExtra, -1, -1, -1, value, $$xitTextLower, 0)
	xitCursorLineColor = value
'
	XstSetPrefSection (prefFileNumber, "PDE-WindowPositionsAndSizes")
	XitGetPDEPrefWindowPositionAndSize (fileBox, "File")
	XitGetPDEPrefWindowPositionAndSize (readBox, "Read")
	XitGetPDEPrefWindowPositionAndSize (writeBox, "Write")
	XitGetPDEPrefWindowPositionAndSize (funcBox, "Function")
	XitGetPDEPrefWindowPositionAndSize (deleteFuncBox, "DeleteFunction")
	XitGetPDEPrefWindowPositionAndSize (memoryBox, "Memory")
	XitGetPDEPrefWindowPositionAndSize (assemblyBox, "Assembly")
	XitGetPDEPrefWindowPositionAndSize (registerBox, "Register")
	XitGetPDEPrefWindowPositionAndSize (variableBox, "Variable")
	XstGetPrefXLONG (prefFileNumber, "Variable-ShowType", $$TRUE, @value)
	XuiSendMessage (variableBox, #SetValue, value, $$Callback, 0, 0, $CheckShowType, 0)
	XstGetPrefXLONG (prefFileNumber, "Variable-ShowLocation", $$TRUE, @value)
	XuiSendMessage (variableBox, #SetValue, value, $$Callback, 0, 0, $CheckShowLocation, 0)
	XstGetPrefXLONG (prefFileNumber, "Variable-ShowHex", $$TRUE, @value)
	XuiSendMessage (variableBox, #SetValue, value, $$Callback, 0, 0, $CheckShowHex, 0)
	XitGetPDEPrefWindowPositionAndSize (arrayBox, "Array")
	XitGetPDEPrefWindowPositionAndSize (stringBox, "String")
	XitGetPDEPrefWindowPositionAndSize (compositeBox, "Composite")
	XitGetPDEPrefWindowPositionAndSize (findBox, "Find")
	XitGetPDEPrefWindowPositionAndSize (errorBox, "Error")
'
	InitWindows ()
'
' Restore the list of recent files when program last used
'
	XstSetPrefSection (prefFileNumber, "PDE-Filenames")
	DIM recentFile$[$$RecentUpper]
	DIM recentFunc$[$$RecentUpper]
	DIM recentCursor[$$RecentUpper]
	nc$ = "recentFile-"
	j = 0
	FOR i = 0 TO UBOUND(recentFile$[])
		name$ = nc$ + STRING$(i)
		fail = XstGetPrefSTRING (prefFileNumber, name$, "", @s$)
		IF fail THEN DO NEXT
		XstParseStringToStringArray (s$, ",", @s$[])
		REDIM s$[5]                                   'ensure proper number of parsed fields
		XstGetFileAttributes (s$[0], @attributes)
		IFZ (attributes AND ($$FileNormal OR $$FileArchive OR $$FileReadOnly)) THEN DO NEXT
		recentFile$[j] = s$[0]
		recentFunc$[j] = s$[1]
		recentCursor[j].pos = XLONG(s$[2])
		recentCursor[j].line = XLONG(s$[3])
		recentCursor[j].indent = XLONG(s$[4])
		recentCursor[j].topLine = XLONG(s$[5])
		INC j
	NEXT i
	DEC j
	REDIM recentFile$[j]
	REDIM recentFunc$[j]
	REDIM recentCursor[j]
'
	XuiSendMessage ( xitFileList, #SetTextArray, 0, 0, 0, 0, 0, @recentFile$[])
'
	IFZ reloadLastFile THEN RETURN
	IFZ recentFile$[] THEN RETURN
'
	fileName$ = recentFile$[0]
	XstGetFileAttributes (fileName$, @attributes)
	IFZ (attributes AND ($$FileNormal OR $$FileArchive OR $$FileReadOnly)) THEN RETURN
	funcName$ = recentFunc$[0]
'
	pos = recentCursor[0].pos
	line = recentCursor[0].line
	indent = recentCursor[0].indent
	topLine = recentCursor[0].topLine
'
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, fileName$)
'
	IF (funcName$ == "$$Text") THEN
		FileTextLoad ($$TRUE)
		XuiSendMessage (xitGrid, #SetTextCursor, pos, line, indent, topLine, $$xitTextLower, 0)
	ELSE
		FileLoad ($$TRUE)
		IF (fileType == $$Program) THEN
			funcNum = XxxFunctionNumber (funcName$)
			Display (funcNum, line, pos, topLine, indent)
		END IF
	END IF
'
END FUNCTION
'
'
'  ################################################
'  #####  XitSetPDEPrefWindowPositionAndSize  #####
'  ################################################
'
FUNCTION  XitSetPDEPrefWindowPositionAndSize (grid, name$)
	SHARED prefFileNumber
	IF grid THEN
		XgrGetGridWindow (grid, @window)
		XgrGetWindowPositionAndSize (window, @x, @y, @w, @h)
		XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
		XgrGetDisplaySize ("", 0, 0, @bw, @th)
'
		IF (w >= workAreaWidth) THEN RETURN           ' don't save if wider than workarea
		IF ((h+th+bw) >= workAreaHeight) THEN RETURN  ' don't save if taller than workarea
'
		XstSetPrefXLONG (prefFileNumber, name$ + "-X", x)
		XstSetPrefXLONG (prefFileNumber, name$ + "-Y", y)
		XstSetPrefXLONG (prefFileNumber, name$ + "-W", w)
		XstSetPrefXLONG (prefFileNumber, name$ + "-H", h)
	END IF
'
END FUNCTION
'
'
'  ############################
'  #####  XitSavePDEPref  #####
'  ############################
'
FUNCTION  XitSavePDEPref ()
	SHARED prefFileNumber
	SHARED xitGrid
	SHARED fileBox, readBox, writeBox
	SHARED funcBox, deleteFuncBox
	SHARED memoryBox, assemblyBox, registerBox
	SHARED arrayBox, stringBox, compositeBox, variableBox
	SHARED findBox
	SHARED errorBox
	SHARED optionMiscBox
	SHARED tabWidth, xitCursorColor
	SHARED xitCursorLineColor
	SHARED CURSORLOCATION recentCursor[]
	SHARED recentFunc$[]
	SHARED recentFile$[]
'
	$XitOptionMisc          =   0  ' kid   0 grid type = XitOptionMisc
	$CheckBounds            =   1  ' kid   1 grid type = XuiCheckBox
	$CheckSaveNewline       =   2  ' kid   2 grid type = XuiCheckBox
	$CheckConsoleDarkColor  =   3  ' kid   3 grid type = XuiCheckBox
	$CheckCompileError      =   4  ' kid   4 grid type = XuiCheckBox
	$CheckConsoleLargeFont  =   5  ' kid   5 grid type = XuiCheckBox
	$CheckProgramLargeFont  =   6  ' kid   6 grid type = XuiCheckBox
	$CheckConsoleLargeBars  =   7  ' kid   7 grid type = XuiCheckBox
	$CheckProgramLargeBars  =   8  ' kid   8 grid type = XuiCheckBox
	$CheckAutoUpperCase     =   9  ' kid   9 grid type = XuiCheckBox
	$CheckProgramLineNumber =  10  ' kid  10 grid type = XuiCheckBox
	$CheckAutoIndent        =  11  ' kid  11 grid type = XuiCheckBox
	$CheckTabBlockIndent    =  12  ' kid  12 grid type = XuiCheckBox
	$CheckMakeBackupFile    =  13  ' kid  13 grid type = XuiCheckBox
	$CheckReloadLastFile    =  14  ' kid  14 grid type = XuiCheckBox
	$CheckSaveBeforeCompile =  15  ' kid  15 grid type = XuiCheckBox
	$CheckSaveBeforeRun     =  16  ' kid  16 grid type = XuiCheckBox
	$CheckProgramRuler      =  17  ' kid  17 grid type = XuiCheckBox
'
	$CheckShowType			= 11
	$CheckShowLocation	= 12
	$CheckShowHex				= 13
'
	IF prefFileNumber THEN
		XstSetPrefSection (prefFileNumber, "PDE-Option-Misc")
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckBounds, 0)
		XstSetPrefXLONG (prefFileNumber, "checkBounds", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckSaveNewline, 0)
		XstSetPrefXLONG (prefFileNumber, "saveWithRN", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckConsoleDarkColor, 0)
		XstSetPrefXLONG (prefFileNumber, "consoleDarkColor", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckCompileError, 0)
		XstSetPrefXLONG (prefFileNumber, "stopCompOnErr", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckConsoleLargeFont, 0)
		XstSetPrefXLONG (prefFileNumber, "consoleLargeFont", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckProgramLargeFont, 0)
		XstSetPrefXLONG (prefFileNumber, "programLargeFont", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckConsoleLargeBars, 0)
		XstSetPrefXLONG (prefFileNumber, "consoleLargeBars", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckProgramLargeBars, 0)
		XstSetPrefXLONG (prefFileNumber, "programLargeBars", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckAutoUpperCase, 0)
		XstSetPrefXLONG (prefFileNumber, "autoUpperCase", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckProgramLineNumber, 0)
		XstSetPrefXLONG (prefFileNumber, "lineNumber", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckAutoIndent, 0)
		XstSetPrefXLONG (prefFileNumber, "autoIndent", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckTabBlockIndent, 0)
		XstSetPrefXLONG (prefFileNumber, "tabBlockIndent", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckMakeBackupFile, 0)
		XstSetPrefXLONG (prefFileNumber, "makeBackupFile", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckReloadLastFile, 0)
		XstSetPrefXLONG (prefFileNumber, "reloadLastFile", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckSaveBeforeCompile, 0)
		XstSetPrefXLONG (prefFileNumber, "saveBeforeCompile", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckSaveBeforeRun, 0)
		XstSetPrefXLONG (prefFileNumber, "saveBeforeRun", value)
		XuiGetValue (optionMiscBox, #GetValue, @value, 0, 0, 0, $CheckProgramRuler, 0)
		XstSetPrefXLONG (prefFileNumber, "rulerGrid", value)
'
		XstSetPrefSection (prefFileNumber, "PDE-Option-Tab")
		XstSetPrefXLONG (prefFileNumber, "tabWidth", tabWidth)
'
		XstSetPrefSection (prefFileNumber, "PDE-Option-Color")
		XstSetPrefXLONG (prefFileNumber, "cursorColor", xitCursorColor)
		XstSetPrefXLONG (prefFileNumber, "cursorLineColor", xitCursorLineColor)
'
		XstSetPrefSection (prefFileNumber, "PDE-Filenames")
'
		FileListFuncSet ()
		nc$ = "recentFile-"
		FOR i = 0 TO UBOUND(recentFile$[])
			name$ = nc$ + STRING$(i)
			s$ = recentFile$[i] + "," + recentFunc$[i]
			s$ = s$ + "," + STRING$(recentCursor[i].pos)    + "," + STRING$(recentCursor[i].line)
			s$ = s$ + "," + STRING$(recentCursor[i].indent) + "," + STRING$(recentCursor[i].topLine)
			XstSetPrefSTRING (prefFileNumber, name$, s$)
		NEXT i
'
		XstSetPrefSection (prefFileNumber, "PDE-WindowPositionsAndSizes")
		XitSetPDEPrefWindowPositionAndSize (xitGrid, "PDE")
		XstGetConsoleGrid (@consoleGrid)
		XitSetPDEPrefWindowPositionAndSize (consoleGrid, "Console")
		XgrGetDisplayOffset ("", @xOffset, @yOffset, @bw, @th)
		XstSetPrefXLONG (prefFileNumber, "Console-xOffset", xOffset)
		XstSetPrefXLONG (prefFileNumber, "Console-yOffset", yOffset)
		XstSetPrefXLONG (prefFileNumber, "Console-BW", bw)
		XstSetPrefXLONG (prefFileNumber, "Console-TH", th)
		XitSetPDEPrefWindowPositionAndSize (fileBox, "File")
		XitSetPDEPrefWindowPositionAndSize (readBox, "Read")
		XitSetPDEPrefWindowPositionAndSize (writeBox, "Write")
		XitSetPDEPrefWindowPositionAndSize (funcBox, "Function")
		XitSetPDEPrefWindowPositionAndSize (deleteFuncBox, "DeleteFunction")
		XitSetPDEPrefWindowPositionAndSize (memoryBox, "Memory")
		XitSetPDEPrefWindowPositionAndSize (assemblyBox, "Assembly")
		XitSetPDEPrefWindowPositionAndSize (registerBox, "Register")
		XitSetPDEPrefWindowPositionAndSize (variableBox, "Variable")
		XuiGetValue (variableBox, #GetValue, @value, 0, 0, 0, $CheckShowType, 0)
		XstSetPrefXLONG (prefFileNumber, "Variable-ShowType", value)
		XuiGetValue (variableBox, #GetValue, @value, 0, 0, 0, $CheckShowLocation, 0)
		XstSetPrefXLONG (prefFileNumber, "Variable-ShowLocation", value)
		XuiGetValue (variableBox, #GetValue, @value, 0, 0, 0, $CheckShowHex, 0)
		XstSetPrefXLONG (prefFileNumber, "Variable-ShowHex", value)
		XitSetPDEPrefWindowPositionAndSize (arrayBox, "Array")
		XitSetPDEPrefWindowPositionAndSize (stringBox, "String")
		XitSetPDEPrefWindowPositionAndSize (compositeBox, "Composite")
		XitSetPDEPrefWindowPositionAndSize (findBox, "Find")
		XitSetPDEPrefWindowPositionAndSize (errorBox, "Error")
	END IF
END FUNCTION
'
'
' ####################################
' #####  SystemErrorSetError ()  #####
' ####################################
'
' this function converts system error variable "errno" into a native error
' number and stores it in the native error variable ##ERROR.
' ##ERROR can be read and or written with the ERROR() instrinsic.
'
' operating system functions typically return a 0 or -1 error indicator.
' when programs receive an error indicator from an operating system routine,
' they can call this function to update the native error.
'
' this function returns the native error number.
'
FUNCTION  SystemErrorSetError ()
'
	XstSystemErrorToError (xb_geterrno(), @error)
	##ERROR = error
	PRINT "SystemErrorSetError(21)", error
	RETURN (error)
END FUNCTION
'
'
' ###########################
' #####  PrintError ()  #####
' ###########################
'
' this function prints a string form of the native error number "##ERROR"
' to the standard output device.
'
FUNCTION  PrintError ()
'
	XstErrorNumberToName (##ERROR, @error$)
	PRINT error$
END FUNCTION
'
'
' #################################
' #####  PrintSystemError ()  #####
' #################################
'
' this function prints a string form of the system error variable "errno"
' to the standard output device.
'
FUNCTION  PrintSystemError ()
'
	XstSystemErrorNumberToName (xb_geterrno(), @errno$)
	PRINT errno$
END FUNCTION
'
'
' ############################################
' #####  PrintSystemErrorNativeError ()  #####
' ############################################
'
' this function prints a string form of the system error variable "errno"
' and the native error variable ##ERROR to the standard output device.
'
FUNCTION  PrintSystemErrorNativeError ()
'
	XstSystemErrorNumberToName (xb_geterrno(), @errno$)
	XstErrorNumberToName (##ERROR, @error$)
	PRINT errno$; " : ";  error$
END FUNCTION
'
'
' ####################
' #####  Asm ()  #####
' ####################
'
FUNCTION  Asm (addr$, lines$, asm$[])
	STATIC  asmAddr
	ULONG  ##CODE
'
	IFZ asmAddr THEN asmAddr = ##CODE
'
	a$ = addr$
	IF a$ THEN
		x = INSTR (a$, "x")
		IFZ x THEN a$ = "0x" + a$
		addr = XLONG (a$)
	ELSE
		addr = asmAddr
	END IF
	IFZ AddressOk (addr) THEN RETURN ($$TRUE)
'
	l$ = lines$
	IF lines$ THEN
		x = INSTR (l$, "x")
		IFZ x THEN l$ = "0x" + l$
		lines = XLONG (l$)
	END IF
	IF (lines <= 0) THEN lines = 16
'
	upper = lines-1
	DIM asm$[upper]
	FOR i = 0 TO upper
		asm$[i] = HEX$(addr,8) + "  " + XxxDisassemble64$ (@addr, $$TRUE)  '*cw* 230306-
'		asm$[i] = HEX$(addr,9) + "  " + XxxDisassemble64$ (@addr, $$TRUE)  '*cw* 230306+
	NEXT i
	asmAddr = addr
	RETURN ($$FALSE)
END FUNCTION
'
'
' ################################
' #####  DisplayAssembly ()  #####
' ################################
'
FUNCTION  DisplayAssembly (addr$, length$)
'
	Asm (@addr$, @length$, @asm$[])
	upper = UBOUND (asm$[])
	FOR i = 0 TO upper
		PRINT asm$[i]
	NEXT i
END FUNCTION
'
'
' ##############################
' #####  DisplayLocate ()  #####
' ##############################
'
FUNCTION  DisplayLocate (value$)
'
	Locate (@value$, @line$[])
	upper = UBOUND (line$[])
	FOR i = 0 TO upper
		PRINT line$[i]
	NEXT i
END FUNCTION
'
'
' #################################
' #####  DisplayRegisters ()  #####
' #################################
'
FUNCTION  DisplayRegisters (CPUCONTEXT cpu)
'
	reg$ = RegisterString$ ()
	PRINT reg$;
	addr = cpu.rip
	IF AddressOk (addr) THEN
		instruction$ = XxxDisassemble64$ (addr, $$TRUE)
		PRINT " "; HEXX$(addr, 8); ":   "; instruction$
	END IF
END FUNCTION
'
'
' ###################################
' #####  DisplayTestHeaders ()  #####
' ###################################
'
FUNCTION  DisplayTestHeaders ()
	SHARED  teston
'
	IF teston THEN RETURN
	teston = $$TRUE
	TestHeaders ()
	teston = $$FALSE
END FUNCTION
'
'
' ######################
' #####  Dump$ ()  #####
' ######################
'
FUNCTION  Dump$ (addr$, xsize$)
	STATIC  nextaddr
'
	IF addr$  THEN
		IFF LCASE$(LEFT$(addr$,2)) == "0x" THEN
			addr$ = "0x" + addr$
		END IF
	END IF
	IF addr$  THEN addr = XLONG (addr$) ELSE addr = nextaddr
'
	IF xsize$ THEN
		IFF LCASE$(LEFT$(xsize$,2)) == "0x" THEN
			xsize$ = "0x" + xsize$
		END IF
	END IF
	IF xsize$ THEN
		zaddr = addr + (XLONG (xsize$))
	ELSE
		zaddr = addr + 0x0100
	END IF
	addr  = addr  AND NOT 0xF
	zaddr = zaddr AND NOT 0xF
'
	IFZ AddressOk  (addr) THEN
		RETURN ("Invalid start address: " + HEX$ (addr, 8) + "\n" + MemoryMap$())
	END IF
'
	IFZ AddressOk (zaddr-1) THEN
		RETURN ("Invalid end address: " + HEX$ (zaddr, 8) + "\n" + MemoryMap$())
	END IF
'
	line = 0
	ascii$ = SPACE$ (17)
	upper = ((zaddr - addr) >> 4)
	DIM dump$[upper]
	DO
		x = 0
		dump$ = HEX$ (addr, 8) + ":  "
		DO
			e = UBYTEAT (addr)
			byte = addr AND 0x000F
			dump$ = dump$ + HEX$ (e,2) + " "
			IF ((e < 0x20) OR (e > 0x7F)) THEN e = '.'
			ascii${byte+x} = e
			INC addr
			IFZ (addr AND 0x07) THEN x = 1 : dump$ = dump$ + " "
		LOOP WHILE (addr AND 0x000F)
		dump$[line] = dump$ + ascii$
		INC line
	LOOP WHILE (addr < zaddr)
	DEC line
	IF (line != upper) THEN REDIM dump$[line]
	XstStringArrayToString (@dump$[], @dump$)
	nextaddr = addr
	RETURN (dump$)
END FUNCTION
'
'
' ##########################
' #####  DumpLong$ ()  #####
' ##########################
'
FUNCTION  DumpLong$ (addr$, xsize$)
	STATIC  nextaddr
'
	IF addr$  THEN addr = XLONG ("0x" + addr$) ELSE addr = nextaddr
	IF xsize$ THEN zaddr = addr + XLONG ("0x" + xsize$) ELSE zaddr = addr + 0x0100
	addr = addr AND NOT 0xF
	zaddr = zaddr AND NOT 0xF
'
	IFZ AddressOk  (addr) THEN
		RETURN ("Invalid start address: " + HEX$ (addr, 16) + "\n" + MemoryMap$())
	END IF
'
	IFZ AddressOk (zaddr-1) THEN
		RETURN ("Invalid end address: " + HEX$ (zaddr, 16) + "\n" + MemoryMap$())
	END IF
'
	line = 0
	ascii$ = SPACE$ (17)
	upper = ((zaddr - addr) >> 4)
	DIM dump$[upper]
	DO
		x = 0
		dump$ = HEX$ (addr, 16) + ":  "
		long$ = "           "
		DO
			e = UBYTEAT (addr)
			byte = addr AND 0x000F
			dump$ = dump$ + HEX$ (e,2) + " "
			long$ = HEX$ (e,2) + long$
			IF ((e < 0x20) OR (e > 0x7F)) THEN e = '.'
			ascii${byte+x} = e
			INC addr
			IFZ (addr AND 0x7) THEN long$ = "  " + long$
			IFZ (addr AND 0x7) THEN x = 1 : dump$ = dump$ + " "
		LOOP WHILE (addr AND 0x000F)
		dump$ = STUFF$(dump$, long$, 20, 49)
		dump$[line] = dump$ + ascii$
		INC line
	LOOP WHILE (addr < zaddr)
	DEC line
	IF (line != upper) THEN REDIM dump$[line]
	XstStringArrayToString (@dump$[], @dump$)
	nextaddr = addr
	RETURN (dump$)
END FUNCTION
'
'
' ###########################
' #####  DumpXlong$ ()  #####
' ###########################
'
FUNCTION  DumpXlong$ (addr$, xsize$)
	STATIC  nextaddr
'
	IF addr$  THEN
		IFF LCASE$(LEFT$(addr$,2)) == "0x" THEN
			addr$ = "0x" + addr$
		END IF
	END IF
	IF addr$  THEN addr = XLONG (addr$) ELSE addr = nextaddr
'
	IF xsize$ THEN
		IFF LCASE$(LEFT$(xsize$,2)) == "0x" THEN
			xsize$ = "0x" + xsize$
		END IF
	END IF
	IF xsize$ THEN
		zaddr = addr + (XLONG (xsize$) * 8) + 8
	ELSE
		zaddr = addr + 0x0100
	END IF
'
	addr = addr AND NOT 0xF
	zaddr = zaddr AND NOT 0xF
'
	PRINT "DumpXlong$(31)", HEXX$(addr)
	IFZ AddressOk  (addr) THEN
		RETURN ("Invalid start address: " + HEX$ (addr, 16) + "\n" + MemoryMap$())
	END IF
'
	IFZ AddressOk (zaddr-1) THEN
		RETURN ("Invalid end address: " + HEX$ (zaddr, 16) + "\n" + MemoryMap$())
	END IF
'
	line = 0
	ascii$ = SPACE$ (17)
	upper = ((zaddr - addr) >> 4)
	DIM dump$[upper]
	DO
		x = 0
		dump$ = HEX$ (addr, 8) + ":"
		long0 = XLONGAT(addr)
		long8 = XLONGAT(addr+8)
		long$ = "  " + HEX$(long0,16)
		long$ = long$ + "  " + HEX$(long8,16)
		DO
			e = UBYTEAT (addr)
			byte = addr AND 0x000F
			IF ((e < 0x20) OR (e > 0x7F)) THEN e = '.'
			ascii${byte+x} = e
			INC addr
			IFZ (addr AND 0x7) THEN x = 1 ' : dump$ = dump$ + " "
		LOOP WHILE (addr AND 0x000F)
		dump$ = dump$ + long$
		dump$[line] = dump$ + "  " + ascii$
		INC line
	LOOP WHILE (addr < zaddr)
	DEC line
	IF (line != upper) THEN REDIM dump$[line]
	XstStringArrayToString (@dump$[], @dump$)
	nextaddr = addr
	RETURN (dump$)
END FUNCTION
'
'
' ##############################
' #####  DynoLinkCheck ()  #####
' ##############################
'
'  array headers look like this:
'
'   word3 = info.word = info.byte + data.type.byte + bytes.per.element.word
'   word2 = upper.bound of this dimension
'   word1 = address downlink  (MSb = 1 if chunk allocated (new 01-June-93)
'   word0 = address uplink
'
'  info word bits:
'   bit 31 = NO LONGER USED (the next line is obsolete)
'   bit 31 = ALLOCATED      (must always = 1 on allocated chunks)
'       bit 30 = ARRAY BIT      (1 = array, 0 = string)
'   bit 29 = NON-LOW-DIM    (1 = non-lowest-dimension, 0 = lowest dimension)
'   bit 28 =
'   bit 27 =
'   bit 26 =
'   bit 25 =
'   bit 24 = INFOMASK       (1 = USER array, 0 = SYSTEM array)
'
FUNCTION  DynoLinkCheck ()
	STATIC heads[]
	$HdrSize = 0x20
'
	IFZ heads[] THEN DIM heads[1000]
	headaddr = ##DYNO
	upLink = XLONGAT (headaddr)
	DO
		headaddr = headaddr + upLink
		prevUpLink = upLink
		prevDnLink = dnLink
		prevUbound = ubound
		prevInfoWd = infoWd
		upLink = XLONGAT (headaddr)
		dnLink = XLONGAT (headaddr, [1])
		ubound = XLONGAT (headaddr, [2])
		infoWd = XLONGAT (headaddr, [3])
		dnValue = MAKE(dnLink, 31, 0)
		IF (dnValue <> prevUpLink) THEN
			PRINT "DynoLinkCheck", HEXX$(headaddr)
			PRINT HEXX$(prevUpLink,16), HEXX$(prevDnLink,16), HEXX$(prevUbound,16), HEXX$(prevInfoWd,16)
			PRINT HEXX$(upLink,16), HEXX$(dnLink,16), HEXX$(ubound,16), HEXX$(infoWd,16)
			RETURN
		END IF

	LOOP WHILE (upLink && (headaddr <##DYNOX))
	PRINT "DynoLinkCheck : done"
'
END FUNCTION
'
'
' #####################
' #####  Fill ()  #####
' #####################
'
FUNCTION  Fill (addr$, xsize$, value$)
'
	IF LEN(addr$) THEN addr = XLONG("0x" + addr$) ELSE RETURN (0)
	IF LEN(xsize$) THEN zaddr = addr + XLONG("0x" + xsize$) ELSE zaddr = addr + 0x0100
	value = XLONG("0x" + value$)
'
	IF (value AND NOT 0xFF) THEN RETURN (-1)
	IFZ AddressOk (addr) THEN RETURN (addr)
	IFZ AddressOk (zaddr) THEN RETURN (zaddr)
'
	DO WHILE (addr < zaddr)
		UBYTEAT (addr) = value
		INC addr
	LOOP
END FUNCTION
'
'
' ########################
' #####  Frames$ ()  #####
' ########################
'
FUNCTION  Frames$ ()
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
'
	frames$ = ""
	XxxGetRbpRsp (@frame, @stack)
	DO WHILE (frame < ##STACKX)
		funcAddress = XLONGAT(frame,8)                  ' return address in calling function
'		frames$ = frames$ + HEX$(funcAddress,8) + "\n"                                       '*cw* 230306-
		frames$ = frames$ + HEX$(funcAddress,9) + "\n"                                       '*cw* 230306+
		frame = XLONGAT(frame)                          ' calling frame address = [frame]
	LOOP
	RETURN (frames$)
END FUNCTION
'
'
' ##################
' #####  G ()  #####
' ##################
'
FUNCTION  G (addr$)
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
	SHARED  lockOutEnvironment
	FUNCADDR	func ()
'
	IFZ addr$ THEN addr$ = HEX$(##UCODE0)
	x = INSTR (addr$, "x")
	IFZ x THEN addr$ = "0x" + addr$
	func = XLONG (addr$)
	IF ##UCODE THEN @func ()
	lockOutEnvironment = $$TRUE
END FUNCTION
'
'
' ###################
' #####  Go ()  #####
' ###################
'
FUNCTION  Go ()
	SHARED  lockOutEnvironment
'
	XxxXBasic ()
	lockOutEnvironment = $$TRUE
END FUNCTION
'
'
' #######################
' #####  Locate ()  #####
' #######################
'
FUNCTION  Locate (value$, line$[])
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
'	ULONG  addr,  zaddr
'
	line = 0
	upper = 255
	DIM line$[upper]
'
	IFZ value$ THEN RETURN
	x = INSTR (value$, "x")
	IFZ x THEN value$ = "0x" + value$
	valueLen = LEN(value$)
	ubytes = ((valueLen-1)/2)-1
	DIM bytes@@[ubytes]
	value = XLONG (value$)
	FOR i = 0 TO ubytes
		shift = i * 8
		bytes@@[i] = value >> shift AND 0xFF
	NEXT i
'
'	addr = ##DATA0
'	zaddr = ##DATAZ  '*cw* 150228+
'	GOSUB Locate     '*cw* 150228+
'	addr = ##UCODE0
'	zaddr = ##UCODEZ
'	GOSUB Locate
'	addr = ##STACK0
'	zaddr = ##STACKZ
'	GOSUB Locate
'
'
	addr = ##DYNO0
	zaddr = ##DYNOZ
	GOSUB Locate
	REDIM line$[line]
	RETURN
'
SUB Locate
	found = 0
	value0 = bytes@@[0]
	DO WHILE (addr < zaddr)
		a = UBYTEAT (addr)
		IF (a = value0) THEN
			GOSUB CheckMore
		END IF
		INC addr
	LOOP
	IF found THEN
		IF loc$ THEN
			IF (line > upper) THEN upper = upper + 256 : REDIM line$[upper]
			line$[line] = loc$
			loc$ = ""
			INC line
		END IF
	END IF
END SUB
'
'
'
SUB CheckMore
	FOR i = 1 TO ubytes
		a = UBYTEAT (addr+i)
		IF (a <> bytes@@[i]) THEN
			EXIT SUB
		END IF
	NEXT i
	IF (addr = &bytes@@) THEN
		EXIT SUB                'just found myself
	END IF
	INC found
	IFZ found{3,0} THEN
		IF (line > upper) THEN upper = upper + 256 : REDIM line$[upper]
		line$[line] = loc$ + HEX$ (addr, 8)
		loc$ = ""
		INC line
	ELSE
		loc$ = loc$ + HEX$(addr, 8) + " "
	END IF
END SUB
'
END FUNCTION
'
'
' ###########################
' #####  MemoryMap$ ()  #####
' ###########################
'
FUNCTION  MemoryMap$ ()
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
'
'	Set current stack bottom if lowest yet
'
	XxxGetRbpRsp (@frame, @stack)
'
	##STACK = frame
	##STACK0 = ##STACK AND 0xFFFFF000
'
	m1$ = "SECTION   PAGE BASE   LOW ADDR    HIGH ADDR   NEXT PAGE\n"
	m2$ = "  CODE    " + HEX$(##CODE0, 8)  + "    " + HEX$(##CODE, 8)  + "    " + HEX$(##CODEX, 8)  + "    " + HEX$(##CODEZ, 8) + "\n"
	m3$ = "  DATA    " + HEX$(##DATA0, 8)  + "    " + HEX$(##DATA, 8)  + "    " + HEX$(##DATAX, 8)  + "    " + HEX$(##DATAZ, 8) + "\n"
	m4$ = "   BSS    " + HEX$(##BSS0, 8)   + "    " + HEX$(##BSS, 8)   + "    " + HEX$(##BSSX, 8)   + "    " + HEX$(##BSSZ, 8) + "\n"
	m5$ = "  DYNO    " + HEX$(##DYNO0, 8)  + "    " + HEX$(##DYNO, 8)  + "    " + HEX$(##DYNOX, 8)  + "    " + HEX$(##DYNOZ, 8) + "\n"
	m6$ = " UCODE    " + HEX$(##UCODE0, 8) + "    " + HEX$(##UCODE, 8) + "    " + HEX$(##UCODEX, 8) + "    " + HEX$(##UCODEZ, 8) + "\n"
	m7$ = " STACK    " + HEX$(##STACK0, 8) + "    " + HEX$(##STACK, 8) + "    " + HEX$(##STACKX, 8) + "    " + HEX$(##STACKZ, 8)
	RETURN (m1$ + m2$ + m3$ + m4$ + m5$ + m6$ + m7$)
END FUNCTION
'
'
' ###########################
' #####  Substitute ()  #####
' ###########################
'
FUNCTION  Substitute (addr$)
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
	STATIC  subAddr
'
	IFZ subAddr THEN subAddr = ##DATA0
	IFZ addr$ THEN addr = subaddr
	x = INSTR (addr$, "x")
	IFZ x THEN addr$ = "0x" + addr$
	addr = XLONG (addr$)
'
	DO
		IFZ AddressOk (addr) THEN PRINT MemoryMap$() : RETURN (addr)
		a = UBYTEAT (addr)
		PRINT HEX$(addr, 8); ": "; HEX$(a, 2);
		x$ = INLINE$(" >> ")
		SELECT CASE x$
			CASE "q" :  RETURN (0)
'			CASE "*" :  addr = a				: DO LOOP
'			CASE "-" :  addr = addr - a	: DO LOOP
'			CASE "+" :  addr = addr + a	: DO LOOP
'			CASE "." :  addr = addr - 4	: DO LOOP
'			CASE ""  :  addr = addr + 4	: DO LOOP
			CASE ""  :  INC addr				: DO LOOP
		END SELECT
'
		lc = x${0}
		IF (((lc >= '0') AND (lc <= '9')) || ((lc >= 'A') AND (lc <= 'F')) || ((lc >= 'a') AND (lc <= 'f'))) THEN
			x = INSTR (x$, "x")
			IFZ x THEN x$ = "0x" + x$
			value = XLONG (x$)
			IF ((addr >= ##CODE0) AND (addr <= ##CODEZ)) THEN
				PRINT "Can't write code area"
			ELSE
				UBYTEAT (addr) = value
				INC addr
			END IF
		END IF
	LOOP
	subAddr = addr
END FUNCTION
'
'
' #######################
' #####  UserGo ()  #####
' #######################
'
'	Entry assumes:
'  Compilation up to date
'  ##USERRUNNING = $$FALSE
'  ##SIGNALACTIVE = $$FALSE
'
FUNCTION  UserGo ()
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  defaultDirectory$
	SHARED  environmentActive
	SHARED  userGoFrame
	SHARED  exception
'
	XstSetCurrentDirectory (@defaultDirectory$)			' reset to original working directory
	BreakProgrammer ($$BreakInstallAll, 0, 0)
'
'	MakeUserCodeRX()																' NT/SCO : not required
'
	XxxGetRbpRsp (@userGoFrame, @userStackAddr)
'	PRINT "UserGo()	: Frame Address = "; HEX$(userGoFrame, 8)
'	PRINT "UserGo()	: Go to user program"
'
	##USERRUNNING = $$TRUE
	IF environmentActive THEN
		SetCurrentStatus ($$StatusRunning, 0)
		ResetDataDisplays ($$InitiatingRun)
		##LOCKOUT = $$FALSE                      ' make sure lockout not set when user program starts
	END IF
	' Reset Xgr User-mode variables
	XxxXgrResetUserMode()
'
	exception = 0
'
'	Enable the Alarm to handle event dispatches
'	SetAlarm (100)								' Preset alarm (UNUSED IN NT)
	ClearRegisters ()							' Clear ##REG[], ##ALARMREG[]
	##TRAPVECTOR = 510						' Default trap is normal breakpoint
'																' ********************************
	XxxG ()												' *****  GO TO USER PROGRAM  *****
'																' ********************************
	##BLOWBACK = $$TRUE
	UserBlowback ()								' call Blowback in user program if one exists
	##BLOWBACK = $$FALSE
	##WHOMASK = 0									' System whomask
'
'	Disable the Alarm
'
'	SetAlarm (0)									' NT/SCO : not required
	ClearRegisters ()
	##USERRUNNING = $$FALSE
'
	XxxGetRbpRsp (@frame, @stack)
'	PRINT "UserGo() : Frame Address = "; HEX$(frame,8)
'	PRINT "UserGo() : Back from user program"
'
'	MakeUserCodeRW()							' NT/SCO : not required
'
	BreakPatch()
	BreakInternal ($$BreakRemoveAll, 0, 0, 0)
'
	XxxCloseAllUser ()															' Close all user file handles
'
	IF environmentActive THEN
		ResetDataDisplays (0)					' assy still ok
		XuiSendMessage (##CONGRID, #Update, 0, 0, 0, 0, 0, 0)
		##BLOWBACK = $$TRUE						'
		XxxXstBlowback ()							' Blowback USER standard library (timers)
		XxxXinBlowback ()							' Blowback USER sockets library (sockets)
		XxxXuiBlowback ()							' Blowback USER GuiDesigner data
		XxxXgrBlowback ()							' Blowback USER GraphicsDesigner data           ' xgr after xui
		XxxXntBlowback ()             ' Blowback USER libraries (call Blowback() in user DLLs)
		FreeAliens ()
'		FindAliensCfunc ()         '*cw* 210906-
		ClearRuntimeError ()
		##BLOWBACK = $$FALSE
	END IF
'
END FUNCTION
'
'
' ##########################
' #####  AddressOk ()  #####
' ##########################
'
FUNCTION  AddressOk (address)
'
	addr = address
	XxxGetRbpRsp (@frame, @stack)
'
	##STACK = frame
	stack0 = ##STACK AND NOT 0xFFF
	IF (stack0 < ##STACK0) THEN ##STACK0 = stack0
'
	IF ((addr >= ##CODE0)  AND (addr < ##CODEZ))  THEN RETURN (##CODEZ)
	IF ((addr >= ##UCODE0) AND (addr < ##UCODEZ)) THEN RETURN (##UCODEZ)
	IF ((addr >= ##DATA0)  AND (addr < ##DATAZ))  THEN RETURN (##DATAZ)
	IF ((addr >= ##BSS0)   AND (addr < ##BSSZ))   THEN RETURN (##BSSZ)
	IF ((addr >= ##DYNO0)  AND (addr < ##DYNOZ))  THEN RETURN (##DYNOZ)
	IF ((addr >= ##STACK0) AND (addr < ##STACKZ)) THEN RETURN (##STACKZ)
	RETURN ($$FALSE)
END FUNCTION
'
'
' ###############################
' #####  ChangeRegister ()  #####
' ###############################
'
FUNCTION  ChangeRegister (reg[], arg0$, arg1$)
'
	arg0$ = LCLIP$(arg0$, 1)
	IF arg0$ THEN arg0  = XLONG(arg0$) ELSE PRINT "Bad register spec": EXIT FUNCTION
	IF arg1$ THEN arg1  = XLONG("0x" + arg1$) ELSE PRINT "Need value": EXIT FUNCTION
	IF (arg0 > 31) THEN PRINT "Bad register spec": EXIT FUNCTION
	IF (arg0 <  0) THEN PRINT "Bad register spec": EXIT FUNCTION
	reg[arg0] = arg1
END FUNCTION
'
'
' ###############################
' #####  ClearRegisters ()  #####
' ###############################
'
FUNCTION  ClearRegisters ()
'
	upper = UBOUND (##REG[])
	DO WHILE (i < upper)
		##ALARMREG[i] = 0
		##REG[i] = 0
		INC i
	LOOP
END FUNCTION
'
'
' ###########################
' #####  ParseLine$ ()  #####
' ###########################
'
FUNCTION  ParseLine$ (line$, a$[])
'
	arg = 0
	DIM a$[]
	IFZ line$ THEN RETURN ("")
'
	off = 0
	slot = -1
	upper = 7
	DIM a$[upper]
	DO
		arg$ = XstNextField$ (@line$, @off, @done)
		IF arg$ THEN
			INC slot
			IF (slot > upper) THEN
				upper = upper + 8
				REDIM a$[upper]
			END IF
			a$[slot] = arg$
		END IF
	LOOP UNTIL done
	REDIM a$[slot]
	RETURN (a$[0])
END FUNCTION
'
'
' ################################
' #####  RegisterString$ ()  #####
' ################################
'
FUNCTION  RegisterString$ ()
	SHARED  CPUCONTEXT  cpu
	STATIC  reg$[]
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	DIM reg$[3]
'
'	reg$[0] = " rax: " + HEX$(cpu.rax,16) + "  rdi: " + HEX$(cpu.rdi,16)  + "  rip: " + HEX$(cpu.rip,16)  + "   es: " + HEX$(cpu.es,16)
'	reg$[1] = " rbx: " + HEX$(cpu.rbx,16) + "  rsi: " + HEX$(cpu.rsi,16)  + " trap: " + HEX$(cpu.trap,16) + "   fs: " + HEX$(cpu.fs,16)
'	reg$[2] = " rcx: " + HEX$(cpu.rcx,16) + "  rbp: " + HEX$(cpu.rbp,16)  + "   cs: " + HEX$(cpu.cs,16)   + "   gs: " + HEX$(cpu.gs,16)
'	reg$[3] = " rdx: " + HEX$(cpu.rdx,16) + "  rsp: " + HEX$(cpu.ursp,16) + "   ds: " + HEX$(cpu.ds,16)   + "   ss: " + HEX$(cpu.ss,16)
'
	reg$[0] = " rax: " + HEX$(cpu.rax,16) + "  rdi: " + HEX$(cpu.rdi,16)  + "  rip: " + HEX$(cpu.rip,16)
	reg$[1] = " rbx: " + HEX$(cpu.rbx,16) + "  rsi: " + HEX$(cpu.rsi,16)  + " trap: " + HEX$(cpu.trap,16)
	reg$[2] = " rcx: " + HEX$(cpu.rcx,16) + "  rbp: " + HEX$(cpu.rbp,16)  + "   cs: " + HEX$(cpu.cs,16)
	reg$[3] = " rdx: " + HEX$(cpu.rdx,16) + "  rsp: " + HEX$(cpu.rsp,16)  + "   ss: " + HEX$(cpu.ss,16)
'
'	XLONG   .ct0
'	XLONG   .ct1
'	XLONG   .ct2
'	XLONG   .ct3
'	XLONG   .ct4
'	XLONG   .r8
'	XLONG   .r9
'	XLONG   .r10
'	XLONG   .r11
'	XLONG   .r12
'	XLONG   .r13
'	XLONG   .r14
'	XLONG   .r15
'
'
'
'
'
'
'
'
'
'	XLONG   .rflags
'	XLONG   .cs
'	XLONG   .ss
'	XLONG   .trap        '????????

'
	XstStringArrayToString (@reg$[], @reg$)
	##WHOMASK = whomask
	RETURN (reg$)
END FUNCTION
'
'
' #####################
' #####  Xarg ()  #####
' #####################
'
FUNCTION  Xarg (retstr$)
'
	IFZ retstr$ THEN RETURN (0)
	firstChar = retstr${0}
	IF (firstChar = '"') THEN
		lastChar = retstr${UBOUND(retstr$)}
		IF (lastChar = '"') THEN
			retstr$ = MID$(retstr$, 2, LEN(retstr$) - 2)
			RETURN  (&retstr$)
		END IF
	END IF
	IF ((firstChar < '0') OR (firstChar > '9')) THEN
		RETURN  (&retstr$)
	ELSE
		retval = XLONG(retstr$)
		RETURN  (retval)
	END IF
END FUNCTION
'
'
' #######################
' #####  XXfree ()  #####
' #######################
'
FUNCTION  XXfree (addr)
	retval = free (addr)
	PRINT HEX$(retval, 8)
	RETURN (retval)
END FUNCTION
'
'
' #########################
' #####  XXmalloc ()  #####
' #########################
'
FUNCTION  XXmalloc (bytes)
	retval = malloc (bytes)
	PRINT HEX$(retval, 8)
	RETURN (retval)
END FUNCTION
'
'
' #########################
' #####  XXcalloc ()  #####
' #########################
'
FUNCTION  XXcalloc (bytes)
	retval = calloc (bytes)
	PRINT HEX$(retval, 8)
	RETURN (retval)
END FUNCTION
'
'
' ##########################
' #####  XXrealloc ()  #####
' ##########################
'
FUNCTION  XXrealloc (addr, bytes)
	retval = realloc (addr, bytes)
	PRINT HEX$(retval, 8)
	RETURN (retval)
END FUNCTION
'
'
' #############################
' #####  CountHeaders ()  #####
' #############################
'
FUNCTION  CountHeaders ()
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
	STATIC  freeChunks[],  freeBins[]
'
	IFZ freeChunks[] THEN
		DIM freeChunks[16]
'		DIM freeBins[255,4]
	END IF
	FOR i = 0 TO 16
		freeChunks[i] = 0
	NEXT i
'	FOR i = 0 TO 255
'		FOR j = 0 TO 4
'			freeBins[i,j] = 0
'		NEXT j
'	NEXT i
'	iFree = 0
'
'	base		= ##BSSZ									' 88k
'	first		= base + 0x6000
	first		= ##DYNO0									' NT
	addr		= first
	count		= 0	: totalSize		= 0
	free		= 0	: freeSize		= 0
	raw			= 0	: rawSize			= 0
	whoraw	= 0	: whorawSize	= 0
	user		= 0	: userSize		= 0
	norm		= 0	: normSize		= 0
	up			= XLONGAT (addr)
	DO WHILE (up)
		INC count
		blockLength = XLONGAT (addr)
		totalSize = totalSize + blockLength
		word1 = XLONGAT (addr, [1])
		word3	= XLONGAT (addr, [3])
		SELECT CASE TRUE
			CASE !(word1 AND 0x80000000)
					INC free
					freeSize = freeSize + blockLength
					i = blockLength - 0x20
					IF (i < 0) THEN i = 0
					i = i >> 4
					IF (i > 16) THEN i = 16
					INC freeChunks[i]
'					IF (i = 16) THEN
'						IF (iFree < 256) THEN
'							freeBins[iFree,0] = addr
'							freeBins[iFree,1] = XLONGAT(addr)
'							freeBins[iFree,2] = word1
'							freeBins[iFree,3] = XLONGAT(addr, [2])
'							freeBins[iFree,4] = word3
'							INC iFree
'						END IF
'					END IF
			CASE (word3 = 0x80000001)
					INC raw
					rawSize = rawSize + blockLength
			CASE (word3 = 0x00000001)
					INC raw
					rawSize = rawSize + blockLength
			CASE (word3 = 0x81000001)
					INC whoraw
					whorawSize = whorawSize + blockLength
			CASE (word3 = 0x01000001)
					INC whoraw
					whorawSize = whorawSize + blockLength
			CASE (word3 AND 0x01000000)
					INC user
					userSize = userSize + blockLength
			CASE ELSE
					INC norm
					normSize = normSize + blockLength
		END SELECT
		addr	= addr + up
		up		= XLONGAT (addr)
	LOOP
	whorawSize = whorawSize >> 10
	userSize = userSize >> 10
	freeSize = freeSize >> 10
	rawSize = rawSize >> 10
	normSize = normSize >> 10
	totalSize = totalSize >> 10
	PRINT
'	IF iFree THEN
'		DEC iFree
'		a$ = "Free headers in bin 17:\n"
'		FOR i = 0 TO iFree
'			a$ = a$ + "  " + STRING(i) + ")  " + HEX$(freeBins[i,0],8) + ":"
'			FOR j = 1 TO 4
'				a$ = a$ + "  " + HEX$(freeBins[i,j],8)
'			NEXT j
'			a$ = a$ + "\n"
'		NEXT i
'		PRINT a$
'	END IF
	PRINT "whoraw = "; whoraw;	TAB(18); whorawSize; " Kb"
	PRINT "user   = "; user;		TAB(18); userSize
	PRINT "free   = "; free;		TAB(18); freeSize,,
	free$ = "  "
	FOR i = 0 TO 16
		free$ = free$ + STR$(freeChunks[i])
	NEXT i
	PRINT free$
	PRINT "raw    = "; raw;			TAB(18); rawSize
	PRINT "norm   = "; norm;		TAB(18); normSize
	PRINT "TOTAL  = "; count;		TAB(18); totalSize
END FUNCTION
'
'
' ########################
' #####  Headers ()  #####
' ########################
'
FUNCTION  Headers (dpoint, headaddr)
'
	FOR i = 0 TO 3
		a = XLONGAT (dpoint, 0x0000)
		b = XLONGAT (dpoint, 0x0004)
		c = XLONGAT (dpoint, 0x0008)
		d = XLONGAT (dpoint, 0x000C)
		PRINT HEX$(dpoint, 8); ":  ";
		PRINT HEX$(a, 8); "  "; HEX$(b, 8); "  "; HEX$(c, 8); "  "; HEX$(d, 8)
		dpoint = dpoint + 0x0010
	NEXT i
	a = XLONGAT (dpoint)
	PRINT     HEX$(dpoint, 8); ":  ";
	PRINT     HEX$(a, 8)
	DO
		a = XLONGAT (headaddr, 0x0000)
		b = XLONGAT (headaddr, 0x0004)
		c = XLONGAT (headaddr, 0x0008)
		d = XLONGAT (headaddr, 0x000C)
		PRINT HEX$(headaddr, 8); ":  ";
		PRINT HEX$(a, 8); "  "; HEX$(b, 8); "  "; HEX$(c, 8); "  "; HEX$(d, 8)
		headaddr = headaddr + a
	LOOP WHILE a
END FUNCTION
'
'
' ##############################
' #####  MissingHeader ()  #####
' ##############################
'
FUNCTION  MissingHeader (addr, heads[], limit)
'
	DO
		IF heads[a] = addr THEN RETURN (0)
		INC a
	LOOP UNTIL (a > limit)
	RETURN ($$TRUE)
END FUNCTION
'
'
' ############################
' #####  PrintHeader ()  #####
' ############################
'
FUNCTION  PrintHeader (addr, ua, da, ul, dl)
	PRINT HEX$(addr, 8); ":  "; HEX$(ua,  8);  "  ";  HEX$(da,  8); "  "; HEX$(ul,  8); "  "; HEX$(dl,  8)
END FUNCTION
'
'
' ############################
' #####  TestHeaders ()  #####
' ############################
'
FUNCTION  TestHeaders ()
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
	SHARED  tempo[],  heads[],  teston,  testdibs
	STATIC  uhead,  firstentry
'
	IFZ teston THEN RETURN
	IF testdibs THEN RETURN
	testdibs = $$TRUE
'
	IFZ firstentry THEN
		uhead = UBOUND(heads[])
		firstentry = $$TRUE
	END IF
'
	headaddr = ##DYNO
	header = 0
'
	DO
		upLink = XLONGAT (headaddr)
		headaddr = headaddr + upLink
		IF (headaddr < ##DYNO) THEN
			GOSUB PrintHeader
			GOSUB PrintTable
			PRINT "Uplink corrupted..."
			testdibs = $$FALSE
			RETURN
		END IF
		IF (headaddr > ##DYNOZ) THEN
			GOSUB PrintHeader
			GOSUB PrintTable
			PRINT "Uplink corrupted..."
			testdibs = $$FALSE
			RETURN
		END IF
		INC header
		IFZ upLink THEN EXIT DO
	LOOP
'
	IF (uhead < header+1) THEN
		DIM heads[header+4]
	END IF
	headaddr = ##DYNO
	header = 0
'
	DO
		upLink = XLONGAT (headaddr)
		heads[header] = headaddr
		headaddr = headaddr + upLink
		INC header
		IFZ upLink THEN EXIT DO
	LOOP
	count = header - 1
'
	FOR entry = 0 TO count
		headaddr = heads[entry]												' address of M
		upAddr		= XLONGAT (headaddr, [0])						' word 0 of M
		adownAddr	= XLONGAT (headaddr, [1])						' word 1 of M
		upLink		= XLONGAT (headaddr, [2])						' word 2 of M
		downLink	= XLONGAT (headaddr, [3])						' word 3 of M
		downAddr	= adownAddr AND 0x7FFFFFFF					' remove allocated bit
		table = (upAddr - 0x20) >> 4									' table# of M
		IF (table > 16) THEN table = 16
		tableAddr = XLONGAT (##DATA, [table])					' tableAddr of M
'
		IF upAddr THEN
			upper = headaddr + upAddr										' address of H
			upAddrx			= XLONGAT (upper, [0])					' word 0 of H
			adownAddrx	= XLONGAT (upper, [1])					' word 1 of H
			upLinkx			= XLONGAT (upper, [2])					' word 2 of H
			downLinkx		= XLONGAT (upper, [3])					' word 3 of H
			downAddrx		= adownAddrx AND 0x7FFFFFFF			' remove allocated bit
			IF upAddrx THEN
				xupper = upper + upAddrx									' address of HH
				xupAddrx		= XLONGAT (xupper, [0])				' word 0 of HH
				axdownAddrx	= XLONGAT (xupper, [1])				' word 1 of HH
				xupLinkx		= XLONGAT (xupper, [2])				' word 2 of HH
				xdownLinkx	= XLONGAT (xupper, [3])				' word 3 of HH
				xdownAddrx	= axdownAddrx AND 0x7FFFFFFF			' remove allocated bit
			END IF
			IF (upAddr != downAddrx) THEN
				ha	= headaddr
				ua	= upAddr
				da	= adownAddr
				ul	= upLink
				dl	= downLink
				up	= upper
				uax	= upAddrx
				dax	= adownAddrx
				ulx	= upLinkx
				dlx	= downLinkx
				PRINT
				PrintHeader (ha, ua, da, ul, dl)
				PrintHeader (up, uax, dax, ulx, dlx)
				PRINT "*****  This addr-upLink != next addr-downlink  *****"
				testdibs = $$FALSE
				RETURN
			END IF
			IF (adownAddr >= 0) AND (adownAddrx >= 0) THEN
				ha	= headaddr
				ua	= upAddr
				da	= adownAddr
				ul	= upLink
				dl	= downLink
				up	= upper
				uax	= upAddrx
				dax	= adownAddrx
				ulx	= upLinkx
				dlx	= downLinkx
				xup	= xupper
				xua	= xupAddrx
				xda	= axdownAddrx
				xul	= xupLinkx
				xdl	= xdownLinkx
				GOSUB PrintTable
				PrintHeader (ha, ua, da, ul, dl)
				PrintHeader (up, uax, dax, ulx, dlx)
				PrintHeader (xup, xua, xda, xul, xdl)
				PRINT "*****  Two free chunks in a row"
				testdibs = $$FALSE
				RETURN
			END IF
		END IF
		IFZ downLink THEN
			IF (headaddr != tableAddr) THEN
				ha	= headaddr
				ua	= upAddr
				da	= adownAddr
				ul	= upLink
				dl	= downLink
				PRINT
				PRINT "Table Pointer #"; table; " = "; HEX$(tableAddr, 8)
				PrintHeader (ha, ua, da, ul, dl)
				PRINT "*****  Size downLink = 0, but table pointer doesn't point here"
				testdibs = $$FALSE
				RETURN
			END IF
		END IF
		IF (adownAddr >= 0) AND (downLink > 0) THEN
			SUinSD = XLONGAT (downLink, [2])
			IF (SUinSD != headaddr) THEN
				ha	= headaddr
				ua	= upAddr
				da	= adownAddr
				ul	= upLink
				dl	= downLink
				PRINT
				PrintHeader (ha, ua, da, ul, dl)
				PRINT "*****  SU addr in SD header doesn't point here  *****"
				testdibs = $$FALSE
				RETURN
			END IF
		END IF
		IF (adownAddr >= 0) AND (upLink > 0) THEN
			SDinSU = XLONGAT (upLink, [3])
			IF (SDinSU != headaddr) THEN
				ha	= headaddr
				ua	= upAddr
				da	= adownAddr
				ul	= upLink
				dl	= downLink
				PRINT
				PrintHeader (ha, ua, da, ul, dl)
				PRINT "*****  SD addr in SU header doesn't point here  *****"
				testdibs = $$FALSE
				RETURN
			END IF
		END IF
		IF (adownAddr > 0) AND (downLink > 0) THEN
			IF (MissingHeader(downLink, @heads[], count)) THEN
				ha	= headaddr
				ua	= upAddr
				da	= adownAddr
				ul	= upLink
				dl	= downLink
				xha	= downLinkenvironment
				xua	= XLONGAT (xha, [0])
				xda	= XLONGAT (xha, [1])
				xul	= XLONGAT (xha, [2])
				xdl	= XLONGAT (xha, [3])
				PRINT
				PrintHeader ( ha,  ua,  da,  ul,  dl)
				PrintHeader (xha, xua, xda, xul, xdl)
				PRINT "*****  SD addr points to invalid/nonexistent header  *****"
				testdibs = $$FALSE
				RETURN
			END IF
		END IF
		IF (adownAddr > 0) AND (upLink > 0) THEN
			IF (MissingHeader(upLink, @heads[], count)) THEN
				ha	= headaddr
				ua	= upAddr
				da	= adownAddr
				ul	= upLink
				dl	= downLink
				xha	= upLink
				xua	= XLONGAT (xha, [0])
				xda	= XLONGAT (xha, [1])
				xul	= XLONGAT (xha, [2])
				xdl	= XLONGAT (xha, [3])
				PRINT
				PrintHeader ( ha,  ua,  da,  ul,  dl)
				PrintHeader (xha, xua, xda, xul, xdl)
				PRINT "*****  SU addr points to invalid/nonexistent header  *****"
				testdibs = $$FALSE
				RETURN
			END IF
		END IF
		IFZ upAddr THEN EXIT FOR
	NEXT entry
	testdibs = $$FALSE
	PRINT "***** "; header; " headers"
	PRINT "*****  DONE  *****"
	RETURN
'
' *****  SUBROUTINES  *****
'
SUB PrintHeader
	aaa = headaddr
'	PRINT HEX$ (aaa, 8); ":  "
	bbb = XLONGAT (headaddr, [0])
	ccc = XLONGAT (headaddr, [1])
	ddd = XLONGAT (headaddr, [2])
	eee = XLONGAT (headaddr, [3])
	PRINT HEX$ (aaa, 8); ":  ";
	PRINT HEX$ (bbb, 8);;;
	PRINT HEX$ (ccc, 8);;;
	PRINT HEX$ (ddd, 8);;;
	PRINT HEX$ (eee, 8)
END SUB
'
SUB PrintTable
	FOR i = 0 TO 16
		tempo[i] = XLONGAT (##DATA, [i])
	NEXT i
	FOR i = 0 TO 16
		PRINT HEX$ (tempo[i], 8);;;
		IF ( i{2,0} = 3 ) THEN PRINT
	NEXT i
	PRINT
END SUB
END FUNCTION
'
'
' ######################
' #####  Break ()  #####
' ######################
'
FUNCTION  Break (command, address)
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
	SHARED  breakAddr[],  breakCode[]
'	ULONG  addr
'
	addr = address
	page = addr AND 0xFFFFF000			' Round down to nearest 4k page
	IF (addr >= ##UCODE0) AND (addr < ##UCODEZ) THEN skipit = $$TRUE
	printErrors = $$TRUE
	SELECT CASE command
		CASE $$BreakSetOne		: GOSUB SetBreakpoint
		CASE $$BreakRemoveOne	: GOSUB RemoveOneBreakpoint
		CASE $$BreakClearOne	: GOSUB ClearBreakpoint
		CASE $$BreakClearAll	: GOSUB ClearAllBreakpoints
		CASE ELSE							: PRINT "Bad command argument to Break(26)"
	END SELECT
	RETURN
'
'
' Set breakpoint at address "addr"
'
SUB SetBreakpoint
	IFZ addr THEN EXIT SUB
	IFZ AddressOk (addr) THEN EXIT SUB
	i =  0
	n = -1
	DO WHILE  (i < 64)
		ba = breakAddr[i]
		IF (ba = addr) THEN
			IF printErrors THEN PRINT "Breakpoint already set at "; HEX$(addr, 8)
			EXIT SUB
		END IF
		IF ((ba = 0) && (n < 0)) THEN n = i		' n = 1st empty array element for info
		INC i
	LOOP
	IF (n < 0) THEN
		IF printErrors THEN PRINT "Can't set breakpoint... too many (64+)"
		EXIT SUB
	END IF
	breakAddr[n] = addr							' store breakpoint address in array
	breakCode[n] = UBYTEAT (addr)		' store opcode at breakpoint addressexception
	UBYTEAT (addr) = $$Breakpoint		' store breakpoint op code in memory
END SUB
'
' Clear breakpoint at address "addr"
'
SUB ClearBreakpoint
	IFZ addr THEN EXIT SUB
	IFZ AddressOk (addr) THEN EXIT SUB
	i = 0
	DO WHILE (i < 64)
		ba = breakAddr[i]
		IF (ba = addr) THEN
			breakTest	= UBYTEAT (addr)
			break = $$Breakpoint
			IF (breakTest = break) THEN
				UBYTEAT (addr) = breakCode[i]
			ELSE
				IF printErrors THEN PRINT "Breakpoint mysteriously vanished!!!"
			END IF
			breakAddr[i] = 0
			breakCode[i] = 0
			EXIT SUB
		ENDIF
		INC i
	LOOP
	IF printErrors THEN PRINT "No breakpoint is set at specified address..."
END SUB
'
'	Remove One Breakpoint
'
SUB RemoveOneBreakpoint
	i = 0
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF ba THEN
			IF (ba = arg1) THEN
				UBYTEAT (ba) = breakCode[i]
				EXIT SUB
			END IF
		END IF
		INC i
	LOOP
END SUB
'
' Clear all breakpoints
'
SUB ClearAllBreakpoints
	printErrors = $$FALSE
	FOR i = 0 TO UBOUND(breakAddr[])
		addr = breakAddr[i]
		IF addr THEN GOSUB ClearBreakpoint
	NEXT i
END SUB
END FUNCTION
'
'
' ##################################
' #####  BreakContinuePrep ()  #####
' ##################################
'
'	BreakContinuePrep() sets up cpu.rip so program execution will
'		continue at "continueAddr" when the top-level function in Xit
'		returns.  It puts the original opcode back at "continueAddr",
'		inspects the opcode to see what kind it is, and on this basis
'		installs breakpoints where required to break program execution
'		after a single instruction.  It logs the addresses and opcodes
'		of these break patches in breakPatchAddr[] and breakPatchCode[],
'		as well as "continueAddr" and the breakpoint opcode that was
'		originally there.
'
FUNCTION  BreakContinuePrep (command, func, continueAddr)
	SHARED  xitGrid
	SHARED  CPUCONTEXT  cpu
'
	IF continueAddr THEN							' no changes if 0
		sxip = continueAddr							' address to continue execution at
		cpu.rip = sxip
	ELSE
		sxip = cpu.rip
	END IF
'
'	PRINT "BreakContinuePrep() : ";
'	PRINT "  sxip = "; HEX$(sxip, 8); " : "; XxxDisassemble64$ (sxip, $$TRUE)
	startAddr = sxip
'
	BreakProgrammer ($$BreakInstallAll, 0, 0)
	SELECT CASE command
		CASE $$BreakContinueRunning
		CASE $$BreakContinueToCursor
					XuiSendMessage (xitGrid, #GetTextCursor, 0, @line, 0, 0, $$xitTextLower, 0)
					BreakInternal ($$BreakInstallOne, func, line, 0)
		CASE $$BreakContinueStepLocal
					BreakInternal ($$BreakInstallFunc, func, 0, 0)
		CASE $$BreakContinueStepGlobal
					BreakInternal ($$BreakInstallAll, 0, 0, 0)
		CASE $$BreakContinueStepOut
					BreakInternal ($$BreakInstallFunc, func, 0, 0)
		CASE ELSE
					PRINT "Bad command to BreakContinuePrep(45)"
	END SELECT
	breakCode	= UBYTEAT (startAddr)
	break = $$Breakpoint
'
	IF (breakCode != break) THEN			' no BP at startAddr to patch around
'		PRINT "BreakContinuePrep(51)  Continue address has no BP to patch around.", HEXX$(breakCode), HEXX$(break), HEXX$(startAddr)
		RETURN
	END IF
'
'	There's a breakpoint at the address we want to start executing at
'
'	PRINT " continue address has a breakpoint : install patches"
'
	BreakProgrammer ($$BreakRemoveOne, startAddr, 0)
	breakTest = UBYTEAT (startAddr)				' NT 1 byte
	IF (breakTest = break) THEN
		opcode = BreakInternal ($$BreakGetFuncLineOpcode, 0, 0, startAddr)
'		PRINT "BreakContinuePrep(63)", HEXX$(breakTest), HEXX$(break), HEXX$(opcode)
		IF (opcode < 0) THEN
			PRINT "  Can't find breakpoint in Internal Arrays either !!!"
			PRINT "  Can't find opcode to overwrite breakpoint at "; HEX$(startAddr, 8)
			PRINT "  This is death... bombing out of BreakContinuePrep(67)"
			EXIT FUNCTION
		ELSE
			UBYTEAT (startAddr) = opcode
		END IF
	ELSE
		opcode = breakTest
	END IF
	BreakPatchLog (startAddr, $$Breakpoint)		' log $$Breakpoint patch
	BreakPatchAll (startAddr)
END FUNCTION
'
'
' ###########################
' #####  BreakPatch ()  #####
' ###########################
'
'	For all non-zero entries in breakPatchAddr[] install the opcode in
'	breakPatchCode[] into memory at the address in breakPatchAddr[].
'
FUNCTION  BreakPatch ()
	SHARED  breakPatchAddr[]
	SHARED  breakPatchCode[]
'
	foundPatches = 0
	upatch = UBOUND(breakPatchAddr[])
	i = 0
'	PRINT "BreakPatch(17)"
	DO UNTIL (i > upatch)
		patchAddr = breakPatchAddr[i]
		IF patchAddr THEN
			INC foundPatches
			patchCode = breakPatchCode[i]				' get original opcode and...
			breakCode = UBYTEAT(patchAddr)			' get breakpoint opcode
'			PRINT "  @"; HEX$(patchAddr, 8); " = "; HEX$(breakCode, 2); " --> "; HEX$(patchCode, 2)
			UBYTEAT (patchAddr) = patchCode			' install original opcode
			breakPatchAddr[i] = 0								' this patch breakpoint is removed
			breakPatchCode[i] = 0								' ditto
		END IF
		INC i
	LOOP
	RETURN (foundPatches)
END FUNCTION
'
'
' ##############################
' #####  BreakPatchAll ()  #####
' ##############################
'
'	Install patch breakpoint over 1st opcode of every source line
'	in program not currently holding a breakpoint (skip startAddr).
'
FUNCTION  BreakPatchAll (startAddr)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN prog[]
	SHARED  lineAddr[]
	SHARED  lineLast[]
	SHARED  breakPatchAddr[]
	SHARED  breakPatchCode[]
'
	i = 0
	uBreak = UBOUND(breakPatchAddr[])
'
	func = 1																' No breakpoints in PROLOG
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO
		lineAddr = lineAddr[func, 0]
		lineLast = lineLast[func]
		line = 0
		firstLine = $$TRUE
		DO UNTIL (line > lineLast)
			nextAddr = lineAddr[func, line + 1]
			IF (lineAddr < nextAddr) THEN				' Skip blank lines/comments
				IF firstLine THEN									' No breakpoints on FUNCTION line
					firstLine = $$FALSE
				ELSE
					opcode = UBYTEAT(lineAddr)
					break = $$Breakpoint
					IF (opcode != break) THEN
						IF (lineAddr != startAddr)
							GOSUB BreakPatchLog
							UBYTEAT (lineAddr) = $$Breakpoint
						END IF
					END IF
				END IF
			END IF
			lineAddr = nextAddr
			INC line
		LOOP
		INC func
	LOOP
	RETURN
'
SUB BreakPatchLog
	DO WHILE (breakPatchAddr[i])
		INC i
	LOOP WHILE (i <= uBreak)
	IF (i > uBreak) THEN
		uBreak = (uBreak + (uBreak >> 1)) OR 7
		REDIM breakPatchAddr[uBreak]
		REDIM breakPatchCode[uBreak]
	END IF
	breakPatchAddr[i] = lineAddr
	breakPatchCode[i] = opcode
END SUB
END FUNCTION
'
'
' ##############################
' #####  BreakPatchLog ()  #####
' ##############################
'
FUNCTION  BreakPatchLog (breakAddr, breakCode)
	SHARED  breakPatchAddr[]
	SHARED  breakPatchCode[]
'
	uBreak = UBOUND(breakPatchAddr[])
	i = 0
	DO WHILE (breakPatchAddr[i])
		INC i
	LOOP WHILE (i <= uBreak)
	IF (i > uBreak) THEN
		uBreak = (uBreak + (uBreak >> 1)) OR 7
		REDIM breakPatchAddr[uBreak]
		REDIM breakPatchCode[uBreak]
	END IF
	breakPatchAddr[i] = breakAddr
	breakPatchCode[i] = breakCode
END FUNCTION
'
'
' ################################
' #####  GetRuntimeError ()  #####
' ################################
'
'	Get the Runtime Error information
'
'	In:				info$			strings passed by reference
'						msg$
'
'	Out:			info$			Info string
'						msg$			Message string
'
'	Return:		showMsg		TRUE		new error to consider
'											FALSE		breakpoint or user interrupt
'
'	Discussion:
'		Labels should be 55 chars max
'
'		SIGTRAP Vectors:
'			511 - unused (because used by 88Open trace utilities--sdb, etc)
'			510 - imbedded breakpoints
'			509 - system call (software interrupt) breakpoints
'			508 - unused
'			507 - Unexpected Higher/Lower Dim	(bounds check)
'			506 -	Need Null Node							(attach)
'			505 - Overflow										(arithmetic/conversion)
'			504 - General purpose							(uses ##ERROR)
'
'		Concept:  - Two standard breakpoint traps (509,510) are required to handle
'									the two types of "continue" (one repeats the last instruction,
'									the other steps over it).
'							- The general purpose trap (504) is invoked with ##ERROR holding
'									the specific error number.
'									If ##ERROR = $$ErrorObjectSystem, errno has OS error#.
'							- Three other vectors (505,506,507) could be merged into the
'									general purpose trap, but are set alone because:
'										- We have the technology (I mean, the vectors are available.)
'										- These error traps are present in code whereever
'												bounds checking, ATTACHing, and type conversion is done.
'												Having unique vectors for these errors reduces code size,
'												code complexity, and number of labels.  It is good.
'
FUNCTION  GetRuntimeError (runtimeInfo$, runtimeMsg$)
	SHARED  exception
	SHARED  CPUCONTEXT  cpu
'
	runtimeInfo$ = " "
	runtimeMsg$ = " "
'
	oldError = $$FALSE
	showMsg  = $$TRUE
	sxip = cpu.rip
'
' Linux in its infinite wisdom, converts and intel "into" (0xCE) instruction
' which is an interrupt 4 if the overflow flag is set, to a SIGSEGV making it
' look like a segment violation. But cpu.trap says it is really an overflow.
'
'	PRINT "GetRuntimeError(60)", exception, cpu.trap, ##TRAPVECTOR, HEXX$(##ERROR), ##WHERE
'	IF (exception == $$ExceptionSegmentViolation) THEN  '*cw* 150302+ 210717-
'		IF (cpu.trap == $$TrapOverflow) THEN              '*cw* 150302+ 210717-
'				exception = $$ExceptionOverflow               '*cw* 150302+ 210717-
'		END IF                                            '*cw* 150302+ 210717-
'	END IF                                              '*cw* 150302+ 210717-
'
	XstExceptionNumberToName (exception, @runtimeMsg$)
	SELECT CASE exception
		CASE $$ExceptionNone
					oldError = $$TRUE
		CASE $$ExceptionSegmentViolation
					##ERROR = (($$ErrorObjectMemory << 8) OR $$ErrorNatureInvalidAccess)
		CASE $$ExceptionOutOfBounds
					##ERROR = (($$ErrorObjectArray << 8) OR $$ErrorNatureInvalidAccess)
		CASE $$ExceptionBreakpoint
					vector = ##TRAPVECTOR									' SIGTRAPs are vectors 504-511
					SELECT CASE TRUE
						CASE (vector = 509), (vector = 510)	' 509, 510 are breakpoint traps
									oldError = $$TRUE
									runtimeMsg$ = " Paused on breakpoint "
									showMsg = $$FALSE
						CASE (vector = 504)									' 504 - General purpose (XERROR)
						CASE (vector < 0)										' < 0 - Windows error
									runtimeMsg$ = " OS error #" + STRING$ (-vector)
						CASE ELSE
									runtimeMsg$ = " ExceptionBreakpoint:  Unknown vector " + STRING$ (vector)
					END SELECT
		CASE $$ExceptionBreakKey
					oldError = $$TRUE
					showMsg = $$FALSE
		CASE $$ExceptionAlignment
					##ERROR = (($$ErrorObjectMemory << 8) OR $$ErrorNatureInvalidAccess)
		CASE $$ExceptionDenormal
					##ERROR = (($$ErrorObjectData << 8) OR $$ErrorNatureInvalidFormat)
		CASE $$ExceptionInvalidOperation
					##ERROR = $$ErrorNatureInvalidOperation
		CASE $$ExceptionDivideByZero
					##ERROR = $$ErrorNatureDivideByZero
		CASE $$ExceptionOverflow
					##ERROR = $$ErrorNatureOverflow
		CASE $$ExceptionStackCheck
					##ERROR = (($$ErrorObjectMemory << 8) OR $$ErrorNatureOverflow)
		CASE $$ExceptionUnderflow
					##ERROR = $$ErrorNatureUnderflow
		CASE $$ExceptionPrivilege
					##ERROR = $$ErrorNaturePrivilege
		CASE $$ExceptionStackOverflow
					##ERROR = (($$ErrorObjectMemory << 8) OR $$ErrorNatureOverflow)
	END SELECT
'
'	PRINT "GetRunTimeError(111)", ##ERROR;; "<"; ERROR$ (##ERROR); ">"
	runtimeInfo$ = " Address " + HEX$(sxip, 8) + ":  " + ERROR$ (##ERROR)
	IF oldError THEN runtimeInfo$ = runtimeInfo$ + "  <== Previous error"
	IF ##XBDV THEN
		IF ##ERROR THEN PRINT runtimeInfo$
		IF ##WHERE THEN PRINT "GetRuntimeError(116):##WHERE", ULONG(##WHERE)
		##WHERE = 0
	END IF
	RETURN (showMsg)
END FUNCTION
'
'
' ################################
' #####  WarningResponse ()  #####
' ################################
'
FUNCTION  WarningResponse (message$, okButton$, optionButton$)
	SHARED  warning2Box,  warning3Box
	FUNCADDR	func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, ANY)
'
	IFZ message$ THEN RETURN
	newline = INSTR (message$, "\n")
'
	IF newline THEN
		left = INSTR (message$, "[")
		right = INSTR (message$, "]")
		IF ((left = 1) AND (right = (newline-1))) THEN
			title$ = MID$ (message$, 2, right-2)
			message$ = MID$ (message$, newline+1)
		END IF
	END IF
'
	func = &XuiMessage2B()
	messageGrid = warning2Box
	IF optionButton$ THEN
		func = &XuiMessage3B()
		messageGrid = warning3Box
	END IF
	IFZ messageGrid THEN PRINT "WarningResponse():No message grid"
'
' Message Window  ( generic message window )
'
	IFZ title$ THEN title$ = " warning "
	@func ( messageGrid, #SetWindowTitle, 0, 0, 0, 0, 0, @title$)
	@func ( messageGrid, #SetTextString, 0, 0, 0, 0, 1, @message$)
	@func ( messageGrid, #SetTextString, 0, 0, 0, 0, 2, @okButton$)
'
	IF optionButton$ THEN
'		@func ( messageGrid, #SetColor, $$BrightGreen, -1, -1, -1, 4, 0)
		@func ( messageGrid, #SetTextString, 0, 0, 0, 0, 3, @optionButton$)
	END IF
'
	@func (messageGrid, #GetSmallestSize, 0, 0, @ww, @hh, 0, 0)
	ww = ww + 16 : hh = hh + 16
'
	width = (#displayWidth >> 1) - #windowBorderWidth - #windowBorderWidth
	height = (#displayHeight >> 2) - #windowTitleHeight
	IF (ww > width) THEN width = ww
	IF (hh > height) THEN height = hh
	xDisp = (#displayWidth >> 1) - (width >> 1) - #windowBorderWidth
	yDisp = (#displayHeight >> 1) - (height >> 1) - #windowBorderWidth
'
	@func ( messageGrid, #ResizeWindow, xDisp, yDisp, width, height, 0, 0)
	@func ( messageGrid, #GetModalInfo, @v0, 0, 0, 0, @reply, 0)
	@func ( messageGrid, #HideWindow, 0, 0, 0, 0, 0, 0)
	XstSleep (200)
'
	IF optionButton$ THEN
		SELECT CASE reply
			CASE 0		:	warningResponse = $$WarningProceed
									IF (v0{$$VirtualKey} = $$KeyEscape) THEN
										warningResponse = $$WarningCancel
									END IF
			CASE 2		:	warningResponse = $$WarningProceed
			CASE 3		:	warningResponse = $$WarningOption
			CASE 4		:	warningResponse = $$WarningCancel
			CASE ELSE	:	PRINT "WarningResponse() : unknown response ="; response
		END SELECT
	ELSE
		SELECT CASE reply
			CASE 0		:	warningResponse = $$WarningProceed
									IF (v0{$$VirtualKey} = $$KeyEscape) THEN
										warningResponse = $$WarningCancel
									END IF
			CASE 2		:	warningResponse = $$WarningProceed
			CASE 3		:	warningResponse = $$WarningCancel
			CASE ELSE	:	PRINT "WarningResponse() : unknown response ="; response
		END SELECT
	END IF
	RETURN (warningResponse)
END FUNCTION
'
'
' #########################
' #####  XitCrash ()  #####
' #########################
'
'  Save text/program file (if any)
'  Write error statistics to stat file
'  Warn user to quit immediately and restart PDE (no guarantees otherwise)
'
FUNCTION  XitCrash (exception, sxip, fatal)
	SHARED  fileType,  xitGrid
	SHARED  processingCrash
	SHARED  saveCRLF
	STATIC  numCrashes
'
	IF (numCrashes > 2) THEN
		PRINT "Too many crashes to continue reliably - must terminate."
		INLINE$ ("  press enter to terminate...")
		XxxXitQuit (1)
	END IF
'
	INC numCrashes
	processingCrash = $$TRUE
	PRINT "\n!!! Environment error !!!   at "; HEX$ (sxip)
'
	INLINE$ (" press enter to save and terminate...")
'
	ofile$ = "xb64.sav"
	SELECT CASE fileType
		CASE $$Text
					XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
					IFZ text$[] THEN EXIT SELECT
					PRINT "  Trying to save current text file as  "; ofile$
					ofile = OPEN (ofile$, $$WRNEW)
					IF (ofile < 0) THEN
						PRINT "    Failed to save:  OPEN failed"
						EXIT SELECT
					END IF
					IF saveCRLF THEN
						XstStringArrayToStringCRLF (@text$[], @text$)		' \r\n
					ELSE
						XstStringArrayToString (@text$[], @text$)				' \n
					END IF
					##ERROR = $$FALSE
					WRITE [ofile], text$
					SELECT CASE TRUE
						CASE ##ERROR	: PRINT "    Failed to save : WRITE failed"
						CASE ELSE			: PRINT "    Saved successfully."
					END SELECT
					CLOSE (ofile)
'					SHELL ("sync &")
'					SetAlarm (0)								' reset and turn off alarm (UNUSED IN NT/SCO)
		CASE ELSE													' Program
					PRINT "  Trying to save current program as  "; ofile$
					ofile = OPEN (ofile$, $$WRNEW)
					IF (ofile < 0) THEN
						PRINT "    Failed to save:  OPEN failed"
						EXIT SELECT
					END IF
					redisplay = $$TRUE
					reportBogusRename = $$TRUE						' tokenize, resets BPs if necessary
					RestoreTextToProg (redisplay, reportBogusRename)
					ConvertProgToText ($$TextString, saveCRLF, $$AbortNotAllowed, @text$)
					##ERROR = $$FALSE
					WRITE [ofile], text$
					SELECT CASE TRUE
						CASE ##ERROR	: PRINT "    Failed to save:  WRITE failed"
						CASE ELSE			: PRINT "    Saved successfully."
					END SELECT
'					SHELL ("sync &")
					CLOSE (ofile)
'					SetAlarm (0)								' reset and turn off alarm (UNUSED IN NT/SCO)
	END SELECT
'
' Tell the bad news
'
	XstExceptionNumberToName (exception, @signal$)
	SELECT CASE fatal
		CASE $$FatalSignalInEnv
			m0$ = "\nEnvironment exception #" + STRING$(exception) + " : " + signal$ + "\n"
		CASE $$FatalSigQuitInAllo
			m0$ = "\nSIGQUIT interrupted memory allocation.\n"
		CASE ELSE
			m0$ = "\nunknown fatal error\n"
	END SELECT
	m1$ = "The PDE is now in an undeterminate state.  Quit the PDE and restart.\n"
	m2$ = "Should this problem persist, consult a representative for assistance.\n"
	message$ = m0$ + m1$ + m2$
	write (1, &message$, LEN(message$))
	PRINT message$
	processingCrash = $$FALSE
END FUNCTION
'
'
' ################################
' #####  AssemblyString$ ()  #####
' ################################
'
' funcNumber and lineNumber exist.  lineAddr[] is up to date.
'		(Environment access only--for displaying status)
'
'		Disassembly is so slow, put END PROGRAM at end of PROLOG instead
'			of entryFunction.
'			Also, save END PROGRAM info in endProgram$[]  (reset in CompileProgram())
'
'		DO: dump END PROGRAM literal strings (between litStringAddr and xpc)
'
FUNCTION  AssemblyString$ (funcNumber, lineNumber)
	EXTERNAL /xxx/  maxFuncNumber,  entryFunction,  litStringAddr,  xpc
	SHARED  TOKEN prog[]
	SHARED  lineAddr[]
	SHARED  lineLast[]
	SHARED  endProgram$[]
	SHARED  softInterrupt
	SHARED  currentCursor
	SHARED  funcFirstAddr[]  '*cw* 230314+
	SHARED  funcAfterAddr[]  '*cw* 230314+
	TOKEN   func[]
	TOKEN   tok[]
	TOKEN   startToken
'
	entryCursor = currentCursor
	softInterrupt = $$FALSE
'
	ATTACH prog[funcNumber,] TO func[]
	ATTACH func[lineNumber,] TO tok[]
	IF tok[] THEN
		startToken = tok[0]														     ' save first token for line
		tok[0].ti.bpexe = $$BPEXECLR                       ' clear BP and EXE
		tok[0].ti.errno = 0                                ' clear error number
		IFZ tok[0].tproto THEN PRINT "AssemblyString$(37)"
		XxxDeparser(@tok[], @asm$)
		asm$ = LTRIM$(asm$) + "\n"
		tok[0] = startToken                                ' restore first token for line
	END IF
	ATTACH tok[] TO func[lineNumber,]
	ATTACH func[] TO prog[funcNumber,]
'
	SELECT CASE startToken.ti.bpexe
		CASE 3	: asm$ = ">: " + asm$					' ExeLine and BP
		CASE 2	: asm$ = ": " + asm$					' BP only
		CASE 1	: asm$ = "> " + asm$					' ExeLine only
	END SELECT
'
	nextAddr = lineAddr[funcNumber, lineNumber]
	lastAddr = lineAddr[funcNumber, lineNumber + 1]
	IF (lastAddr <= nextAddr) THEN									' comment or newline
		codeLines = 0
	ELSE
		codeLines = (lastAddr - nextAddr) + 1					' max lines + title line
	END IF
'
	DIM asmArray$[codeLines]
	line = 0
	asmChars = LEN(asm$)
	ATTACH asm$ TO asmArray$[line]
'
	DO WHILE (nextAddr < lastAddr)
		labels = XxxGetLabelGivenAddress (nextAddr, @labels$[])
		IF labels THEN
			FOR i = 0 TO labels-1
				asm$ = asm$ + labels$[i] + ":" + "\n"
			NEXT i
		END IF
		addr = nextAddr
		instruction$ = XxxDisassemble64$ (@nextAddr, $$TRUE)
'		asm$ = asm$ + "  " + HEX$(addr,8) + "   " + instruction$ + "\n"  '*cw* 230306-
		asm$ = asm$ + "  " + HEX$(addr,9) + "   " + instruction$ + "\n"  '*cw* 230306+
'
		asmChars = asmChars + LEN(asm$)
		INC line
		ATTACH asm$ TO asmArray$[line]
'
		IFZ (line AND 0xFF) THEN												' Update every 64 lines
			SetCurrentStatus ($$StatusDecoding, line)
			IF softInterrupt THEN
				asm$ = "Assembly decoding aborted here..."
				asmChars = asmChars + LEN(asm$)
				INC line
				ATTACH asm$ TO asmArray$[line]
				GOTO concatStrings
			END IF
		END IF
	LOOP
	codeLines = line
	REDIM asmArray$[codeLines]
'
'	END PROGRAM goes after last line in PROLOG
'	IF (funcNumber = entryFunction) THEN
	IFZ funcNumber THEN
		IF (lineNumber = lineLast[funcNumber]) THEN
			IFZ endProgram$[] THEN
				nextAddr = lineAddr[maxFuncNumber + 1, 0]
				lastAddr = litStringAddr
				IF (lastAddr > nextAddr) THEN
					endLines = lastAddr - nextAddr
					REDIM endProgram$[endLines]
					asm$ = "\nEND PROGRAM:\n\n"
					funcFirstAddr[funcNumber] = nextAddr                    '*cw* 230314+
					funcAfterAddr[funcNumber] = lastAddr                    '*cw* 230314+
					endLine = -1
					DO WHILE (nextAddr < lastAddr)
						labels = XxxGetLabelGivenAddress (nextAddr, @labels$[])
						IF labels THEN
							i = 0
							DO
								asm$ = asm$ + labels$[i] + ":" + "\n"
								INC i
							LOOP UNTIL (i >= labels)
						END IF
						addr = nextAddr
'						asm$ = asm$ + "  " + HEX$(addr,8) + "  " + XxxDisassemble64$ (@nextAddr, $$TRUE) + "\n"  '*cw* 230306-
						asm$ = asm$ + "  " + HEX$(addr,9) + "  " + XxxDisassemble64$ (@nextAddr, $$TRUE) + "\n"  '*cw* 230306+
						INC endLine:  INC line
						ATTACH asm$ TO endProgram$[endLine]
'
						IFZ (line AND 0xFF) THEN									' Update every 64 lines
							SetCurrentStatus ($$StatusDecoding, line)
							IF softInterrupt THEN
								asm$ = "Assembly decoding aborted here..."
								INC endLine:  INC line
								ATTACH asm$ TO endProgram$[endLine]
								REDIM asmArray$[line]
								FOR i = 0 TO endLine
									asmChars = asmChars + LEN(endProgram$[i])
									asmArray$[codeLines + i + 1] = endProgram$[i]
								NEXT i
								GOTO concatStrings
							END IF
						END IF
					LOOP
					asm$ = "Literal String Definitions from " + HEXX$(litStringAddr,8) + " to " + HEXX$(xpc,8)  '*cw* 230306-
'					asm$ = "Literal String Definitions from " + HEXX$(litStringAddr,9) + " to " + HEXX$(xpc,9)  '*cw* 230306+
					INC endLine:  INC line
					ATTACH asm$ TO endProgram$[endLine]
					REDIM endProgram$[endLine]
				END IF
			END IF
			IF endProgram$[] THEN
				endLines = UBOUND(endProgram$[])
				line = codeLines + endLines + 1
				REDIM asmArray$[line]
				FOR i = 0 TO endLines
					asmChars = asmChars + LEN(endProgram$[i])
					asmArray$[codeLines + i + 1] = endProgram$[i]
				NEXT i
			END IF
		END IF
	END IF
'
concatStrings:
	asm$ = NULL$ (asmChars)
	destAddr = &asm$
	offset = 0
	FOR i = 0 TO line
		IFZ asmArray$[i] THEN DO NEXT
		lastOffset = UBOUND(asmArray$[i])								' offset from 0
		srcAddr = &asmArray$[i]
		FOR j = 0 TO lastOffset
			UBYTEAT(destAddr, offset) = UBYTEAT(srcAddr, j)
			INC offset
		NEXT j
	NEXT i
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN
		SetCurrentStatus ($$StatusRunning, 0)
	END IF
	RETURN (asm$)
END FUNCTION
'
'
' #########################
' #####  MainLoop ()  #####
' #########################
'
'	Process system events until exitFlag becomes TRUE
'
'	In:				exitFlagAddr		Address of exit flag
'	Out:			none						arg unchanged
'	Return:		none
'
FUNCTION  MainLoop (exitFlagAddr)
	EXTERNAL /xxx/ errorCount
	SHARED  graphicsInitialized,  fileType
	SHARED  programAltered,  dispatchCount
	SHARED  currentStatus
	SHARED  huh
	SHARED	textAlteredSinceSave
	STATIC	entered
'
	IFZ graphicsInitialized THEN
		Message ("[MainLoop( )]\n GraphicsDesigner not initialized ")
		EXIT FUNCTION
	END IF
'
' exitFlagAddr must be zero or valid data address
'
	error = $$TRUE
	addr = exitFlagAddr
	IF exitFlagAddr THEN
		SELECT CASE TRUE
			CASE ((addr > ##BSS0) AND (addr < ##BSSZ))    :	error = $$FALSE
			CASE ((addr > ##DATA0) AND (addr < ##DATAZ))  :	error = $$FALSE
			CASE ((addr > ##DYNO0) AND (addr < ##DYNOZ))  :	error = $$FALSE
		END SELECT
		IF error THEN THEN
			a$ = HEXX$(addr,8)  '*cw* 230306-
'			a$ = HEXX$(addr,9)  '*cw* 230306+
			PRINT a$
			PRINT MemoryMap$()
			Message ("[MainLoop( )]\n Exit flag address not in static memory \n\n " + a$ + " ")
			XstSleep (2500)
			RETURN
		END IF
	END IF
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN RETURN	' Exit if alarm is on...
'
	IFZ entered THEN
		entered = $$TRUE
		XstGetCommandLineArguments (@count, @arg$[])
		upper = count - 1
		IF count THEN
			FOR arg = 0 TO upper
				arg$ = arg$[arg]
				IF arg$ THEN
					command$ = ""
					SELECT CASE arg$
						CASE "-fl"	:	IF (arg < upper) THEN
														INC arg
														arg$ = arg$[arg]
														IF arg$ THEN command$ = ".fl " + arg$[arg]
													END IF
						CASE "-ft"	:	IF (arg < upper) THEN
														INC arg
														arg$ = arg$[arg]
														IF arg$ THEN command$ = ".ft " + arg$[arg]
													END IF
					END SELECT
					IF (command$) THEN
'						XstLog (command$)
						length = LEN (command$)
						AddCommandItem (@command$)
						ImmediateMode ($$KeyEnter)
					END IF
				END IF
			NEXT arg
		END IF
	END IF
'
'
'	PRINT "MainLoop() : beginning loop : status ="; status
'
	DO
'		IF (currentCursor != $$CursorReady) THEN SetCursor ($$CursorReady)
		IF (fileType != $$Program) THEN
			IF textAlteredSinceSave THEN
				status = $$StatusEditing
			ELSE
				status = $$StatusText
			END IF
		ELSE
			SELECT CASE TRUE
				CASE ##USERRUNNING AND (NOT ##SIGNALACTIVE) : status = $$StatusRunning
				CASE (##USERRUNNING AND ##SIGNALACTIVE)     : status = $$StatusPaused
				CASE programAltered	&& textAlteredSinceSave : status = $$StatusEditing
				CASE NOT programAltered                     : status = $$StatusCompiled
				CASE ELSE                                   : status = $$StatusXit
			END SELECT
		END IF
		IF (currentStatus != status) THEN SetCurrentStatus (status, 0)
		IF dispatchCount THEN Dispatch()					' dispatch stranded actions
		IF huh THEN XxxXstLog ("{-")
		XgrProcessMessages (1)
		IF huh THEN XxxXstLog ("#")
		IF XLONGAT(exitFlagAddr) THEN EXIT DO
		IF huh THEN XxxXstLog ("#")
		IF dispatchCount THEN Dispatch()					' dispatch stranded actions
		IF huh THEN XxxXstLog ("-}")
	LOOP
END FUNCTION
'
'
' ##################################
' #####  ClearMessageQueue ()  #####
' ##################################
'
'	Special processing of the Xit event queue
'
'	Discussion:
'		This routine is used by Xit routines to:
'			- Process #Redraw and #LostKeyboardFocus messages
'			- Look for a "abort" instruction (the ABORT button)
'
'		It is not used while the program is running.
'		Routines with runtime conflicts have special code to avoid conflict.
'
FUNCTION  ClearMessageQueue ()
	SHARED  xitCommand
	SHARED  xitHotAbort
	SHARED  xitTextLower
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN
		RETURN		' Let alarm handle it
	END IF
'
	XgrMessagesPending (@count)
	IFZ count THEN RETURN
'
	DO
		XgrPeekMessage (@wingrid, @message, 0, 0, 0, 0, 0, @r1)
'
		IF (wingrid = xitHotAbort) THEN
			XgrProcessMessages ($$ProcessOneOrNone)             '0
		ELSE
			SELECT CASE message
				CASE  #Redraw, #RedrawGrid, #RedrawText, #LostKeyboardFocus, #GotKeyboardFocus :
					XgrProcessMessages ($$ProcessOneOrNone)
				CASE  #TimeOut, #Update, #Resize, #HideWindow :
					XgrProcessMessages ($$ProcessOneOrNone)
				CASE  #WindowMouseEnter, #WindowMouseDown, #WindowMouseUp :
						SELECT CASE r1
							CASE xitHotAbort, xitTextLower+1, xitCommand+2, ##CONGRID+1 :
													XgrProcessMessages ($$ProcessOneOrNone)
							CASE ELSE : XgrDeleteMessages (1)
						END SELECT
				CASE ELSE
					XgrGetMessageType (message, @msgType)
					IF (msgType = $$Window) THEN
						XgrProcessMessages ($$ProcessOneOrNone)               '0
					ELSE
						XgrDeleteMessages (1)
					END IF
			END SELECT
		END IF
		XgrMessagesPending (@count)
	LOOP WHILE count
END FUNCTION
'
'
' ############################
' #####  AddDispatch ()  #####
' ############################
'
'	Add a function to the dispatch queue (execute AFTER a blowback)
'
FUNCTION  AddDispatch (funcAddress, arg)
	SHARED  dispatch[]
	SHARED  dispatchCount
'
	IFZ dispatch[] THEN DIM dispatch[7, 1]
'
	uPatch = UBOUND (dispatch[])
	IF (dispatchCount > uPatch) THEN
		uPatch = (dispatchCount + 7) OR 3
		REDIM dispatch[uPatch, 1]
	END IF
'
	dispatch[dispatchCount, 0] = funcAddress
	dispatch[dispatchCount, 1] = arg
	INC dispatchCount
END FUNCTION
'
'
' #########################
' #####  Dispatch ()  #####
' #########################
'
'	Dispatch queued functions after blowback
'
FUNCTION  Dispatch ()
	SHARED  dispatch[]
	SHARED  dispatchCount
	FUNCADDR  XLONG  func (XLONG)
'
	IF dispatchCount THEN
		FOR i = 0 TO (dispatchCount - 1)
			func = dispatch[i, 0]
			@func (dispatch[i, 1])
		NEXT i
		dispatchCount = 0
	END IF
END FUNCTION
'
'
' ###################################
' #####  EnableAbortSignals ()  #####
' ###################################
'
FUNCTION  EnableAbortSignals ()
	SHARED  sigs[]
'
	sigs[0] = &XxxXitQuit()					' Quit releases shmid, resets echo
	sigs[1] = 0x00000000
	sigs[2] = 0x00000000
	sigs[3] = 0x00000000
END FUNCTION
'
'
' #################################
' #####  BreakClearArrays ()  #####
' #################################
'
FUNCTION  BreakClearArrays ()
	SHARED  breakPatchAddr[]
	SHARED  breakPatchCode[]
	SHARED  breakAddr[]
	SHARED  breakCode[]
'
		BreakProgrammer ($$BreakClearAll, 0, 0)
'
	DIM breakPatchAddr[7]
	DIM breakPatchCode[7]
	DIM breakAddr[63]
	DIM breakCode[63]
END FUNCTION
'
'
' ##############################
' #####  BreakInternal ()  #####  Internal Breakpoints  #####
' ##############################
'
'	No breakpoints are installed:
'		- in the PROLOG
'		- on first line in function
'
'	"opcode" refers to the first byte of the opcode.
'
FUNCTION  BreakInternal (command, func, line, addr)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN prog[]
	SHARED  lineAddr[]
	SHARED  lineCode@@[]
	SHARED  lineLast[]
'
	SELECT CASE command
		CASE $$BreakRemoveAll					: GOSUB RemoveAllProgramLineBreakpoints
		CASE $$BreakInstallAll				: GOSUB InstallAllProgramLineBreakpoints
		CASE $$BreakInstallFunc				: GOSUB InstallAllFunctionLineBreakpoints
		CASE $$BreakInstallOne				: GOSUB InstallOneFunctionLineBreakpoint
		CASE $$BreakGetFuncLineOpcode	: GOSUB GetFuncAndLineAndOpcodeGivenAddress
		CASE ELSE											: PRINT "Bad command to BreakInternal(26)"
	END SELECT
	RETURN (0)
'
'
' Install breakpoint over 1st opcode of every source line in program
'
SUB InstallAllProgramLineBreakpoints
	func = 1
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func : DO DO
		XxxFunctionName ($$XGET, @funcName$, func)
		IF (funcName$ == "Blowback") THEN INC func : DO DO
		lineAddr = lineAddr[func, 0]
		lineLast = lineLast[func]
		line = 0
		firstLine = $$TRUE
		DO UNTIL (line > lineLast)
			nextAddr = lineAddr[func, line + 1]
			IF (lineAddr < nextAddr) THEN				' Skip blank lines/comments
				IF firstLine THEN									' No breakpoints on FUNCTION line
					firstLine = $$FALSE
				ELSE
					UBYTEAT (lineAddr) = $$Breakpoint
				END IF
			END IF
			lineAddr = nextAddr
			INC line
		LOOP
		INC func
	LOOP
END SUB
'
'
'	Install breakpoint over 1st byte of lineNumber line in function func
'		If FUNCTION line, install it on next valid line
'
SUB InstallOneFunctionLineBreakpoint
	IFZ func THEN EXIT SUB							' No breakpoints in PROLOG
	XxxFunctionName ($$XGET, @funcName$, func)
	IF (funcName$ == "Blowback") THEN EXIT SUB
	IF (line > lineLast[func]) THEN RETURN (0)
	bpLineAddr = lineAddr[func, line]
'
'	Find line following FUNCTION line ("second" line)
'
	lineAddr = lineAddr[func, 0]
	lineLast = lineLast[func]
	line = 0
	firstLine = $$TRUE
	DO UNTIL (line > lineLast)
		nextAddr = lineAddr[func, line + 1]
		IF (lineAddr < nextAddr) THEN			' Skip blank lines/comments
			IF firstLine THEN
				firstLine = $$FALSE
			ELSE
				EXIT DO
			END IF
		END IF
		lineAddr = nextAddr
		INC line
	LOOP
'
	IF (bpLineAddr < lineAddr) THEN bpLineAddr = lineAddr
'
	UBYTEAT (bpLineAddr) = $$Breakpoint
END SUB
'
'
'	Install breakpoint over 1st opcode of every source line in one function
'
SUB InstallAllFunctionLineBreakpoints
	IFZ func THEN EXIT SUB							' No breakpoints in PROLOG
	XxxFunctionName ($$XGET, @funcName$, func)
	IF (funcName$ == "Blowback") THEN EXIT SUB
	lineAddr = lineAddr[func, 0]
	lineLast = lineLast[func]
	line = 0
	firstLine = $$TRUE
	DO UNTIL (line > lineLast)
		nextAddr = lineAddr[func, line + 1]
		IF (lineAddr < nextAddr) THEN			' Skip blank lines/comments
			IF firstLine THEN								' No breakpoints on FUNCTION line
				firstLine = $$FALSE
			ELSE
				UBYTEAT (lineAddr) = $$Breakpoint
			END IF
		END IF
		lineAddr = nextAddr
		INC line
	LOOP
END SUB
'
'
'	Remove breakpoints from 1st opcode on every source line in program
'
SUB RemoveAllProgramLineBreakpoints
	func = 1															' No breakpoints in PROLOG
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO
		lineAddr = lineAddr[func, 0]
		lineLast = lineLast[func]
		line = 0
		DO UNTIL (line > lineLast)
			nextAddr = lineAddr[func, line + 1]
			IF (lineAddr < nextAddr) THEN									' Skip nothing lines
				UBYTEAT (lineAddr) = lineCode@@[func, line]
			END IF
			lineAddr = nextAddr
			INC line
		LOOP
		INC func
	LOOP
END SUB
'
'
'	Get funcNumber and lineNumber given an address
'	"opcode" is first byte of opcode
'
SUB GetFuncAndLineAndOpcodeGivenAddress
	func = 1															' no breakpoints in PROLOG
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO
		lineLast = lineLast[func]
		line = 0
		DO UNTIL (line > lineLast)
			lineAddr = lineAddr[func, line]
			lineCode = lineCode@@[func, line]
			IF (lineAddr = addr) THEN RETURN (lineCode)
			INC line
		LOOP
		INC func
	LOOP
	RETURN (-1)
END SUB
END FUNCTION
'
'
' ################################
' #####  BreakProgrammer ()  #####  Programmer Breakpoints  #####
' ################################
'
FUNCTION  BreakProgrammer (command, arg1, func)
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DATA0,  ##DATA,  ##DATAX,  ##DATAZ
'	ULONG  ##BSS0,   ##BSS,   ##BSSX,   ##BSSZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
'	ULONG  ##UCODE0, ##UCODE, ##UCODEX, ##UCODEZ
'	ULONG  ##STACK0, ##STACK, ##STACKX, ##STACKZ
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	SHARED  TOKEN prog[]
	SHARED  breakAddr[]
	SHARED  breakCode[]
	SHARED  lineAddr[],  lineCode@@[],  lineLast[]
	SHARED  breakpointsAltered
'
	ubreak = UBOUND(breakAddr[])
	SELECT CASE command
		CASE $$BreakClearAll		: GOSUB ClearAllProgrammerBreakpoints
		CASE $$BreakClearFunc		: GOSUB ClearAllFunctionProgrammerBreakpoints
		CASE $$BreakClearOne		: GOSUB ClearOneProgrammerBreakpoint
		CASE $$BreakCheckOne		: GOSUB CheckOneProgrammerBreakpoint
		CASE $$BreakSetOne			: GOSUB SetOneProgrammerBreakpoint
		CASE $$BreakGetOpcode		: GOSUB GetOneProgrammerBreakpointOpcode
		CASE $$BreakInstallAll	: GOSUB InstallAllProgrammerBreakpoints
		CASE $$BreakRemoveAll		: GOSUB RemoveAllProgrammerBreakpoints
		CASE $$BreakRemoveOne		: GOSUB RemoveOneProgrammerBreakpoint
		CASE ELSE								: PRINT "Bad command to BreakProgrammer(33)"
	END SELECT
	RETURN (0)
'
'
'  *****  Clear All Programmer Breakpoints  *****
'
SUB ClearAllProgrammerBreakpoints
	i = 0
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF (ba >= ##UCODE0) THEN
			IF (ba < ##UCODEZ) THEN
				UBYTEAT (ba) = breakCode[i]		' restore opcode
			END IF
		END IF
		breakAddr[i] = 0
		breakCode[i] = 0
		INC i
	LOOP
END SUB
'
'
'  *****  Clear All Function Programmer Breakpoints  *****
'
SUB ClearAllFunctionProgrammerBreakpoints
	lineLast = lineLast[func]
	line = 0
	DO UNTIL (line > lineLast)
		lineAddr = lineAddr[func, line]
		i = 0
		DO UNTIL (i > ubreak)
			ba = breakAddr[i]
			IF (ba = lineAddr) THEN
				IF (ba >= ##UCODE0) THEN
					IF (ba < ##UCODEZ) THEN
						UBYTEAT (ba) = breakCode[i]		' restore opcode
					END IF
				END IF
				breakAddr[i] = 0
				breakCode[i] = 0
			END IF
			INC i
		LOOP
		INC line
	LOOP
END SUB
'
'
'  *****  Clear One Programmer Breakpoint at address "arg1"  *****
'
SUB ClearOneProgrammerBreakpoint
	i =  0
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF (ba = arg1) THEN
			IF (ba >= ##UCODE0) THEN
				IF (ba < ##UCODEZ) THEN
					UBYTEAT (ba) = breakCode[i]		' restore opcode
				END IF
			END IF
			breakAddr[i] = 0
			breakCode[i] = 0
			EXIT SUB
		END IF
		INC i
	LOOP
END SUB
'
'
'  *****  Check for Programm Breakpoint at address "arg1"
'
SUB CheckOneProgrammerBreakpoint
	i =  0
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF (ba = arg1) THEN RETURN ($$TRUE)
		INC i
	LOOP
	RETURN ($$FALSE)
END SUB
'
'
' *****  Set Programmer Breakpoint at address "arg1"
'
SUB SetOneProgrammerBreakpoint
	IFZ arg1 THEN
		Message ("[BreakProgrammer]\n Can't set breakpoint \n\n address = 0x00000000 ")
		EXIT SUB
	END IF
	IF ((arg1 < ##UCODE0) OR (arg1 >= ##UCODEZ)) THEN
		Message ("[BreakProgrammer]\n Can't set breakpoint \n\n bad address ")
		EXIT SUB
	END IF
'
	tempCode = UBYTEAT (arg1)
	break = $$Breakpoint
'
	IF (tempCode = break) THEN
		Message ("[BreakProgrammer]\n SetOneProgBreakpoint \n\n found breakpoint already there ")
		EXIT SUB
	END IF
'
	i = 0
	firstOpenSlot = -1
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF (ba = arg1) THEN EXIT SUB				' breakpoint already set here
		IF (firstOpenSlot < 0) THEN
			IFZ ba THEN firstOpenSlot = i
		END IF
		INC i
	LOOP
	IF (firstOpenSlot < 0) THEN
		Message ("[BreakProgrammer]\n SetOneProgBreakpoint \n\n no room in breakpoint array ")
		EXIT SUB
	END IF
'	PRINT "BreakProgrammer : SetOne success "; HEX$(arg1,8), HEX$(tempCode,8)
	breakAddr[firstOpenSlot] = arg1				' Store breakpoint address in array
	breakCode[firstOpenSlot] = tempCode		' store op code at breakpoint address
	RETURN ($$TRUE)
END SUB
'
'
'  *****  Get Opcode Under Programmer Breakpoint at address "arg1"
'
SUB GetOneProgrammerBreakpointOpcode
	i =  0
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF (ba = arg1) THEN RETURN (breakCode[i])
		INC i
	LOOP
	RETURN ($$FALSE)
END SUB
'
'
'  *****  Install All Programmer Breakpoints  *****
'
SUB InstallAllProgrammerBreakpoints
	SELECT CASE TRUE
		CASE breakpointsAltered
			GOSUB ClearAllProgrammerBreakpoints
			IFZ prog[] THEN EXIT SUB
			func = 1														' Prolog BP invalid
			i = 0
			excess = $$FALSE
			DO UNTIL (func > maxFuncNumber) OR excess
				IFZ prog[func,] THEN INC func: DO DO
				ATTACH prog[func,] TO func[]
				uLine = UBOUND(func[])
				line = 0
				DO UNTIL (line > uLine) OR excess
					IF (func[line, 0].ti.bpexe AND $$BP) THEN             ' breakpoint
						ba = lineAddr[func, line]
						bc = lineCode@@[func, line]
						IF ((ba >= ##UCODE0) AND (ba < ##UCODEZ)) THEN
'							PRINT "BreakPoint Install: "; HEX$(ba,8)
							breakAddr[i] = ba						' Store breakpoint address in array
							breakCode[i] = bc						' Store op code in array
							temp = UBYTEAT (ba)
							break = $$Breakpoint
							IF (temp != break) THEN
								UBYTEAT (ba) = $$Breakpoint
							END IF
						END IF
						INC i
						IF (i > ubreak) THEN excess = $$TRUE
					END IF
					INC line
				LOOP
				ATTACH func[] TO prog[func,]
				INC func
			LOOP
			IF excess THEN
				nb = ubreak + 1
				Message ("only loaded first " + STRING(nb) + " breakpoints")
			END IF
			breakpointsAltered = $$FALSE
		CASE ELSE
			i = 0
			DO UNTIL (i > ubreak)
				ba = breakAddr[i]
				IF ba THEN
'					PRINT "BreakPoint Install : "; HEX$(ba,8)
					IF ((ba >= ##UCODE0) AND (ba < ##UCODEZ)) THEN
						temp = UBYTEAT (ba)
						break = $$Breakpoint
						IF (temp != break) THEN
							UBYTEAT (ba) = $$Breakpoint
						END IF
					END IF
				END IF
				INC i
			LOOP
	END SELECT
END SUB
'
'
'  *****  Remove All Programmer Breakpoints  *****
'
SUB RemoveAllProgrammerBreakpoints
	i = 0
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF ba THEN
			IF ((ba >= ##UCODE0) AND (ba < ##UCODEZ)) THEN
				UBYTEAT (ba) = breakCode[i]
			END IF
		END IF
		INC i
	LOOP
END SUB
'
'
'  *****  Remove One Programmer Breakpoint  *****
'
SUB RemoveOneProgrammerBreakpoint
	i = 0
	DO UNTIL (i > ubreak)
		ba = breakAddr[i]
		IF ba THEN
			IF (ba = arg1) THEN
				UBYTEAT (ba) = breakCode[i]
				EXIT SUB
			END IF
		END IF
		INC i
	LOOP
END SUB
END FUNCTION
'
'
' ##################################################
' #####  GetFuncAndLineNumberAtThisAddress ()  #####
' ##################################################
'
'	Scan line arrays for current address (UpdateFrames used with environment)
'
FUNCTION  GetFuncAndLineNumberAtThisAddress (addr)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN prog[]
	SHARED  lineAddr[]
	SHARED  lineLast[]
	SHARED  exeFunction,  exeLine
'
	exeFunction = 0
	exeLine = 0
	IFZ lineAddr[] THEN RETURN
	IFZ lineLast[] THEN RETURN
'
	func = 0
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO
		lineAddr = lineAddr[func, 0]
		lineLast = lineLast[func]
		line = 0
		DO UNTIL (line > lineLast)
			nextAddr = lineAddr[func, line + 1]
			IF ((lineAddr <= addr) AND (addr < nextAddr)) THEN
				exeFunction = func
				exeLine = line
				RETURN
			END IF
			lineAddr = nextAddr
			INC line
		LOOP
		INC func
	LOOP
END FUNCTION
'
'
'  ###########################
'  #####  XitExecute ()  #####
'  ###########################
'
FUNCTION  XitExecute ()
	SHARED  exitMainLoop
	SHARED  environmentActive
	SHARED  environmentEntered
'
	IFZ environmentEntered THEN
		eui = Xui ()
'		PRINT "XitExecute() : initialized Xui() : "; eui
		failed = CreateWindows ()
'		PRINT "XitExecute() : called CreateWindows(16)"
		IF failed THEN
			PRINT "XitExecute() : cannot start environment : CreateWindows() failed"
			environmentActive = $$FALSE
			RETURN
		ELSE
			InitWindows()
		END IF
	END IF
'
	environmentActive = $$TRUE
	exitMainLoop = $$FALSE
	MainLoop (&exitMainLoop)
END FUNCTION
'
'
' ##############################
' #####  CreateWindows ()  #####
' ##############################
'
' return TRUE if setup failed
'	update Immediate() if add/subtract basic menu items
' set up only once:  environmentEntered reflects reentry
'
FUNCTION  CreateWindows ()
	EXTERNAL  /xxx/  checkBounds
	SHARED  graphicsInitialized
	SHARED  environmentEntered
	SHARED  xitGrid
	SHARED  xitWindow
	SHARED  xitCommand
	SHARED  xitTextLower
	SHARED  xitHotAbort
'	SHARED  tabWidth                'reserved
	SHARED  textCursor
	SHARED  waitCursor
	SHARED  mainTitle$
	SHARED  popupGrids[]
	SHARED  messageFont
'
'	xit environment popup boxes:  grid numbers
'
	SHARED  backupBox
	SHARED  cleanBox
	SHARED  newBox,  fileBox,  modeBox,  renameBox
	SHARED  findBox,  readBox,  writeBox,  abandonBox
	SHARED  funcBox,  viewNewBox,  deleteFuncBox,  viewRenameBox
	SHARED  viewCloneBox,  viewLoadBox,  viewSaveBox,  viewMergeBox,  viewImportBox
	SHARED  optionMiscBox,  optTabBox,  optFontBox
	SHARED  memoryBox,  assemblyBox,  registerBox
	SHARED  errorBox,  runtimeErrorBox
	SHARED  variableBox,  arrayBox,  stringBox,  compositeBox
	SHARED  framesBox
	SHARED  warning2Box,  warning3Box
'
	SHARED  prefFileNumber
	SHARED  helpIndexBox
	SHARED  editFile$
	SHARED  programFont
'
	$Command      = 34  ' kid 34
	$HotAbort     = 13  ' kid 13
	$TextLower    = 35  ' kid 35
'
	$Style2       = 2
	$StyleNotify  = 0x10
'
' ******************************
' *****  CODE STARTS HERE  *****
' ******************************
'
	IF environmentEntered THEN RETURN ($$FALSE)			' environment exists
	IFZ graphicsInitialized THEN RETURN ($$TRUE)		' graphics unavailable
'
'	*****  Create EnvironmentWindow  *****  Size for display width/height
'
' compute initial size and position of window
'   minimal width for 80 character line
'   half display height
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
	line$ = "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	XgrGetTextImageSize (0, @line$, @dx, @dy, @width, @height, @gap, @space)
	maxwidth = #displayWidth - #windowBorderWidth - #windowBorderWidth
	textwidth = width + 32
'
	IF (prefFileNumber) THEN
		XstSetPrefSection (prefFileNumber, "PDE-WindowPositionsAndSizes")
		name$ = "PDE"
		XstGetPrefXLONG (prefFileNumber, name$ + "-X", 0, @x)
		XstGetPrefXLONG (prefFileNumber, name$ + "-Y", 0, @y)
		XstGetPrefXLONG (prefFileNumber, name$ + "-W", 0, @w)
		XstGetPrefXLONG (prefFileNumber, name$ + "-H", 0, @h)
	END IF
'
	IFZ (x && y && w && h ) THEN
		h = (#displayHeight >> 1) - #windowBorderWidth - #windowBorderWidth - #windowTitleHeight
		y = (#displayHeight >> 1) + #windowTitleHeight + #windowBorderWidth
		w = (#displayWidth  >> 1) - #windowBorderWidth - #windowBorderWidth
		IF (w < textwidth) THEN w = textwidth
		IF (w > maxwidth)  THEN w = maxwidth
		x = #displayWidth - w - #windowBorderWidth
	END IF
'
	altered = XgrPlaceWindow (0, @x, @y, @w, @h)
	IFZ mainTitle$ THEN mainTitle$ = " main window "
	Environment    (@xitGrid, #CreateWindow, x, y, w, h, 0, 0)
	XuiSendMessage ( xitGrid, #SetCallback, xitGrid, &EnvironmentCode(), -1, -1, -1, xitGrid)
	XuiSendMessage ( xitGrid, #SetWindowTitle, 0, 0, 0, 0, 0, @mainTitle$)
	XuiSendMessage ( xitGrid, #SetGridName, 0, 0, 0, 0, 0, @"xitGrid")
	XuiSendMessage ( xitGrid, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"xitGrid_")
	XuiSendMessage ( xitGrid, #GetWindow, @xitWindow, 0, 0, 0, 0, 0)
	XuiSendMessage ( xitGrid, #GetGridNumber, @xitCommand, 0, 0, 0, $Command, 0)
	XuiSendMessage ( xitGrid, #GetGridNumber, @xitTextLower, 0, 0, 0, $TextLower, 0)
	XuiSendMessage ( xitGrid, #GetGridNumber, @xitHotAbort, 0, 0, 0, $HotAbort, 0)
	XuiSendMessage ( xitGrid, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	XuiSendMessage ( xitGrid, #GetFontNumber, @programFont, 0, 0, 0, 0, 0)
	XgrSetCursorOverride (waitCursor, @entryCursor)
'
'
' *****************************************
' *****  Xit Environment Popup Boxes  *****
' *****************************************
'
	windowType = $$WindowTypeTopMost OR $$WindowTypeNormal
'
' Default file/directory is the current directory ("")
'
	editFile$ = ""
	dir$ = editFile$
	x0 = #windowBorderWidth
	y0 = #windowBorderWidth + #windowTitleHeight
'
'
' *****  HelpAbout  *****  XuiMessage1B  *****
'
	HelpAbout ($$FALSE)
'
'
' *****  FileNew  *****  XuiMessage4B  *****
'
	DIM r1$[5]
	r1$[1] = " begin new <text file> or <program> or <gui program> "
	r1$[2] = " text file "
	r1$[3] = " program "
	r1$[4] = " gui program "
	r1$[5] = " cancel "
	XuiMessage4B   (@newBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( newBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" new file ")
	XuiSendMessage ( newBox, #SetGridName, 0, 0, 0, 0, 0, @"newBox")
	XuiSendMessage ( newBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( newBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:FileNew")
	XuiSendMessage ( newBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
'	XuiSendMessage ( newBox, #Resize, 0, 0, 0, 0, 0, 0)
	AlignWindow (newBox, 0)
'
'
' *****  SelectFile  *****  XuiFile  *****  FileTextLoad : FileLoad : FileSave
'
	XuiFile        (@fileBox, #CreateWindow, x0, y0, 600, 480, windowType, 0)
	XuiSendMessage ( fileBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Select an XBasic file")
	XuiSendMessage ( fileBox, #SetGridName, 0, 0, 0, 0, 0, @"fileBox")
	XuiSendMessage ( fileBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"fileBox_")
	XuiSendMessage ( fileBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:SelectFile")
	XuiSendMessage ( fileBox, #SetTextString, 0, 0, 0, 0, 0, dir$)
	XuiSendMessage ( fileBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	XuiSendMessage ( fileBox, #Update, 0, 0, 0, 0, 0, 0)
	AlignWindow (fileBox, 0)
'
'
' *****  FileMode  *****  XuiMessage3B  *****
'
	DIM r1$[4]
	r1$[1] = " convert to program or text mode "
	r1$[2] = " program "
	r1$[3] = " text "
	r1$[4] = " cancel "
	XuiMessage3B   (@modeBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( modeBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" file mode ")
	XuiSendMessage ( modeBox, #SetGridName, 0, 0, 0, 0, 0, @"modeBox")
	XuiSendMessage ( modeBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( modeBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:FileMode")
	XuiSendMessage ( modeBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (modeBox, 0)
'
'
' *****  FileRename  *****  XuiDialog2B  *****
'
	DIM r1$[4]
	r1$[1] = " edit the filename "
	r1$[3] = " rename "
	r1$[4] = " cancel "
	XuiDialog2B    (@renameBox, #CreateWindow, x0, y0, 400, 0, windowType, 0)
	XuiSendMessage ( renameBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" rename file ")
	XuiSendMessage ( renameBox, #SetGridName, 0, 0, 0, 0, 0, @"renameBox")
	XuiSendMessage ( renameBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"renameBox_")
	XuiSendMessage ( renameBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( renameBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:FileRename")
	XuiSendMessage ( renameBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (renameBox, 0)
'
'
' *****  EditFind  *****  XitFind  *****  Non-Modal
'
	XitFind        (@findBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( findBox, #SetCallback, findBox, &EditFind(), -1, -1, -1, findBox)
	XuiSendMessage ( findBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"find / replace")
	XuiSendMessage ( findBox, #SetGridName, 0, 0, 0, 0, 0, @"findBox")
	XuiSendMessage ( findBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"findBox_")
	XuiSendMessage ( findBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:EditFind")
	XuiSendMessage ( findBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (findBox, 0)
'
'
' *****  EditRead  *****  XuiFile  *****
'
	XuiFile        (@readBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( readBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" read file ")
	XuiSendMessage ( readBox, #SetGridName, 0, 0, 0, 0, 0, @"readBox")
	XuiSendMessage ( readBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"readBox_")
	XuiSendMessage ( readBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:EditRead")
	XuiSendMessage ( readBox, #SetTextString, 0, 0, 0, 0, 0, dir$)
	XuiSendMessage ( readBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	XuiSendMessage ( readBox, #Update, 0, 0, 0, 0, 0, 0)
	AlignWindow (readBox, 0)
'
'
' *****  EditWrite  *****  XuiFile  *****
'
	XuiFile        (@writeBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( writeBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" write file ")
	XuiSendMessage ( writeBox, #SetGridName, 0, 0, 0, 0, 0, @"writeBox")
	XuiSendMessage ( writeBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"writeBox_")
	XuiSendMessage ( writeBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:EditWrite")
	XuiSendMessage ( writeBox, #SetTextString, 0, 0, 0, 0, 0, dir$)
	XuiSendMessage ( writeBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	XuiSendMessage ( writeBox, #Update, 0, 0, 0, 0, 0, 0)
	AlignWindow (writeBox, 0)
'
'
' *****  Edit -> Load Backup  *****
'
	XuiListDialog2B (@backupBox, #CreateWindow, x0, y0, 250, 212, windowType, 0)
	XuiSendMessage  ( backupBox, #SetCallback, backupBox, &EditLoadBackup(), -1, -1, -1, backupBox)
	XuiSendMessage  ( backupBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Load Backup")
	XuiSendMessage  ( backupBox, #SetGridName, 0, 0, 0, 0, 0, @"backupBox")
	XuiSendMessage  ( backupBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"backupBox_")
	XuiSendMessage  ( backupBox, #SetStyle, $StyleNotify OR $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage  ( backupBox, #SetTextString, 0, 0, 0, 0, 1, @"File Backup List")
	XuiSendMessage  ( backupBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage  ( backupBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:EditLoadBackup")
	XuiSendMessage  ( backupBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (backupBox, 0)
'
'
' *****  Edit -> Clean Backup  *****  XuiDialog3B  *****
'
	DIM r1$[4]
	r1$[1] = " \n backup files for the 'current' file name \n or backup files for 'all names' of files \n"
	r1$[1] = r1$[1] + "will be deleted if older than the  \n  specified number of hours: \n "
	r1$[2] = "48"
	r1$[3] = " current "
	r1$[4] = " all names "
	XuiDialog3B    (@cleanBox, #CreateWindow, x0, y0, 400, 0, windowType, 0)
	XuiSendMessage ( cleanBox, #SetCallback, cleanBox, &EditCleanBackup(), -1, -1, -1, cleanBox)
	XuiSendMessage ( cleanBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Clean Backup")
	XuiSendMessage ( cleanBox, #SetGridName, 0, 0, 0, 0, 0, @"cleanBox")
	XuiSendMessage ( cleanBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"cleanBox_")
	XuiSendMessage ( cleanBox, #SetColor, $$BrightBlue, $$Yellow, -1, -1, 1, 0)
	XuiSendMessage ( cleanBox, #SetColorExtra, -1, -1, $$Black, $$Yellow, 1, 0)
	XuiSendMessage ( cleanBox, #SetFontNumber, messageFont, 0, 0, 0, 1, 0)
	XuiSendMessage ( cleanBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( cleanBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:EditLoadBackup")
	XuiSendMessage ( cleanBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (cleanBox, 0)
'
'
' *****  ViewFunction  *****  XuiListDialog2B  *****  Non-Modal
'
	DIM r1$[4]
	r1$[1] = " function name "
	r1$[4] = " view "
	XuiListDialog2B (@funcBox, #CreateWindow, x0, y0, 250, 200, windowType, 0)
	XuiSendMessage  ( funcBox, #SetCallback, funcBox, &ViewFunc(), -1, -1, -1, funcBox)
	XuiSendMessage  ( funcBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" view function ")
	XuiSendMessage  ( funcBox, #SetGridName, 0, 0, 0, 0, 0, @"funcBox")
	XuiSendMessage  ( funcBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"funcBox_")
	XuiSendMessage  ( funcBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewFunction")
	XuiSendMessage  ( funcBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage  ( funcBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (funcBox, 0)
'
'
' *****  ViewNewFunc  *****  XuiDialog2B  *****
'
	DIM r1$[3]
	r1$[1] = " new function name "
	r1$[3] = " view "
	XuiDialog2B    (@viewNewBox, #CreateWindow, x0, y0, 256, 0, windowType, 0)
	XuiSendMessage ( viewNewBox, #SetCallback, viewNewBox, &ViewNewFunc(), -1, -1, -1, viewNewBox)
	XuiSendMessage ( viewNewBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" new function ")
	XuiSendMessage ( viewNewBox, #SetGridName, 0, 0, 0, 0, 0, @"viewNewBox")
	XuiSendMessage ( viewNewBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"viewNewBox_")
	XuiSendMessage ( viewNewBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( viewNewBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewNew")
	XuiSendMessage ( viewNewBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (viewNewBox, 0)
'
'
' *****  ViewDeleteFunc  *****  XuiListDialog2B  *****  Non-Modal
'
	DIM r1$[4]
	r1$[1] = " function name "
	r1$[4] = " delete "
	XuiListDialog2B (@deleteFuncBox, #CreateWindow, x0, y0, 256, 0, windowType, 0)
	XuiSendMessage  ( deleteFuncBox, #SetCallback, deleteFuncBox, &ViewDeleteFunc(), -1, -1, -1, deleteFuncBox)
	XuiSendMessage  ( deleteFuncBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" delete function ")
	XuiSendMessage  ( deleteFuncBox, #SetGridName, 0, 0, 0, 0, 0, @"deleteFuncBox")
	XuiSendMessage  ( deleteFuncBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"deleteFuncBox_")
	XuiSendMessage  ( deleteFuncBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewDelete")
	XuiSendMessage  ( deleteFuncBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage  ( deleteFuncBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (deleteFuncBox, 0)
'
'
' *****  ViewRenameFunc  *****  XuiDialog2B  *****
'
	DIM r1$[3]
	r1$[1] = " new function name "
	r1$[3] = " rename "
	XuiDialog2B    (@viewRenameBox, #CreateWindow, x0, y0, 256, 0, windowType, 0)
	XuiSendMessage ( viewRenameBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" rename function ")
	XuiSendMessage ( viewRenameBox, #SetGridName, 0, 0, 0, 0, 0, @"viewRenameBox")
	XuiSendMessage ( viewRenameBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"viewRenameBox_")
	XuiSendMessage ( viewRenameBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( viewRenameBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewRename")
	XuiSendMessage ( viewRenameBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (viewRenameBox, 0)
'
'
' *****  ViewCloneFunc  *****  XuiDialog2B  *****
'
	DIM r1$[3]
	r1$[1] = " function name for clone "
	r1$[3] = " clone "
	XuiDialog2B    (@viewCloneBox, #CreateWindow, x0, y0, 256, 0, windowType, 0)
	XuiSendMessage ( viewCloneBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" clone function ")
	XuiSendMessage ( viewCloneBox, #SetGridName, 0, 0, 0, 0, 0, @"viewCloneBox")
	XuiSendMessage ( viewCloneBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"viewCloneBox_")
	XuiSendMessage ( viewCloneBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( viewCloneBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewClone")
	XuiSendMessage ( viewCloneBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (viewCloneBox, 0)
'
'
' *****  ViewLoadFunc  *****  Xit2LineDialog  *****
'
	DIM r1$[5]
	r1$[1] = " function name to load "
	r1$[3] = " file name to load "
	r1$[5] = " load "
	Xit3LineDialog (@viewLoadBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( viewLoadBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" load function ")
	XuiSendMessage ( viewLoadBox, #SetGridName, 0, 0, 0, 0, 0, @"viewLoadBox")
	XuiSendMessage ( viewLoadBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"viewLoadBox_")
	XuiSendMessage ( viewLoadBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( viewLoadBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewLoad")
	XuiSendMessage ( viewLoadBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (viewLoadBox, 0)
'
'
' *****  ViewSaveFunc  *****  Xit2LineDialog  *****
'
	DIM r1$[5]
	r1$[1] = " function name to save "
	r1$[3] = " file name to save function in "
	r1$[5] = " save "
	Xit2LineDialog (@viewSaveBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( viewSaveBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" save function ")
	XuiSendMessage ( viewSaveBox, #SetGridName, 0, 0, 0, 0, 0, @"viewSaveBox")
	XuiSendMessage ( viewSaveBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"viewSaveBox_")
	XuiSendMessage ( viewSaveBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( viewSaveBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewSave")
	XuiSendMessage ( viewSaveBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (viewSaveBox, 0)
'
'
' *****  ViewMergePROLOG  *****  XuiDialog2B  *****
'
	DIM r1$[3]
	r1$[1] = " file name to merge with prolog "
	r1$[3] = " merge "
	XuiDialog2B    (@viewMergeBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( viewMergeBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" merge PROLOG ")
	XuiSendMessage ( viewMergeBox, #SetGridName, 0, 0, 0, 0, 0, @"viewMergeBox")
	XuiSendMessage ( viewMergeBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"viewMergeBox_")
	XuiSendMessage ( viewMergeBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( viewMergeBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewMerge")
	XuiSendMessage ( viewMergeBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (viewMergeBox, 0)
'
'
' *****  ViewImportFunctionFromProgram  *****  Xit2LineDialog  *****
'
	DIM r1$[5]
	r1$[1] = " function name to import "
	r1$[3] = " file name to load "
	r1$[5] = " import "
	Xit2LineDialog (@viewImportBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( viewImportBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" import function ")
	XuiSendMessage ( viewImportBox, #SetGridName, 0, 0, 0, 0, 0, @"viewImportBox")
	XuiSendMessage ( viewImportBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"viewImportBox_")
	XuiSendMessage ( viewImportBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( viewImportBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ViewImport")
	XuiSendMessage ( viewImportBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (viewImportBox, 0)
'
'
' *****  OptionMisc  *****  XitOptionMisc  *****
'
	XitOptionMisc  (@optionMiscBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( optionMiscBox, #SetCallback, optionMiscBox, &XitOptionMiscCode(), -1, -1, -1, optionMiscBox)
	XuiSendMessage ( optionMiscBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" Miscellaneous Options ")
	XuiSendMessage ( optionMiscBox, #SetGridName, 0, 0, 0, 0, 0, @"optionMiscBox")
	XuiSendMessage ( optionMiscBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:OptionMisc")
	XuiSendMessage ( optionMiscBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (optionMiscBox, 0)
'
'
' *****  OptionTabWidth  *****  XuiDialog2B  *****
'
	DIM r1$[4]
	r1$[1] = " tab width "
	r1$[3] = " set "
	r1$[4] = " cancel "
	XuiDialog2B    (@optTabBox, #CreateWindow, x0, y0, 180, 0, windowType, 0)
	XuiSendMessage ( optTabBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" tab width ")
	XuiSendMessage ( optTabBox, #SetGridName, 0, 0, 0, 0, 0, @"optTabBox")
	XuiSendMessage ( optTabBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"optTabBox_")
	XuiSendMessage ( optTabBox, #SetTextStrings, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage ( optTabBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:OptionTabs")
	XuiSendMessage ( optTabBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (optTabBox, 0)
'
'
' *****  OptionTextCursor  *****  XuiColor  *****
'
	XitTextCursor  (@textCursor, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( textCursor, #SetCallback, textCursor, &OptionTextCursor(), -1, -1, -1, textCursor)
	XuiSendMessage ( textCursor, #SetWindowTitle, 0, 0, 0, 0, 0, @" text cursor color ")
	XuiSendMessage ( textCursor, #SetGridName, 0, 0, 0, 0, 0, @"textCursor")
	XuiSendMessage ( textCursor, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"textCursor_")
	XuiSendMessage ( textCursor, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:OptionTextCursor")
	XuiSendMessage ( textCursor, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (textCursor, 0)
'
'
' *****  Memory  *****  XitMemory  *****  Non-Modal
'
	XitMemory      (@memoryBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( memoryBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" memory ")
	XuiSendMessage ( memoryBox, #SetGridName, 0, 0, 0, 0, 0, @"memoryBox")
	XuiSendMessage ( memoryBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"memoryBox_")
	XuiSendMessage ( memoryBox, #SetCallback, memoryBox, &DebugMemory(), -1, -1, -1, memoryBox)
	XuiSendMessage ( memoryBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:DebugMemory")
	XuiSendMessage ( memoryBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (memoryBox, 0)
'
'
' *****  Assembly  *****  XitAssembly  *****  Non-Modal
'
	XitAssembly    (@assemblyBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( assemblyBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" assembly ")
	XuiSendMessage ( assemblyBox, #SetGridName, 0, 0, 0, 0, 0, @"assemblyBox")
	XuiSendMessage ( assemblyBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"assemblyBox_")
	XuiSendMessage ( assemblyBox, #SetCallback, assemblyBox, &DebugAssembly(), -1, -1, -1, assemblyBox)
	XuiSendMessage ( assemblyBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:DebugAssembly")
	XuiSendMessage ( assemblyBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (assemblyBox, 0)
'
'
' *****  Registers  *****  XitRegisters  *****  Non-Modal
'
	XitRegisters   (@registerBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( registerBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" registers ")
	XuiSendMessage ( registerBox, #SetGridName, 0, 0, 0, 0, 0, @"registerBox")
	XuiSendMessage ( registerBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"registerBox_")
	XuiSendMessage ( registerBox, #SetCallback, registerBox, &DebugRegisters(), -1, -1, -1, registerBox)
	XuiSendMessage ( registerBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:DebugRegister")
	XuiSendMessage ( registerBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (registerBox, 0)
'
'
' *****  CompilationErrors  *****  XitErrorCompile  *****  Non-Modal
'
	XitErrorCompile (@errorBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage  ( errorBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" compile errors ")
	XuiSendMessage  ( errorBox, #SetGridName, 0, 0, 0, 0, 0, @"errorBox")
	XuiSendMessage  ( errorBox, #SetCallback, errorBox, &WizardCompErrors(), -1, -1, -1, errorBox)
	XuiSendMessage  ( errorBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ErrorCompile")
	XuiSendMessage  ( errorBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (errorBox, 0)
'
'
' *****  RuntimeErrors  *****  XitErrorRuntime  *****  Non-Modal
'
	XitErrorRuntime (@runtimeErrorBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage  ( runtimeErrorBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" runtime errors ")
	XuiSendMessage  ( runtimeErrorBox, #SetGridName, 0, 0, 0, 0, 0, @"runtimeErrorBox")
	XuiSendMessage  ( runtimeErrorBox, #SetCallback, runtimeErrorBox, &WizardRunErrors(), -1, -1, -1, runtimeErrorBox)
	XuiSendMessage  ( runtimeErrorBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:ErrorRuntime")
	XuiSendMessage  ( runtimeErrorBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (runtimeErrorBox, 0)
'
'
' *****  Help Index  *****  XitHelpIndex  *****
'
	x = 100 : y = 0 : w = 28 : h = 50
	XstWindowSizePercent (@x, @y, @w, @h, 0)
	XuiListDialog2B (@helpIndexBox, #CreateWindow, x, y, w, h, windowType, 0)
	XuiSendMessage  ( helpIndexBox, #SetCallback, helpIndexBox, &XitHelpIndexCode(), -1, -1, -1, helpIndexBox)
	XuiSendMessage  ( helpIndexBox, #SetGridName, 0, 0, 0, 0, 0, @"helpIndexBox")
	XuiSendMessage  ( helpIndexBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"helpIndexBox_")
	XuiSendMessage  ( helpIndexBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Help  Index")
	XuiSendMessage  ( helpIndexBox, #SetTextString, 0, 0, 0, 0, 1, @"Alphabetical List")
	XuiSendMessage  ( helpIndexBox, #SetStyle, $StyleNotify OR $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage  ( helpIndexBox, #SetColorExtra, $$BrightYellow, -1, -1, -1, 2, 0)
	XuiSendMessage  ( helpIndexBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
'
'
' ********************************
' *****  HOT BUTTON WIDGETS  *****
' ********************************
'
' *****  Variables  *****  XitVariables  *****  Non-Modal
'
	XitVariables   (@variableBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( variableBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" variables ")
	XuiSendMessage ( variableBox, #SetGridName, 0, 0, 0, 0, 0, @"variableBox")
	XuiSendMessage ( variableBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"variableBox_")
	XuiSendMessage ( variableBox, #SetCallback, variableBox, &HotVariables(), -1, -1, -1, variableBox)
	XuiSendMessage ( variableBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Variables")
	XuiSendMessage ( variableBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (variableBox, 0)
'
'
' *****  Variable Arrays  *****  XitArray  *****  Non-Modal
'
	XitArray       (@arrayBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( arrayBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" array ")
	XuiSendMessage ( arrayBox, #SetGridName, 0, 0, 0, 0, 0, @"arrayBox")
	XuiSendMessage ( arrayBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"arrayBox_")
	XuiSendMessage ( arrayBox, #SetCallback, arrayBox, &VariablesArray(), -1, -1, -1, arrayBox)
	XuiSendMessage ( arrayBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Array")
	XuiSendMessage ( arrayBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (arrayBox, 0)
'
' *****  Variable Strings  *****  XitString  *****  Non-Modal
'
	XitString      (@stringBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( stringBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" string ")
	XuiSendMessage ( stringBox, #SetGridName, 0, 0, 0, 0, 0, @"stringBox")
	XuiSendMessage ( stringBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"stringBox_")
	XuiSendMessage ( stringBox, #SetCallback, stringBox, &VariablesString(), -1, -1, -1, stringBox)
	XuiSendMessage ( stringBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:String")
	XuiSendMessage ( stringBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (stringBox, 0)
'
'
' *****  Variable Composites  *****  XitComposite  *****  Non-Modal
'
	XitComposite   (@compositeBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( compositeBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" composite ")
	XuiSendMessage ( compositeBox, #SetGridName, 0, 0, 0, 0, 0, @"compositeBox")
	XuiSendMessage ( compositeBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"compositeBox_")
	XuiSendMessage ( compositeBox, #SetCallback, compositeBox, &VariablesComposite(), -1, -1, -1, compositeBox)
	XuiSendMessage ( compositeBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Composite")
	XuiSendMessage ( compositeBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (compositeBox, 0)
'
'
' *****  Frames  *****  XitFrames  *****  Non-Modal
'
	XitFrames      (@framesBox, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( framesBox, #SetWindowTitle, 0, 0, 0, 0, 0, @" frames ")
	XuiSendMessage ( framesBox, #SetGridName, 0, 0, 0, 0, 0, @"framesBox")
	XuiSendMessage ( framesBox, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"framesBox_")
	XuiSendMessage ( framesBox, #SetCallback, framesBox, &HotFrames(), -1, -1, -1, framesBox)
	XuiSendMessage ( framesBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Frames")
	XuiSendMessage ( framesBox, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (framesBox, 0)
'
'
' *****  WarningBox  *****  XuiMessage2/3  *****
'
	XuiMessage2B   (@warning2Box, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( warning2Box, #SetWindowTitle, 0, 0, 0, 0, 0, @" warning ")
	XuiSendMessage ( warning2Box, #SetGridName, 0, 0, 0, 0, 0, @"warning2Box")
	XuiSendMessage ( warning2Box, #SetTexture, $$TextureShadow, 0, 0, 0, 1, 0)
	XuiSendMessage ( warning2Box, #SetFontNumber, messageFont, 0, 0, 0, 1, 0)
	XuiSendMessage ( warning2Box, #SetColor, $$BrightBlue, $$BrightYellow, -1, -1, 1, 0)
	XuiSendMessage ( warning2Box, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Warning2")
	XuiSendMessage ( warning2Box, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (warning2Box, 0)
'
	XuiMessage3B   (@warning3Box, #CreateWindow, x0, y0, 0, 0, windowType, 0)
	XuiSendMessage ( warning3Box, #SetWindowTitle, 0, 0, 0, 0, 0, @" warning ")
	XuiSendMessage ( warning3Box, #SetGridName, 0, 0, 0, 0, 0, @"warning3Box")
	XuiSendMessage ( warning3Box, #SetTexture, $$TextureShadow, 0, 0, 0, 1, 0)
	XuiSendMessage ( warning3Box, #SetFontNumber, messageFont, 0, 0, 0, 1, 0)
	XuiSendMessage ( warning3Box, #SetColor, $$BrightBlue, $$BrightYellow, -1, -1, 1, 0)
	XuiSendMessage ( warning3Box, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Warning3")
	XuiSendMessage ( warning3Box, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	AlignWindow (warning3Box, 0)
'
'
' ****************************
' *****  Done Box Setup  *****
' ****************************
'
'	Environment Grids:  7/14/93
'		xitGrid  newBox  fileBox  modeBox  renameBox
'		findBox  readBox  writeBox  abandonBox
'		funcBox  viewNewBox  deleteFuncBox  viewRenameBox  viewCloneBox
'		viewLoadBox  viewSaveBox  viewMergeBox
'		optionMiscBox  optTabBox  optFontBox
'		memoryBox  assemblyBox  registerBox
'		errorBox  runtimeErrorBox
'		variableBox  arrayBox  stringBox  compositeBox
'		framesBox
'		warning2Box  warning3Box
'
	DIM popupGrids[63]									' for cursor changes
	i = 0:	popupGrids[i] = newBox
	INC i:	popupGrids[i] = fileBox
	INC i:	popupGrids[i] = modeBox
	INC i:	popupGrids[i] = renameBox
	INC i:	popupGrids[i] = findBox
	INC i:	popupGrids[i] = readBox
	INC i:	popupGrids[i] = writeBox
	INC i:	popupGrids[i] = abandonBox
	INC i:	popupGrids[i] = funcBox
	INC i:	popupGrids[i] = viewNewBox
	INC i:	popupGrids[i] = deleteFuncBox
	INC i:	popupGrids[i] = viewRenameBox
	INC i:	popupGrids[i] = viewCloneBox
	INC i:	popupGrids[i] = viewLoadBox
	INC i:	popupGrids[i] = viewSaveBox
	INC i:	popupGrids[i] = viewMergeBox
	INC i:	popupGrids[i] = optionMiscBox
	INC i:	popupGrids[i] = optTabBox
	INC i:	popupGrids[i] = optFontBox
	INC i:	popupGrids[i] = memoryBox
	INC i:	popupGrids[i] = assemblyBox
	INC i:	popupGrids[i] = registerBox
	INC i:	popupGrids[i] = errorBox
	INC i:	popupGrids[i] = runtimeErrorBox
	INC i:	popupGrids[i] = variableBox
	INC i:	popupGrids[i] = arrayBox
	INC i:	popupGrids[i] = stringBox
	INC i:	popupGrids[i] = compositeBox
	INC i:	popupGrids[i] = framesBox
	INC i:	popupGrids[i] = warning2Box
	INC i:	popupGrids[i] = warning3Box
	REDIM popupGrids[i]
'
' Reset signals, disable Alarm:
'
'	SetAlarm (0)											' Unused in NT/SCO
'
'	Turn on message CEO
'
	XgrSetCEO (&XitCEO())
	environmentEntered = $$TRUE
	ClearMessageQueue()
'
'	After extensive review, it appears that it is
' necessary to initialize the compiler for only
' one reason at this point.  If the compiler is
' not initialized here, then the BehaviorWindow
' does not display message function names since
' function addresses have not yet been loaded.
'
	XgrSetCursorOverride (0, 0)
'
END FUNCTION
'
'
' ############################
' #####  InitWindows ()  #####
' ############################
'
FUNCTION  InitWindows ()
	SHARED  xitGrid
'
	XuiSendMessage ( xitGrid, #DisplayWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ############################
' #####  AlignWindow ()  #####
' ############################
'
FUNCTION  AlignWindow (grid, align)
'
	IFZ grid THEN RETURN
	XuiSendMessage (grid, #GetWindowGrid, @gggg, 0, 0, 0, 0, 0)
	IFZ gggg THEN gggg = grid
'	PRINT "########################"
'	PRINT "grid, gggg     = "; HEX$(grid,4);; HEX$(gggg,4)
'	PRINT "displayWidth   = "; HEX$(#displayWidth, 4)
'	PRINT "displayHeight  = "; HEX$(#displayHeight, 4)
'	PRINT "borderWidth    = "; HEX$(#windowBorderWidth, 4)
'	PRINT "titleHeight    = "; HEX$(#windowTitleHeight, 4)
'
	xx = #windowBorderWidth
	yy = #windowBorderWidth + #windowTitleHeight
	XuiSendMessage (gggg, #GetSize, @x, @y, @ww, @hh, 0, 0)
	XuiSendMessage (gggg, #ResizeWindow, xx, yy, ww, hh, 0, 0)
	XuiSendMessage (gggg, #Resize, 0, 0, ww, hh, 0, 0)
	XuiSendMessage (gggg, #GetSize, @x, @y, @ww, @hh, 0, 0)
'	PRINT "xx, yy, ww, hh = "; HEX$(xx,4);; HEX$(yy,4);; HEX$(ww,4);; HEX$(hh,4)
'
	maxwidth = #displayWidth - #windowBorderWidth - #windowBorderWidth
	maxheight = #displayHeight - #windowBorderWidth - #windowBorderWidth - #windowTitleHeight
'	PRINT "maxwidth, maxheight = "; HEX$(maxwidth,4);; HEX$(maxheight,4)
'
	resize = $$FALSE
	IF (ww > maxwidth) THEN ww = maxwidth : xx = #windowBorderWidth : resize = $$TRUE
	IF (hh > maxheight) THEN hh = maxheight : yy = #windowBorderWidth + #windowTitleHeight : resize = $$TRUE
'
	IF resize THEN
		XuiSendMessage (gggg, #Resize, 0, 0, ww, hh, 0, 0)
		XuiSendMessage (gggg, #GetSize, @x, @y, @w, @h, 0, 0)
	END IF
'	PRINT "xx, yy, ww, hh = "; HEX$(xx,4);; HEX$(yy,4);; HEX$(ww,4);; HEX$(hh,4)
'
	xx = (#displayWidth >> 1) - (ww >> 1)
	yy = (#displayHeight >> 1) - (hh >> 1) - #windowTitleHeight
'
'	PRINT "AlignWindow(44):xx, yy, ww, hh = "; HEX$(xx,4);; HEX$(yy,4);; HEX$(ww,4);; HEX$(hh,4)
	XuiSendMessage (gggg, #ResizeWindow, xx, yy, ww, hh+1, 0, 0)
'	PRINT "xx, yy, ww, hh = "; HEX$(xx,4);; HEX$(yy,4);; HEX$(ww,4);; HEX$(hh,4)
END FUNCTION
'
'
' ###########################
' #####  HideWindow ()  #####
' ###########################
'
FUNCTION  HideWindow (grid, message, v0, v1, v2, v3, r0, r1)
	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
'	############################
'	#####  Environment ()  #####
'	############################
'
FUNCTION  Environment (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  Environment
	SHARED  fileListPBGrid, xitFileList
'
	$Style2       = 2
	$StyleNotify  = 0x10
'
	$Environment          =   0  ' kid   0 grid type = Environment
	$MenuBar              =   1  ' kid   1 grid type = XuiMenu
	$HotProlog            =   2  ' kid   2 grid type = XuiPushButton
	$FileListPB           =   3  ' kid   3 grid type = XuiPushButton
	$StatusLabel          =   4  ' kid   4 grid type = XuiLabel
	$HotNew               =   5  ' kid   5 grid type = XuiPushButton
	$HotLoad              =   6  ' kid   6 grid type = XuiPushButton
	$HotSave              =   7  ' kid   7 grid type = XuiPushButton
	$HotSavePlus          =   8  ' kid   8 grid type = XuiPushButton
	$HotCut               =   9  ' kid   9 grid type = XuiPushButton
	$HotCopy              =  10  ' kid  10 grid type = XuiPushButton
	$HotPaste             =  11  ' kid  11 grid type = XuiPushButton
	$HotGui               =  12  ' kid  12 grid type = XuiPushButton
	$HotAbort             =  13  ' kid  13 grid type = XuiPushButton
	$HotFind              =  14  ' kid  14 grid type = XuiPushButton
	$HotReplace           =  15  ' kid  15 grid type = XuiPushButton
	$HotBack              =  16  ' kid  16 grid type = XuiPushButton
	$HotNext              =  17  ' kid  17 grid type = XuiPushButton
	$HotPrevious          =  18  ' kid  18 grid type = XuiPushButton
	$Function             =  19  ' kid  19 grid type = XuiListButton
	$HotStart             =  20  ' kid  20 grid type = XuiPushButton
	$HotContinue          =  21  ' kid  21 grid type = XuiPushButton
	$HotPause             =  22  ' kid  22 grid type = XuiPushButton
	$HotKill              =  23  ' kid  23 grid type = XuiPushButton
	$HotToCursor          =  24  ' kid  24 grid type = XuiPushButton
	$HotStepLocal         =  25  ' kid  25 grid type = XuiPushButton
	$HotStepGlobal        =  26  ' kid  26 grid type = XuiPushButton
	$HotStepOut           =  27  ' kid  26 grid type = XuiPushButton
	$HotToggleBreakpoint  =  28  ' kid  27 grid type = XuiPushButton
	$HotClearBreakpoints  =  29  ' kid  28 grid type = XuiPushButton
	$HotVariables         =  30  ' kid  29 grid type = XuiPushButton
	$HotFrames            =  31  ' kid  30 grid type = XuiPushButton
	$HotAssembly          =  32  ' kid  31 grid type = XuiPushButton
	$HotRegisters         =  33  ' kid  32 grid type = XuiPushButton
	$Command              =  34  ' kid  34 grid type = XuiDropBox
	$TextLower            =  35  ' kid  35 grid type = XuiTextArea
	$UpperKid             =  35  ' kid maximum
'
'	XxxLog10 ("Environment(*) ", 0, grid, message, v0, v1, v2, v3, r0, r1)
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, Environment) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
	message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, Environment, @v0, @v1, @v2, @v3, r0, r1, &Environment())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"Environment")
	XuiSendMessage ( grid, #SetBorder, $$BorderNone, $$BorderNone, $$BorderFrame, 0, 0, 0)
	XuiSendMessage ( grid, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:Environment")
	XuiMenu        (@g, #Create, 0, 0, 344, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $MenuBar, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"menu")
	XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderFrame, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:MenuBar")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"main menu")
	DIM text$[80]
	i = 0 : text$[i] = "_File "
	INC i : text$[i] = " _New"
	INC i : text$[i] = " Open As _Text"
	INC i : text$[i] = " _Open"
	INC i : text$[i] = " _Save"
	INC i : text$[i] = " _RenameSave"
	INC i : text$[i] = " _Mode"
	INC i : text$[i] = " E_xit"
	INC i : text$[i] = "_Edit "
	INC i : text$[i] = " Cu_T"
	INC i : text$[i] = " _Copy"
	INC i : text$[i] = " _Paste"
	INC i : text$[i] = " _Delete Extra"
	INC i : text$[i] = " C_opy Extra"
	INC i : text$[i] = " P_aste Extra"
	INC i : text$[i] = " _Erase"
	INC i : text$[i] = " _Find"
	INC i : text$[i] = " _Read"
	INC i : text$[i] = " Pa_ste To File"
	INC i : text$[i] = " Extra To File"
	INC i : text$[i] = " Console To File"
	INC i : text$[i] = " Clean Bac_kup"
	INC i : text$[i] = " _Load Backup"
	INC i : text$[i] = "_View "
	INC i : text$[i] = " _Function"
	INC i : text$[i] = " _Prior Function"
	INC i : text$[i] = " _New Function"
	INC i : text$[i] = " _Delete Function"
	INC i : text$[i] = " _Rename Function"
	INC i : text$[i] = " _Clone Function"
	INC i : text$[i] = " _Load Function"
	INC i : text$[i] = " _Save Function"
	INC i : text$[i] = " _Merge Prolog"
	INC i : text$[i] = " _Import Function From *.x"
	INC i : text$[i] = " _GuiDesigner toolkit"
	INC i : text$[i] = "_Options "
	INC i : text$[i] = " _Misc"
	INC i : text$[i] = " _Color of Text Cursor and Line"
	INC i : text$[i] = " _Tab Width (Pixels)"
	INC i : text$[i] = "_Run "
	INC i : text$[i] = " _Start"
	INC i : text$[i] = " _Continue"
	INC i : text$[i] = " _Jump"
	INC i : text$[i] = " _Pause"
	INC i : text$[i] = " _Kill"
	INC i : text$[i] = " _Erase Output"
	INC i : text$[i] = " _Recompile"
	INC i : text$[i] = " _Assembler"
	INC i : text$[i] = " _Library"
	INC i : text$[i] = " _make Standalone"
	INC i : text$[i] = " E_xecute Standalone"
	INC i : text$[i] = "_Debug "
	INC i : text$[i] = " _Toggle Breakpoint"
	INC i : text$[i] = " _Clear All Breakpoints"
	INC i : text$[i] = " _Erase Local Breakpoints"
	INC i : text$[i] = " _Memory"
	INC i : text$[i] = " _Assembly"
	INC i : text$[i] = " _Registers"
	INC i : text$[i] = " Breakpoint Trace On"
	INC i : text$[i] = " Breakpoint Trace Off"
	INC i : text$[i] = "_Status "
	INC i : text$[i] = " _Compilation Errors"
	INC i : text$[i] = " _Runtime Errors"
	INC i : text$[i] = " Clear _Errors"
	INC i : text$[i] = "_Help"
	INC i : text$[i] = " Help _Index"
	INC i : text$[i] = " Help Index _Find"
	INC i : text$[i] = " _Read Me"
	INC i : text$[i] = " _Change Log"
	INC i : text$[i] = " _About"
	INC i : text$[i] = " _Support"
	INC i : text$[i] = " _Message"
	INC i : text$[i] = " _Language"
	INC i : text$[i] = " _Operator Summary"
	INC i : text$[i] = " _Dot Command"
	INC i : text$[i] = " Standard Library (Xst)"
	INC i : text$[i] = " Graphics Library  (Xgr)"
	INC i : text$[i] = " GuiDesigner Library (Xui)"
	INC i : text$[i] = " Mathematics Library  (Xma)"
	INC i : text$[i] = " Complex Number Library (Xcm)"
	INC i : text$[i] = " Network/Internet Library (Xin)"
	IF (i != UBOUND(text$[])) THEN PRINT "Environment(170)main menu index error", i, UBOUND(text$[])
'
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:MenuBar")
	XuiPushButton  (@g, #Create, 344, 0, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotProlog, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotProlog")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotProlog")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display program PROLOG")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_prolog.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
'
'
' FileLabel push button to display recent filename pulldown list
'
	XuiPushButton  (@g, #Create, 368, 0, 160, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), g, -1, $FileListPB, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonFile")
	XuiSendMessage ( g, #SetColor, $$Grey, -1, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, -1, $$Black, $$LightYellow, $$Black, 0, 0)
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:FileLabel")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"filename")
	XuiSendMessage ( g, #SetFont, 280, 400, 0, 0, 0, @"Courier")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"-filename-")
	fileListPBGrid = g
'
	XgrGetFontMetrics (0, 0, @maxCharHeight, 0, 0, 0, 0)
	h = ($$RecentUpper+1) * maxCharHeight + 24
	wt = $$WindowTypeTopMost OR $$WindowTypeNoSelect OR $$WindowTypeNoFrame OR $$WindowTypeNoIcon OR window
	XuiList        (@g, #CreateWindow, 368, 24, 320, h, wt, 0)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), g, -1, $FileListPB, grid)
	XuiSendMessage ( g, #SetWindowTitle, 0, 0, 0, 0, 0, @"FileList")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"fileList")
	XuiSendMessage ( g, #SetStyle, $StyleNotify, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderRidge, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightYellow, -1, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:RecentFileList")
	XuiSendMessage (fileListPBGrid, #GetKidArray, 0, 0, 0, 0, 0, @k[])
	upper = UBOUND(k[])
	IF (upper < 1) THEN REDIM k[1]
	k[1] = g
	XuiSendMessage (fileListPBGrid, #SetKidArray, 0, 0, 0, 0, 0, @k[])
	xitFileList = g
'
	XuiLabel       (@g, #Create, 528, 0, 160, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelStatus")
	XuiSendMessage ( g, #SetColorExtra, -1, -1, -1, $$LightYellow, 0, 0)
	XuiSendMessage ( g, #SetColor, $$Grey, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:StatusLabel")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"status")
	XuiSendMessage ( g, #SetFont, 280, 400, 0, 0, 0, @"Courier")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"-status-")
	XuiPushButton  (@g, #Create, 0, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotNew, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotNew")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotNew")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"new program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_new.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 24, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotLoad, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotLoad")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotLoad")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"load program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_open.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 48, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotSave, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotSave")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotSave")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"save program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_save.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 72, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotSavePlus, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotSavePlus")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotSavePlus")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"save new version of program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_saveplus.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 104, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotCut, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotCut")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotCut")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"cut selected text, put copy in clipboard")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_cut.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 128, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotCopy, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotCopy")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotCopy")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"copy selected text, put in clipboard")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_copy.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 152, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotPaste, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotPaste")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotPaste")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"paste clipboard text at cursor")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_paste.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 184, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotGui, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotGui")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotGui")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display/hide GuiDesigner toolkit")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_toolkit.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 208, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotAbort, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotAbort")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotAbort")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"abort executing command")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_stop.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 240, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotFind, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotFind")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotFind")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F11 : find string in program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_find.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 264, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotReplace, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotReplace")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotReplace")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F12 : replace string in program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_replace.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 296, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotBack, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotBack")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotBack")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display previous function")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_back.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 320, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotNext, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotNext")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotNext")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display next function")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_next.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 344, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotPrevious, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotPrevious")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotPrevious")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display previously displayed function")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_previous.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiListButton  (@g, #Create, 368, 24, 320, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $Function, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"function")
	XuiSendMessage ( g, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"function_")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, -1, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetStyle, $StyleNotify, 0, 0, 0, 2, 0)
	XuiSendMessage ( g, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Function")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"view function")
	XuiSendMessage ( g, #SetFont, 300, 700, 0, 0, 0, @"Courier")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"select function pulldown")
	DIM text$[0]
	text$[0] = "PROLOG or text"
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:Function")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 1, @"view function")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 2, @"pde.hlp:Function")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 2, @"view function")
	XuiPushButton  (@g, #Create, 0, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotStart, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotStart")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotStart")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F1 : start program execution from beginning")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_start.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 24, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotContinue, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotContinue")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotContinue")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F2 : continue program execution after pause")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_continue.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 48, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotPause, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotPause")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotPause")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F3 : pause program execution now")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_pause.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 72, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotKill, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotKill")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotKill")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F4 : kill program execution : continue not possible")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_kill.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 104, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotToCursor, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotToCursor")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotToCursor")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F5 : execute program with breakpoint at cursor line")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_step_cursor.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 128, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotStepLocal, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotStepLocal")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotStepLocal")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F6 : execute single-step local - step over called functions")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_step_local.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 152, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotStepGlobal, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotStepGlobal")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotStepGlobal")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F7 : execute single-step global - step into called functions")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_step_global.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 176, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotStepOut, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotStepOut")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotStepOut")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"execute program till return to calling function")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_step_out.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 208, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotToggleBreakpoint, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotToggleBreakpoint")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotToggleBreakpoint")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"toggle breakpoint on/off at cursor line")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_breakpoint.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 232, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotClearBreakpoints, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotClearBreakpoints")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotClearBreakpoints")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"clear all breakpoints")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_breakpoints_clear.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 264, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotVariables, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotVariables")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotVariables")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F8 : display variables - view and change values")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_variables.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 288, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotFrames, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotFrames")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotFrames")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F9 : display function call-stack")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_stack.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 320, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotAssembly, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotAssembly")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotAssembly")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F10 : display assembly language for cursor line")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_assembly.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 344, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $HotRegisters, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHotRegisters")
	XuiSendMessage ( g, #SetStyle, $Style2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotRegisters")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display CPU registers")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_registers.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiDropBox     (@g, #Create, 368, 48, 320, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $Command, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"command")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @".c enter dot commands here")
	DIM text$[15]
	text$[ 0] = ".c enter dot commands here"
	text$[ 1] = ".fl filename"
	text$[ 2] = ".ft filename"
	text$[ 3] = ".fs filename"
	text$[ 4] = ".fq"
	text$[ 5] = ".v funcname"
	text$[ 6] = ".v PROLOG"
	text$[ 7] = ".vp"
	text$[ 8] = ".v-"
	text$[ 9] = ".v"
	text$[10] = ".rs"
	text$[11] = ".rr"
	text$[12] = ".rk"
	text$[13] = ".h"
	text$[14] = ".f findstring"
	text$[15] = ".r findstring replacestring"
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetColorExtra, $$LightYellow, $$LightYellow, $$Black, $$White, 1, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @".c enter dot commands here")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 2, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 2, @"show command list")
	XuiSendMessage ( g, #SetWindowTitle, 0, 0, 0, 0, 3, @"CommandList")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 3, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 3, @"select command")
	XuiTextArea    (@g, #Create, 0, 72, 688, 128, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Environment(), -1, -1, $TextLower, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"xitTextLower")
	XuiSendMessage ( g, #SetTextFlag, $$TextFlagCursorLineHilite, $$TRUE, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, -1, -1, -1, 123, 0, 0)     ' cursor line color
	XuiSendMessage ( g, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:TextLower")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:TextLower")
	XuiSendMessage ( g, #SetColor, 19, -1, -1, -1, 2, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 2, @"pde.hlp:TextLower")
	XuiSendMessage ( g, #SetColor, 19, -1, -1, -1, 3, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 3, @"pde.hlp:TextLower")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Environment")
END SUB
'
'
' *****  GetSmallestSize  *****  see "Anatomy of Grid Functions"
'
SUB GetSmallestSize
	v2 = designWidth
	v3 = designHeight
END SUB
'
'
' *****  Resize  *****  see "Anatomy of Grid Functions"
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	IF (v2 < vv2) THEN v2 = vv2
	IF (v3 < vv3) THEN v3 = vv3
'
' position and size main/parent grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
'
' make sure we have a plausibly compact font in the menu bar
'
	XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 280, 400, 0, 0, $MenuBar, @"MS Sans Serif")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Arial")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Comic Sans MS")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 280, 400, 0, 0, $MenuBar, @"Helvetica")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Helvetica")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Helv")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 300, 400, 0, 0, $MenuBar, @"Tw Cen MT")
'
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 280, 400, 0, 0, $MenuBar, @"verdana")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 300, 400, 0, 0, $MenuBar, @"trebuchet ms")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 300, 400, 0, 0, $MenuBar, @"Arial")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 300, 400, 0, 0, $MenuBar, @"Comic Sans MS")
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 300, 400, 0, 0, $MenuBar, @"Courier")
'	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
'	IFZ font THEN XuiSendMessage ( grid, #SetFont, 350, 400, 0, 0, $MenuBar, @"Helvetica")
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 320, 400, 0, 0, $MenuBar, @"Helvetica")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 290, 400, 0, 0, $MenuBar, @"Arial")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 290, 400, 0, 0, $MenuBar, @"Lucida")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
'
	XuiSendMessage (grid, #SetFontNumber, font, 0, 0, 0, $FileListPB, 0)
	XuiSendMessage (grid, #SetFontNumber, font, 0, 0, 0, $StatusLabel, 0)
'
	XuiSendMessage (grid, #GetSmallestSize, 0, 0, @mbw, @mbh, $MenuBar, 0)
	XuiGetSize (grid, #GetSize, 0, 0, @hpw, @hph, $HotProlog, 0)
	XuiGetSize (grid, #GetSize, @xx, @yy, @ww, @hh, $Environment, 0)	' whole window
	XuiGetSize (grid, #GetSize, @tx, @ty, @tw, @th, $TextLower, 0)		' program text
	XuiGetSize (grid, #GetSize, @fx, @fy, @fw, @fh, $Function, 0)			' function
'
	IF (fx < (mbw + hpw)) THEN fx = mbw + hpw
	hpx = fx - hpw
'
	xw0 = v2 - fx									' space to right of menu-bar & buttons

	xw2 = xw0 \ 3                 ' width of right-hand button
	IF (xw2 < (designWidth \5)) THEN xw2 = xw0 >> 1
	xw1 = xw0 - xw2               ' width of left-hand button

	sx = fx + xw1									' x position of right-hand button
	th = v3 - ty									' new height of program text
'
'	PRINT "Environment(616)", v0; v1; v2; v3;; fx; sx; tx;;; xw0; xw1; xw2;;; xx; yy; ww; hh
'
	XuiSendMessage (grid, #Resize, 0,  0, mbw, 24, $MenuBar, 0)
	XuiSendMessage (grid, #Resize, hpx,  0, hpw, 24, $HotProlog, 0)
	XuiSendMessage (grid, #Resize, fx,  0, xw1, 24, $FileListPB, 0)
	XuiSendMessage (grid, #Resize, sx,  0, xw2, 24, $StatusLabel, 0)
	XuiSendMessage (grid, #Resize, fx, 24, xw0, 24, $Function, 0)
	XuiSendMessage (grid, #Resize, fx, 48, xw0, 24, $Command, 0)
	XuiSendMessage (grid, #Resize, tx, ty,  v2, th, $TextLower, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Selection  *****  see "Anatomy of Grid Functions"
'
SUB Selection
END SUB
'
'
' *****  Initialize  *****  ' see "Anatomy of Grid Functions"
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]           = &XuiCallback ()               ' disable to handle Callback messages internally
	func[#GetSmallestSize]    = 0                             ' enable to add internal GetSmallestSize routine
	func[#GotKeyboardFocus]   = &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]  = &XuiLostKeyboardFocus()
	func[#Resize]             = 0                             ' enable to add internal Resize routine
	func[#SetKeyboardFocus]   = &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
'	sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
	sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
	sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
	sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
	sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
	sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
	IF sub[0] THEN PRINT "Environment(656) : Initialize : error ::: (undefined message)"
	IF func[0] THEN PRINT "Environment(657) : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@Environment, "Environment", &Environment(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
	designX = 908
	designY = 623
	designWidth = 632
	designHeight = 200
'
	gridType = Environment
	XuiSetGridTypeProperty (gridType, @"x",                designX)
	XuiSetGridTypeProperty (gridType, @"y",                designY)
	XuiSetGridTypeProperty (gridType, @"width",            designWidth)
	XuiSetGridTypeProperty (gridType, @"height",           designHeight)
	XuiSetGridTypeProperty (gridType, @"minWidth",         designWidth)
	XuiSetGridTypeProperty (gridType, @"minHeight",        designHeight)
	XuiSetGridTypeProperty (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$InputTextString OR $$InputTextArray OR $$TextSelection)
	XuiSetGridTypeProperty (gridType, @"focusKid",         $TextLower)
	XuiSetGridTypeProperty (gridType, @"inputTextArray",   $TextLower)
	XuiSetGridTypeProperty (gridType, @"inputTextString",  $Command)
	XuiSetGridTypeProperty (gridType, @"redrawFlags",      $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
' ################################
' #####  EnvironmentCode ()  #####
' ################################
'
FUNCTION  EnvironmentCode (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1$[]))
	SHARED  fileType,  programAltered,  softInterrupt
	SHARED  saveBeforeCompile
	SHARED  editFunction
	SHARED  haltedByEdit,  textAlteredSinceSave
	SHARED  funcAltered[],  funcNeedsTokenizing[]
	SHARED  backupBox
	SHARED  cleanBox
	SHARED  findBox,  funcBox,  deleteFuncBox,  viewNewBox
	SHARED  optionMiscBox,  memoryBox,  assemblyBox,  registerBox
	SHARED  errorBox,  runtimeErrorBox,  framesBox
	SHARED  aboutGrid
	SHARED  variableBox
	SHARED  textCursor
	SHARED  xitCursorLineColor
	SHARED  helpIndexBox
	SHARED  fileListPBGrid, xitFileList
	SHARED  CURSORLOCATION recentCursor[]
	SHARED  recentFile$[]
	SHARED  recentFunc$[]
	SHARED  xitTextLower
	SHARED  makeBackupFile
	SHARED  xbasicBackupDir$
	STATIC  lostFocusMsec
	STATIC  needBlowback
'
	$Environment          =   0  ' kid   0 grid type = Environment
	$MenuBar              =   1  ' kid   1 grid type = XuiMenu
	$HotProlog            =   2  ' kid   2 grid type = XuiPushButton
	$FileListPB           =   3  ' kid   3 grid type = XuiPushButton
	$StatusLabel          =   4  ' kid   4 grid type = XuiLabel
	$HotNew               =   5  ' kid   5 grid type = XuiPushButton
	$HotLoad              =   6  ' kid   6 grid type = XuiPushButton
	$HotSave              =   7  ' kid   7 grid type = XuiPushButton
	$HotSavePlus          =   8  ' kid   8 grid type = XuiPushButton
	$HotCut               =   9  ' kid   9 grid type = XuiPushButton
	$HotCopy              =  10  ' kid  10 grid type = XuiPushButton
	$HotPaste             =  11  ' kid  11 grid type = XuiPushButton
	$HotGui               =  12  ' kid  12 grid type = XuiPushButton
	$HotAbort             =  13  ' kid  13 grid type = XuiPushButton
	$HotFind              =  14  ' kid  14 grid type = XuiPushButton
	$HotReplace           =  15  ' kid  15 grid type = XuiPushButton
	$HotBack              =  16  ' kid  16 grid type = XuiPushButton
	$HotNext              =  17  ' kid  17 grid type = XuiPushButton
	$HotPrevious          =  18  ' kid  18 grid type = XuiPushButton
	$Function             =  19  ' kid  19 grid type = XuiListButton
	$HotStart             =  20  ' kid  20 grid type = XuiPushButton
	$HotContinue          =  21  ' kid  21 grid type = XuiPushButton
	$HotPause             =  22  ' kid  22 grid type = XuiPushButton
	$HotKill              =  23  ' kid  23 grid type = XuiPushButton
	$HotToCursor          =  24  ' kid  24 grid type = XuiPushButton
	$HotStepLocal         =  25  ' kid  25 grid type = XuiPushButton
	$HotStepGlobal        =  26  ' kid  26 grid type = XuiPushButton
	$HotStepOut           =  27  ' kid  26 grid type = XuiPushButton
	$HotToggleBreakpoint  =  28  ' kid  27 grid type = XuiPushButton
	$HotClearBreakpoints  =  29  ' kid  28 grid type = XuiPushButton
	$HotVariables         =  30  ' kid  29 grid type = XuiPushButton
	$HotFrames            =  31  ' kid  30 grid type = XuiPushButton
	$HotAssembly          =  32  ' kid  31 grid type = XuiPushButton
	$HotRegisters         =  33  ' kid  32 grid type = XuiPushButton
	$Command              =  34  ' kid  34 grid type = XuiDropBox
	$TextLower            =  35  ' kid  35 grid type = XuiTextArea
	$UpperKid             =  35  ' kid maximum
'
	$Style2       = 0x02
	$StyleNotify  = 0x10
'
	IF needBlowback THEN
		IF (message != #Callback) || (r1 != #TextModified) THEN
			XgrMessageNumberToName (message, @message$)
			IF (message == #Callback) THEN
				XgrMessageNumberToName (r1, @r1m$)
			ELSE
				r1m$ = ""
			END IF
			PRINT "EnvironmentCode() : "; grid, message$, v0, v1, v2, v3, r0, r1, r1m$
		END IF
	END IF
'	XxxLog10 ("EnvironmentCode() : "; grid, 0, message, v0, v1, v2, v3, r0, r1)
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #ContextChange	: GOSUB ContextChange
		CASE #MouseDown			: GOSUB MouseDown
		CASE #Selection			: GOSUB Selection
		CASE #TextEvent			: GOSUB TextEvent
		CASE #TextModified  : GOSUB TextModified
	END SELECT
'
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	callback = message
	SELECT CASE message
		CASE #Cancel				: GOSUB Cancel
		CASE #ContextChange	: GOSUB ContextChange
		CASE #CloseWindow		: GOSUB CloseWindow
		CASE #Notify				: GOSUB Notify
		CASE #Selection			:	GOSUB Selection
		CASE #TextEvent			:	GOSUB TextEvent
		CASE #TextModified  : GOSUB TextModified
	END SELECT
END SUB
'
'
' *****  CloseWindow  *****
'
SUB CloseWindow
	FileQuit ()
END SUB
'
'
' *****  Cancel  *****
'
SUB Cancel
	XstGetSystemTime (@lostFocusMsec)
	XuiMonitorContext (grid, #MonitorContext, grid, &EnvironmentCode(), 0, 0, 0, $$FALSE)
	XuiMonitorMouse (grid, #MonitorMouse, grid, &EnvironmentCode(), 0, 0, 0, $$FALSE)
	XuiSendMessage (xitFileList, #HideWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  ContextChange  *****
'
SUB ContextChange
	IF (r0 == 0) THEN GOSUB Cancel
END SUB
'
'
' *****  MouseDown  *****   caused by #MonitorMouse when recent file list window is active
'
SUB MouseDown
	XgrGetGridParent (r1, @parent)
	IF (parent != xitFileList) THEN  'not any grid in FileList window
		IF (r1 != fileListPBGrid) THEN
			GOSUB Cancel
		END IF
	END IF
END SUB
'
'
' *****  Notify  *****  from XuiDropButton grid that displays file/function-list
'
SUB Notify
'
	IF (r0 == $FileListPB) THEN
		IF (v0 != -1) THEN EXIT SUB
		XstGetSystemTime (@lostFocusMsec)
		GOSUB Cancel
		IF ##XBDV THEN PRINT "EnvironmentCode()Notify:Cancel", v0, r0
		EXIT SUB
	END IF
'
	IF (v0 == -1) THEN EXIT SUB
'
	IF (r0 != $Function) THEN EXIT SUB															' bad kid
	IF (fileType != $$Program) THEN
		DIM name$[]                                                   ' blank function array
		XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, r0, @name$[])
		EXIT SUB                                                      ' ingore text
	END IF
	items = SortFunctionNames (@name$[], $$TRUE)										' include PROLOG
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, r0, @name$[])	' set function names
'
	XxxFunctionName ($$XGET, @name$, editFunction)
	viewLine = 0
	FOR i = 0 TO items - 1
		IF (name$ == name$[i]) THEN
			viewLine = i
			EXIT FOR
		END IF
	NEXT i
'
	IF viewLine THEN
		XuiSendMessage (grid, #GetTextCursor, 0, 0, 0, 0, r0, @rows)
		XuiSendMessage (grid, #SetTextCursor, 0, viewLine, 0, viewLine-(rows\2), r0, 0)
		XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, r0, 0)
	END IF
END SUB
'
'
' *****  Selection  *****  r0 = kid : xitMenu:  v0 = Menu heading # (1+) and v1 = pulldown entry (0+)
'
SUB Selection
	SELECT CASE r0
		CASE $HotProlog						: immediate$ = ".vv PROLOG"
																GOSUB Immediate
		CASE $HotNew							: FileNew(0)
		CASE $HotLoad							: FileLoad(0)
		CASE $HotSave							:	SELECT CASE TRUE
																	CASE makeBackupFile   : FileSave($$TRUE)
																	CASE xbasicBackupDir$ : FileSave($$TRUE)
																	CASE ELSE             : FileSave($$FALSE)
																END SELECT
																XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
		CASE $HotSavePlus					: FileSave(0)
		CASE $HotCut							: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
																XuiEditCut(0)
		CASE $HotCopy							: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
																XuiEditCopy(0)
		CASE $HotPaste						: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
																XuiEditPaste (xitTextLower, 0)
		CASE $HotGui							: XxxGuiDesignerOnOff (1)
																XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
		CASE $HotAbort						: softInterrupt = $$TRUE
																##USERABORT = $$TRUE
																##USERWAITING = $$FALSE
																XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
		CASE $HotFind							: button = v2{3,0}
																message = #FindForward
																IF (button = 2) THEN message = #FindReverse
																IF (v2 AND $$CtrlBit) THEN message = #FindReverse
																IF (v2 AND $$ShiftBit) THEN message = #DisplayWindow
																EditFind (findBox, message, 0, 0, 0, 0, $$FindFindButton, 0)
																XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
		CASE $HotReplace					: button = v2{4,0}
																message = #ReplaceForward
																IF (button = 2) THEN message = #ReplaceReverse
																IF (v2 AND $$CtrlBit) THEN message = #ReplaceReverse
																IF (v2 AND $$ShiftBit) THEN message = #DisplayWindow
																EditFind (findBox, message, 0, 0, 0, 0, $$FindReplaceButton, 0)
																XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
		CASE $HotBack							: immediate$ = ".v-"
																GOSUB Immediate
		CASE $HotNext							: immediate$ = ".v"
																GOSUB Immediate
		CASE $HotPrevious					: immediate$ = ".vp"
																GOSUB Immediate
		CASE $HotStart						: RunStart()
		CASE $HotContinue					: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																RunContinue()
		CASE $HotPause						: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																RunPause()
		CASE $HotKill							: RunKill()
																XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
		CASE $HotToCursor					: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																HotToCursor()
		CASE $HotStepLocal				: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																HotStepLocal()
		CASE $HotStepGlobal				: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																HotStepGlobal()
		CASE $HotStepOut					: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																HotStepOut ()
		CASE $HotToggleBreakpoint	: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																DebugToggle()
		CASE $HotClearBreakpoints	: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																DebugClear()
		CASE $HotVariables				: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																HotVariables (variableBox, #DisplayWindow, $$TRUE, 0, 0, 0, 0, 0)
		CASE $HotFrames						: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																HotFrames (framesBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		CASE $HotAssembly					: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																DebugAssembly (assemblyBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		CASE $HotRegisters				: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																DebugRegisters (registerBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		CASE $TextLower						: IF (v0{$$VirtualKey} = $$KeyEscape) THEN
																	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Command, "")
																	XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $Command, 0)
																	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $Command, 0)
																	XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
																END IF
		CASE $Function						: GOSUB Function
		CASE $FileListPB					: GOSUB FileList
		CASE $Command							: GOSUB Command
		CASE $MenuBar
				IF ((v0 < 1) OR (v1 < 0)) THEN RETURN
				SELECT CASE v0
					CASE 1
							SELECT CASE v1
								CASE 0:		FileNew (0)
								CASE 1:		FileTextLoad (0)
								CASE 2:		FileLoad (0)
								CASE 3:		SELECT CASE TRUE
														CASE makeBackupFile   : FileSave($$TRUE)
														CASE xbasicBackupDir$ : FileSave($$TRUE)
														CASE ELSE             : FileSave($$FALSE)
													END SELECT
								CASE 4:		FileSave ($$FALSE)       'Rename and Save
								CASE 5:		FileMode (0)
								CASE 6:		FileQuit ()
							END SELECT
					CASE 2
							XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
							SELECT CASE v1
								CASE 0:		XuiEditCut (0)
								CASE 1:		XuiEditCopy (0)
								CASE 2:		XuiEditPaste (xitTextLower, 0)
								CASE 3:		XuiEditCut (1)
								CASE 4:		XuiEditCopy (1)
								CASE 5:		XuiEditPaste (xitTextLower, 1)
								CASE 6:		XuiEditCut (-1)
								CASE 7:		EditFind (findBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 8:		EditRead (0)
								CASE 9:		EditWrite (0, 0)
								CASE 10:	EditWrite (0, 1)
								CASE 11:	EditWrite (0, ##CONGRID)
								CASE 12:	EditCleanBackup (cleanBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 13:	EditLoadBackup (backupBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
							END SELECT
					CASE 3
							SELECT CASE v1
								CASE 0:		ViewFunc (funcBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 1:		ViewPriorFunc ()
								CASE 2:		ViewNewFunc (viewNewBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 3:		ViewDeleteFunc (deleteFuncBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 4:		ViewRenameFunc (0)
								CASE 5:		ViewCloneFunc (0)
								CASE 6:		ViewLoadFunc (0)
								CASE 7:		ViewSaveFunc (0)
								CASE 8:		ViewMergePROLOG (0)
								CASE 9:		ViewImportFunctionFromProgram (0)
								CASE 10:	XxxGuiDesignerOnOff (1)
							END SELECT
					CASE 4
							SELECT CASE v1
								CASE 0:		XuiSendMessage (optionMiscBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 1:		XuiSendMessage (textCursor, #SetColor, xitCursorLineColor, -1, -1, -1, 5, 0)
													XuiSendMessage (textCursor, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 2:		OptionTabWidth (0)
							END SELECT
					CASE 5
							SELECT CASE v1
								CASE 0:		RunStart ()
								CASE 1:		RunContinue ()
								CASE 2:		RunJump ()
								CASE 3:		RunPause ()
								CASE 4:		RunKill ()
								CASE 5:		XstClearConsole ()
								CASE 6:		IF saveBeforeCompile && textAlteredSinceSave THEN
														IFZ FileSave ($$TRUE) THEN RunRecompile ()
													ELSE
														RunRecompile ()
													END IF
								CASE 7:		IF saveBeforeCompile && textAlteredSinceSave THEN
														IFZ FileSave ($$TRUE) THEN RunAssembler ()
													ELSE
														RunAssembler ()
													END IF
								CASE 8:		IF saveBeforeCompile && textAlteredSinceSave THEN
														IFZ FileSave ($$TRUE) THEN RunLibrary ()
													ELSE
														RunLibrary ()
													END IF
								CASE 9:		RunMake ()
								CASE 10:	RunStandalone ()
							END SELECT
					CASE 6
							SELECT CASE v1
								CASE 0:		DebugToggle ()
								CASE 1:		DebugClear ()
								CASE 2:		DebugErase ()
								CASE 3:		XuiSendMessage (memoryBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 4:		DebugAssembly (assemblyBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 5:		DebugRegisters (registerBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 6:		BPTraceOn ()
								CASE 7:		BPTraceOff ()
							END SELECT
					CASE 7
							SELECT CASE v1
								CASE 0:		WizardCompErrors (errorBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 1:		XuiSendMessage (runtimeErrorBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE 2:		ClearErrors ()
							END SELECT
					CASE 8
							SELECT CASE v1
								CASE  0:  XuiSendMessage (helpIndexBox, #HideWindow, 0, 0, 0, 0, 0, 0)
													XuiSendMessage (helpIndexBox, #SetStyle, $StyleNotify OR $Style2, 0, 0, 0, 0, 0)
													XuiSendMessage (helpIndexBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE  1:  XuiSendMessage (helpIndexBox, #HideWindow, 0, 0, 0, 0, 0, 0)
													XuiSendMessage (helpIndexBox, #SetStyle, $Style2, 0, 0, 0, 0, 0)
													XuiSendMessage (helpIndexBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE  2:
									IF ##XBSystem = $$XBSysLinux THEN
										XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/README.Linux:*")
									ELSE
										XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/README.Win32:*")
									END IF
								CASE  3:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/changelog.hlp:*")
								CASE  4:	XuiSendMessage (aboutGrid, #DisplayWindow, 0, 0, 0, 0, 0, 0)
								CASE  5:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/support.hlp:*")
								CASE  6:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/messagelist.hlp:*")
								CASE  7:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/languagelist.hlp:*")
								CASE  8:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/lang.hlp:Operator Summary")
								CASE  9:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/command.hlp:*")
								CASE 10:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/include/xst.dec:*")
								CASE 11:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/include/xgr.dec:*")
								CASE 12:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/include/xui.dec:*")
								CASE 13:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/include/xma.dec:*")
								CASE 14:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/include/xcm.dec:*")
								CASE 15:	XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/include/xin.dec:*")
							END SELECT
				END SELECT
	END SELECT
END SUB
'
'
' *****  Immediate  *****
'
SUB Immediate
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Command, @immediate$)
	ImmediateMode (0x0D10000D)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Command, "")
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $Command, 0)
END SUB
'
'
' *****  FileList  *****  display recent filename list
'
SUB FileList
'
	IF (v0 == -1) THEN                    ' v0 = -1 for cancel
		XstGetSystemTime (@lostFocusMsec)
		GOSUB Cancel
		EXIT SUB
	END IF
'
	IF (v2 == fileListPBGrid) THEN
		XgrGetGridWindow (xitFileList, @fileListWindow)
		XgrGetWindowState (fileListWindow, @visible)
		IF visible THEN
			XuiSendMessage (xitFileList, #HideWindow, 0, 0, 0, 0, 0, 0)
			GOSUB Cancel
			XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
			EXIT SUB
		ELSE
			'
			' Don't show the file list if it has just been hidden
			'
			XstGetSystemTime (@msec)
			IF ((msec - lostFocusMsec) < 500) THEN
				XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
				EXIT SUB
			END IF
			'
			IFZ recentFile$[] THEN EXIT SUB
			'
			GOSUB ValidateFileList
			XuiSendMessage (grid, #GetGridNumber, @fileListPBGrid, 0, 0, 0, $FileListPB, 0)
			XgrGetGridPositionAndSize (fileListPBGrid, @xGrid, @yGrid, @wGrid, @hGrid)
			XgrConvertWindowToDisplay (grid, 0, 0, @xWin, @yWin)
			XgrGetGridFont (xitFileList, @font)
			XgrGetTextArrayImageSize (font, @recentFile$[], @wTxt, @hTxt, 0, 0, 0, 0)
			wTxt = wTxt + 28
			IF (wTxt < wGrid) THEN wTxt = wGrid
			xMax = xGrid + wGrid + wGrid
			xTxt = xMax - wTxt
			IF (xTxt > xGrid) THEN
				xTxt = xGrid
			ELSE
				IF (xTxt < 0) THEN
					xTxt = 0
					wTxt = xMax
				END IF
			END IF
			XuiSendMessage (xitFileList, #ResizeWindow, xWin+xTxt, yWin+yGrid+hGrid, wTxt, hTxt+24, 0, 0)
			XuiSendMessage (xitFileList, #DisplayWindow, 0, 0, 0, 0, 0, 0)
			XuiSendMessage (xitFileList, #SetKeyboardFocus, 0, 0, 0, 0, 0, 0)
			XuiMonitorMouse (grid, #MonitorMouse, grid, &EnvironmentCode(), 0, 0, 0, $$TRUE)
			XuiMonitorContext (grid, #MonitorContext, grid, &EnvironmentCode(), 0, 0, 0, $$TRUE)
		END IF
	END IF
'
	IF (v2 != xitFileList) THEN EXIT SUB
'
' recent file selected, v0 = index to recent file list
'
	IFZ (v0 > uRecent) THEN FileListFuncSet ()
	IFZ (v0 < 0) THEN FileListFuncSet ()
	FileRecentLoad (v0)
	XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
'
END SUB
'
'
' *****  ValidateFileList  *****
'
' remove any file from the list if it does not still exist
'
SUB ValidateFileList
	IFZ recentFile$[] THEN EXIT SUB
	uRecent = UBOUND (recentFile$[])
	IF (uRecent < 0) THEN EXIT SUB
	i = 0
	DO
		fileName$ = recentFile$[i]
		XstGetFileAttributes (fileName$, @attributes)
		IF (attributes AND ($$FileNormal OR $$FileArchive OR $$FileReadOnly)) THEN
			INC i
		ELSE
			FOR j = i TO (uRecent - 1)
				recentFile$[j] = recentFile$[j+1]
				recentFunc$[j] = recentFunc$[j+1]
				recentCursor[j] = recentCursor[j+1]
			NEXT j
			DEC uRecent
		END IF
		IF (i > uRecent) THEN EXIT DO
	LOOP
	IF (uRecent < 0) THEN EXIT SUB
	REDIM recentFile$[uRecent]
	REDIM recentFunc$[uRecent]
	REDIM recentCursor[uRecent]
	XuiSendMessage (xitFileList, #SetTextArray, 0, 0, 0, 0, 0, @recentFile$[])
END SUB
'
'
' *****  Function  *****  display selected function
'
SUB Function
'
	IF (fileType != $$Program) THEN EXIT SUB												' text file
	IF (v0 < 0) THEN EXIT SUB																				' nothing
'
	XuiSendMessage (grid, #GetTextArray, 0, 0, 0, 0, r0, @funcname$[])
'
	funcname$ = ""
	upper = UBOUND (funcname$[])
	IF (v0 <= upper) THEN funcname$ = funcname$[v0]
	IFZ funcname$ THEN EXIT SUB
'
	ViewFunc (funcBox, #View, 0, 0, 0, 0, 0, @funcname$)
END SUB
'
'
' *****  Command  *****  immediate command selected from list
'
SUB Command
	XuiSendMessage (grid, #GetTextArray, 0, 0, 0, 0, r0, @command$[])
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, r0, @command$)
	upper = UBOUND (command$[])
'
'	PRINT "EnvironmentCode().Command.a :::  "; grid; message; v0; v1; v2; v3; r0; r1, HEX$(v2,8), upper;; command$
'
'	IF (v0 == -1) THEN
'		PRINT "EnvironmentCode().Command.b :::  "; grid; message; v0; v1; v2; v3; r0; r1, HEX$(v2,8), upper;; command$
'		ImmediateMode (0x0D10000D)
'	END IF
'
	IF (v0 >= 0) AND (v0 <= upper) THEN
		command$ = command$[v0]
'		PRINT "EnvironmentCode().Command.c :::  "; grid; message; v0; v1; v2; v3; r0; r1, HEX$(v2,8), upper;; command$
		AddCommandItem (@command$)
'		XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, r0, @command$)
'		XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, r0, 0)
'		ImmediateMode (0x0D10000D)
	END IF
'
'	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, r0, "")
'	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, r0, 0)
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	IF (r0 == $Command) THEN
		IF (v2{$$VirtualKey} == $$KeyEnter) THEN
			XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $Command, @command$)
			AddCommandItem (@command$)
			ImmediateMode (v2)
			XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
			r0 = -1
		END IF
		IF (v2{$$VirtualKey} == $$KeyEscape) THEN
			XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
			r0 = -1
		END IF
		EXIT SUB
	END IF
'
	IF (r0 != $TextLower) THEN EXIT SUB
	XgrGetKeystateModify (v2, @modify, @edit)
	IFZ modify THEN EXIT SUB
'
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Command, "")
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $Command, 0)
'
' If the needBlowback is set, it indicates a previous
' TextEvent did not send a #TextModified message
'
	IF needBlowback THEN
		PRINT "EnvironmentCode(684)needBlowback set!!!", needBlowback
		GOSUB TextModified     ' process needBlowback now
		r0 = -1                ' abort this modification
		EXIT SUB
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		message$ = "??? stop program execution ???"
		warningResponse = WarningResponse (@message$, @" stop ", "")
		IF (warningResponse = $$WarningCancel) THEN
			r0 = -1																		' abort modification
			EXIT SUB
		END IF
		'
		' Strange things can happen if a blowback is done at the same time
		' as text is being modified. So just set the "needBlowback" indicator
		' and do the blowback when the #TextModified message is received.
		'
		needBlowback = $$TRUE  ' do blowback when #TextModified received
		##USERWAITING = $$FALSE			' unblock waiting in INLINE$()
		##USERABORT = $$TRUE        ' unblock waiting in XstFindFiles
	END IF
'
	IFZ textAlteredSinceSave THEN
		textAlteredSinceSave = $$TRUE
		UpdateFileFuncLabels ($$TRUE, 0)						' reset file name
	END IF
	IF (fileType != $$Program) THEN EXIT SUB			' done if Text mode
'
' By modifying the text, the user is forced to recompile before running
'
	IFZ programAltered THEN
		programAltered = $$TRUE
		BreakProgrammer ($$BreakClearAll, 0, 0)
	END IF
'
	funcAltered[editFunction] = $$TRUE
	funcNeedsTokenizing[editFunction] = $$TRUE
'
END SUB
'
'
' *****  TextModified  *****
'
SUB TextModified
	IF needBlowback THEN
		haltedByEdit = $$TRUE
		XxxSetBlowback ()
		AddDispatch (&ResetDataDisplays(), $$ResetAssembly)
		needBlowback = $$FALSE
	END IF
'
END SUB
'
END FUNCTION
'
'
' ##################################
' #####  WelcomeWindowCode ()  #####
' ##################################
'
FUNCTION  WelcomeWindowCode (grid, message, v0, v1, v2, v3, r0, r1)
'
	IF (message == #Callback) THEN message = r1
'
	SELECT CASE message
		CASE #Selection			: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END FUNCTION
'
'
' #######################  processes system messages only
' #####  XitCEO ()  #####  #WindowKeyDown: v2 = state
' #######################
'
FUNCTION  XitCEO (winGrid, message, v0, v1, v2, v3, r0, r1)
	SHARED  assemblyBox,  findBox,  framesBox,  variableBox
'
'	XgrMessageNumberToName (message, @message$)
'	PRINT "XitCEO(): "; winGrid, message$, v0, v1, HEX$(v2,8), HEX$(v3,8), r0, r1
'	XxxLog ("XitCEO(): " + message$)
'
	SELECT CASE message
		CASE  #WindowKeyDown
			ctrl = v2 AND $$CtrlBit
			shift = v2 AND $$ShiftBit
'			PRINT "XitCEO", !!ctrl, !!shift, v2{$$VirtualKey}
			r0 = $$TRUE
			SELECT CASE v2{$$VirtualKey}
				CASE $$KeyF1:			RunStart()
				CASE $$KeyF2:			RunContinue()
				CASE $$KeyF3:			RunPause()
				CASE $$KeyF4:			RunKill()
				CASE $$KeyF5:			HotToCursor()
				CASE $$KeyF6:			HotStepLocal()
				CASE $$KeyF7:			XitF7()
				CASE $$KeyF8:			HotVariables (variableBox, #DisplayWindow, $$TRUE, 0, 0, 0, 0, 0)
				CASE $$KeyF9:			HotFrames (framesBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
				CASE $$KeyF10:		DebugAssembly (assemblyBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
				CASE $$KeyF11:		message = #FindForward
													IF ctrl THEN message = #FindReverse
													IF shift THEN message = #DisplayWindow
													EditFind (findBox, message, 0, 0, 0, 0, 0, 0)
				CASE $$KeyF12:		message = #ReplaceForward
													IF ctrl THEN message = #ReplaceReverse
													IF shift THEN message = #DisplayWindow
													EditFind (findBox, message, 0, 0, 0, 0, 0, 0)
				CASE $$KeyPause:  XitSoftBreak()
				CASE ELSE:        r0 = $$FALSE
			END SELECT
	END SELECT
END FUNCTION
'
'
' #########################
' #####  XitArray ()  #####
' #########################
'
FUNCTION  XitArray (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitArray
'
	$functionLabel	= 1
	$symbolLabel		= 2
	$columnLabel		= 3
	$list						= 4
	$higherButton		= 5
	$lowerButton		= 6
	$indexLabel			= 7
	$indexText			= 8
	$elementLabel		= 9
	$elementText		= 10
	$button0				= 11
	$button1				= 12
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitArray) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh in window : r0 = window
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitArray, v0, v1, v2, v3, r0, r1, &XitArray())
	XuiLabel       (@g, #Create, 4, 4, 536, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"funcLine")
	XuiLabel       (@g, #Create, 4, 24, 536, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"arrayName")
	XuiLabel       (@g, #Create, 4, 44, 536, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelHeading")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"index       location     hex               value      ")
	XuiList        (@g, #Create, 4, 64, 536, 120, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitArray(), -1, -1, $list, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"list")
	XuiPushButton  (@g, #Create, 4, 184, 268, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitArray(), -1, -1, $higherButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonNextHigher")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"<<<  next higher dimension <<<")
	XuiPushButton  (@g, #Create, 272, 184, 268, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitArray(), -1, -1, $lowerButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonNextLower")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @">>>  next lower dimension >>>")
	XuiLabel       (@g, #Create, 4, 204, 224, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelViewIndex")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"view index [0-##########]  ")
	XuiTextLine    (@g, #Create, 4, 224, 224, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitArray(), -1, -1, $indexText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"index")
	XuiLabel       (@g, #Create, 228, 204, 312, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelViewElement")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"view element [i,j,]")
	XuiTextLine    (@g, #Create, 228, 224, 312, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitArray(), -1, -1, $elementText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"element")
	XuiPushButton  (@g, #Create, 4, 244, 268, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitArray(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonDetail")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" detail ")
	XuiPushButton  (@g, #Create, 272, 244, 268, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitArray(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****   v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Array Detail")
END SUB
'
'
' *****  GetSmallestSize  *****  Return v23 = smallest wh
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @functionLabelWidth, @functionLabelHeight, $functionLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @symbolLabelWidth, @symbolLabelHeight, $symbolLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @columnLabelWidth, @columnLabelHeight, $columnLabel, 16)
'
	XuiSendToKid (grid, #GetSmallestSize, 20, 4, @listWidth, @listHeight, $list, 16)
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @higherButtonWidth, @higherButtonHeight, $higherButton, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @lowerButtonWidth, @lowerButtonHeight, $lowerButton, 16)
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @indexLabelWidth, @indexLabelHeight, $indexLabel, 8)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @indexTextHeight, $indexText, 8)
'
	buttonWidth = 12
	buttonHeight = 12
	FOR i = $button0 TO $button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 12)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = functionLabelWidth
	IF (width < symbolLabelWidth) THEN width = symbolLabelWidth
	IF (width < columnLabelWidth) THEN width = columnLabelWidth
	whilo = higherButtonWidth + lowerButtonWidth
	IF (width < whilo) THEN width = whilo
	wb0b1 = buttonWidth + buttonWidth
	IF (width < wb0b1) THEN width = wb0b1
	IF (width < listWidth) THEN width = listWidth
	v2 = width + bw + bw
	v3 = functionLabelHeight + symbolLabelHeight + columnLabelHeight
	v3 = v3 + listHeight + higherButtonHeight
	v3 = v3 + indexLabelHeight + indexTextHeight
	v3 = v3 + buttonHeight + bw + bw
	minW = v2
	minH = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minH
'
	IF (v3 > (h + 4)) THEN
		buttonHeight = buttonHeight + 4									:	h = h + 4
		IF (v3 > (h + 12)) THEN
			functionLabelHeight = functionLabelHeight + 4	:	h = h + 12
			symbolLabelHeight = symbolLabelHeight + 4
			columnLabelHeight = columnLabelHeight + 4
			IF (v3 > (h + 4)) THEN
				higherButtonHeight = higherButtonHeight + 4	:	h = h + 4
				IF (v3 > (h + 8)) THEN
					indexLabelHeight = indexLabelHeight + 4
					indexTextHeight = indexTextHeight + 4
				END IF
			END IF
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = functionLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $functionLabel, 0)
'
	y = y + h
	h = symbolLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $symbolLabel, 0)
'
	y = y + h
	h = columnLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $columnLabel, 0)
'
	y = y + h
	h = v3 - functionLabelHeight - symbolLabelHeight - columnLabelHeight
	h = h - higherButtonHeight - indexLabelHeight - indexTextHeight
	h = h - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $list, 0)
'
	y = y + h
	w = w >> 1
	h = higherButtonHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $higherButton, 0)
	x = x + w
	w = v2 - w - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $lowerButton, 0)
'
	x = bw
	y = y + h
	w = indexLabelWidth
	h = indexLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $indexLabel, 0)
	y = y + h
	h = indexTextHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $indexText, 0)
'
	x = x + w
	y = y - indexLabelHeight
	w = v2 - indexLabelWidth - bw - bw
	h = indexLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $elementLabel, 0)
	y = y + h
	h = indexTextHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $elementText, 0)
'
	x = bw
	y = y + h
	h = buttonHeight
	w1 = (v2 - bw - bw) >> 1
	w2 = v2 - w1 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button0, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitArray() : Initialize: error ::: undefined message"
	IF sub[0] THEN PRINT "XitArray() : Initialize: error ::: undefined message"
	XuiRegisterGridType (@XitArray, @"XitArray", &XitArray(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 544
	designHeight = 268
'
	gridType = XitArray
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $indexText)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ############################
' #####  XitAssembly ()  #####
' ############################
'
FUNCTION  XitAssembly (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitAssembly
'
	$label		= 1
	$textArea	= 2
	$button0	= 3
	$button1	= 4
	$button2	= 5
	$button3	= 6
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitAssembly) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitAssembly, @v0, @v1, @v2, @v3, r0, r1, &XitAssembly())
	XuiLabel       (@g, #Create, 4, 4, 588, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Location")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiTextArea    (@g, #Create, 4, 24, 588, 112, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitAssembly(), 0, 0, $textArea, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Assembly")
	XuiPushButton  (@g, #Create, 4, 136, 147, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitAssembly(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonNext")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" next ")
	XuiPushButton  (@g, #Create, 151, 136, 147, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitAssembly(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCurrent")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" current ")
	XuiPushButton  (@g, #Create, 298, 136, 147, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitAssembly(), -1, -1, $button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonBack")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" back ")
	XuiPushButton  (@g, #Create, 445, 136, 147, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitAssembly(), -1, -1, $button3, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, 0, 0)
	XgrGetFontMetrics (font, @maxCharWidth, 0, 0, 0, 0, 0)
	XuiSendMessage ( grid, #SetTabWidth, (maxCharWidth << 3), 0, 0, 0, $textArea, 0)
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0 <= 0) THEN v0 = designX
	IF (v1 <= 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Assembly")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @labelHeight, $label, 16)
	XuiSendToKid (grid, #GetSmallestSize, 20, 4, @areaWidth, @areaHeight, $textArea, 16)
'
	buttonWidth = 12
	buttonHeight = 12
	FOR i = $button0 TO $button3
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 12)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth << 2
	width = MAX (width, areaWidth)
	width = MAX (width, lineWidth)
	v2 = width + bw + bw
	v3 = labelHeight + areaHeight + buttonHeight + bw + bw
	minX = v2
	minY = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minY
'
	IF (v3 > (h + 4)) THEN
		buttonHeight = buttonHeight + 4	: h = h + 4
		IF (v3 > (h + 4)) THEN
			labelHeight = labelHeight + 4
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = labelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $label, 0)
'
	y = y + h
	h = v3 - labelHeight - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $textArea, 0)
'
	y = y + h
	h = buttonHeight
	w1 = w >> 2
	w2 = v2 - (w1 + w1 + w1) - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button0, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button2, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button3, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
	func[#TextEvent]					= &XuiTextModifyNot()
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitAssembly() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitAssembly() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitAssembly, @"XitAssembly", &XitAssembly(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 596
	designHeight = 160
'
	gridType = XitAssembly
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $textArea)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  XitComposite ()  #####
' #############################
'
FUNCTION  XitComposite (grid, message, v0, v1, v2, v3, r0, r1)
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitComposite
'
	$functionLabel	=  1
	$symbolLabel		=  2
	$columnLabel		=  3
	$list						=  4
	$higherButton		=  5
	$lowerButton		=  6
	$viewLabel			=  7
	$viewText				=  8
	$button0				=  9
	$button1				= 10
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitComposite) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh in window : r0 = window
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitComposite, @v0, @v1, @v2, @v3, r0, r1, &XitComposite())
	XuiLabel       (@g, #Create, 4, 4, 584, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelFunction")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyCenter, -1, -1, 0, 0)
	XuiLabel       (@g, #Create, 4, 24, 584, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelSymbol")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyCenter, -1, -1, 0, 0)
	XuiLabel       (@g, #Create, 4, 44, 584, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelColumn")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"type       symbol                location   hex               value     ")
	XuiList        (@g, #Create, 4, 64, 584, 72, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitComposite(), -1, -1, $list, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"listElement")
	XuiPushButton  (@g, #Create, 4, 136, 292, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitComposite(), -1, -1, $higherButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonHigher")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" <<<  next higher composite <<< ")
	XuiPushButton  (@g, #Create, 296, 136, 292, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitComposite(), -1, -1, $lowerButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonLower")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" >>>  next lower composite >>> ")
	XuiLabel       (@g, #Create, 4, 156, 584, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelElement")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" view element:  .a.b.c ")
	XuiTextLine    (@g, #Create, 4, 176, 584, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitComposite(), -1, -1, $viewText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"element")
	XuiPushButton  (@g, #Create, 4, 196, 292, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitComposite(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonDetail")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" detail ")
	XuiPushButton  (@g, #Create, 296, 196, 292, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitComposite(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Composite Detail")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @bw)
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @functionLabelWidth, @functionLabelHeight, $functionLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @symbolLabelWidth, @symbolLabelHeight, $symbolLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @columnLabelWidth, @columnLabelHeight, $columnLabel, 16)
'
	XuiSendToKid (grid, #GetSmallestSize, 20, 4, @listWidth, @listHeight, $list, 16)
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @higherWidth, @higherHeight, $higherButton, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @lowerWidth, @lowerHeight, $lowerButton, 16)
	hiloWidth = MAX(higherWidth, lowerWidth) << 1
	hiloHeight = MAX(higherHeight, lowerHeight)
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @viewLabelHeight, $viewLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @viewTextHeight, $viewText, 16)
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth
	IF (width < functionLabelWidth) THEN width = functionLabelWidth
	IF (width < symbolLabelWidth) THEN width = symbolLabelWidth
	IF (width < columnLabelWidth) THEN width = columnLabelWidth
	IF (width < listWidth) THEN width = listWidth
	IF (width < hiloWidth) THEN width = hiloWidth
	v2 = width + bw + bw
	v3 = functionLabelHeight + symbolLabelHeight + columnLabelHeight
	v3 = v3 + listHeight + hiloHeight
	v3 = v3 + viewLabelHeight + viewTextHeight + buttonHeight + bw + bw
	minW = v2
	minH = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(vv2, v2)
	v3 = MAX(vv3, v3)
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minH
'
	IF (v3 > (h + 4)) THEN
		buttonHeight = buttonHeight + 4										:	h = h + 4
		IF (v3 > (h + 4)) THEN
			higherHeight = higherHeight + 4									:	h = h + 4
			IF (v3 > (h + 12)) THEN
				functionLabelHeight = functionLabelHeight + 4	:	h = h + 12
				symbolLabelHeight = symbolLabelHeight + 4
				columnLabelHeight = columnLabelHeight + 4
				IF (v3 > (h + 8)) THEN
					viewLabelHeight = viewLabelHeight + 4
					viewTextHeight = viewTextHeight + 4
				END IF
			END IF
		END IF
	END IF
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = functionLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $functionLabel, 0)
'
	y = y + h
	h = symbolLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $symbolLabel, 0)
'
	y = y + h
	h = columnLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $columnLabel, 0)
'
	y = y + h
	h = v3 - functionLabelHeight - symbolLabelHeight - columnLabelHeight
	h = h - higherHeight - viewLabelHeight - viewTextHeight
	h = h - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $list, 0)
'
	y = y + h
	h = higherHeight
	w1 = (v2 - bw - bw) >> 1
	w2 = v2 - w1 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w2, h, $higherButton, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $lowerButton, 0)
'
	x = bw
	y = y + h
	w = v2 - bw - bw
	h = viewLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $viewLabel, 0)
	y = y + h
	h = viewTextHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $viewText, 0)
'
	y = y + h
	h = buttonHeight
	w1 = w >> 1
	w2 = v2 - w1 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button0, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitComposite() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitComposite() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitComposite, @"XitComposite", &XitComposite(), @func[], @sub[])
'
	designX = 4
	designY = 23
	designWidth = 592
	designHeight = 220
'
	gridType = XitComposite
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $viewText)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
'	###############################
'	#####  Xit2LineDialog ()  #####
'	###############################
'
FUNCTION  Xit2LineDialog (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  Xit2LineDialog
'
	$label0		= 1
	$text0		= 2	: $focusKid = 2
	$label1		= 3
	$text1		= 4
	$button0	= 5
	$button1	= 6
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, Xit2LineDialog) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
'	*****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, Xit2LineDialog, v0, v1, v2, v3, r0, r1, &Xit2LineDialog())
	XuiLabel       (@g, #Create, 4, 24, 372, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"label0")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, 4, 0, 0, 0)
	XuiTextLine    (@g, #Create, 4, 44, 372, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit2LineDialog(), -1, -1, $text0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"text0")
	XuiLabel       (@g, #Create, 4, 64, 372, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"label1")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, 4, 0, 0, 0)
	XuiTextLine    (@g, #Create, 4, 84, 372, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit2LineDialog(), -1, -1, $text1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"text1")
	XuiPushButton  (@g, #Create, 4, 144, 124, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit2LineDialog(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonOk")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" ok ")
	XuiPushButton  (@g, #Create, 128, 144, 124, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit2LineDialog(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
'	*****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Xit2LineDialog")
END SUB
'
'
'	*****  GetSmallestSize  *****  Return v23 = smallest wh
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	labelWidth = 16
	labelHeight = 16
	FOR i = $label0 TO $label1 STEP 2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > labelWidth) THEN labelWidth = width
		IF (height > labelHeight) THEN labelHeight = height
	NEXT i
'
	textHeight = 0
	FOR i = $text0 TO $text1 STEP 2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @height, i, 16)
		IF (height > textHeight) THEN textHeight = height
	NEXT i
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	buttonWidth = buttonWidth + buttonWidth + buttonWidth
'
	width = MAX(buttonWidth, labelWidth) + bw + bw
	height = labelHeight + textHeight
	height = height + height + buttonHeight + bw + bw
	v2 = width
	v3 = height
	minX = v2
	minY = v3
END SUB
'
'
'	*****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, v0, v1, v2, v3)
	h = labelHeight + textHeight
	h = h + h + buttonHeight + bw + bw
	IF (v3 >= (h + 4)) THEN
		buttonHeight = buttonHeight + 4		:	h = h + 4
		IF (v3 >= (h + 8)) THEN
			textHeight = textHeight + 4
		END IF
	END IF
'
'	Resize kids
'
	width = v2 - bw - bw
	x = bw
	y = bw
	w = width
	ht = textHeight
	h = ht + ht + buttonHeight + bw + bw
	h1 = (v3 - h) >> 1
	h2 = v3 - h - h1
	XuiSendToKid (grid, #Resize, x, y, w, h2, $label0, 0)	: y = y + h2
	XuiSendToKid (grid, #Resize, x, y, w, ht, $text0, 0)	: y = y + ht
	XuiSendToKid (grid, #Resize, x, y, w, h1, $label1, 0)	: y = y + h1
	XuiSendToKid (grid, #Resize, x, y, w, ht, $text1, 0)	: y = y + ht
'
	w1 = w >> 1
	w2 = w - w1
	h = buttonHeight
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button0, 0):	x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "Xit2LineDialog() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "Xit2LineDialog() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@Xit2LineDialog, "Xit2LineDialog", &Xit2LineDialog(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 512
	designHeight = 128
'
	gridType = Xit2LineDialog
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus)
	XuiSetGridTypeValue (gridType, @"focusKid",      $focusKid)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
'	###############################
'	#####  Xit3LineDialog ()  #####
'	###############################
'
FUNCTION  Xit3LineDialog (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  Xit3LineDialog
'
	$label0		= 1
	$text0		= 2	: $focusKid = 2
	$label1		= 3
	$text1		= 4
	$button0	= 5
	$button1	= 6
	$button2	= 7
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, Xit3LineDialog) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
'	*****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, Xit3LineDialog, v0, v1, v2, v3, r0, r1, &Xit3LineDialog())
	XuiLabel       (@g, #Create, 4, 24, 380, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"label0")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, 4, 0, 0, 0)
	XuiTextLine    (@g, #Create, 4, 44, 372, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit3LineDialog(), -1, -1, $text0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"text0")
	XuiLabel       (@g, #Create, 4, 64, 372, 20, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"label1")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, 4, 0, 0, 0)
	XuiTextLine    (@g, #Create, 4, 84, 372, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit3LineDialog(), -1, -1, $text1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"text1")
	XuiPushButton  (@g, #Create, 4, 144, 124, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit3LineDialog(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonOk")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" ok ")
	XuiPushButton  (@g, #Create, 128, 144, 124, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit3LineDialog(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonBrowse")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" browse ")
	XuiPushButton  (@g, #Create, 252, 144, 124, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Xit3LineDialog(), -1, -1, $button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
'	*****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Xit3LineDialog")
END SUB
'
'
'	*****  GetSmallestSize  *****  Return v23 = smallest wh
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	labelWidth = 16
	labelHeight = 16
	FOR i = $label0 TO $label1 STEP 2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > labelWidth) THEN labelWidth = width
		IF (height > labelHeight) THEN labelHeight = height
	NEXT i
'
	textHeight = 0
	FOR i = $text0 TO $text1 STEP 2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @height, i, 16)
		IF (height > textHeight) THEN textHeight = height
	NEXT i
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	buttonWidth = buttonWidth + buttonWidth + buttonWidth
'
	width = MAX(buttonWidth, labelWidth) + bw + bw
	height = labelHeight + textHeight
	height = height + height + buttonHeight + bw + bw
	v2 = width
	v3 = height
	minX = v2
	minY = v3
END SUB
'
'
'	*****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, v0, v1, v2, v3)
	h = labelHeight + textHeight
	h = h + h + buttonHeight + bw + bw
	IF (v3 >= (h + 4)) THEN
		buttonHeight = buttonHeight + 4		:	h = h + 4
		IF (v3 >= (h + 8)) THEN
			textHeight = textHeight + 4
		END IF
	END IF
'
'	Resize kids
'
	width = v2 - bw - bw
	x = bw
	y = bw
	w = width
	ht = textHeight
	h = ht + ht + buttonHeight + bw + bw
	h1 = (v3 - h) >> 1
	h2 = v3 - h - h1
	XuiSendToKid (grid, #Resize, x, y, w, h2, $label0, 0)	: y = y + h2
	XuiSendToKid (grid, #Resize, x, y, w, ht, $text0, 0)	: y = y + ht
	XuiSendToKid (grid, #Resize, x, y, w, h1, $label1, 0)	: y = y + h1
	XuiSendToKid (grid, #Resize, x, y, w, ht, $text1, 0)	: y = y + ht
'
	w0 = w \ 3
	w1 = w - w0 - w0
	w2 = w0
	h = buttonHeight
	XuiSendToKid (grid, #Resize, x, y, w0, h, $button0, 0):	x = x + w0
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0):	x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button2, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "Xit3LineDialog() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "Xit3LineDialog() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@Xit3LineDialog, "Xit3LineDialog", &Xit3LineDialog(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 512
	designHeight = 128
'
	gridType = Xit3LineDialog
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus)
	XuiSetGridTypeValue (gridType, @"focusKid",      $focusKid)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ################################
' #####  XitErrorCompile ()  #####
' ################################
'
FUNCTION  XitErrorCompile (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitErrorCompile
'
	$label0		= 1
	$label1		= 2
	$button0	= 3
	$button1	= 4
	$button2	= 5
	$button3	= 6
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitErrorCompile) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitErrorCompile, @v0, @v1, @v2, @v3, r0, r1, &XitErrorCompile())
	XuiLabel       (@g, #Create, 4, 4, 368, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "sourceLine")
	XuiLabel       (@g, #Create, 4, 24, 368, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "errorCode")
	XuiPushButton  (@g, #Create, 4, 44, 92, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitErrorCompile(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "buttonNext")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" next ")
	XuiPushButton  (@g, #Create, 96, 44, 92, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitErrorCompile(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "buttonCurrent")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" current ")
	XuiPushButton  (@g, #Create, 188, 44, 92, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitErrorCompile(), -1, -1, $button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "buttonPrevious")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" previous ")
	XuiPushButton  (@g, #Create, 280, 44, 92, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitErrorCompile(), -1, -1, $button3, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Compilation Errors")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	labelWidth = 16
	labelHeight = 16
	FOR i = $label0 TO $label1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > labelWidth) THEN labelWidth = width
		IF (height > labelHeight) THEN labelHeight = height
	NEXT i
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button3
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth << 2
	width = MAX (width, labelWidth)
	v2 = width + bw + bw
	v3 = labelHeight + labelHeight + buttonHeight + bw + bw
	minX = v2
	minY = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = labelHeight + labelHeight + buttonHeight + bw + bw
	IF (v3 > (h + 4)) THEN buttonHeight = buttonHeight + 4
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = v3 - buttonHeight - bw - bw
	h1 = h >> 1
	h2 = h - h1
	XuiSendToKid (grid, #Resize, x, y, w, h1, $label0, 0) : y = y + h1
	XuiSendToKid (grid, #Resize, x, y, w, h2, $label1, 0)
'
	y = y + h2
	h = buttonHeight
	w1 = w >> 2
	w2 = v2 - (w1 + w1 + w1) - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button0, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button2, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button3, 0) : x = x + w1
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitErrorCompile() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitErrorCompile() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitErrorCompile, @"XitErrorCompile", &XitErrorCompile(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 376
	designHeight = 68
'
	gridType = XitErrorCompile
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $button0)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ################################
' #####  XitErrorRuntime ()  #####
' ################################
'
FUNCTION  XitErrorRuntime (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitErrorRuntime
'
	$label0	= 1
	$label1	= 2
	$button	= 3
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitErrorRuntime) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitErrorRuntime, @v0, @v1, @v2, @v3, r0, r1, &XitErrorRuntime())
	XuiLabel       (@g, #Create, 4, 4, 368, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "runtimeInfo")
	XuiLabel       (@g, #Create, 4, 24, 368, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "runtimeMsg")
	XuiPushButton  (@g, #Create, 4, 44, 368, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitErrorRuntime(), -1, -1, $button, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, "buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Runtime Error")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	labelWidth = 16
	labelHeight = 16
	FOR i = $label0 TO $label1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > labelWidth) THEN labelWidth = width
		IF (height > labelHeight) THEN labelHeight = height
	NEXT i
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, $button, 16)
	buttonWidth = width
	buttonHeight = height
	width = buttonWidth
	width = MAX (width, labelWidth)
	v2 = width + bw + bw
	v3 = labelHeight + labelHeight + buttonHeight + bw + bw
	minX = v2
	minY = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = labelHeight + labelHeight + buttonHeight + bw + bw
	IF (v3 > (h + 4)) THEN buttonHeight = buttonHeight + 4
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = v3 - buttonHeight - bw - bw
	h1 = h >> 1
	h2 = h - h1
	XuiSendToKid (grid, #Resize, x, y, w, h1, $label0, 0) : y = y + h1
	XuiSendToKid (grid, #Resize, x, y, w, h2, $label1, 0)
'
	y = y + h2
	h = buttonHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $button, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitErrorRuntime() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitErrorRuntime() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitErrorRuntime, @"XitErrorRuntime", &XitErrorRuntime(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 376
	designHeight = 68
'
	gridType = XitErrorRuntime
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $button)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
'	########################
'	#####  XitFind ()  #####
'	########################
'
FUNCTION  XitFind (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	FUNCADDR  func[] ()
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitFind
'
	$localToggle		= 1
	$caseToggle			= 2
	$reverseToggle	= 3
	$wordToggle     = 4
	$findLabel			= 5
	$findText				= 6  : $focusKid = 6
	$replaceLabel		= 7
	$replaceText		= 8
	$repsLabel			= 9
	$repsText				= 10
	$findButton			= 11
	$replaceButton	= 12
	$cancelButton		= 13
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitFind) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
'	*****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid		(@grid, XitFind, v0, v1, v2, v3, r0, r1, &XitFind())
'
	XuiToggleButton	(@g, #Create, 4, 4, 126, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $localToggle, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"toggleLocal")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @" local ")
	XuiToggleButton	(@g, #Create, 130, 4, 126, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $caseToggle, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"toggleCase")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @"match case")
'
	XuiToggleButton	(@g, #Create, 4, 24, 126, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $reverseToggle, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"toggleReverse")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @" reverse ")
	XuiToggleButton	(@g, #Create, 130, 24, 126, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $wordToggle, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"toggleWord")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @"whole word")
	XuiSendMessage  ( g, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:WholeWord")
'
	XuiLabel				(@g, #Create, 4, 44, 84, 20, r0, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"labelFind")
	XuiSendMessage	( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, 4, 0, 0, 0)
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @"find:")
	XuiTextLine			(@g, #Create, 88, 44, 168, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $findText, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"findText")
'
	XuiLabel				(@g, #Create, 4, 64, 84, 20, r0, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"labelReplace")
	XuiSendMessage	( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, 4, 0, 0, 0)
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @"replace:")
	XuiTextLine			(@g, #Create, 88, 64, 168, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $replaceText, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"replaceText")
'
	XuiLabel				(@g, #Create, 4, 84, 168, 20, r0, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"labelReps")
	XuiSendMessage	( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, 4, 0, 0, 0)
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @"repetitions  [* = all]")
	XuiTextLine			(@g, #Create, 172, 84, 84, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $repsText, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"repetitions")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @"0")
'
	XuiPushButton		(@g, #Create, 4, 104, 84, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $findButton, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonFind")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @" find ")
	XuiPushButton		(@g, #Create, 88, 104, 84, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $replaceButton, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonReplace")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @" replace ")
	XuiPushButton		(@g, #Create, 172, 104, 84, 20, r0, grid)
	XuiSendMessage	( g, #SetCallback, grid, &XitFind(), -1, -1, $cancelButton, grid)
	XuiSendMessage	( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage	( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
'	*****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Find")
END SUB
'
'
'	*****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	toggleWidth = 16
	hmax = 16
	FOR i = $localToggle TO $wordToggle
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > toggleWidth) THEN toggleWidth = width
		IF (height > hmax) THEN hmax = height
	NEXT i
	toggleWidth = toggleWidth + toggleWidth     ' 4 toggle buttons (2 by 2)
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, $findLabel, 16)
	wl1 = width
	IF (height > hmax) THEN hmax = height
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, $replaceLabel, 16)
	IF (width > wl1) THEN wl1 = width
	IF (height > hmax) THEN hmax = height
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, $repsLabel, 16)
	wl2 = width
	IF (height > hmax) THEN hmax = height
'
	FOR i = $findText TO $repsText STEP 2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @height, i, 16)
	IF (height > hmax) THEN hmax = height
	NEXT i
'
	buttonWidth = 16
	FOR i = $findButton TO $cancelButton
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > buttonWidth) THEN buttonWidth = width
	IF (height > hmax) THEN hmax = height
	NEXT i
	buttonWidth = buttonWidth + buttonWidth + buttonWidth
'
	width = MAX(toggleWidth, buttonWidth) + bw + bw
	height = (hmax * 6) + bw + bw
	v2 = width
	v3 = height
END SUB
'
'
'	*****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'
'	Resize grid
'
	XuiPositionGrid (grid, v0, v1, v2, v3)
'
	wg = v2 - bw - bw      ' width of grid inside the border
	hg = v3 - bw - bw      ' height of grid inside the border
'
	y0 = bw
	y1 = hg / 6 + bw
	y2 = hg * 2 / 6 + bw
	y3 = hg * 3 / 6 + bw
	y4 = hg * 4 / 6 + bw
	y5 = hg * 5 / 6 + bw
	y6 = hg + bw
'
'	Resize kids
'
	width = v2 - bw - bw
	x = bw
	w1 = wg / 2
	w2 = wg - w1
	h = y1 - y0
	XuiSendToKid (grid, #Resize, x,    y0, w1, h, $localToggle, 0)
	XuiSendToKid (grid, #Resize, x+w1, y0, w2, h, $caseToggle, 0)
	h = y2 - y1
	XuiSendToKid (grid, #Resize, x,    y1, w1, h, $reverseToggle, 0)
	XuiSendToKid (grid, #Resize, x+w1, y1, w2, h, $wordToggle, 0)
'
	h = y3 - y2
	XuiSendToKid (grid, #Resize, x,     y2, wl1,    h, $findLabel, 0)
	XuiSendToKid (grid, #Resize, x+wl1, y2, wg-wl1, h, $findText, 0)
'
	h = y4 - y3
	XuiSendToKid (grid, #Resize, x,     y3, wl1,    h, $replaceLabel, 0)
	XuiSendToKid (grid, #Resize, x+wl1, y3, wg-wl1, h, $replaceText, 0)
'
	h = y5 - y4
	XuiSendToKid (grid, #Resize, x,     y4, wl2,    h, $repsLabel, 0)
	XuiSendToKid (grid, #Resize, x+wl2, y4, wg-wl2, h, $repsText, 0)
'
	w1 = wg / 3
	w2 = w1 + w1
	h = y6 - y5
	XuiSendToKid (grid, #Resize, x,    y5, w1,    h, $findButton, 0)
	XuiSendToKid (grid, #Resize, x+w1, y5, w1,    h, $replaceButton, 0)
	XuiSendToKid (grid, #Resize, x+w2, y5, wg-w2, h, $cancelButton, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitFind() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitFind() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitFind, "XitFind", &XitFind(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 260
	designHeight = 122
'
	gridType = XitFind
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus)
	XuiSetGridTypeValue (gridType, @"focusKid",     $focusKid)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
'
END FUNCTION
'
'
' ##########################
' #####  XitFrames ()  #####
' ##########################
'
FUNCTION  XitFrames (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitFrames
'
	$label				= 1
	$list					= 2
	$button0			= 3
	$button1			= 4
	$button2			= 5
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitFrames) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh in window : r0 = window
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitFrames, v0, v1, v2, v3, r0, r1, &XitFrames())
	XuiLabel       (@g, #Create, 0, 0, 1, 1, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelFunction")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"     #      line  Function                ")
	XuiList        (@g, #Create, 0, 0, 1, 1, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitFrames(), -1, -1, $list, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"listFrames")
	XuiPushButton  (@g, #Create, 0, 0, 1, 1, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitFrames(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonView")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" view ")
	XuiPushButton  (@g, #Create, 0, 0, 1, 1, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitFrames(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonDetail")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" detail ")
	XuiPushButton  (@g, #Create, 0, 0, 1, 1, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitFrames(), -1, -1, $button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Call Frames")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @labelWidth, @labelHeight, $label, 16)
	XuiSendToKid (grid, #GetMaxMinSize, 20, 4, @listWidth, @listHeight, $list, 0)
	bw = border
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
'
	width = MAX(labelWidth, buttonWidth)
	v2 = MAX(width, listWidth) + bw + bw
	v3 = labelHeight + listHeight + buttonHeight + bw + bw
	minX = v2
	minY = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX (v2Entry, v2)
	v3 = MAX (v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minY
'
	IF (v3 > (h + 4)) THEN
		buttonHeight = buttonHeight + 4	: h = h + 4
		IF (v3 > (h + 4)) THEN
			labelHeight = labelHeight + 4
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = labelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $label, 0)
'
	y = y + h
	h = v3 - labelHeight - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $list, 0)
'
	y = y + h
	w1 = w / 3
	w2 = w - w1 - w1
	h = buttonHeight
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button0, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button1, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button2, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitFrames() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitFrames() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitFrames, @"XitFrames", &XitFrames(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 160
	designHeight = 256
'
	gridType = XitFrames
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    64)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $button0)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##########################
' #####  XitMemory ()  #####
' ##########################
'
FUNCTION  XitMemory (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitMemory
'
	$textArea	= 1
	$textLine	= 2
	$button0	= 3
	$button1	= 4
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, @XitMemory) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitMemory, @v0, @v1, @v2, @v3, r0, r1, &XitMemory())
	XuiTextArea    (@g, #Create, 4, 4, 668, 220, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitMemory(), -1, -1, $textArea, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Output")
	XuiTextLine    (@g, #Create, 4, 224, 668, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitMemory(), -1, -1, $textLine, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Command")
	XuiPushButton  (@g, #Create, 4, 244, 334, 20, r0, grid)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" execute ")
	XuiSendMessage ( g, #SetCallback, grid, &XitMemory(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonExecute")
	XuiPushButton  (@g, #Create, 338, 244, 334, 20, r0, grid)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	XuiSendMessage ( g, #SetCallback, grid, &XitMemory(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Memory")
END SUB
'
'
' *****  GetSmallestSize  *****  Return v23 = smallest wh
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	XuiSendToKid (grid, #GetSmallestSize, 20, 4, @areaWidth, @areaHeight, $textArea, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @lineHeight, $textLine, 16)
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth
	width = MAX (width, areaWidth)
	width = MAX (width, lineWidth)
	v2 = width + bw + bw
	v3 = areaHeight + lineHeight + buttonHeight + bw + bw
	minX = v2
	minY = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minY
'
	IF (v3 > (h + 4)) THEN
		buttonHeight = buttonHeight + 4	:	h = h + 4
		IF (v3 > (h + 4)) THEN
			lineHeight = lineHeight + 4
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = v3 - lineHeight - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $textArea, 0)
'
	y = y + h
	h = lineHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $textLine, 0)
'
	y = y + h
	h = buttonHeight
	w = w >> 1
	XuiSendToKid (grid, #Resize, x, y, w, h, $button0, 0) : x = x + w
	XuiSendToKid (grid, #Resize, x, y, w, h, $button1, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitMemory() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitMemory() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitMemory, @"XitMemory", &XitMemory(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 378
	designHeight = 256
'
	gridType = XitMemory
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $textLine)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##############################
' #####  XitOptionMisc ()  #####
' ##############################
'
FUNCTION  XitOptionMisc (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitOptionMisc
'
	$XitOptionMisc          =   0  ' kid   0 grid type = XitOptionMisc
	$CheckBounds            =   1  ' kid   1 grid type = XuiCheckBox
	$CheckSaveNewline       =   2  ' kid   2 grid type = XuiCheckBox
	$CheckConsoleDarkColor  =   3  ' kid   3 grid type = XuiCheckBox
	$CheckCompileError      =   4  ' kid   4 grid type = XuiCheckBox
	$CheckConsoleLargeFont  =   5  ' kid   5 grid type = XuiCheckBox
	$CheckProgramLargeFont  =   6  ' kid   6 grid type = XuiCheckBox
	$CheckConsoleLargeBars  =   7  ' kid   7 grid type = XuiCheckBox
	$CheckProgramLargeBars  =   8  ' kid   8 grid type = XuiCheckBox
	$CheckAutoUpperCase     =   9  ' kid   9 grid type = XuiCheckBox
	$CheckProgramLineNumber =  10  ' kid  10 grid type = XuiCheckBox
	$CheckAutoIndent        =  11  ' kid  11 grid type = XuiCheckBox
	$CheckTabBlockIndent    =  12  ' kid  12 grid type = XuiCheckBox
	$CheckMakeBackupFile    =  13  ' kid  13 grid type = XuiCheckBox
	$CheckReloadLastFile    =  14  ' kid  14 grid type = XuiCheckBox
	$CheckSaveBeforeCompile =  15  ' kid  15 grid type = XuiCheckBox
	$CheckSaveBeforeRun     =  16  ' kid  16 grid type = XuiCheckBox
	$CheckProgramRuler      =  17  ' kid  17 grid type = XuiCheckBox
	$ButtonEnter            =  18  ' kid  18 grid type = XuiPushButton
	$UpperKid               =  18  ' kid maximum
	$ButtonRows             =  10
'
'	XgrMessageNumberToName (r1, @mess$)
'	XgrMessageNumberToName (message, @message$)
'	PRINT "XitOptionMisc() : "; grid;; message$;; v0; v1; v2; v3; r0; r1;; mess$
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitOptionMisc) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitOptionMisc, @v0, @v1, @v2, @v3, r0, r1, &XitOptionMisc())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"XitOptionMisc")
'
	x = 4 : y = 4 : w = 192 : h = 28
	kid = $CheckBounds            : name$ = "checkBounds"            : text$ = " check bounds"
	GOSUB CreateCheckBox
	kid = $CheckSaveNewline       : name$ = "checkSaveNewline"       : text$ = " save with \\r\\n"
	GOSUB CreateCheckBox
	kid = $CheckConsoleDarkColor  : name$ = "checkConsoleDarkColor"  : text$ = " console dark color"
	GOSUB CreateCheckBox
	kid = $CheckCompileError      : name$ = "checkCompileError"      : text$ = " stop compile on error"
	hint$ = "stops compiling at the end of each function that has errors"
	GOSUB CreateCheckBox
	kid = $CheckConsoleLargeFont  : name$ = "checkConsoleLargeFont"  : text$ = " console large font"
	GOSUB CreateCheckBox
	kid = $CheckProgramLargeFont  : name$ = "checkProgramLargeFont"  : text$ = " program large font"
	GOSUB CreateCheckBox
	kid = $CheckConsoleLargeBars  : name$ = "checkConsoleLargeBars"  : text$ = " console large bars"
	GOSUB CreateCheckBox
	kid = $CheckProgramLargeBars  : name$ = "checkProgramLargeBars"  : text$ = " program large bars"
	GOSUB CreateCheckBox
	kid = $CheckAutoUpperCase     : name$ = "checkAutoUpperCase"     : text$ = " auto upper case"
	GOSUB CreateCheckBox
	kid = $CheckProgramLineNumber : name$ = "checkLineNumber"        : text$ = " program line numbers"
	GOSUB CreateCheckBox
	kid = $CheckAutoIndent        : name$ = "checkAutoIndent"        : text$ = " auto indent"
	GOSUB CreateCheckBox
	kid = $CheckTabBlockIndent    : name$ = "checkTabBlockIndent"    : text$ = " tab block indent"
	GOSUB CreateCheckBox
	kid = $CheckMakeBackupFile    : name$ = "checkMakeBackupFile"    : text$ = " make backup file"
	GOSUB CreateCheckBox
	kid = $CheckReloadLastFile    : name$ = "checkReloadLastFile"    : text$ = " reload last file"
	GOSUB CreateCheckBox
	kid = $CheckSaveBeforeCompile : name$ = "checkSaveBeforeCompile" : text$ = " save before comp."
	GOSUB CreateCheckBox
	kid = $CheckSaveBeforeRun     : name$ = "checkSaveBeforeRun"     : text$ = " save before run"
	GOSUB CreateCheckBox
	kid = $CheckProgramRuler      : name$ = "checkProgramRuler"      : text$ = " program ruler"
	GOSUB CreateCheckBox
'
	x = 4 : y = y + h : w = w*2
'	PRINT kid, x, y, w, h
	XuiPushButton  (@g, #Create, x, y, w, h, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitOptionMisc(), -1, -1, $ButtonEnter, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonEnter")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColor, 17, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"close")
	GOSUB Resize
END SUB
'
'
' *****  CreateCheckBox  *****
'
SUB CreateCheckBox
	IF (kid != saveKid+1) THEN PRINT "XitOptionMisc() kid number error", kid, saveKid
	IF (kid AND 1) THEN
		x = 4                      ' odd numbered kids on left side
		IF saveKid THEN y = y + h  ' if not first odd kid set y for next row
	ELSE
		x = 196                    ' even numbered kids on right side, same row
	END IF
	saveKid = kid
'	PRINT kid, x, y, w, h
	XuiCheckBox    (@g, #Create, x, y, w, h, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitOptionMisc(), -1, -1, kid, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @name$)
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @text$)
	IF hint$ THEN
		XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @hint$)
		hint$ = ""
	END IF
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @" Miscellaneous Options ")
END SUB
'
'
' *****  GetSmallestSize  *****  Return v23 = smallest wh  (set variables for Resize)
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $CheckBounds TO $ButtonEnter
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		buttonWidth = MAX (width, buttonWidth)
		buttonHeight = MAX (height, buttonHeight)
	NEXT i
	v2 = buttonWidth + buttonWidth + bw + bw + 4
'	v3 = (buttonHeight << 2) + buttonHeight + bw + bw + 4
	v3 = buttonHeight * $ButtonRows + bw + bw + 4
	minW = v2
	minH = v3
END SUB
'
'
' *****  KeyDown  *****
'
SUB KeyDown
	SELECT CASE v2{$$VirtualKey}
		CASE $$KeyEnter
					XuiCallback (grid, #Selection, 0, 0, 0, 0, 0, grid)
		CASE $$KeyEscape
					XuiCallback (grid, #Selection, -1, 0, 0, 0, 0, grid)
	END SELECT
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	buttonWidth = v2 >> 1
	buttonHeight = (v3 - bw - bw) \ $ButtonRows
'
'	IF (v3 >= ((buttonHeight << 2) + buttonHeight + bw + bw + 20)) THEN
	IF (v3 >= (buttonHeight * $ButtonRows) + bw + bw + (4 * $ButtonRows)) THEN
		buttonHeight = buttonHeight + 4
	END IF
'
'	Resize kids
'
	xl = bw
	xr = bw + buttonWidth
	y1 = bw
	wl = buttonWidth
	wr = v2 - wl - bw - bw
	wt = v2 - bw - bw
	h1 = buttonHeight
	hLast = v3 - (h1 * ($ButtonRows - 1)) - bw - bw
'
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckBounds, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckSaveNewline, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckConsoleDarkColor, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckCompileError, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckConsoleLargeFont, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckProgramLargeFont, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckConsoleLargeBars, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckProgramLargeBars, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckAutoUpperCase, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckProgramLineNumber, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckAutoIndent, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckTabBlockIndent, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckMakeBackupFile, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckReloadLastFile, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckSaveBeforeCompile, 0)
	XuiSendToKid (grid, #Resize, xr, y1, wr, h1, $CheckSaveBeforeRun, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wl, h1, $CheckProgramRuler, 0)
	y1 = y1 + buttonHeight
	XuiSendToKid (grid, #Resize, xl, y1, wt, hLast, $ButtonEnter, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
'	sub[#Callback]						= SUBADDRESS (Callback)
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#KeyDown]							= SUBADDRESS (KeyDown)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitOptionMisc() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitOptionMisc() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitOptionMisc, @"XitOptionMisc", &XitOptionMisc(), @func[], @sub[])
'
	designX = 4
	designY = 23
	designWidth = 392
	designHeight = $ButtonRows * 28
'
	gridType = XitOptionMisc
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $ButtonEnter)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  XitRegisters ()  #####
' #############################
'
FUNCTION  XitRegisters (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitRegisters
'
	$label		= 1
	$textArea	= 2
	$textLine	= 3
	$button0	= 4
	$button1	= 5
	$button2	= 6
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitRegisters) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitRegisters, @v0, @v1, @v2, @v3, r0, r1, &XitRegisters())
	XuiLabel       (@g, #Create, 4, 4, 508, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"location")
	XuiTextArea    (@g, #Create, 4, 24, 508, 72, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitRegisters(), -1, -1, $textArea, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"registers")
	XuiTextLine    (@g, #Create, 4, 96, 508, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitRegisters(), -1, -1, $textLine, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"command")
	XuiPushButton  (@g, #Create, 4, 116, 169, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitRegisters(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonSet")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" set ")
	XuiPushButton  (@g, #Create, 174, 116, 170, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitRegisters(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonReset")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" reset ")
	XuiPushButton  (@g, #Create, 343, 116, 169, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitRegisters(), -1, -1, $button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Registers")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @labelHeight, $label, 16)
	XuiSendToKid (grid, #GetSmallestSize, 20, 1, @areaWidth, @areaHeight, $textArea, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @lineHeight, $textLine, 16)
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth + buttonWidth
	width = MAX (width, areaWidth)
	width = MAX (width, lineWidth)
	v2 = width + bw + bw
	v3 = labelHeight + areaHeight + lineHeight + buttonHeight + bw + bw
	minX = v2
	minY = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minY
'
	IF (v3 > (h + 4)) THEN
		buttonHeight = buttonHeight + 4	:	h = h + 4
		IF (v3 > (h + 4)) THEN
			lineHeight = lineHeight + 4		:	h = h + 4
			IF (v3 > (h + 4)) THEN
				labelHeight = labelHeight + 4
			END IF
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = labelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $label, 0)
'
	y = y + h
	h = v3 - labelHeight - lineHeight - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $textArea, 0)
'
	y = y + h
	h = lineHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $textLine, 0)
'
	y = y + h
	h = buttonHeight
	w0 = w / 3
	w1 = w - w0 - w0
	w2 = w0
	XuiSendToKid (grid, #Resize, x, y, w0, h, $button0, 0) : x = x + w0
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button2, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	IF (r0 != $textArea) THEN EXIT SUB
	XgrGetKeystateModify (v2, @modify, @edit)
	IF modify THEN r0 = -1
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
	func[#TextEvent]					= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	sub[#TextEvent]						= SUBADDRESS (TextEvent)
	IF func[0] THEN PRINT "XitRegisters() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitRegisters() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitRegisters, @"XitRegisters", &XitRegisters(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 512
	designHeight = 128
'
	gridType = XitRegisters
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $textLine)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##########################
' #####  XitString ()  #####
' ##########################
'
FUNCTION  XitString (grid, message, v0, v1, v2, v3, r0, r1)
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitString
'
	$functionLabel	= 1
	$symbolLabel		= 2
	$textArea				= 3
	$toggle					= 4
	$button0				= 5
	$button1				= 6
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitString) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh in window : r0 = window
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid   (@grid, XitString, v0, v1, v2, v3, r0, r1, &XitString())
	XuiLabel        (@g, #Create, 4, 4, 532, 20, r0, grid)
	XuiSendMessage  ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage  ( g, #SetGridName, 0, 0, 0, 0, 0, @"funcLine")
	XuiLabel        (@g, #Create, 4, 24, 532, 20, r0, grid)
	XuiSendMessage  ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage  ( g, #SetGridName, 0, 0, 0, 0, 0, @"stringName")
	XuiTextArea     (@g, #Create, 4, 44, 532, 128, r0, grid)
	XuiSendMessage  ( g, #SetCallback, grid, &XitString(), -1, -1, $textArea, grid)
	XuiSendMessage  ( g, #SetGridName, 0, 0, 0, 0, 0, @"string")
	XuiToggleButton (@g, #Create, 4, 172, 532, 20, r0, grid)
	XuiSendMessage  ( g, #SetCallback, grid, &XitString(), -1, -1, $toggle, grid)
	XuiSendMessage  ( g, #SetGridName, 0, 0, 0, 0, 0, @"toggleMode")
	XuiSendMessage  ( g, #SetTextString, 0, 0, 0, 0, 0, @" backslash mode ")
	XuiPushButton   (@g, #Create, 4, 192, 266, 20, r0, grid)
	XuiSendMessage  ( g, #SetCallback, grid, &XitString(), -1, -1, $button0, grid)
	XuiSendMessage  ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonNewValue")
	XuiSendMessage  ( g, #SetTextString, 0, 0, 0, 0, 0, @" new value ")
	XuiPushButton   (@g, #Create, 270, 192, 266, 20, r0, grid)
	XuiSendMessage  ( g, #SetCallback, grid, &XitString(), -1, -1, $button1, grid)
	XuiSendMessage  ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage  ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"String Detail")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @functionLabelWidth, @functionLabelHeight, $functionLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @symbolLabelWidth, @symbolLabelHeight, $symbolLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 20, 4, @areaWidth, @areaHeight, $textArea, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @toggleWidth, @toggleHeight, $toggle, 16)
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth << 1
	IF (width < functionLabelWidth) THEN width = functionLabelWidth
	IF (width < symbolLabelWidth) THEN width = symbolLabelWidth
	IF (width < areaWidth) THEN width = areaWidth
	IF (width < toggleWidth) THEN width = toggleWidth
	v2 = width + bw + bw
	v3 = functionLabelHeight + symbolLabelHeight + areaHeight
	v3 = v3 + toggleHeight + buttonHeight + bw + bw
	minW = v2
	minH = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minH
'
	IF (v3 > (h + 4)) THEN
		buttonHeight = buttonHeight + 4		:	h = h + 4
		IF (v3 > (h + 4)) THEN
			toggleHeight = toggleHeight + 4	:	h = h + 4
			IF (v3 > (h + 8)) THEN
				functionLabelHeight = functionLabelHeight + 4
				symbolLabelHeight = symbolLabelHeight + 4
			END IF
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = functionLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $functionLabel, 0)
'
	y = y + h
	h = symbolLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $symbolLabel, 0)
'
	y = y + h
	h = v3 - functionLabelHeight - symbolLabelHeight
	h = h - toggleHeight - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $textArea, 0)
'
	y = y + h
	h = toggleHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $toggle, 0)
'
	y = y + h
	h = buttonHeight
	w1 = w >> 1
	w2 = v2 - w1 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button0, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button1, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
	sub[#Create]						= SUBADDRESS (Create)
	sub[#CreateWindow]			= SUBADDRESS (CreateWindow)
	sub[#Resize]						= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitString() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitString() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitString, @"XitString", &XitString(), @func[], @sub[])
'
	designX = 4
	designY = 23
	designWidth = 512
	designHeight = 128
'
	gridType = XitString
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     64)
	XuiSetGridTypeValue (gridType, @"minHeight",    32)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $textArea)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##############################
' #####  XitTextCursor ()  #####
' ##############################
'
' See: OptionTextCursor()
'
FUNCTION  XitTextCursor (grid, message, v0, v1, v2, v3, r0, r1)
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitTextCursor
'
	$XitTextCursor          =   0  ' kid   0 grid type = XitTextCursor
	$TextCursorColorLabel   =   1  ' kid   1 grid type = XuiLabel
	$TextCursorColor        =   2  ' kid   2 grid type = XuiColor
	$CursorLineColorLabel   =   3  ' kid   3 grid type = XuiLabel
	$CursorLineColor        =   4  ' kid   4 grid type = XuiColor
	$TextCursorColorSample  =   5  ' kid   5 grid type = XuiTextLine
	$TextCursorColorCancel  =   6  ' kid   6 grid type = XuiPushButton
	$UpperKid               =   6  ' kid maximum
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitTextCursor) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
	message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XitTextCursor, @v0, @v1, @v2, @v3, r0, r1, &XitTextCursor())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"XitTextCursor")
	XuiLabel       (@g, #Create, 4, 4, 208, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelTextCursorColor")
	XuiSendMessage ( g, #SetColor, 17, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" change text-cursor color ")
	XuiColor       (@g, #Create, 8, 32, 200, 80, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitTextCursor(), -1, -1, $TextCursorColor, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"colorTextCursor")
	XuiLabel       (@g, #Create, 4, 116, 208, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelCursorLineColor")
	XuiSendMessage ( g, #SetColor, 17, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" change cursor-line color ")
	XuiColor       (@g, #Create, 8, 144, 200, 80, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitTextCursor(), -1, -1, $CursorLineColor, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"colorCursorLine")
	XuiTextLine    (@g, #Create, 4, 228, 208, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitTextCursor(), -1, -1, $TextCursorColorSample, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"colorSample")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ABCDEFG 0123456789")
	XuiPushButton  (@g, #Create, 4, 252, 208, 32, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitTextCursor(), -1, -1, $TextCursorColorCancel, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetColor, 102, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetTexture, $$TextureShadow, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XitTextCursor")
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE r0
		CASE 2	: XuiCallback (grid, #Selection, v0, r0, 0, 0, 0, 0)
							XuiSendToKid (grid, #SetKeyboardFocus, 0, 0, 0, 0, 5, 0)
		CASE 4	: XuiCallback (grid, #Selection, v0, r0, 0, 0, 0, 0)
							XuiSendToKid (grid, #SetKeyboardFocus, 0, 0, 0, 0, 5, 0)
		CASE 5	:
		CASE 6	: XuiCallback (grid, #Selection, -1, r0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	IF (v2{$$VirtualKey} = $$KeyEscape) THEN
		XuiCallback (grid, #Selection, -1, 0, 0, 0, 0, grid)
	END IF
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
' func[#Callback]           = &XuiCallback ()               ' disable to handle Callback messages internally
' func[#GetSmallestSize]    = 0                             ' enable to add internal GetSmallestSize routine
' func[#Resize]             = 0                             ' enable to add internal Resize routine
'
	DIM sub[upperMessage]
	sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
	sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
	sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
' sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
' sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
	sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
	sub[#TextEvent]						= SUBADDRESS (TextEvent)				'
'
	IF sub[0] THEN PRINT "XitTextCursor() : Initialize : error ::: undefined message Initialize: Error::: Undefined Message"
	IF func[0] THEN PRINT "XitTextCursor() : Initialize : error ::: undefined message Initialize: Error::: Undefined Message"
	XuiRegisterGridType (@XitTextCursor, "XitTextCursor", &XitTextCursor(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
	designX = 256
	designY = 23
	designWidth = 216
	designHeight = 288
'
	gridType = XitTextCursor
	XuiSetGridTypeValue (gridType, @"x",                designX)
	XuiSetGridTypeValue (gridType, @"y",                designY)
	XuiSetGridTypeValue (gridType, @"width",            designWidth)
	XuiSetGridTypeValue (gridType, @"height",           designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
	XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
	XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$TextSelection)
	XuiSetGridTypeValue (gridType, @"focusKid",         $TextCursorColorSample)
	XuiSetGridTypeValue (gridType, @"inputTextString",  $TextCursorColorSample)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  XitVariables ()  #####
' #############################
'
' See: HotVariables
'
FUNCTION  XitVariables (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XitVariables
'
	$functionLabel	= 1
	$columnLabel		= 2
	$list						= 3
	$findLabel			= 4
	$findText				= 5
	$valueLabel			= 6
	$valueText			= 7
	$button0				= 8
	$button1				= 9
	$button2				= 10
	$CheckShowType			= 11
	$CheckShowLocation	= 12
	$CheckShowHex				= 13
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitVariables) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XitVariables, @v0, @v1, @v2, @v3, r0, r1, &XitVariables())
	XuiLabel       (@g, #Create, 4, 4, 752, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelFuncLine")
	XuiLabel       (@g, #Create, 4, 24, 752, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelHeading")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"type       value      ")
	XuiList        (@g, #Create, 4, 44, 752, 128, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $list, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"list")
	XuiSendMessage ( g, #SetColorExtra, -1, 0x69, -1, -1, 0, 0)
	XuiLabel       (@g, #Create, 4, 172, 136, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelFindSymbol")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"find symbol     ")
	XuiTextLine    (@g, #Create, 4, 192, 136, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $findText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"findSymbol")
	XuiLabel       (@g, #Create, 140, 172, 616, 20, r0, grid)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, $$JustifyLeft, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"labelNewValue")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"new value:")
	XuiTextLine    (@g, #Create, 140, 192, 616, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $valueText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"newValue")
	XuiPushButton  (@g, #Create, 4, 212, 250, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonNewValue")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" new value ")
	XuiPushButton  (@g, #Create, 254, 212, 252, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonDetail")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" detail ")
	XuiPushButton  (@g, #Create, 506, 212, 250, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"buttonCancel")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" cancel ")
	XuiCheckBox    (@g, #Create, 4, 240 , 250, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $CheckShowType, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"checkShowType")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"show type")
	XuiCheckBox    (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $CheckShowLocation, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"checkShowLocation")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" show location ")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"location")
	XuiCheckBox    (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XitVariables(), -1, -1, $CheckShowHex, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"checkShowHex")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"show hex")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Variables")
END SUB
'
'
' *****  GetSmallestSize  *****  Return v23 = smallest wh
'
SUB GetSmallestSize
	XuiSendMessage (grid, #GetBorder, @style, 0, 0, 0, 0, @border)
	bw = border
'
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @functionLabelWidth, @functionLabelHeight, $functionLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @columnLabelWidth, @columnLabelHeight, $columnLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 20, 4, @listWidth, @listHeight, $list, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @findLabelWidth, @findLabelHeight, $findLabel, 16)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @findTextWidth, @findTextHeight, $findText, 16)
'
	buttonWidth = 16
	buttonHeight = 16
	FOR i = $button0 TO $CheckShowHex
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 16)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth * 3
	IF (width < functionLabelWidth) THEN width = functionLabelWidth
	IF (width < columnLabelWidth) THEN width = columnLabelWidth
	IF (width < findLabelWidth) THEN width = findLabelWidth
	IF (width < findTextWidth) THEN width = findTextWidth
	IF (width < listWidth) THEN width = listWidth
	v2 = width + bw + bw
	v3 = functionLabelHeight + columnLabelHeight + listHeight
	v3 = v3 + findLabelHeight + findTextHeight + (buttonHeight * 2) + bw + bw
	minW = v2
	minH = v3
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	v2Entry = v2
	v3Entry = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX(v2Entry, v2)
	v3 = MAX(v3Entry, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = minH
'
	IF (v3 > (h + 8)) THEN
		buttonHeight = buttonHeight + 4									:	h = h + 8
		IF (v3 > (h + 8)) THEN
			functionLabelHeight = functionLabelHeight + 4	:	h = h + 8
			columnLabelHeight = columnLabelHeight + 4
			IF (v3 > (h + 8)) THEN
				findLabelHeight = findLabelHeight + 4
				findTextHeight = findTextHeight + 4
			END IF
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	h = functionLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $functionLabel, 0)
'
	y = y + h
	h = columnLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $columnLabel, 0)
'
	y = y + h
	h = v3 - functionLabelHeight - columnLabelHeight - findLabelHeight
	h = h - findTextHeight - (buttonHeight * 2) - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $list, 0)
'
	y = y + h
	w = findLabelWidth
	h = findLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $findLabel, 0)
	y = y + h
	h = findTextHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $findText, 0)
'
	x = x + w
	y = y - findLabelHeight
	w = v2 - findLabelWidth - bw - bw
	h = findLabelHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $valueLabel, 0)
	y = y + h
	h = findTextHeight
	XuiSendToKid (grid, #Resize, x, y, w, h, $valueText, 0)
'
	x = bw
	y = y + h
	h = buttonHeight
	w1 = (v2 - bw - bw) / 3
	w2 = v2 - w1 - w1 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button0, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w2, h, $button1, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $button2, 0)
'
	x = bw
	y = y + h
	h = buttonHeight
	w1 = (v2 - bw - bw) / 3
	w2 = v2 - w1 - w1 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w1, h, $CheckShowType, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w2, h, $CheckShowLocation, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $CheckShowHex, 0)
'
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
	IF func[0] THEN PRINT "XitVariables() : Initialize : error ::: undefined message"
	IF sub[0] THEN PRINT "XitVariables() : Initialize : error ::: undefined message"
	XuiRegisterGridType (@XitVariables, @"XitVariables", &XitVariables(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 512
	designHeight = 236
'
	gridType = XitVariables
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     293)
	XuiSetGridTypeValue (gridType, @"minHeight",    185)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",      $findText)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###############################
' #####  AddCommandItem ()  #####
' ###############################
'
FUNCTION  AddCommandItem (text$)
	SHARED  xitGrid
'
	IFZ text$ THEN RETURN
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"AddCommandItem()lockout", lockout)
'
	XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitCommand, @array$[])
'
	upper = UBOUND (array$[])
'
	IF (upper != 15) THEN
		upper = 15
		##WHOMASK = 0
		##LOCKOUT = 200001
		DIM array$[upper]
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
	i = upper
	next$ = ""
	this$ = text$
'
	FOR i = 0 TO upper
		SWAP this$, array$[i]
		IF (this$ == text$) THEN EXIT FOR
	NEXT i
'
	array$[0] = text$
	cursorPos = LEN (text$)
	XuiSendMessage (xitGrid, #SetTextString, 0, 0, 0, 0, $$xitCommand, @text$)
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitCommand, @array$[])
	XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, 0, 0, 0, $$xitCommand, 0)
	XuiSendMessage (xitGrid, #Redraw, 0, 0, 0, 0, $$xitCommand, 0)
END FUNCTION
'
'
' ##############################
' #####  ImmediateMode ()  #####
' ##############################
'
'	SYNTAX:  .<command>[<space><argument>]
'
'	fn  ft  fl  fs  fm  fr  fq
' ec  eg  ep  ed  eb  ei  ee  ef  er  ew  ea
' vf  vn  vd  vr  vc  vl  vs  vm
' oc  ot
' rs  rc  rj  rp  rk  rr  ra  rl
' dt  dc  de  dm  da  dr
' wc  wr  wx
' hi  hc  hh
'
' key [ # ]
'
'	Commands:
'			All menu bar commands are executed using their 2-letter mnemonic
'				(eg  File-Load  is  .fl)
'				Accept filename args:  ft  fl  fs  fr  er  ew  vm
'				Accept function name:  vv  vn  vd  vr  vc
'				Accept func/file:      vl  vs
'
'				f		<see below>		find immediate
'				r		<see below>		replace immediate
'				c									Clear upper window of text
'				s#								Set tag (a-z)
'				j#								Jump to tag
'				.									Line number and Character number
'				#									show line number #
'				v[-]							view ahead [behind] 1 function
'				a									again (repeat last instruction)
'				h									Help
'
'
' FIND ARGUMENT SYNTAX:
'		SYNTAX:  .[*|<#>][f|r][-][<space><find text>[<tab><replace text>]]
'									[*|<#>]	= repetitions		(* = all instances, default = 1)
'										[f|r]	= find | replace
'											[-]	= reverse
'			[<space>find text]	= a single space delimits the find text
'															(optional: if not specified, last find text is used)
'			[<tab>replace text]	= a single tab (NOT \t) delimits the replace text
'															(optional: if not specified, last replace text is used)
'		Examples:  .*r PIRNT	PRINT
'									|      |
'								space   tab					replace (forward) all instances
'
'		Observations:
'				first char = tab	--	find text$ untouched
'															replace text = text less first tab
'				no text after tab --  replace text = ""
'				Any tabs after first tab are included in replace text
'
FUNCTION  ImmediateMode (keyState)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  backupBox
	SHARED  cleanBox
	SHARED  jump[]
	SHARED  TOKEN prog[]
	SHARED  xitGrid
	SHARED  readFile$,  writeFile$
	SHARED  editFunction,  fileType
	SHARED  findText$,  replaceText$,  findReverse,  findReps
	SHARED  environmentActive,  exitMainLoop
	SHARED  fileBox,  renameBox
	SHARED  readBox,  writeBox,  findBox,  funcBox
	SHARED  viewNewBox,  deleteFuncBox,  viewRenameBox,  viewCloneBox
	SHARED  viewLoadBox,  viewSaveBox,  viewMergeBox
	SHARED  memoryBox,  assemblyBox,  registerBox
	SHARED  errorBox,  runtimeErrorBox
	SHARED  optionMiscBox,  textCursor
	SHARED  huh
	SHARED  xitTextLower
	STATIC  lastCommandLine$
	STATIC  FILEINFO  fileinfo[]
	STATIC  gd, ghuh
'
'	Add newline unless SHIFT-Enter
'
'	PRINT "::: ImmediateMode :::  "; keyState, HEX$(keyState,8)
'
' commented out lines are from old style environment window
'
'	XuiSendMessage (xitGrid, #GetTextCursor, @pos, @cursorLine, 0, 0, $$xitTextUpper, 0)
'	IFZ (keyState AND $$ShiftBit) THEN
'		XuiSendMessage (xitGrid, #TextInsert, 0, 0, 0, $$KeyEnter, $$xitTextUpper, 0)
'	END IF
'	XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextUpper, @text$[])
'	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
'	IFZ text$[] THEN RETURN ($$FALSE)
'
'	PRINT "ImmediateMode() : ", HEX$(keyState,8), cursorLine, UBOUND(text$[])
'
	XuiSendMessage (xitGrid, #GetTextString, 0, 0, 0, 0, $$xitCommand, @text$)
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
	IFZ text$ THEN RETURN ($$FALSE)
'
' commented out lines are from old style environment window
'
'	upper = UBOUND(text$[])
'	IF ((cursorLine < 0) OR (cursorLine > upper)) THEN
'		XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextUpper, @text$[])
'		RETURN ($$FALSE)
'	END IF
'
'	line$ = text$[cursorLine]
'	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextUpper, @text$[])
'	PRINT "line$ = '"; line$; "'"
'
'	IFZ line$ THEN RETURN ($$FALSE)
'	IF (line${0} != '.') THEN RETURN ($$FALSE)
'
'	tempCommandLine$ = line$
'	trimLine$ = TRIM$(line$)
'	trimLength = LEN (trimLine$)
'
' new environment window
'
	line$ = text$
	trimLine$ = TRIM$ (text$)
	trimLength = LEN (trimLine$)
	IFZ trimLine$ THEN RETURN ($$FALSE)
	IF (line${0} != '.') THEN RETURN ($$FALSE)
'
	tempCommandLine$ = line$
	key$ = LEFT$ (trimLine$,4)
'
'
' old time stamp and key code removed from here
'
'
	IF ((trimLine$ = ".a") OR (trimLine$ = ".A")) THEN
		lastAgain = $$TRUE
		line$ = lastCommandLine$
		trimLine$ = TRIM$(line$)
	END IF
'
	IF ((trimLine$ = ".") OR (trimLine$ = "..")) THEN
		GOSUB LineImmediate
		IFZ lastAgain THEN
			lastCommandLine$ = tempCommandLine$
		END IF
		RETURN
	END IF
'
	line$ = MID$(line$, 2)
	eow = INCHR (line$, " \t")								' space/tab delimits command word
	SELECT CASE eow
		CASE 0		:	command$ = line$
								argument$ = ""
		CASE 1		:	RETURN ($$FALSE)
		CASE ELSE	:	command$ = MID$(line$, 1, eow - 1)
								argument$ = MID$(line$, eow + 1)
	END SELECT
	arg$ = argument$
	IF argument$ THEN argument$ = TRIM$(argument$)
'
	reps = 1																	' default reps = 1
	digit = command${0}
	SELECT CASE TRUE
		CASE (digit = '*')
					reps= -1
					command$ = MID$(command$, 2)
		CASE (digit >= '0') AND (digit <= '9')	' 0-9
					reps = digit - '0'								' Slicker with XLONG(command$)
					index = 2													'   then INCHR NOT in matchstring
					lenCommand = LEN(command$)
					DO UNTIL (index > lenCommand)
						digit = command${index - 1}
						IF (digit >= '0') AND (digit <= '9') THEN
							reps = reps * 10 + digit - '0'
						ELSE
							EXIT DO
						END IF
						INC index
					LOOP
					command$ = MID$(command$, index)
	END SELECT
'
	command$ = LCASE$(command$)
	SELECT CASE LEN(command$)
		CASE 0:															GOSUB LineGoto		' .*  or  .###
		CASE 1
			SELECT CASE command${0}
				CASE 'f':												GOSUB FindImmediate
				CASE 'r':												GOSUB FindImmediate
				CASE 'h':												GOSUB HelpImmediate
				CASE 'c':												GOSUB ClearCommand
				CASE 'v':												GOSUB View
			END SELECT
		CASE 2
			SELECT CASE command${0}
				CASE 'f'
					SELECT CASE command${1}
						CASE '-':										GOSUB FindImmediate
						CASE 'n':										GOSUB FileNew
						CASE 't', 'l', 's', 'r':		GOSUB File
						CASE 'm':										GOSUB FileMode
						CASE 'q':										FileQuit ()
					END SELECT
				CASE 'e'
					XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
					SELECT CASE command${1}
						CASE 'c':										XuiEditCut (0)
						CASE 'g':										XuiEditCopy (0)
						CASE 'p':										XuiEditPaste (xitTextLower, 0)
						CASE 'd':										XuiEditCut (1)
						CASE 'b':										XuiEditCopy (1)
						CASE 'i':										XuiEditPaste (xitTextLower, 1)
						CASE 'e':										XuiEditCut (-1)
						CASE 'f':										EditFind (findBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
						CASE 'r', 'w':							GOSUB ReadWrite
						CASE 'k':										EditCleanBackup (cleanBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
						CASE 'l':										EditLoadBackup (backupBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
					END SELECT
				CASE 'v':												GOSUB View
				CASE 'o'
					SELECT CASE command${1}
						CASE 'm':										XuiSendMessage (optionMiscBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
						CASE 'c':										GOSUB OptionTextCursor
						CASE 't':										GOSUB OptionTabWidth
					END SELECT
				CASE 'r'
					SELECT CASE command${1}
						CASE '-':										GOSUB FindImmediate
						CASE 's':										RunStart()
						CASE 'c':										RunContinue()
						CASE 'j':										RunJump()
						CASE 'p':										RunPause()
						CASE 'k':										RunKill()
						CASE 'r':										RunRecompile()
						CASE 'a':										RunAssembler()
						CASE 'l':										RunLibrary()
						CASE 'm':										RunMake ()
						CASE 'x':										RunStandalone ()
					END SELECT
				CASE 'd'
					SELECT CASE command${1}
						CASE 't':										DebugToggle()
						CASE 'c':										DebugClear()
						CASE 'e':										DebugErase()
						CASE 'm':										XuiSendMessage (memoryBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
						CASE 'a':										DebugAssembly (assemblyBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
						CASE 'r':										DebugRegisters (registerBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
					END SELECT
				CASE 's'
					SELECT CASE command${1}
						CASE 'c':										WizardCompErrors (errorBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
						CASE 'r':										XuiSendMessage (runtimeErrorBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
					END SELECT
				CASE 'h'
					SELECT CASE command${1}
						CASE 'h':
							IF ##XBSystem = $$XBSysLinux
								XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/README.Linux:*")
							ELSE
								XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/README.Win32:*")
							END IF
						CASE '!':										XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/changelog.hlp:*")
						CASE 'n':										XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/notes.hlp:*")
						CASE 's':										XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/support.hlp:*")
						CASE 'm':										XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/messagelist.hlp:*")
						CASE 'l':										XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/languagelist.hlp:*")
						CASE 'o':										XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/operator.hlp:*")
						CASE 'd':										XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/command.hlp:*")
					END SELECT
				CASE 's':												GOSUB SetTag
				CASE 'j':												GOSUB JumpTag
				CASE 'x':
					SELECT CASE command${1}
						CASE 'i':										HelpIndex ()
						CASE 'c':										HelpContents ()
						CASE 'h':										HelpHighlight ()
						CASE 'x':										huh = NOT huh
						CASE 'y':										gd = NOT gd : XgrSetDebug (gd)
						CASE 'z':										ghuh = NOT ghuh : XxxXgrSetHuh (ghuh)
					END SELECT
			END SELECT
		CASE ELSE
			IF (command$ = "xit") THEN				GOSUB Xit
	END SELECT
	IFZ lastAgain THEN
		lastCommandLine$ = tempCommandLine$
	END IF
	RETURN
'
'
' *****  ClearCommand  *****
'
SUB ClearCommand
	text$ = ""
	XuiSendMessage (xitGrid, #SetTextString, 0, 0, 0, 0, $$xitCommand, @text$)
	XuiSendMessage (xitGrid, #Redraw, 0, 0, 0, 0, $$xitCommand, 0)
END SUB
'
'
' *****  FileMode  *****
'
SUB FileMode
	IF argument$ THEN arg = argument${0} ELSE arg = 0
	SELECT CASE arg
		CASE 't'	: mode = $$Text
		CASE 'p'	: mode = $$Program
		CASE 'g'	: mode = $$Program
		CASE ELSE	: mode = $$FALSE
	END SELECT
	FileMode (mode)
END SUB
'
'
' *****  FileNew  *****
'
SUB FileNew
	IF argument$ THEN arg = argument${0} ELSE arg = 0
	SELECT CASE arg
		CASE 't'	: arg = $$Text
		CASE 'p'	: arg = $$Program
		CASE 'g'	: arg = $$GuiProgram
		CASE ELSE	: arg = $$FALSE
	END SELECT
	FileNew (arg)
END SUB
'
'
' *****  FileTextLoad  FileLoad  FileSave  FileRename  *****
'
SUB File
	fileName$ = XstPathString$ (@argument$)
	lenName = LEN(fileName$)
'
	SELECT CASE command${1}
		CASE 't'																					' FileTextLoad
					IF fileName$ THEN
						XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @fileName$)
						FileTextLoad ($$TRUE)
					ELSE
						FileTextLoad ($$FALSE)
					END IF
		CASE 'l'																					' FileLoad
					IF fileName$ THEN
						XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @fileName$)
						FileLoad ($$TRUE)
					ELSE
						FileLoad ($$FALSE)
					END IF
		CASE 's'																					' FileSave
					IF fileName$ THEN
						XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @fileName$)
						FileSave ($$TRUE)
					ELSE
						FileSave ($$FALSE)
					END IF
		CASE 'r'																					' FileRename
					IF fileName$ THEN
						XuiSendMessage (renameBox, #SetTextString, lenName, 0, 0, 0, $$DialogText, @fileName$)
						XuiSendMessage (renameBox, #SetTextCursor, lenName, 0, 0, 0, $$DialogText, 0)
						XuiSendMessage (renameBox, #SetTextString, lenName, 0, 0, 0, 0, @fileName$)
						FileRename ($$TRUE)
					ELSE
						FileRename ($$FALSE)
					END IF
	END SELECT
END SUB
'
SUB HelpImmediate
	XuiSendMessage (xitGrid, #SetHelp, 0, 0, 0, 0, 0, "command.hlp:*")
END SUB
'
SUB LineGoto
	XuiSendMessage (xitGrid, #SetTextCursor, 0, reps, -1, -1, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
END SUB
'
SUB ReadWrite
	fileName$ = XstPathString$ (@argument$)
	lenName = LEN (fileName$)
	IF (command$ = "er") THEN
		readFile$ = fileName$
		XuiSendMessage (readBox, #SetTextString, lenName, 0, 0, 0, 0, @fileName$)
		XuiSendMessage (readBox, #SetTextCursor, lenName, 0, 0, 0, $$FileTextLine, 0)
		IFZ readFile$ THEN EditRead ($$FALSE) ELSE EditRead ($$TRUE)
	ELSE
		writeFile$ = fileName$
		XuiSendMessage (writeBox, #SetTextString, lenName, 0, 0, 0, 0, @fileName$)
		XuiSendMessage (writeBox, #SetTextCursor, lenName, 0, 0, 0, $$FileTextLine, 0)
		IFZ writeFile$ THEN EditWrite ($$FALSE, 0) ELSE EditWrite ($$TRUE, 0)
	END IF
END SUB
'
SUB FindImmediate
	IFZ reps THEN
		Message ("[ImmediateMode()]\n  .f find : 0 repititions requested")
		EXIT SUB
	END IF
'
	IF (LEN(command$) = 2) THEN										' f-  r-
		findReverse = $$TRUE
		command$ = LEFT$(command$, 1)
	ELSE
		findReverse = $$FALSE
	END IF
	XuiSendMessage (findBox, #SetValues, findReverse, 0, 0, 0, $$FindReverseToggle, 0)
'
	IF (command$ = "f") THEN
		IF (reps < 0) THEN reps = 1
	END IF
'
	IF LEN(arg$) THEN										' if no argument, findText$/replaceText$ untouched
		itab = INSTR(arg$, "\t")
		SELECT CASE itab
			CASE 0
				findText$ = arg$							' no tab, replaceText$ untouched
				XuiSendMessage (findBox, #SetTextString, 0, 0, 0, 0, $$FindFindText, @findText$)
				XuiSendMessage (findBox, #RedrawText, 0, 0, 0, 0, $$FindFindText, 0)
				IF (INSTR(findText$, "\\")) THEN
					findText$ = XstBackStringToBinString$ (@findText$)
				END IF
			CASE 1
				replaceText$ = MID$(arg$, 2)	' <tab>... findText$ untouched
				XuiSendMessage (findBox, #SetTextString, 0, 0, 0, 0, $$FindReplaceText, @replaceText$)
				XuiSendMessage (findBox, #RedrawText, 0, 0, 0, 0, $$FindReplaceText, 0)
				IF (INSTR(replaceText$, "\\")) THEN
					replaceText$ = XstBackStringToBinString$ (@replaceText$)
				END IF
			CASE ELSE:
				findText$ = MID$(arg$, 1, itab-1)
				XuiSendMessage (findBox, #SetTextString, 0, 0, 0, 0, $$FindFindText, @findText$)
				XuiSendMessage (findBox, #RedrawText, 0, 0, 0, 0, $$FindFindText, 0)
				IF (INSTR(findText$, "\\")) THEN
					findText$ = XstBackStringToBinString$ (@findText$)
				END IF
				replaceText$ = MID$(arg$, itab+1)
				XuiSendMessage (findBox, #SetTextString, 0, 0, 0, 0, $$FindReplaceText, @replaceText$)
				XuiSendMessage (findBox, #RedrawText, 0, 0, 0, 0, $$FindReplaceText, 0)
				IF (INSTR(replaceText$, "\\")) THEN
					replaceText$ = XstBackStringToBinString$ (@replaceText$)
				END IF
		END SELECT
	END IF
'
	IF (reps = -1) THEN
		reps$ = "*"
	ELSE
		reps$ = STRING$(reps)
	END IF
	XuiSendMessage (findBox, #SetTextString, 0, 0, 0, 0, $$FindRepsText, @reps$)
	XuiSendMessage (findBox, #RedrawText, 0, 0, 0, 0, $$FindRepsText, 0)
'
	findReps = reps
	IF (command$ = "f") THEN
		FindSearch()
	ELSE
		ReplaceSearch()
	END IF
END SUB
'
SUB SetTag
	char = LCASE$(command$){1}
	IF ((char < 'a') OR (char > 'z')) THEN EXIT SUB
	i = char - 'a'
	IF (fileType = $$Program) THEN
		jump[i, 0] = editFunction
	END IF
	XuiSendMessage (xitGrid, #GetTextCursor, 0, @cursorLine, 0, 0, $$xitTextLower, 0)
	jump[i, 1] = cursorLine
END SUB
'
SUB JumpTag
	char = LCASE$(command$){1}
	IF ((char < 'a') OR (char > 'z')) THEN EXIT SUB
	i = char - 'a'
	IF (fileType = $$Program) THEN
		Display (jump[i, 0], jump[i, 1], 0, -1, -1)
	ELSE
		XuiSendMessage (xitGrid, #SetTextCursor, 0, jump[i, 1], -1, -1, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	END IF
END SUB
'
SUB LineImmediate
	XuiSendMessage (xitGrid, #GrabTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, 0, 0, $$xitTextLower, 0)
	lastLine = 0
	lastPos = 0
	IF text$[] THEN
		lastLine = UBOUND(text$[])
		lastPos = LEN(text$[lastLine])
'
		totalChars = 0
		FOR line = 0 TO lastLine
			IF (line = cursorLine) THEN lineChars = totalChars + cursorPos
			totalChars = totalChars + LEN(text$[line]) + 1
		NEXT line
		XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	END IF
'
'	m$ = "\nLine = " + STRING(cursorLine) + "/" + STRING(lastLine)
'	m$ = m$ + "   CursorPos = " + STRING(cursorPos)
'	m$ = m$ + "   Character = " + STRING(lineChars) + "/"
'	m$ = m$ + STRING(totalChars) + "\n"
'
	m$ = "line = " + STRING$(cursorLine) + "/" + STRING$(lastLine)
	m$ = m$ + "  xPos = " + STRING$(cursorPos)
	m$ = m$ + "  char = " + STRING$(lineChars) + "/"
	m$ = m$ + STRING$(totalChars)
	AddCommandItem (@m$)
'
'	XuiSendMessage (xitGrid, #GetTextArrayBounds, 0, 0, @lastPos, @lastLine, $$xitTextUpper, 0)
'	XuiSendMessage (xitGrid, #TextReplace, lastPos, lastLine, lastPos, lastLine, $$xitTextUpper, @m$)
'	XuiSendMessage (xitGrid, #SetTextCursor, 0, lastLine + 2, 0, 0, $$xitTextUpper, 0)
'	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextUpper, 0)
END SUB
'
SUB View
	IF (fileType != $$Program) THEN
		Message ("[ViewImmediate]\n Invalid on text file ")
		EXIT SUB
	END IF
	functionName$ = TRIM$(argument$)
	lenName = LEN (functionName$)
'
	IF (command$ == "v") THEN
		IFZ functionName$ THEN
			forward = $$TRUE
			GOSUB ViewFunctionSkip
			EXIT SUB
		ELSE
			command$ = "vv"
		END IF
	END IF
'
	IF (command$ == "v-") THEN
		IFZ functionName$ THEN
			forward = $$FALSE
			GOSUB ViewFunctionSkip
			EXIT SUB
		ELSE
			command$ = "vv"
		END IF
	END IF
'
	SELECT CASE command${1}
		CASE '0':	Display (0, -1, -1, -1, -1)
		CASE 'v':	IFZ functionName$ THEN
								ViewFunc (funcBox, #DisplayWindow, 0, 0, 0, 0, 0, @"")
							ELSE
								ViewFunc (funcBox, #View, 0, 0, 0, 0, 0, @functionName$)
							END IF
		CASE 'f':	IFZ functionName$ THEN
								ViewFunc (funcBox, #DisplayWindow, 0, 0, 0, 0, 0, @"")
							ELSE
								ViewFunc (funcBox, #View, 0, 0, 0, 0, 0, @functionName$)
							END IF
		CASE 'p':	ViewPriorFunc ()
		CASE 'n':	XuiSendMessage (viewNewBox, #SetTextString, lenName, 0, 0, 0, $$DialogText, @functionName$)
							XuiSendMessage (viewNewBox, #SetTextCursor, lenName, 0, 0, 0, $$DialogText, 0)
							ViewNewFunc (viewNewBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		CASE 'd':	ViewDeleteFunc (deleteFuncBox, #DisplayWindow, 0, 0, 0, 0, 0, @functionName$)
		CASE 'r':	XuiSendMessage (viewRenameBox, #SetTextString, lenName, 0, 0, 0, $$DialogText, @functionName$)
							XuiSendMessage (viewRenameBox, #SetTextCursor, lenName, 0, 0, 0, $$DialogText, 0)
							ViewRenameFunc ($$TRUE)
		CASE 'c':	XuiSendMessage (viewCloneBox, #SetTextString, lenName, 0, 0, 0, $$DialogText, @functionName$)
							XuiSendMessage (viewCloneBox, #SetTextCursor, lenName, 0, 0, 0, $$DialogText, 0)
							ViewCloneFunc ($$TRUE)
		CASE 'l':	IF functionName$ THEN
								index = 1:	done = 0
								funcName$ = TRIM$ (XstNextField$ (@functionName$, @index, @done))
								lenName = LEN (funcName$)
								XuiSendMessage (viewLoadBox, #SetTextString, lenName, 0, 0, 0, 2, @funcName$)
								XuiSendMessage (viewLoadBox, #SetTextCursor, lenName, 0, 0, 0, 2, 0)
								IFZ done THEN
									fileName$ = TRIM$(MID$(functionName$, index))
									lenName = LEN (fileName$)
									XuiSendMessage (viewLoadBox, #SetTextString, lenName, 0, 0, 0, 4, @fileName$)
									XuiSendMessage (viewLoadBox, #SetTextCursor, lenName, 0, 0, 0, 4, 0)
								END IF
							END IF
							ViewLoadFunc ($$TRUE)
		CASE 's':	IF functionName$ THEN
								index = 1:	done = 0
								funcName$ = TRIM$ (XstNextField$ (@functionName$, @index, @done))
								lenName = LEN (funcName$)
								XuiSendMessage (viewSaveBox, #SetTextString, lenName, 0, 0, 0, 2, @funcName$)
								XuiSendMessage (viewSaveBox, #SetTextCursor, lenName, 0, 0, 0, 2, 0)
								IFZ done THEN
									fileName$ = TRIM$(MID$(functionName$, index))
									lenName = LEN (fileName$)
									XuiSendMessage (viewSaveBox, #SetTextString, lenName, 0, 0, 0, 4, @fileName$)
									XuiSendMessage (viewSaveBox, #SetTextCursor, lenName, 0, 0, 0, 4, 0)
								END IF
							ELSE
								IFZ editFunction THEN
									funcName$ = "PROLOG"
								ELSE
									XxxFunctionName ($$XGET, @funcName$, editFunction)
								END IF
								lenName = LEN (funcName$)
								XuiSendMessage (viewSaveBox, #SetTextString, lenName, 0, 0, 0, 2, @funcName$)
								XuiSendMessage (viewSaveBox, #SetTextCursor, lenName, 0, 0, 0, 2, 0)
							END IF
							ViewSaveFunc ($$TRUE)
		CASE 'm':	IF functionName$ THEN				' actually, fileName$
								lenName = LEN (functionName$)
								XuiSendMessage (viewMergeBox, #SetTextString, lenName, 0, 0, 0, $$DialogText, @functionName$)
								XuiSendMessage (viewMergeBox, #SetTextCursor, lenName, 0, 0, 0, $$DialogText, 0)
							END IF
							ViewMergePROLOG ($$TRUE)
		CASE 'i':	ViewImportFunctionFromProgram (0)
	END SELECT
END SUB
'
' goes forward/backward 1 function by funcNumber (wraps around)
'
SUB ViewFunctionSkip
	IF ((fileType != $$Program) OR (prog[] == 0)) THEN
		Message (" error \n\n no program loaded ")
		EXIT SUB
	END IF
'
	IF forward THEN
		funcNumber = editFunction + 1
		DO UNTIL (funcNumber > maxFuncNumber)
			IF prog[funcNumber,] THEN
				Display (funcNumber, -1, -1, -1, -1)		' old cursor Position
				EXIT SUB
			END IF
			INC funcNumber
		LOOP
	ELSE
		funcNumber = editFunction - 1
		IF (funcNumber < 0) THEN funcNumber = maxFuncNumber
		DO UNTIL (funcNumber <= 0)
			IF prog[funcNumber,] THEN
				Display (funcNumber, -1, -1, -1, -1)		' old cursor Position
				EXIT SUB
			END IF
			DEC funcNumber
		LOOP
	END IF
	Display (0, -1, -1, -1, -1)										' PROLOG always exists
END SUB
'
SUB OptionTabWidth
	arg = 0
	IF argument$ THEN
		first = argument${0}
		SELECT CASE TRUE
			CASE  (first = 'a')												: arg = 64		' assembly
			CASE  (first = 's')												: arg = 16		' source
			CASE  (first = 'x')												: arg = 16		' xbasic
			CASE ((first >= '0') AND (first <= '9'))	: arg = XLONG (argument$)
		END SELECT
	END IF
	OptionTabWidth (arg)
END SUB
'
SUB OptionTextCursor
	color = 0
	IF argument$ THEN
		color = XLONG (argument$)
		IF ((color >= 1) AND (color <= 124)) THEN
			XuiSendMessage (textCursor, #HideWindow, 0, 0, 0, 0, 0, 0)
			XxxXuiTextCursor (color)
		END IF
	ELSE
		XuiSendMessage (textCursor, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	END IF
END SUB
'
SUB Xit																' goto low-level Xit debugger
	exitMainLoop = $$TRUE
	environmentActive = $$FALSE
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN XitSoftBreak()
END SUB
END FUNCTION
'
'
' ########################
' #####  FileNew ()  #####  Create new Text, Program, GuiProgram.
' ########################  Erase current source (confirm if not saved).
'
FUNCTION  FileNew (newFileType)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  jump[]
	SHARED  uprog,  fileBox,  environmentActive
	SHARED  xitGrid,  newBox,  fileType,  funcBox,  deleteFuncBox
	SHARED  editFile$,  textAlteredSinceSave
	SHARED  resetCodeSize
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" new ", "")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		XxxSetBlowback ()
		AddDispatch (&FileNew(), 0)				' execute blowback first
		RETURN
	END IF
'
	SELECT CASE newFileType
		CASE $$Text
		CASE $$Program
		CASE $$GuiProgram
		CASE ELSE						: newFileType = 0		' unspecified
	END SELECT
'
	IF environmentActive THEN
		IF textAlteredSinceSave THEN
			IF (fileType = $$Program) THEN
				message$ = "FileNew()\nprogram not saved"
			ELSE
				message$ = "FileNew()\ntext not saved"
			END IF
			warningResponse = WarningResponse (@message$, @" new ", @" save ")
			SELECT CASE warningResponse
				CASE $$WarningOption	: abort = FileSave ($$FALSE)
																IF abort THEN RETURN
				CASE $$WarningCancel	: RETURN
			END SELECT
		END IF
	END IF
'
	FileListFuncSet ()
'
	IFZ newFileType THEN
		response = 0
		XuiSendMessage (newBox, #GetModalInfo, @v0, 0, 0, 0, @response, 0)
		newFileType = $$Text
		gui = $$FALSE
		SELECT CASE response
			CASE 0		:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
									newFileType = $$Text
			CASE 2		:	newFileType = $$Text
			CASE 3		:	newFileType = $$Program
			CASE 4		:	newFileType = $$GuiProgram
			CASE 5		:	RETURN
			CASE ELSE	:	PRINT "FileNew() : unknown responses ="; response
									RETURN
		END SELECT
	END IF
'
	DIM name$[]
	XuiSendMessage (funcBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (funcBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (funcBox, #RedrawText, 0, 0, 0, 0, 2, 0)
	XuiSendMessage (funcBox, #RedrawText, 0, 0, 0, 0, 3, 0)
	XuiSendMessage (deleteFuncBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (deleteFuncBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (deleteFuncBox, #RedrawText, 0, 0, 0, 0, 2, 0)
	XuiSendMessage (deleteFuncBox, #RedrawText, 0, 0, 0, 0, 3, 0)
'
	editFile$ = ""
'
	SELECT CASE newFileType
		CASE $$Text						: GOSUB NewText
		CASE $$Program				: GOSUB NewProgram
		CASE $$GuiProgram			: GOSUB NewGuiProgram
	END SELECT
'
	ResetDataDisplays ($$ResetAssembly)
	DIM jump[25,1]															' Clear jump tags
	textAlteredSinceSave = $$FALSE
	IF gui THEN textAlteredSinceSave = $$TRUE
	UpdateFileFuncLabels ($$TRUE, $$TRUE)				'	Reset file/function names
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
	RETURN
'
'
' *****  NewText  *****
'
SUB NewText
	DIM text$[]
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	DIM prog[]															' free prog[]
	DIM funcAltered[]
	DIM funcBPAltered[]
	DIM funcNeedsTokenizing[]
	DIM funcCursorPosition[]
	XuiSendMessage (funcBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage (deleteFuncBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	maxFuncNumber = 0
	fileType = $$Text
END SUB
'
'
' *****  NewProgram  *****
'
SUB NewProgram
	resetCodeSize = $$TRUE
	error = $$FALSE
	fileType = $$Program
	error = XstLoadStringArray ("$XBDIR/templates/prolog.xxx", @text$[])
	IF error THEN DefaultFunctionText (0, @text$[])
	aborted = ConvertTextToProg ($$TextArray, @text$[], $$AbortAllowed)
	IF aborted THEN GOSUB AbortLoad : RETURN
	error = XitLoadFunction (@"Entry", "$XBDIR/templates/entry.xxx")
	IF error THEN Message ("could not load " + "$XBDIR/templates/entry.xxx")
	XitSetDisplayedFunction (@"Entry")
END SUB
'
'
' *****  NewGuiProgram  *****
'
SUB NewGuiProgram
	error = $$FALSE
	fileType = $$Program
	error = XstLoadStringArray ("$XBDIR/templates/gprolog.xxx", @text$[])
	IF error THEN Message ("could not load " + "$XBDIR/templates/gprolog.xxx") : RETURN
	aborted = ConvertTextToProg ($$TextArray, @text$[], $$AbortAllowed)
	IF aborted THEN GOSUB AbortLoad : RETURN
	error = XitLoadFunction (@"Entry", "$XBDIR/templates/gentry.xxx")
	IF error THEN Message ("could not load " + "$XBDIR/templates/gentry.xxx") : GOSUB AbortLoad : RETURN
	error = XitLoadFunction (@"InitGui", "$XBDIR/templates/initgui.xxx")
	IF error THEN Message ("could not load " + "$XBDIR/templates/initgui.xxx") : GOSUB AbortLoad : RETURN
	error = XitLoadFunction (@"InitProgram", "$XBDIR/templates/initprog.xxx")
	IF error THEN Message ("could not load " + "$XBDIR/templates/initprog.xxx") : GOSUB AbortLoad : RETURN
	error = XitLoadFunction (@"CreateWindows", "$XBDIR/templates/create.xxx")
	IF error THEN Message ("could not load " + "$XBDIR/templates/create.xxx") : GOSUB AbortLoad : RETURN
	error = XitLoadFunction (@"InitWindows", "$XBDIR/templates/initwins.xxx")
	IF error THEN Message ("could not load " + "$XBDIR/templates/initwins.xxx") : GOSUB AbortLoad : RETURN
END SUB
'
'
' *****  AbortLoad  *****
'
SUB AbortLoad
	IF (fileType == $$Program) THEN
		Message ("[FileNew( )]\n No new program \n\n resident program removed ")
		DIM text$[]
		XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		fileType = $$Text
		DIM prog[]														' free prog[]
		DIM funcAltered[]
		DIM funcBPAltered[]
		DIM funcNeedsTokenizing[]
		DIM funcCursorPosition[]
		uprog = 0
		maxFuncNumber = 0
		editFile$ = ""
		XstGetCurrentDirectory (@dir$)
		XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @dir$)
		textAlteredSinceSave = $$FALSE
		UpdateFileFuncLabels ($$TRUE, $$TRUE)
		ResetDataDisplays ($$ResetAssembly)
	ELSE
		Message ("[FileNew( )]\n No new text \n\n current text retained ")
	END IF
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
END SUB
END FUNCTION
'
'
' #############################
' #####  FileTextLoad ()  #####
' #############################
'
FUNCTION  FileTextLoad (skipUpdate)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  jump[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  fileBox,  funcBox,  deleteFuncBox
	SHARED  xitGrid,  fileType,  editFile$
	SHARED  textAlteredSinceSave,  environmentActive
	SHARED  uprog
	SHARED  editFileIsReadOnly
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" new ", "")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		XxxSetBlowback ()
		AddDispatch (&FileTextLoad(), 0)					' execute blowback first
		RETURN
	END IF
'
	IF environmentActive THEN
		IF textAlteredSinceSave THEN
			IF (fileType == $$Program) THEN
				message$ = " FileTextLoad() \n program has not been saved "
			ELSE
				message$ = " FileTextLoad() \n text has not been saved "
			END IF
			warningResponse = WarningResponse (@message$, @" load ", @" save ")
			SELECT CASE warningResponse
				CASE $$WarningOption	: abort = FileSave ($$TRUE)
																IF abort THEN RETURN
				CASE $$WarningCancel	: RETURN
			END SELECT
		END IF
	END IF
'
	FileListFuncSet ()
'
	ClearRuntimeError ()
'
	XuiSendMessage (fileBox, #GetTextString, 0, 0, 0, 0, 0, @file$)
	length = LEN (file$)
'
	XstGuessFilename (@editFile$, @file$, @fileName$, @attributes)
	IF (attributes AND $$FileDirectory) THEN skipUpdate = $$FALSE
	IFZ attributes THEN skipUpdate = $$FALSE
'
	IF skipUpdate THEN
		XstGetFileAttributes (@fileName$, @attributes)
		IFZ attributes THEN skipUpdate = $$FALSE
	END IF
'
	length = LEN(fileName$)
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @fileName$)
'
	IFZ skipUpdate THEN
		XuiSendMessage (fileBox, #SetKeyboardFocus, 0, 0, 0, 0, $$FileTextLine, 0)
		XuiSendMessage (fileBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:FileTextLoad")
		XuiSendMessage (fileBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Select text file to load")
		DIM filterArray$[1]
		filterArray$[0] = "*.c, *.dec, *.hlp, *.s, *.txt, *.win, *.x, *.xxx"
		filterArray$[1] = "*"
		XuiSendMessage (fileBox, #SetTextArray, 0, 0, 0, 0, $$FileFilterDropBox, @filterArray$[])
		XuiSendMessage (fileBox, #Update, 0, 0, 0, 0, 0, 0)
		XuiSendMessage (fileBox, #GetModalInfo, @v0, 0, 0, 0, 0, 0)
		XuiSendMessage (fileBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:SelectFile")
		XuiSendMessage (fileBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Select file")
'
		SELECT CASE v0
			CASE -1			:	RETURN						' KeyEscape or Cancel
			CASE 2,6,7	:	' text/file, OK button
			CASE ELSE		:	PRINT "FileTextLoad() : unknown response ="; v0
										RETURN
		END SELECT
		XuiSendMessage (fileBox, #GetTextString, 0, 0, 0, 0, 0, @fileName$)
	END IF
'
	XstGetFileAttributes (@fileName$, @attributes)
'
	SELECT CASE TRUE
		CASE (attributes == 0)
					Message ("[FileTextLoad( )]\n Cannot find file \n\n " + fileName$)
					RETURN
		CASE (attributes AND $$FileDirectory)
					Message ("[FileTextLoad( )]\n Invalid file type \n\n " + fileName$)
					RETURN
	END SELECT
'
' Open file, check its size, make string of nulls, read file into the string
'
	XxxXgrSysMessages ()                                   ' process system messages
	ifile = OPEN (fileName$, $$RD)
'
	IF (ifile < 0) THEN
		Message ("[FileTextLoad( )]\n Error opening file \n\n " + fileName$)
		RETURN
	END IF
'
	editFileIsReadOnly = $$FALSE
	IF (attributes AND $$FileReadOnly) THEN editFileIsReadOnly = $$TRUE
'
	IF (fileType = $$Program) THEN
		DIM prog[]																			' free prog[]
		DIM funcAltered[]
		DIM funcBPAltered[]
		DIM funcNeedsTokenizing[]
		DIM funcCursorPosition[]
		uprog = 0
		maxFuncNumber = 0
		fileType = $$Text
		ResetDataDisplays ($$ResetAssembly)
	END IF
'
	DIM text$[]
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
'
	editFile$ = fileName$
	lenName = LEN (editFile$)
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @editFile$)
	textAlteredSinceSave = $$FALSE
	UpdateFileFuncLabels ($$TRUE, $$TRUE)
'
	DIM name$[]
	XuiSendMessage (funcBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (funcBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (funcBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage (deleteFuncBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (deleteFuncBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (deleteFuncBox, #HideWindow, 0, 0, 0, 0, 0, 0)
'
	DIM jump[25,1]																	' Clear jump tags
'
	ifileSize = LOF (ifile)
	IFZ ifileSize THEN
		CLOSE (ifile)
		Message ("[FileTextLoad( )]\n File has no contents ")
		RETURN
	END IF
'
	SetCurrentStatus ($$StatusLoading, 0)
	text$ = NULL$ (ifileSize)
	READ [ifile], text$
	CLOSE (ifile)
'
' Put loaded string into the text widget, set up editFile$ and fileType
'		TextArea converts to array
'
	XstStringToStringArray (@text$, @text$[])
	text$ = ""																			' free text$ immediately
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	AddFileToBackupDir ($$FALSE)
END FUNCTION
'
'
' #########################
' #####  FileLoad ()  #####
' #########################
'
FUNCTION  FileLoad (skipUpdate)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  jump[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  uprog
	SHARED  fileBox,  editFile$,  editFunction,  xitGrid
	SHARED  textAlteredSinceSave,  fileType,  funcBox,  deleteFuncBox
	SHARED  environmentActive
	SHARED  editFileIsReadOnly
	SHARED  resetCodeSize
'
	FileListFuncSet ()
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" new ", "")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		XxxSetBlowback ()
		AddDispatch (&FileLoad(), 0)
		RETURN
	END IF
'
	IF environmentActive THEN
		IF textAlteredSinceSave THEN
			IF (fileType = $$Program) THEN
				message$ = " FileLoad() \n program has not been saved "
			ELSE
				message$ = " FileLoad() \n text has not been saved "
			END IF
			warningResponse = WarningResponse (@message$, @" load ", @" save ")
			SELECT CASE warningResponse
				CASE $$WarningOption	: abort = FileSave ($$TRUE)
																IF abort THEN RETURN
				CASE $$WarningCancel	: RETURN
			END SELECT
		END IF
	END IF
'
	ClearRuntimeError ()
'
	XuiSendMessage (fileBox, #GetTextString, 0, 0, 0, 0, 0, @file$)
'
	XstGuessFilename (@editFile$, @file$, @fileName$, @attributes)
	IF (attributes AND $$FileDirectory) THEN skipUpdate = $$FALSE
	IFZ attributes THEN skipUpdate = $$FALSE
'
	IF skipUpdate THEN
		XstGetFileAttributes (@fileName$, @attributes)
		IFZ attributes THEN skipUpdate = $$FALSE
	END IF
'
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @fileName$)
'
	IFZ skipUpdate THEN
		XuiSendMessage (fileBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:FileLoad")
		XuiSendMessage (fileBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Select XBasic file to load")
		DIM filterArray$[2]
		filterArray$[0] = "*.x"
		filterArray$[1] = "*.dec, *.txt, *.win, *.x"
		filterArray$[2] = "*"
		XuiSendMessage (fileBox, #SetTextArray, 0, 0, 0, 0, $$FileFilterDropBox, @filterArray$[])
		XuiSendMessage (fileBox, #Update, 0, 0, 0, 0, 0, 0)
		XuiSendMessage (fileBox, #GetModalInfo, @v0, 0, 0, 0, 0, 0)
		XuiSendMessage (fileBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:SelectFile")
		XuiSendMessage (fileBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Select file")
		XxxXgrSysMessages ()                                  ' process system messages
'
		SELECT CASE v0
			CASE -1,0		:	RETURN						' KeyEscape or Cancel
			CASE 2,6,7	:	' text, file, OK button
			CASE ELSE		:	PRINT "xit.x : FileLoad() : unknown response ="; v0
										RETURN
		END SELECT
		XuiSendMessage (fileBox, #GetTextString, 0, 0, 0, 0, 0, @fileName$)
	END IF
'
	IFZ skipUpdate THEN
		IF (LCASE$(RIGHT$(fileName$, 2)) != ".x") THEN
			FileTextLoad ($$TRUE)
			RETURN
		END IF
	END IF
'
	IF (LCASE$(RIGHT$(fileName$, 2)) != ".x") THEN
		IF (LCASE$(RIGHT$(fileName$, 6)) != ".x.bak") THEN
			message$ = " '" + fileName$ + "' \n\n is an invalid file name \n\n must end with .x "
			Message (@message$)
			RETURN
		END IF
	END IF
'
	editFileIsReadOnly = $$FALSE
	XstGetFileAttributes (@fileName$, @attributes)
	SELECT CASE TRUE
		CASE (attributes == 0)
			Message ("[FileLoad( )]\n Cannot find file \n\n " + fileName$)
			RETURN
		CASE (attributes AND $$FileDirectory)
			Message ("[FileLoad( )]\n Invalid file type \n\n " + fileName$)
			RETURN
	END SELECT
'
	ifile  = OPEN (fileName$, $$RD)
	IF (ifile < 0) THEN
		Message ("[FileLoad( )]\n Cannot open file \n\n " + fileName$)
		RETURN
	END IF
'
'	Waste current program now
'
	DIM text$[]
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	DIM name$[]
	XuiSendMessage (funcBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (funcBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (funcBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage (deleteFuncBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (deleteFuncBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (deleteFuncBox, #HideWindow, 0, 0, 0, 0, 0, 0)
'
	editFunction = 0
	fileType = $$Program
	editFile$ = fileName$
	editFileIsReadOnly = $$FALSE
	IF (attributes AND $$FileReadOnly) THEN editFileIsReadOnly = $$TRUE
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @editFile$)
	textAlteredSinceSave = $$FALSE
	UpdateFileFuncLabels ($$TRUE, $$TRUE)
'
	ClearRuntimeError ()
	resetCodeSize = $$TRUE
'
	DIM jump[25,1]																	' Clear jump tags
'
	ifileSize = LOF (ifile)
	IFZ ifileSize THEN
		Message ("[FileLoad( )]\n File has no contents\n\n" + fileName$)
		CLOSE (ifile)
		GOTO AbortLoad
	END IF
'
	SetCurrentStatus ($$StatusLoading, 0)
'
	text$ = NULL$ (ifileSize)							' appends terminating NULL
	IFZ text$ THEN
		Message ("[FileLoad( )]\n Aborted: failed to get memory")
		GOTO AbortLoad
	END IF
	READ [ifile], text$
	CLOSE (ifile)
'
	IFZ TextHasNonWhites ($$TextString, @text$) THEN
		PRINT "FileLoad(167)", text$
		Message ("[FileLoad( )]\n File contains non text\n\n " + fileName$)
		GOTO AbortLoad
	END IF
'
	aborted = ConvertTextToProg ($$TextString, @text$, $$AbortAllowed)
	IF aborted THEN
		Message ("[FileLoad( )]\n Aborted")
		GOTO AbortLoad
	END IF
'
	fileType = $$Program
	ResetDataDisplays ($$ResetAssembly)
	AddFileToBackupDir ($$FALSE)
	RETURN
'
AbortLoad:
	DIM prog[]																				' free prog[]
	DIM funcAltered[]
	DIM funcBPAltered[]
	DIM funcNeedsTokenizing[]
	DIM funcCursorPosition[]
	uprog = 0
	maxFuncNumber = 0
	editFile$ = ""
	XstGetCurrentDirectory (@dir$)
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @dir$)
	fileType = $$Text
	UpdateFileFuncLabels ($$TRUE, $$TRUE)
	ResetDataDisplays ($$ResetAssembly)
END FUNCTION
'
'
' ###############################
' #####  FileRecentLoad ()  #####
' ###############################
'
' index is the index to the recent file list
'
FUNCTION  FileRecentLoad (index)
	EXTERNAL /xxx/ maxFuncNumber
	SHARED  CURSORLOCATION recentCursor[]
	SHARED  deleteFuncBox
	SHARED  editFile$
	SHARED  editFunction
	SHARED  environmentActive
	SHARED  fileBox
	SHARED  xitFileList
	SHARED  fileType
	SHARED  funcAltered[]
	SHARED  funcBox
	SHARED  funcBPAltered[]
	SHARED  funcCursorPosition[]
	SHARED  funcNeedsTokenizing[]
	SHARED  TOKEN prog[]
	SHARED  recentFunc$[]
	SHARED  textAlteredSinceSave
	SHARED  uprog
	SHARED  xitGrid
	SHARED  jump[]
	SHARED  editFileIsReadOnly
	SHARED  resetCodeSize
'
	XuiSendMessage (xitFileList, #HideWindow, 0, 0, 0, 0, 0, 0)
	IF (index < 0) THEN RETURN
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" new ", "")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		AddDispatch (&FileRecentLoad(), index)
		XxxSetBlowback ()
		RETURN
	END IF
'
	IF environmentActive THEN
		IF textAlteredSinceSave THEN
			IF (fileType = $$Program) THEN
				message$ = " FileRecentLoad() \n program has not been saved "
			ELSE
				message$ = " FileRecentLoad() \n text has not been saved "
			END IF
			warningResponse = WarningResponse (@message$, @" load ", @" save ")
			SELECT CASE warningResponse
				CASE $$WarningOption	: abort = FileSave ($$TRUE)
																IF abort THEN RETURN
				CASE $$WarningCancel	: RETURN
			END SELECT
			textAlteredSinceSave = $$FALSE  ' indicate saved whether it was or not
		END IF
	END IF
'
	ClearRuntimeError ()
'
	XuiSendMessage (xitFileList, #GetTextArrayLine, index, @okay, 0, @upper, 0, @fileName$)
	IF (index > upper) THEN RETURN
	funcName$ = recentFunc$[index]
'
	pos = recentCursor[index].pos
	line = recentCursor[index].line
	indent = recentCursor[index].indent
	topLine = recentCursor[index].topLine
'
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, fileName$)
'
	FileListFuncSet ()  ' save present file and function in recent list
'
	ifile  = OPEN (fileName$, $$RD)
	IF (ifile < 0) THEN
		Message ("[FileRecentLoad( )]\n Cannot open file \n\n " + fileName$)
		RETURN
	END IF
'
	editFileIsReadOnly = $$FALSE
	XstGetFileAttributes (@fileName$, @attributes)
	IF (attributes AND $$FileReadOnly) THEN editFileIsReadOnly = $$TRUE
'
'	Waste current program now
'
	DIM text$[]
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	DIM name$[]
	XuiSendMessage (funcBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (funcBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (funcBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage (deleteFuncBox, #SetTextArray, 0, 0, 0, 0, 2, @name$[])
	XuiSendMessage (deleteFuncBox, #SetTextString, 0, 0, 0, 0, 3, @"")
	XuiSendMessage (deleteFuncBox, #HideWindow, 0, 0, 0, 0, 0, 0)
'
	editFunction = 0
	editFile$ = fileName$
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @editFile$)
	textAlteredSinceSave = $$FALSE
'
	ClearRuntimeError ()
'
	DIM jump[25,1]																	' Clear jump tags
'
	ifileSize = LOF (ifile)
	IFZ ifileSize THEN
		Message ("[FileRecentLoad( )]\n File has no contents\n\n" + fileName$)
		CLOSE (ifile)
		GOTO AbortLoad
	END IF
'
	SetCurrentStatus ($$StatusLoading, 0)
'
	text$ = NULL$ (ifileSize)							' appends terminating NULL
	READ [ifile], text$
	CLOSE (ifile)
'
' Check for and load text file, could also be program file in text mode
'
	IF ((LCASE$(RIGHT$(fileName$, 2)) != ".x") || (funcName$ == "$$Text")) THEN
		fileType = $$Text
		UpdateFileFuncLabels ($$TRUE, $$TRUE)
		DIM prog[]
		DIM funcAltered[]
		DIM funcBPAltered[]
		DIM funcNeedsTokenizing[]
		DIM funcCursorPosition[]
		uprog = 0
		maxFuncNumber = 0
		fileType = $$Text
		ResetDataDisplays ($$ResetAssembly)
'
		XstStringToStringArray (text$, @text$[])
		text$ = ""
		XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, pos, line, indent, topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		AddFileToBackupDir ($$FALSE)
		RETURN
	END IF
'
' Load program file
'
	resetCodeSize = $$TRUE
'
	IFZ TextHasNonWhites ($$TextString, @text$) THEN
		PRINT "FileRecentLoad(155)", text$
		Message ("[FileRecentLoad()]\n File contains non text\n\n" + fileName$)
		GOTO AbortLoad
	END IF
'
	aborted = ConvertTextToProg ($$TextString, @text$, $$AbortAllowed)
	IF aborted THEN
		Message ("[FileRecentLoad( )]\n Aborted")
		GOTO AbortLoad
	END IF
'
	fileType = $$Program                        ' converted to program
	UpdateFileFuncLabels ($$TRUE, $$TRUE)
	ResetDataDisplays ($$ResetAssembly)
'
' Go to saved function and cursor position
'
	IF (editFile$ == fileName$) THEN
		IF (fileType == $$Program) THEN
			funcNum = XxxFunctionNumber (funcName$)
			Display (funcNum, line, pos, topLine, indent)
		END IF
	END IF
	AddFileToBackupDir ($$FALSE)
	RETURN
'
' ---------------------------------------------------------------------
'
AbortLoad:
	DIM prog[]																				' free prog[]
	DIM funcAltered[]
	DIM funcBPAltered[]
	DIM funcNeedsTokenizing[]
	DIM funcCursorPosition[]
	uprog = 0
	maxFuncNumber = 0
	editFile$ = ""
	XstGetCurrentDirectory (@dir$)
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @dir$)
	fileType = $$Text
	UpdateFileFuncLabels ($$TRUE, $$TRUE)
	ResetDataDisplays ($$ResetAssembly)
'
END FUNCTION
'
'
' #########################
' #####  FileSave ()  #####
' #########################
'
FUNCTION  FileSave (skipUpdate)
	SHARED  xitGrid,  fileBox,  fileType,  textAlteredSinceSave
	SHARED  editFile$
	SHARED  saveCRLF, makeBackupFile
	SHARED  xbasicBackupDir$
'
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, editFile$)
'	XuiSendMessage (fileBox, #GetTextString, 0, 0, 0, 0, 0, @file$)
'
	XstGuessFilename (@editFile$, @file$, @fileName$, @attributes)
	IF (attributes AND $$FileDirectory) THEN skipUpdate = $$FALSE
	IF (attributes AND $$FileReadOnly) THEN skipUpdate = $$FALSE
	IFZ attributes THEN skipUpdate = $$FALSE
'
	IF (LCASE$(RIGHT$(fileName$, 4)) == ".bak") THEN skipUpdate = $$FALSE
'
	IFZ skipUpdate THEN
'		XuiSendMessage (fileBox, #Update, 0, 0, 0, 0, 0, 0)
		XuiSendMessage (fileBox, #SetKeyboardFocus, 0, 0, 0, 0, $$FileTextLine, 0)
		XuiSendMessage (fileBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:FileSave")
		XuiSendMessage (fileBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Save file")
'
		dot = RINSTR(editFile$, ".")
		IF dot THEN
			filter0$ = "*" + MID$(editFile$, dot)
		ELSE
			IF (fileType == $$Program) THEN
				filter0$ = "*.x"
			ELSE
				filter0$ = "*"
			END IF
		END IF
'
		DIM filterArray$[2]
		filterArray$[0] = filter0$
		filterArray$[1] = "*.x, *.txt, *.win"
		filterArray$[2] = "*"
		XuiSendMessage (fileBox, #SetTextArray, 0, 0, 0, 0, $$FileFilterDropBox, @filterArray$[])
		XuiSendMessage (fileBox, #Update, 0, 0, 0, 0, 0, 0)
		XuiSendMessage (fileBox, #GetModalInfo, @v0, 0, 0, 0, 0, 0)
		XuiSendMessage (fileBox, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:SelectFile")
		XuiSendMessage (fileBox, #SetWindowTitle, 0, 0, 0, 0, 0, @"Select file")
'
		SELECT CASE v0
			CASE -1			:	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @file$)
										RETURN (-1)						' KeyEscape or Cancel
			CASE 2,6,7	:	' text/file, OK button
			CASE ELSE		:	PRINT "FileSave() : unknown response ="; v0
										RETURN (-1)
		END SELECT
		XuiSendMessage (fileBox, #GetTextString, 0, 0, 0, 0, 0, @fileName$)
	END IF
'
	fileName$ = TRIM$(fileName$)
'
	IFZ fileName$ THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n need file name ")
		RETURN (-1)
	END IF
'
	XstGetFileAttributes (@fileName$, @attributes)
	IF (attributes AND $$FileDirectory) THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n file name is a directory \n\n " + fileName$ + " ")
		RETURN (-1)
	END IF
	IF (attributes AND $$FileReadOnly) THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n file name is Read Only \n\n " + fileName$ + " ")
		RETURN (-1)
	END IF
'
	IF UCASE$(fileName$) != UCASE$(editFile$) THEN
		IF XstGetFileAttributes (fileName$, 0) THEN
			message$ = "FileSave( )\nfilename already exists\n" + fileName$
			warningResponse = WarningResponse (@message$, @" save ", "")
			IF (warningResponse = $$WarningCancel) THEN
				XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @file$)
				RETURN (-1)
			END IF
		END IF
	END IF
'
	IF textAlteredSinceSave THEN
		IF makeBackupFile THEN
			IF XstGetFileAttributes (fileName$, 0) THEN
				XstCopyFile (fileName$, fileName$ + ".bak")
			END IF
		END IF
	END IF
'
	IF xbasicBackupDir$ THEN
		saveInBackupDir = textAlteredSinceSave    'make backup after it is saved
		IFZ skipUpdate THEN saveInBackupDir = $$TRUE  'file might be renamed
	END IF
'
	SELECT CASE fileType
		CASE $$Text			:	GOSUB SaveFileText
		CASE $$Program	:	GOSUB SaveFileProgram
	END SELECT
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @editFile$)
'
	IF saveInBackupDir THEN
		AddFileToBackupDir (skipUpdate)
	END IF
'
	RETURN (0)
'
'
'	*****  Save the environment TEXT to a disk file  *****
'
SUB SaveFileText
	ofile = OPEN (fileName$, $$WRNEW)
	IF (ofile < 0) THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n unable to open file \n\n \"" + fileName$ + "\" ")
		CLOSE (ofile)
		RETURN (-1)
	END IF
'
	SetCurrentStatus ($$StatusSaving, 0)
'
' write text to file
'
	XuiSendMessage (xitGrid, #GetTextSelection, @begPos, @begLine, @endPos, @endLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #GrabTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	IF text$[] THEN
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		FOR i = 0 TO UBOUND (text$[])
			text$[i] = RTRIM$(text$[i])  'trim white-space from end of lines
		NEXT i
'
		IF saveCRLF THEN
			XstStringArrayToStringCRLF (@text$[], @text$)		' newline = \r\n
		ELSE
			XstStringArrayToString (@text$[], @text$)				' newline = \n
		END IF
		XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		##ERROR = $$FALSE
		WRITE [ofile], text$
		IF ##ERROR THEN
			Message ("[FileSave( )]\n !!! file not saved !!! \n\n write to file failed ")
			CLOSE (ofile)
			RETURN (-1)
		END IF
		IF (LEN(text$) != LOF(ofile)) THEN
			Message ("[FileSave( )]\n !!! file not saved !!! \n\n write to file failed ")
			CLOSE (ofile)
			RETURN (-1)
		END IF
		IF ((begPos !=endPos) || (begLine != endLine)) THEN
			XuiSendMessage (xitGrid, #SetTextSelection, begPos, begLine, endPos, endLine, $$xitTextLower, 0)
		END IF
		XuiSendMessage (xitGrid, #Redraw, 0, 0, 0, 0, $$xitTextLower, 0)
	END IF
	CLOSE (ofile)
	editFile$ = fileName$
	textAlteredSinceSave = $$FALSE
'
'	Reset file name
'
	UpdateFileFuncLabels ($$TRUE, 0)
END SUB
'
'
'	*****  Save the environment PROGRAM to a disk file  *****
'
SUB SaveFileProgram
'
	XuiSendMessage (xitGrid, #GetTextSelection, @begPos, @begLine, @endPos, @endLine, $$xitTextLower, 0)
'
' Note:  if ##USERRUNNING then text is unaltered and Restore.. does nothing
'
	redisplay = $$TRUE
	reportBogusRename = $$TRUE						' tokenize, resets BPs if necessary
	RestoreTextToProg (redisplay, reportBogusRename)
'
	aborted = ConvertProgToText ($$TextString, saveCRLF, $$AbortAllowed, @text$)
'	PRINT "FileSave(182):" text$
	IF aborted THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n aborted ")
		RETURN (-1)
	END IF
'
	ofile = OPEN (fileName$, $$WRNEW)
	IF (ofile < 0) THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n can't open file \n\n \"" + fileName$ + "\" ")
		RETURN (-1)
	END IF
'
	SetCurrentStatus ($$StatusSaving, 0)
'
	##ERROR = $$FALSE
	WRITE [ofile], text$
	IF ##ERROR THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n write to file failed ")
		CLOSE (ofile)
		RETURN (-1)
	END IF
	IF (LEN(text$) != LOF(ofile)) THEN
		Message ("[FileSave( )]\n !!! file not saved !!! \n\n write to file failed ")
		CLOSE (ofile)
		RETURN (-1)
	END IF
	CLOSE (ofile)
'
	editFile$ = fileName$
	textAlteredSinceSave = $$FALSE
'
'	Reset file name
'
	UpdateFileFuncLabels ($$TRUE, 0)
'
	IF ((begPos !=endPos) || (begLine != endLine)) THEN
		XuiSendMessage (xitGrid, #SetTextSelection, begPos, begLine, endPos, endLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #Redraw, 0, 0, 0, 0, $$xitTextLower, 0)
	END IF
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN
		SetCurrentStatus ($$StatusRunning, 0)
	END IF
END SUB
END FUNCTION
'
'
' #########################
' #####  FileMode ()  #####
' #########################
'
FUNCTION  FileMode (mode)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[],  jump[]
	SHARED  environmentActive
	SHARED  uprog
	SHARED  modeBox
	SHARED  xitGrid
	SHARED  fileType
	SHARED  textAlteredSinceSave
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" mode ", "")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		AddDispatch (&FileMode(), 0)          ' add dispatch first
		XxxSetBlowback ()
'		AddDispatch (&FileMode(), 0)					' execute blowback first
		RETURN
	END IF
'
	IF environmentActive THEN
		IF textAlteredSinceSave THEN
			IF (fileType = $$Program) THEN
				message$ = "FileMode()\nprogram not saved"
			ELSE
				message$ = "FileMode()\ntext not saved"
			END IF
			warningResponse = WarningResponse (@message$, @" mode ", @" save ")
			SELECT CASE warningResponse
				CASE $$WarningOption	: FileSave ($$FALSE)
																RETURN
				CASE $$WarningCancel	: RETURN
			END SELECT
		END IF
	END IF
'
	response = 0
	SELECT CASE mode
		CASE $$Text				: modeType = $$Text
		CASE $$Program		: modeType = $$Program
		CASE $$GuiProgram	: modeType = $$Program
		CASE ELSE					: modeType = 0
	END SELECT
'
	IFZ modeType THEN
		modeType = $$Text
		XuiSendMessage (modeBox, #GetModalInfo, @v0, 0, 0, 0, @response, 0)
		SELECT CASE response
			CASE 0		:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
									modeType = $$Program
			CASE 2		:	modeType = $$Program
			CASE 3		:	modeType = $$Text
			CASE 4		:	RETURN
			CASE ELSE	:	PRINT "FileMode() : unknown response ="; response
									RETURN
		END SELECT
	END IF
'
	IF (modeType = $$Program) THEN
		IF (fileType = $$Program) THEN RETURN								' wise guy
'
		XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		IFZ TextHasNonWhites ($$TextArray, @text$[]) THEN		' fix NULL
			XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			DefaultFunctionText (0, @text$[])									' whiz up a PROLOG
			aborted = ConvertTextToProg ($$TextArray, @text$[], $$AbortAllowed)
		ELSE
'
'			Convert from string:  ConvertTextToProg mangles array...
'
			XstStringArrayToStringCRLF (@text$[], @text$)		' CRLF
			aborted = ConvertTextToProg ($$TextString, @text$, $$AbortAllowed)
		END IF
'
		IF aborted THEN
			Message ("[FileMode( )]\n mode unchanged \n\n current text retained \n\n conversion aborted ")
			XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
			RETURN
		END IF
		fileType = $$Program
		UpdateFileFuncLabels (0, $$TRUE)
		ResetDataDisplays ($$ResetAssembly)
	ELSE
		IF (fileType = $$Text) THEN RETURN		' wise guy
		redisplay = $$TRUE
		reportBogusRename = $$TRUE						' tokenize, resets BPs if necessary
		RestoreTextToProg (redisplay, reportBogusRename)
		ClearRuntimeError ()
		aborted = ConvertProgToText ($$TextArray, 0, $$AbortAllowed, @text$[])
	PRINT text$
		IF aborted THEN
			Message ("[FileMode( )]\n mode not changed \n\n conversion aborted ")
			RETURN
		END IF
		fileType = $$Text
		XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
		DIM prog[]														' free prog[]
		DIM funcAltered[]
		DIM funcBPAltered[]
		DIM funcNeedsTokenizing[]
		DIM funcCursorPosition[]
		uprog = 0
		maxFuncNumber = 0
		UpdateFileFuncLabels (0, $$TRUE)
		ResetDataDisplays ($$ResetAssembly)
	END IF
	DIM jump[25,1]													' Clear jump tags
END FUNCTION
'
'
' ###########################
' #####  FileRename ()  #####
' ###########################
'
FUNCTION  FileRename (skipUpdate)
	SHARED  fileBox
	SHARED  fileType
	SHARED  renameBox
	SHARED  editFile$
'
	XuiSendMessage (renameBox, #GetTextString, 0, 0, 0, 0, $$DialogText, @newName$)
'
	IFZ skipUpdate THEN
		IF (newName$ != editFile$) THEN
			lenName = LEN (editFile$)
			XuiSendMessage (renameBox, #SetTextString, lenName, 0, 0, 0, $$DialogText, @editFile$)
			XuiSendMessage (renameBox, #SetTextCursor, lenName, 0, 0, 0, $$DialogText, 0)
		END IF
	END IF
'
	IFZ skipUpdate THEN
		response = 0
		XuiSendMessage (renameBox, #GetModalInfo, @v0, 0, 0, 0, @response, 0)
		SELECT CASE response
			CASE 2		:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
			CASE 3		:	' OK button
			CASE 4		:	RETURN
			CASE ELSE	:	PRINT "FileRename() : unknown response ="; response
									RETURN
		END SELECT
		XuiSendMessage (renameBox, #GetTextString, 0, 0, 0, 0, $$DialogText, @newName$)
	END IF
'
	IFZ newName$ THEN
		Message ("[FileRename( )]\n No file name specified ")
		RETURN
	END IF
'
	IF ((fileType = $$Program) OR (fileType = $$GuiProgram)) THEN
		dot = INSTR (newFile$, ".")
		IFZ dot THEN newFile$ = newFile$ + ".x"
		IF (RIGHT$(newFile$,2) != ".x") THEN
			Message ("[FileRename( )]\n Did not rename \n\n Name must end with .x ")
			RETURN
		END IF
	END IF
'
	XstGetFileAttributes (@newName$, @attributes)
	SELECT CASE TRUE
		CASE (attributes AND $$FileDirectory)
			Message ("[FileRename( )]\n Error \n\n Invalid file name \n\n " + newName$)
			RETURN
		CASE attributes
			Message ("[FileRename( )]\n warning \n\n File already exists \n\n " + newName$)
	END SELECT
'
'	Reset file name
'
	XuiSendMessage (fileBox, #SetTextString, 0, 0, 0, 0, 0, @newName$)
	editFile$ = newName$
	UpdateFileFuncLabels ($$TRUE, 0)
END FUNCTION
'
'
' #########################
' #####  FileQuit ()  #####
' #########################
'
FUNCTION  FileQuit ()
	SHARED  environmentActive
	SHARED  fileType
	SHARED  prefFileNumber
	SHARED  textAlteredSinceSave
'
' If there is an exception other than a breakpoint,
' just quit immediately
'
	IF (##EXCEPTION AND NOT $$ExceptionBreakpoint) THEN
		XxxXitQuit (0)
	END IF
'
' Stop user program, if desired, before quitting
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		message$ = "???? stop program execution ????"
		warningResponse = WarningResponse (@message$, @" stop ", "")
		IF (warningResponse = $$WarningCancel) THEN XxxXitQuit (0)
		'
		XxxSetBlowback ()
		AddDispatch (&FileQuit(), 0)         ' return here after blowback
		##USERWAITING = $$FALSE              ' unblock waiting in INLINE$()
		##USERABORT = $$TRUE                 ' unblock waiting in XstFindFiles
		RETURN
	END IF
'
	IF environmentActive THEN
		IF textAlteredSinceSave THEN
			IF (fileType = $$Program) THEN
				message$ = "Quit\nprogram not saved"
			ELSE
				message$ = "Quit\ntext not saved"
			END IF
			warningResponse = WarningResponse (@message$, @" quit ", @" save ")
			SELECT CASE warningResponse
				CASE $$WarningProceed
				CASE $$WarningOption	: abort = FileSave ($$TRUE)
																IF abort THEN RETURN
				CASE $$WarningCancel	: RETURN
				CASE ELSE             : RETURN  'handle failed response as cancel
			END SELECT
		END IF
	END IF
'
	SetCurrentStatus ($$StatusQuitting, 0)
	IFZ (##EXCEPTION AND NOT $$ExceptionBreakpoint) THEN
		XitSavePDEPref ()
		error = XstClosePref (prefFileNumber)
		IF error THEN XxxLog2 ("FileQuit():Error", error)
	END IF
	XxxXitQuit (0)
'
END FUNCTION
'
'
' ################################
' #####  FileListFuncSet ()  #####
' ################################
'
' This function is called immediately before another file is loaded,
' to save the function name and cursor position of the existing file.
'
FUNCTION  FileListFuncSet ()
	SHARED CURSORLOCATION recentCursor[]
	SHARED recentFile$[]
	SHARED recentFunc$[]
	SHARED editFile$
	SHARED editFunction
	SHARED fileType
	SHARED xitGrid
'
	IFZ editFile$ THEN RETURN
	IFZ recentFile$[] THEN RETURN
	IF (editFile$ != recentFile$[0]) THEN
		IF ##XBDV THEN PRINT "FileListFuncSet():error", editFile$, "<>", recentFile$[0]
	END IF
'
	IF (fileType == $$Program) THEN
		XxxFunctionName ($$XGET, @functionName$, editFunction)
		recentFunc$[0] = functionName$
	ELSE
		recentFunc$[0] = "$$Text"
	END IF
	XuiSendMessage (xitGrid, #GetTextCursor, @pos, @line, @indent, @topLine, $$xitTextLower, 0)
	recentCursor[0].pos     = pos
	recentCursor[0].line    = line
	recentCursor[0].indent  = indent
	recentCursor[0].topLine = topLine
'
END FUNCTION
'
'
' #########################
' #####  EditFind ()  #####
' #########################
'
FUNCTION  EditFind (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	SHARED  findText$,  replaceText$,  findReps
	SHARED  findLocal,  findReverse, findCase, findWord
	SHARED  xitGrid
'
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $$FindFindText, @findText$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $$FindReplaceText, @replaceText$)
	SELECT CASE message
		CASE #Callback				: GOSUB Callback
		CASE #DisplayWindow		: GOSUB DisplayWindow		' Direct
		CASE #FindForward, #FindReverse
			IFZ findText$ THEN
				GOSUB DisplayWindow
			ELSE
				GOSUB Execute					' Direct
			END IF
		CASE #ReplaceForward, #ReplaceReverse
			IF findText$ = "" || replaceText$ = "" THEN
				GOSUB DisplayWindow
			ELSE
				GOSUB Execute					' Direct
			END IF
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
		CASE #TextModified	: GOSUB TextModified
	END SELECT
END SUB
'
'
' *****  TextModified  *****
'
SUB TextModified
	IF (r0 == $$FindFindText) THEN
		IF findText$ THEN
			backHint$ = XstBinStringToBackString$ (findText$)
			XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitHotFind, "F11 : find \"" + backHint$ + "\"")
		ELSE
			XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitHotFind, @"F11 : find string in program or text-file")
		END IF
	END IF
	IF (r0 == $$FindReplaceText) THEN
		IF replaceText$ THEN
			backHint$ = XstBinStringToBackString$ (replaceText$)
			XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitHotReplace, "F12 : replace string \"" + backHint$ + "\"")
		ELSE
			XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitHotReplace, @"F12 : replace string in program or text-file")
		END IF
	END IF
END SUB
'
'
' *****  DisplayWindow  *****
'
SUB DisplayWindow
	XgrGetTextSelectionGrid (@textSelectionGrid)
	IF textSelectionGrid THEN
		XuiSendMessage (textSelectionGrid, #GetTextSelection, 0, 0, 0, 0, 0, @select$)
		IF select$ THEN
			backHint$ = XstBinStringToBackString$ (select$)
			SELECT CASE r0
				CASE $$FindFindButton
					textKid = $$FindFindText
					hintKid = $$xitHotFind
					hint$ = "F11 : find \"" + backHint$ + "\""
				CASE $$FindReplaceButton
					textKid = $$FindReplaceText
					hintKid = $$xitHotReplace
					hint$ = "F12 : replace string \"" + backHint$ + "\""
				CASE ELSE : EXIT IF
			END SELECT
			lenName = LEN (select$)
			XuiSendMessage (textSelectionGrid, #RedrawText, 0, 0, 0, 0, 0, 0)
			backSelect$ = XstBinStringToBackString$ (select$)
			XuiSendMessage (grid, #SetTextString, lenName, 0, 0, 0, textKid, @backSelect$)
			XuiSendMessage (grid, #SetTextCursor, lenName, 0, 0, 0, textKid, 0)
			XuiSendMessage (grid, #RedrawGrid, 0, 0, 0, 0, textKid, 0)
			XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, hintKid, hint$)
		END IF
	END IF
	XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, 1, 0)
END SUB
'
'
' *****  Execute  *****  For Hot button execution only
'
SUB Execute
	findReps = 0
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $$FindFindText, @findText$)
'
	SELECT CASE message
		CASE #FindForward    : findReverse = $$FALSE : r0 = $$FindFindButton
		CASE #FindReverse    : findReverse = $$TRUE  : r0 = $$FindFindButton
		CASE #ReplaceForward : findReverse = $$FALSE : r0 = $$FindReplaceButton
		CASE #ReplaceReverse : findReverse = $$TRUE  : r0 = $$FindReplaceButton
	END SELECT
	GOSUB FindReplace
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $$FindRepsText, @reps$)
	IF (reps$ = "*") THEN
		findReps = -1
	ELSE
		findReps = XLONG(reps$)
	END IF
'
	SELECT CASE r0
		CASE $$FindLocalToggle
					findLocal = $$FALSE
					IF v0 THEN findLocal = $$TRUE
		CASE $$FindReverseToggle
					findReverse = $$FALSE
					IF v0 THEN findReverse = $$TRUE
		CASE $$FindCaseToggle
					findCase = $$FALSE
					IF v0 THEN findCase = $$TRUE
		CASE $$FindWordToggle
					findWord = $$FALSE
					IF v0 THEN findWord = $$TRUE
		CASE $$FindFindText, $$FindReplaceText, $$FindRepsText
					IF (v0{$$VirtualKey} = $$KeyEscape) THEN
						XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)		' CANCEL
					ELSE
						r0 = $$FindFindButton
						GOSUB FindReplace																				' FIND
					END IF
		CASE $$FindCancelButton
					XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $$FindReplaceText, "")
					XuiSendMessage (grid, #RedrawGrid, 0, 0, 0, 0, $$FindReplaceText, 0)
					hint$ = "F12 : replace string in program or text-file"
					XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitHotReplace, hint$)
					XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $$FindFindText, "")
					XuiSendMessage (grid, #RedrawGrid, 0, 0, 0, 0, $$FindFindText, 0)
					hint$ = "F11 : find string in program or text-file"
					XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitHotFind, hint$)
					IFF (v2 AND $$ShiftBit) THEN  'Do not Hide if Shift key is held down
						XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
					END IF
		CASE $$FindFindButton, $$FindReplaceButton
					IF (v2 AND $$ShiftBit) THEN  'Shift key is held down means
						GOSUB DisplayWindow        'change find or replace string.
					ELSE
						GOSUB FindReplace
					END IF
	END SELECT
END SUB
'
'
' *****  FindReplace  *****
'
SUB FindReplace
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $$FindFindText, @findText$)
	IF (INSTR (findText$, "\\")) THEN
		findText$ = XstBackStringToBinString$ (@findText$)
	END IF
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $$FindReplaceText, @replaceText$)
	IF (INSTR (replaceText$, "\\")) THEN
		replaceText$ = XstBackStringToBinString$ (@replaceText$)
	END IF
	IFZ findText$ THEN
		Message ("[EditFind( )]\n No find text specified ")
		RETURN
	END IF
'
' A replace with zero repetitions means replace the selected text,
' if it matches the find-string, and then search for the next match.
'
	IFZ findReps THEN
		IF (r0 = $$FindReplaceButton) THEN
			GOSUB ReplacePaste
		END IF
		IF (r0 = $$FindFindButton) THEN
			FindSearch ()
		END IF
		RETURN
	END IF
	IF (r0 = $$FindFindButton) THEN
		FindSearch ()
	ELSE
		ReplaceSearch ()
	END IF
END SUB
'
'
' *****  ReplacePaste  *****
'
SUB ReplacePaste
	IFZ replaceText$ THEN
		Message ("[EditFind( )]\n No replace string specified ")
		EXIT SUB
	END IF
'
	XuiSendMessage (xitGrid, #GetTextSelection, @begPos, @begLine, @endPos, @endLine, $$xitTextLower, @select$)
	IF (LCASE$(select$) == LCASE$(findText$)) THEN
		v2 = ($$KeyInsert << 24) OR $$KeyInsert OR $$ShiftBit
		r0 = $$xitTextLower
		EnvironmentCode (xitGrid, #TextEvent, 0, 0, v2, 0, @r0, 0)
		IF (r0 = -1) THEN RETURN
		XuiSendMessage (xitGrid, #TextReplace, @begPos, @begLine, @endPos, @endLine, $$xitTextLower, replaceText$)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		IF findReverse THEN
			XuiSendMessage (xitGrid, #SetTextCursor, begPos-1, begLine, -1, -1, $$xitTextLower, 0)
		ELSE
			XuiSendMessage (xitGrid, #SetTextCursor, endPos-1, endLine, -1, -1, $$xitTextLower, 0)
		END IF
		EnvironmentCode (xitGrid, #TextModified, 0, 0, 0, 0, 0, 0)
		FindSearch ()
	ELSE
		Message ("[EditFind( )]\n Selected string does not match find string specified ")
	END IF
'
END SUB
'
END FUNCTION
'
'
' ###########################
' #####  FindSearch ()  #####
' ###########################
'
'	Find routine (based on SHARED parameters)
'
'	In:				none
'	Out:			none
'
'	Discussion:
'		All functions are frozen for the search.  The editFunction text is
'			carried in text$[], all the other functions use progText$.
'			When the final match is made, if it is not in editFunction, then
'			editFunction is Restored and the match function displayed.
'
FUNCTION  FindSearch ()
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN prog[]
	SHARED  funcCursorPosition[]
	SHARED  xitGrid,  editFunction,  priorFunction
	SHARED  findBox,  findReverse,  findReps,  findText$
	SHARED  fileType,  softInterrupt
	SHARED  findCase,  findLocal
	SHARED  findWord
	SHARED  currentCursor
	SHARED	freezeState
'
	IF freezeState THEN RETURN				' not recursive - causes stack blowup
	entryCursor = currentCursor
	softInterrupt = $$FALSE
'
' Skip it if no text selected
'
	IFZ findText$ THEN
		Message ("[FindSearch( )]\n no find string specified ")
		RETURN (-1)
	END IF
'
'	Skip it if 0 reps requested
'
	IF (findReps < 0) THEN
		findReps = 0
		XuiSendMessage (findBox, #SetTextString, 0, 0, 0, 0, $$FindRepsText, @"0")
		XuiSendMessage (findBox, #RedrawText, 0, 0, 0, 0, $$FindRepsText, 0)
	END IF
	reps = findReps
	IFZ reps THEN reps = 1
	IF findCase THEN
		mode = $$FindForward OR $$FindCaseSensitive
		IF findReverse THEN mode = $$FindReverse OR $$FindCaseSensitive
	ELSE
		mode = $$FindForward OR $$FindCaseInsensitive
		IF findReverse THEN mode = $$FindReverse OR $$FindCaseInsensitive
	END IF
	IF findWord THEN
		mode = mode OR $$FindWordSensitive
	ELSE
		mode = mode OR $$FindWordInsensitive
	END IF
'
	freezeState = $$TRUE											' can't start another replace
'
' $$Text and $$Program first check the current text widget
'
	IF (mode AND $$FindReverse) THEN
		XuiSendMessage (xitGrid, #GetTextSelection, @cursorPos, @cursorLine, 0, 0, $$xitTextLower, 0)
	END IF
	IFZ (cursorPos OR cursorLine) THEN
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, 0, @topLine, $$xitTextLower, @rows)
	ELSE
		XuiSendMessage (xitGrid, #GetTextCursor, 0, 0, 0, @topLine, $$xitTextLower, @rows)
	END IF
'
	XuiSendMessage (xitGrid, #GetTextSelection, 0, 0, 0, 0, $$xitTextLower, @selection$)
	IF (LCASE$(selection$) == LCASE$(findText$)) THEN                          ' skip if cursor at a match
		skip = $$TRUE
	ELSE
		skip = $$FALSE
	END IF
'
	XuiSendMessage (xitGrid, #GrabTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	FindArray (mode, @text$[], @findText$, cursorLine, cursorPos, @reps, skip, @matches[])
	IFZ reps THEN GOTO matchInText
'
' TEXT/LOCAL only checks from cursor to end of text
'
	IF (fileType != $$Program) OR (findLocal = $$TRUE) THEN GOTO noMatch
	IFZ prog[] THEN GOTO noMatch
	skip = $$FALSE
	IF maxFuncNumber THEN												'	Do global check of rest of PROGRAM
		i = 0
		funcNumber = editFunction
		DO
			IF findReverse THEN
				DEC funcNumber
				IF (funcNumber < 0) THEN funcNumber = maxFuncNumber
			ELSE
				INC funcNumber
				IF (funcNumber > maxFuncNumber) THEN funcNumber = 0
			END IF
			IF (funcNumber = editFunction) THEN EXIT DO			' Stop before editFunction
			IFZ prog[funcNumber,] THEN DO DO
			SetCurrentStatus ($$StatusSearching, i)					' Clears queue
			IF softInterrupt THEN GOTO noMatch
			TokenArrayToText (funcNumber, @progText$[])
			IF findReverse THEN
				line = UBOUND(progText$[])
				pos = LEN(progText$[line])
			ELSE
				line = 0
				pos = 0
			END IF
			FindArray (mode, @progText$[], @findText$, line, pos, @reps, skip, @matches[])
			IFZ reps THEN GOTO matchInProg
			INC i
		LOOP
	END IF
'
' Now check other half of text
'
	SELECT CASE TRUE
		CASE findReverse
			IF (cursorLine = uText) THEN							' already tested entire text?
				IF (cursorPos >= LEN(text$[cursorLine])) THEN EXIT SELECT
			END IF
			line = uText
			pos = LEN(text$[uText])
			FindArray (mode, @text$[], @findText$, line, pos, @reps, skip, @matches[])
			IFZ reps THEN
				match = UBOUND(matches[])
				line = matches[match,0]
				pos = matches[match,1]
				IF (line < cursorLine) THEN EXIT SELECT
				IF (line = cursorLine) THEN
					IF (pos <= cursorPos) THEN EXIT SELECT
				END IF
				GOTO matchInText
			END IF
		CASE ELSE
			IF (cursorLine = 0) THEN									' already tested entire text
				IF (cursorPos = 0) THEN EXIT SELECT
			END IF
			line = 0
			pos = 0
			FindArray (mode, @text$[], @findText$, line, pos, @reps, skip, @matches[])
			IFZ reps THEN
				match = UBOUND(matches[])
				line = matches[match,0]
				pos = matches[match,1]
				IF (line > cursorLine) THEN EXIT SELECT
				IF (line = cursorLine) THEN
					IF (pos >= cursorPos) THEN EXIT SELECT
				END IF
				GOTO matchInText
			END IF
	END SELECT
'
noMatch:
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	IF softInterrupt THEN
		Message ("[FindSearch( )]\n Interrupted ")
	ELSE
		backText$ = XstBinStringToBackStringNL$ (LEFT$(findText$, 512))
		Message ("[<FindSearch( )]\n No match found for: \n\n" + backText$)
	END IF
	freezeState = $$FALSE
	RETURN (-1)
'
matchInText:
	match = UBOUND (matches[])
	cursorLine = matches[match,0]
	cursorPos = matches[match,1]
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	IF ((cursorLine < topLine) || ((cursorLine - topLine) > rows-2)) THEN
		topLine = cursorLine - (rows/2)
		IF (topLine < 0) THEN topLine = 0
	END IF
'
	XstStringToStringArray (@findText$, @findText$[])
	uFindText = UBOUND(findText$[])
	IF uFindText THEN
		endPos = LEN(findText$[uFindText])
		endLine = cursorLine + uFindText
	ELSE
		endPos = cursorPos + LEN(findText$)
		endLine = cursorLine
	END IF
'
	XuiSendMessage (xitGrid, #SetTextCursor, endPos, cursorLine, 0, topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, cursorLine, -1, topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetTextSelection, cursorPos, cursorLine, endPos, endLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	IF (fileType = $$Program) THEN
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		funcCursorPosition[editFunction, 0] = cursorLine
		funcCursorPosition[editFunction, 1] = cursorPos
		funcCursorPosition[editFunction, 2] = topLine
		funcCursorPosition[editFunction, 3] = topIndent
	END IF
'
	freezeState = $$FALSE
	RETURN (cursorChar)
'
matchInProg:												' match, not in editFunction
	match = UBOUND (matches[])
	cursorLine = matches[match,0]
	cursorPos = matches[match,1]
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	redisplay = $$FALSE
	reportBogusRename = $$TRUE
	RestoreTextToProg (redisplay, reportBogusRename)			' out with the old...
	priorFunction = editFunction
	editFunction = funcNumber
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @progText$[])
	IF ((cursorLine < topLine) || ((cursorLine - topLine) > rows)) THEN
		topLine = cursorLine - (rows/2)
		IF (topLine < 0) THEN topLine = 0
	END IF
'
	XstStringToStringArray (@findText$, @findText$[])
	uFindText = UBOUND(findText$[])
	IF uFindText THEN
		endPos = LEN(findText$[uFindText])
		endLine = cursorLine + uFindText
	ELSE
		endPos = cursorPos+LEN(findText$)
		endLine = cursorLine
	END IF
'
	XuiSendMessage (xitGrid, #SetTextCursor, endPos, cursorLine, 0, topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, cursorLine, -1, topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetTextSelection, cursorPos, cursorLine, endPos, endLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
	funcCursorPosition[editFunction, 0] = cursorLine
	funcCursorPosition[editFunction, 1] = cursorPos
	funcCursorPosition[editFunction, 2] = topLine
	funcCursorPosition[editFunction, 3] = topIndent
	funcCursorPosition[editFunction, 4] = xCursor
	funcCursorPosition[editFunction, 5] = yCursor
'
	UpdateFileFuncLabels (0, $$TRUE)							' Reset function name
	freezeState = $$FALSE
	RETURN
END FUNCTION
'
'
' ##############################
' #####  ReplaceSearch ()  #####
' ##############################
'
'	Replace routine (based on SHARED parameters)
'
'	In:				none
'	Out:			none
'
'	Discussion:
'		Renaming functions is not allowed during replace (or manual mod for that
'			matter).  The function is converted to text and an unmonitored replace
'			is executed.  The text is retokenized, and if the function happened
'			to be renamed, the name is overwritten with the original name.
'			(Function renaming must be done with the ViewRename)
'		In PROGRAM mode, if the text is made NULL by the replace, it is filled
'			with the default FUNCTION...END FUNCTION code (as in View New Function).
'		If replaces restricted to editFunction, don't retokenize--this will
'			happen naturally as the environment is used.
'
'		If scanning across functions:
'			1)  editFunction 1st scan:  don't retokenize; wait till 2nd scan.
'			2)  each function:
'						progText$[] = deparsed function
'						apply replace to progText$[]
'						if changes
'								- If empty, replace with FUNCTION...END FUNCTION minimum.
'								- retokenize (overwrites rename, if any)
'								- ATTACH array back onto prog
'			3)  editFunction remaining half:
'						if any changes to editFunction,
'								- If empty, replace with FUNCTION...END FUNCTION minimum.
'								- retokenize (overwrites rename, if any)
'								- ATTACH array back onto prog
'
FUNCTION  ReplaceSearch ()
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	TOKEN   tempToken[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  xitGrid,  findReverse,  findReps
	SHARED  findText$,  replaceText$,  fileType
	SHARED  editFunction,  softInterrupt
	SHARED  findCase,  findLocal
	SHARED  findWord
	SHARED  programAltered,  textAlteredSinceSave
	SHARED  currentCursor
	SHARED	freezeState
'
	IF freezeState THEN RETURN				' not recursive - causes stack blowup
	entryCursor = currentCursor
	softInterrupt = $$FALSE
'
' Skip it if no text selected
'
	IFZ findText$ THEN
		Message ("[ReplaceSearch( )]\n No find string specified ")
		RETURN
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		message$ = "ReplaceSearch()\ncannot REPLACE while program executes"
		warningResponse = WarningResponse (@message$, @" terminate ", "")
		IF (warningResponse = $$WarningCancel) THEN RETURN
		XxxSetBlowback ()
		RETURN
	END IF
'
'
	reps = findReps
	IFZ reps THEN reps = 1
'
	IF findCase THEN
		mode = $$FindForward OR $$FindCaseSensitive
		IF findReverse THEN mode = $$FindReverse OR $$FindCaseSensitive
	ELSE
		mode = $$FindForward OR $$FindCaseInsensitive
		IF findReverse THEN mode = $$FindReverse OR $$FindCaseInsensitive
	END IF
	IF findWord THEN
		mode = mode OR $$FindWordSensitive
	ELSE
		mode = mode OR $$FindWordInsensitive
	END IF
'
	freezeState = $$TRUE											' can't start another replace
'
	lastFunctionFound = editFunction
	XuiSendMessage (xitGrid, #GrabTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, 0, @topLine, $$xitTextLower, 0)
	skip = $$FALSE																' reverse: skip if cursor at a match
	IF findReverse THEN skip = $$TRUE
	line = cursorLine
	pos = cursorPos
	ReplaceArray (mode, @text$[], @findText$, @replaceText$, @line, @pos, @reps, skip)
'
	IF (reps < findReps) THEN
		IFZ textAlteredSinceSave THEN
			textAlteredSinceSave = $$TRUE
			UpdateFileFuncLabels ($$TRUE, 0)
		END IF
		editFunctionChanged = $$TRUE
		IF (fileType = $$Program) THEN
			funcAltered[editFunction] = $$TRUE
			funcNeedsTokenizing[editFunction] = $$TRUE
		END IF
		lastEditLine = line
		lastEditPos = pos
		skip = $$TRUE					' xxx add 01/01/94
	END IF
'
	IF ((fileType = $$Text) OR findLocal OR (reps = 0)) THEN
		IFZ editFunctionChanged THEN
			XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			XuiSendMessage (xitGrid, #SetTextCursor, pos, line, 0, topLine, $$xitTextLower, 0)
			GOTO noMatch
		END IF
		IF (fileType = $$Text) THEN
			XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			XuiSendMessage (xitGrid, #SetTextCursor, pos, line, 0, topLine, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		ELSE
			IFZ TextHasNonWhites ($$TextArray, @text$[]) THEN			' fix empty
				DefaultFunctionText (funcNumber, @text$[])
				XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
				XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
			ELSE
				XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
				XuiSendMessage (xitGrid, #SetTextCursor, pos, line, 0, topLine, $$xitTextLower, 0)
			END IF
			XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
			funcCursorPosition[editFunction, 0] = cursorLine
			funcCursorPosition[editFunction, 1] = cursorPos
			funcCursorPosition[editFunction, 2] = topLine
			funcCursorPosition[editFunction, 3] = topIndent
			funcCursorPosition[editFunction, 4] = xCursor
			funcCursorPosition[editFunction, 5] = yCursor
		END IF
		IFZ textAlteredSinceSave THEN
			textAlteredSinceSave = $$TRUE
			UpdateFileFuncLabels ($$TRUE, 0)						' reset file name
		END IF
'
		XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
		freezeState = $$FALSE
		RETURN
	END IF
'
'	$$Program AND NOT findLocal AND more reps to go:
'
'	1)  editFunction 1st scan:  don't retokenize; wait till 2nd scan.
'
	renameAttempts = 0
'
'	2)  each function:
'				progText$ = deparsed function
'				apply replace to progText$
'				if changes
'						- If empty, replace with FUNCTION...END FUNCTION minimum.
'						- retokenize (overwrites rename, if any)
'						- ATTACH array back onto prog
'
	skip = $$FALSE												' reverse: skip if cursor at a match
	IF maxFuncNumber THEN									' Do global test of rest of PROGRAM
		i = 0
		funcNumber = editFunction
		DO
			IF findReverse THEN
				DEC funcNumber
				IF (funcNumber < 0) THEN funcNumber = maxFuncNumber
			ELSE
				INC funcNumber
				IF (funcNumber > maxFuncNumber) THEN funcNumber = 0
			END IF
			IF (funcNumber = editFunction) THEN EXIT DO	' Stop before editFunction
			IFZ prog[funcNumber,] THEN DO DO
'
			SetCurrentStatus ($$StatusSearching, i)					' Clears queue
			TokenArrayToText (funcNumber, @progText$[])
			IF softInterrupt THEN
				IF (reps = findReps) THEN GOTO noMatch				' Nothing changed, put text$[] back in TextArea
				GOTO replaceProg
			END IF
'
			line = 0 : pos = 0
			IF findReverse THEN
				line = UBOUND(progText$[])
				pos = LEN(progText$[line])
			END IF
			startReps = reps
			ReplaceArray (mode, @progText$[], @findText$, @replaceText$, @line, @pos, @reps, skip)
			IFZ reps THEN
				lastFunctionFound = funcNumber
				GOTO replaceProg
			END IF
'
			IF (reps < startReps) THEN									' Tokenize: don't allow rename (freeze)
				lastFunctionFound = funcNumber
				IFZ TextHasNonWhites ($$TextArray, @progText$[]) THEN		' fix empty
					DefaultFunctionText (funcNumber, @progText$[])
				END IF
				freeze = $$TRUE
				bogusFunction = TextToTokenArray (@progText$[], @func[], funcNumber, freeze)
				ATTACH prog[funcNumber,] TO tempToken[]				' Waste old array
				DIM tempToken[]
				ATTACH func[] TO prog[funcNumber,]
				funcAltered[funcNumber] = $$TRUE
				funcNeedsTokenizing[funcNumber] = $$FALSE
'
				funcCursorPosition[funcNumber, 0] = line	' reset cursorChar / topChar
				funcCursorPosition[funcNumber, 1] = pos
				funcCursorPosition[funcNumber, 2] = -1
				funcCursorPosition[funcNumber, 3] = 0
				funcCursorPosition[funcNumber, 4] = 0
				funcCursorPosition[funcNumber, 5] = -1
'				PRINT "rx0", cursorLine, cursorPos, line, pos
				IFZ funcNumber THEN prologAltered = $$TRUE
				IF bogusFunction THEN INC renameAttempts	' rename attempt squashed
				skip = $$TRUE					' xxx add 01/01/94
			END IF
			INC i
		LOOP
	END IF
'
'	Now check other half of editFunction
'		3)  editFunction 2nd scan:
'					if any changes to editFunction,
'							- If empty, replace with FUNCTION...END FUNCTION minimum.
'							- retokenize (overwrites rename, if any)
'							- ATTACH array back onto prog
'
'	PRINT "rx1", cursorLine; cursorPos; line; pos
	SELECT CASE TRUE
		CASE findReverse
			IF (cursorLine = uText) THEN											' already tested entire text?
				IF (cursorPos >= LEN(text$[cursorLine])) THEN EXIT SELECT
			END IF
'
'			Create end half array
'
			uText = UBOUND(text$[])
			IF ((cursorLine = 0) AND (cursorPos <= 0)) THEN
				entireText = $$TRUE
				SWAP text$[], endText$[]
				uEndText = uText
			ELSE
				entireText = $$FALSE
				uEndText = uText - cursorLine
				DIM endText$[uEndText]
				endText$[0] = MID$(text$[cursorLine], cursorPos + 1)
				IF uEndText THEN
					endText = 1
					FOR i = cursorLine + 1 TO uText
						ATTACH text$[i] TO endText$[endText]
						INC endText
					NEXT i
				END IF
			END IF
			line = uEndText
			pos = LEN(endText$[uEndText])
			startReps = reps
			ReplaceArray (mode, @endText$[], @findText$, @replaceText$, @line, @pos, @reps, skip)
			IF (reps < startReps) THEN
				lastFunctionFound = editFunction
				editFunctionChanged = $$TRUE
				funcAltered[editFunction] = $$TRUE
				funcNeedsTokenizing[editFunction] = $$TRUE
				lastEditLine = line
				lastEditPos = pos
				skip = $$TRUE						' xxx add 01/01/94
			END IF
'
'			Merge remaining text
'
			IF entireText THEN
				SWAP endText$[], text$[]
			ELSE
				IFZ endText$[] THEN
					REDIM text$[cursorLine]
					text$[cursorLine] = LEFT$(text$[cursorLine], cursorPos)
				ELSE
					uEndText = UBOUND (endText$[])
					uNewText = cursorLine + uEndText
					REDIM text$[uNewText]
					text$[cursorLine] = LEFT$(text$[cursorLine], cursorPos) + endText$[0]
					IF uEndText THEN
						FOR i = 1 TO uEndText
							ATTACH endText$[i] TO text$[cursorLine + i]
						NEXT i
					END IF
				END IF
			END IF
			IFZ reps THEN GOTO replaceText
		CASE ELSE
			IFZ cursorLine THEN											' already tested entire text
				IFZ cursorPos THEN EXIT SELECT
			END IF
'
'			Create beg half array
'
			uText = UBOUND(text$[])
			IF ((cursorLine = uText) AND (cursorPos >= LEN(text$[uText]))) THEN
				entireText = $$TRUE
				SWAP text$[], begText$[]
			ELSE
				entireText = $$FALSE
				DIM begText$[cursorLine]
				IF cursorLine THEN
					FOR i = 0 TO cursorLine - 1
						ATTACH text$[i] TO begText$[i]
					NEXT i
				END IF
				begText$[cursorLine] = LEFT$(text$[cursorLine], cursorPos)
			END IF
			line = 0
			pos = 0
			startReps = reps
			ReplaceArray (mode, @begText$[], @findText$, @replaceText$, @line, @pos, @reps, skip)
			IF (reps < startReps) THEN
				lastFunctionFound = editFunction
				editFunctionChanged = $$TRUE
				funcAltered[editFunction] = $$TRUE
				funcNeedsTokenizing[editFunction] = $$TRUE
				lastEditLine = line
				lastEditPos = pos
				skip = $$TRUE								' xxx add 01/01/94
			END IF
'
'			Merge remaining text
'
			IF entireText THEN
				SWAP begText$[], text$[]
			ELSE
				IFZ begText$[] THEN
					uNewText = uText - cursorLine
					DIM begText$[uNewText]
					uBegText = 0
				ELSE
					uBegText = UBOUND (begText$[])
					uNewText = uBegText + (uText - cursorLine)
					REDIM begText$[uNewText]
				END IF
				begText$[uBegText] = begText$[uBegText] + MID$(text$[cursorLine], cursorPos + 1)
				IF (uText > cursorLine) THEN
					begText = uBegText + 1
					FOR i = cursorLine + 1 TO uText
						ATTACH text$[i] TO begText$[begText]
						INC begText
					NEXT i
				END IF
				SWAP begText$[], text$[]
			END IF
			IFZ reps THEN GOTO replaceText
	END SELECT
	IF (reps = findReps) THEN GOTO noMatch
	GOTO replaceText
'
'
'
replaceProg:																							' funcNumber has been changed
	IFZ TextHasNonWhites ($$TextArray, @progText$[]) THEN		' fix empty
		DefaultFunctionText (funcNumber, @progText$[])
		line = 0
		pos = 0
	END IF
	freeze = $$TRUE
	bogusFunction = TextToTokenArray (@progText$[], @func[], funcNumber, freeze)
	ATTACH prog[funcNumber,] TO tempToken[]			' Waste old array
	DIM tempToken[]
	ATTACH func[] TO prog[funcNumber,]
	funcAltered[funcNumber] = $$TRUE
	funcNeedsTokenizing[funcNumber] = $$FALSE
	IFZ funcNumber THEN prologAltered = $$TRUE
	IF bogusFunction THEN INC renameAttempts					' rename attempt squashed
'
'
'
replaceText:
	IF (lastFunctionFound = editFunction) THEN
		XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, pos, line, 0, topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
		funcCursorPosition[editFunction, 0] = cursorLine
		funcCursorPosition[editFunction, 1] = cursorPos
		funcCursorPosition[editFunction, 2] = topLine
		funcCursorPosition[editFunction, 3] = topIndent
		funcCursorPosition[editFunction, 4] = xCursor
		funcCursorPosition[editFunction, 5] = yCursor
	ELSE
		IFZ editFunctionChanged THEN						' handle editFunction before moving on
			XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			XuiSendMessage (xitGrid, #SetTextCursor, pos, line, 0, 0, $$xitTextLower, 0)
		ELSE
			IFZ TextHasNonWhites($$TextArray, @text$[]) THEN
				DefaultFunctionText (editFunction, @text$[])
			END IF
			XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			XuiSendMessage (xitGrid, #SetTextCursor, pos, line, 0, 0, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
			funcCursorPosition[editFunction, 0] = cursorLine
			funcCursorPosition[editFunction, 1] = cursorPos
			funcCursorPosition[editFunction, 2] = topLine
			funcCursorPosition[editFunction, 3] = topIndent
			funcCursorPosition[editFunction, 4] = xCursor
			funcCursorPosition[editFunction, 5] = yCursor
			IFZ editFunction THEN prologAltered = $$TRUE
			line = cursorLine
			pos = cursorPos
		END IF
		funcCursorPosition[lastFunctionFound, 0] = line
		funcCursorPosition[lastFunctionFound, 1] = pos
		funcCursorPosition[lastFunctionFound, 2] = -1
		funcCursorPosition[lastFunctionFound, 3] = -1
		funcCursorPosition[lastFunctionFound, 4] = -1
		funcCursorPosition[lastFunctionFound, 5] = -1
		Display (lastFunctionFound, -1, -1, -1, -1)
	END IF
'
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
'
	IFZ textAlteredSinceSave THEN
		textAlteredSinceSave = $$TRUE
		UpdateFileFuncLabels ($$TRUE, 0)						' reset file name
	END IF
'
	IF (fileType = $$Program) THEN
		IFZ programAltered THEN
			programAltered = $$TRUE
			AddDispatch (&ResetDataDisplays(), $$ResetAssembly)
		END IF
	END IF
'
	IF renameAttempts THEN
		m0$ = " ReplaceSearch() : replace cannot rename functions : ("
		IF (renameAttempts = 1) THEN
			m0$ = m0$ + "1 voided attempt)"
		ELSE
			m0$ = m0$ + STRING(renameAttempts) + " voided attempts)"
		END IF
		IF prologAltered THEN
			m0$ = m0$ + " \n\n !!! function names in PROLOG may have been altered !!! "
		END IF
		Message (@m0$)
	END IF
	freezeState = $$FALSE
	RETURN
'
'
'
noMatch:
	IF text$[]
		XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, pos, line, 0, topLine, $$xitTextLower, 0)
	END IF
	IF softInterrupt THEN
		Message ("[ReplaceSearch( )]\n Interrupted")
	ELSE
		backText$ = XstBinStringToBackStringNL$ (LEFT$(findText$, 512))
		Message ("[<ReplaceSearch( )]\n No match found for \n\n" + backText$)
	END IF
	freezeState = $$FALSE
	RETURN
END FUNCTION
'
'
' #########################
' #####  EditRead ()  #####
' #########################
'
'	Read a disk file and put its contents into clipboard
'
FUNCTION  EditRead (skipUpdate)
	SHARED  readBox,  readFile$
	UBYTE null[]
'
	XuiSendMessage (readBox, #GetTextString, 0, 0, 0, 0, 0, @file$)
	lenName = LEN (file$)
	XuiSendMessage (readBox, #SetTextCursor, 0, 0, 0, 0, $$FileTextLine, 0)
	XuiSendMessage (readBox, #SetTextCursor, lenName, 0, 0, 0, $$FileTextLine, 0)
'
	XstGuessFilename (@readFile$, @file$, @fileName$, @attributes)
	IF (attributes AND $$FileDirectory) THEN skipUpdate = $$FALSE
	IFZ attributes THEN skipUpdate = $$FALSE
'
	IF skipUpdate THEN
		XstGetFileAttributes (@fileName$, @attributes)
		IFZ attributes THEN skipUpdate = $$FALSE
	END IF
'
	length = LEN(fileName$)
	XuiSendMessage (readBox, #SetTextString, 0, 0, 0, 0, 0, @fileName$)
	XuiSendMessage (readBox, #SetTextCursor, 0, 0, 0, 0, $$FileTextLine, 0)
	XuiSendMessage (readBox, #SetTextCursor, length, 0, 0, 0, $$FileTextLine, 0)
'
	IFZ skipUpdate THEN
		XuiSendMessage (readBox, #Update, 0, 0, 0, 0, 0, 0)
		XuiSendMessage (readBox, #SetKeyboardFocus, 0, 0, 0, 0, $$FileTextLine, 0)
		XuiSendMessage (readBox, #GetModalInfo, @v0, 0, 0, 0, 0, 0)
'
		SELECT CASE v0
			CASE -1			:	RETURN									' KeyEscape or Cancel
			CASE 2,6,7	:	' text/file, OK button
			CASE ELSE		:	PRINT "EditRead() : unknown response ="; v0
										RETURN
		END SELECT
		XuiSendMessage (readBox, #GetTextString, 0, 0, 0, 0, 0, @fileName$)
	END IF
'
	IFZ fileName$ THEN
		Message ("[EditRead( )]\n No file name specified ")
		RETURN
	END IF
'
	XstGetFileAttributes (@fileName$, @attributes)
	SELECT CASE TRUE
		CASE (attributes = 0)
					Message ("[EditRead( )]\n Cannot find file \n\n " + fileName$ + " ")
					RETURN
		CASE (attributes AND $$FileDirectory)
					Message ("[EditRead( )]\n Invalid file type \n\n " + fileName$ + " ")
					RETURN
	END SELECT
'
	DIM null[]
	XstLoadString (@fileName$, @text$)
	XgrSetClipboard (0, $$ClipboardTypeText, @text$, @null[])
END FUNCTION
'
'
' ##########################
' #####  EditWrite ()  #####
' ##########################
'
'	Write the contents of the interapplication clipboard into a disk file.
'
FUNCTION  EditWrite (skipUpdate, bufferNumber)
	SHARED  writeBox,  writeFile$
	UBYTE null[]
'
	XuiSendMessage (writeBox, #GetTextString, 0, 0, 0, 0, 0, @file$)
	lenName = LEN (file$)
	XuiSendMessage (writeBox, #SetTextCursor, 0, 0, 0, 0, $$FileTextLine, 0)
	XuiSendMessage (writeBox, #SetTextCursor, lenName, 0, 0, 0, $$FileTextLine, 0)
'
	XstGuessFilename (@writeFile$, @file$, @fileName$, @attributes)
	IF (attributes AND $$FileDirectory) THEN skipUpdate = $$FALSE
	IFZ fileName$ THEN skipUpdate = $$FALSE
'
	length = LEN(fileName$)
	XuiSendMessage (writeBox, #SetTextString, 0, 0, 0, 0, 0, @fileName$)
	XuiSendMessage (writeBox, #SetTextCursor, 0, 0, 0, 0, $$FileTextLine, 0)
	XuiSendMessage (writeBox, #SetTextCursor, length, 0, 0, 0, $$FileTextLine, 0)
'
	IFZ skipUpdate THEN
		XuiSendMessage (writeBox, #Update, 0, 0, 0, 0, 0, 0)
		XuiSendMessage (writeBox, #SetKeyboardFocus, 0, 0, 0, 0, $$FileTextLine, 0)
		XuiSendMessage (writeBox, #GetModalInfo, @v0, 0, 0, 0, 0, 0)
'
		SELECT CASE v0
			CASE -1			:	RETURN									' KeyEscape or Cancel
			CASE 2,6,7	:	' text/file, OK button
			CASE ELSE		:	PRINT "EditWrite() : unknown response ="; v0
										RETURN
		END SELECT
		XuiSendMessage (writeBox, #GetTextString, 0, 0, 0, 0, 0, @fileName$)
	END IF
'
	IFZ fileName$ THEN
		Message ("[EditWrite( )]\n No file name specified ")
		RETURN
	END IF
'
	XstGetFileAttributes (@fileName$, @attributes)
	SELECT CASE TRUE
		CASE (attributes AND $$FileDirectory)
					Message ("[EditWrite( )]\n Invalid file type \n\n directory \n\n " + fileName$ + " ")
					RETURN
	END SELECT

	SELECT CASE bufferNumber
		CASE 0, 1      : GOSUB SaveClipboard
		CASE ##CONGRID : GOSUB SaveConsole
		CASE ELSE      : PRINT "EditWrite(56):Invalid buffer number", bufferNumber
	END SELECT
'
RETURN
'
'
' *****  SaveClipboard  *****
'
SUB SaveClipboard
	DIM null[]
	XgrGetClipboard (bufferNumber, $$ClipboardTypeText, @text$, @null[])
	XstSaveString (@fileName$, @text$)
END SUB
'
'
' *****  SaveConsole  *****
'
SUB SaveConsole
	XuiSendMessage (##CONGRID, #GrabTextArray, 0, 0, 0, 0, 0, @text$[])
	error = XstSaveStringArray (fileName$, @text$[])
	XuiSendMessage (##CONGRID, #PokeTextArray, 0, 0, 0, 0, 0, @text$[])
	IF error THEN
		error$ = ERROR$(ERROR(-1))
		Message ("[EditWrite( )]\n Failed to write to file \n " + error$)
	END IF
'	PRINT "EditWrite(81):SaveConsole()", error, bufferNumber, fileName$
END SUB
'
END FUNCTION
'
'
' ############################
' #####  EditAbandon ()  #####
' ############################
'
'	Restore text from editFunction tokens.  PROGRAM mode to erase latest edits.
'
'	In:				none
'	Out:			none
'	Return:		none
'
FUNCTION  EditAbandon ()
	SHARED  abandonBox,  editFunction,  fileType
	SHARED  funcBPAltered[],  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  xitGrid
'
	IF (fileType != $$Program) THEN
		Message ("[EditAbandon( )]\n No program loaded ")
		RETURN
	END IF
'
	DIM text$[2]
	IFZ funcNeedsTokenizing[editFunction] THEN
		text$[1] = " text has not been altered "
		text$[2] = " ok "
	ELSE
		text$[1] = " abandon latest edits: "
		text$[2] = " abandon "
	END IF
	XuiSendMessage (abandonBox, #SetTextStrings, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage (abandonBox, #Resize, 0, 0, 0, 0, 0, 0)
	response = 0
	XuiSendMessage (abandonBox, #GetModalInfo, @v0, 0, 0, 0, @response, 0)
	SELECT CASE response
		CASE 0		:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
		CASE 2		:	' OK button
		CASE 3		:	RETURN
		CASE ELSE	:	PRINT "EditAbandon() : unknown response ="; response
								RETURN
	END SELECT
'
	TokenArrayToText (editFunction, @text$[])
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	funcCursorPosition[editFunction, 0] = 0					' Reset cursorChar / topChar
	funcCursorPosition[editFunction, 1] = 0
	funcCursorPosition[editFunction, 2] = 0
	funcCursorPosition[editFunction, 3] = 0
	funcCursorPosition[editFunction, 4] = 0
	funcCursorPosition[editFunction, 5] = 0
	funcBPAltered[editFunction] = $$FALSE
	funcNeedsTokenizing[editFunction] = $$FALSE
'
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
END FUNCTION
'
'
' ################################
' #####  EditCleanBackup ()  #####
' ################################
'
FUNCTION  EditCleanBackup (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	SHARED  cleanBox
	SHARED  editFile$
	SHARED  xitTextLower
	SHARED  xitWindow
	SHARED  xbasicBackupDir$
	FILEINFO fileInfo[]
'
	$label		= 1
	$text			= 2
	$button0	= 3
	$button1	= 4
	$button2	= 5
'
	IFZ cleanBox THEN RETURN
	IF (grid != cleanBox) THEN
		PRINT "EditCleanBackup()Invalid grid", grid
		RETURN
	END IF
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
		CASE ELSE           : PRINT "EditCleanBackup()Invalid message", message, message$
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (cleanBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  Selection  *****  r0 = 2345 = List/Text/Button01
'
SUB Selection
	IFZ xbasicBackupDir$ THEN RETURN
	SELECT CASE r0
		CASE $text
					IF (v0{$$VirtualKey} = $$KeyEscape) THEN
						XuiSendMessage (cleanBox, #HideWindow, 0, 0, 0, 0, 0, 0)
						EXIT SUB
					END IF
					GOSUB DeleteFiles
		CASE $button0             ' current filename
					deletAll = $$FALSE
					GOSUB DeleteFiles
		CASE $button1             ' all filenames
					deletAll = $$TRUE
					GOSUB DeleteFiles
		CASE $button2
					XuiSendMessage (cleanBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****
'
SUB DisplayWindow
'
	IFZ xbasicBackupDir$ THEN
		XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/misc.hlp:Edit -> Load Backup")
		RETURN
	END IF
'
	XgrGetWindowPositionAndSize (xitWindow, @xXit, @yXit, @wXit, @hXit)
	XgrGetGridPositionAndSize (xitTextLower, @xLower, @yLower, @wLower, @hLower)
'
	XuiSendMessage (cleanBox, #GetSmallestSize, 0, 0, @width, @height, 0, minWH)
	hLower = hLower - #windowTitleHeight - #windowBorderWidth
	IF (height > hLower) THEN height = hLower
	x = xXit + 100
	y = yXit + yLower +#windowTitleHeight + (#windowBorderWidth * 2)
	XuiSendMessage (cleanBox, #ResizeWindow, x, y, width, height, 0, 0)
	XuiSendMessage (cleanBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
END SUB
'
'
' *****  DeleteFiles  *****
'
SUB DeleteFiles
'	IF ##XBDV THEN PRINT "EditCleanBackup()DeleteFiles", deletAll
	XuiSendMessage (cleanBox, #GetTextString, 0, 0, 0, 0, $text, @text$)
	text$ = TRIM$(text$)
	IFZ text$ THEN
		Message ("[EditCleanBackup( )]\n No value entered \n for number of hours ")
		EXIT SUB
	END IF
'
	value$ = ""
	FOR i = 0 TO UBOUND(text$)
		char = text${i}
		IF ((char < '0') || (char > '9')) THEN
			Message ("[EditCleanBackup( )]\n Invalid character \n in hours number ")
			EXIT SUB
		END IF
'
		value$ = value$ + CHR$(char)
	NEXT i
	backHours = XLONG(value$)
'	IF ##XBDV THEN PRINT "EditCleanBackup()DeleteFiles", text$, backHours
'
	GOSUB GetFiles
	IFZ backupList$[] THEN
		Message ("[EditCleanBackup( )]\n\n no files found \n")
		XuiSendMessage (cleanBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		EXIT SUB
	END IF
'
	GOSUB GetTime
'
	uBackups = UBOUND(backupList$[])
	lenLimit = LEN(deleteTime$)
	FOR i = 0 TO uBackups
		fileName$ = backupList$[i]
		fileTime$ = RIGHT$(fileName$, lenLimit)
		IF (fileTime$ < deleteTime$) THEN
			attributes = fileInfo[i].attributes
			IF (attributes AND $$FileReadOnly) THEN DO NEXT
			INC deletedFiles
			fileName$ = xbasicBackupDir$ + fileName$
'			IF ##XBDV THEN PRINT "Delete file : ", fileName$
			error = XstDeleteFile (fileName$)
			IF error THEN
				PRINT "Delete file error : ", fileName$, ERROR$(ERROR(0))
			END IF
		ELSE
			INC keptFiles
'			IF ##XBDV THEN PRINT "Keep file : ", fileName$
		END IF
	NEXT i
'
	message$ = "[EditCleanBackup( )]"
	message$ = message$ + "\nTotal files deleted = " + STR$(deletedFiles)
	message$ = message$ + "\nTotal files retained = " + STR$(keptFiles)
	Message (message$)
	XuiSendMessage (cleanBox, #HideWindow, 0, 0, 0, 0, 0, 0)
'
END SUB
'
'
'	*****  GetFiles  *****
'
SUB GetFiles
	XstGetEnvironmentVariable ("XBASICBACKUPDIR64", @xbasicBackupDir$)
	IFZ xbasicBackupDir$ THEN RETURN
	XstPathToAbsolutePath (xbasicBackupDir$, @absolutepath$)
	IF (xbasicBackupDir$ != absolutepath$) THEN
		IFZ messageDisplayed THEN
			error$ = "[XBASICBACKUPDIR64]\n"
			error$ = error$ + "\nEnvironment variable\nXBASICBACKUPDIR64 \n"
			error$ = error$ + "must be a full absolute path name:\n"
			error$ = error$ + xbasicBackupDir$
			PRINT error$
			messageDisplayed = $$TRUE
		END IF
		xbasicBackupDir$ = ""
		RETURN
	END IF
	XstGetFileAttributes (xbasicBackupDir$, @attributes)
	IFZ (attributes AND $$FileDirectory) THEN
		IFZ messageDisplayed THEN
			error$ = "[XBASICBACKUPDIR64]\n"
			error$ = error$ + "\nEnvironment variable\nXBASICBACKUPDIR64 \n"
			error$ = error$ + "is not a valid directory:\n"
			error$ = error$ + xbasicBackupDir$ + HEXX$(attributes)
			PRINT error$
			messageDisplayed = $$TRUE
		END IF
		xbasicBackupDir$ = ""
		RETURN
	END IF
	lastChar$ = RIGHT$(xbasicBackupDir$)
	IF lastChar$ THEN
		IF (lastChar$ != $$PathSlash$) THEN xbasicBackupDir$ = xbasicBackupDir$ + $$PathSlash$
	END IF
'
'	filter$ = "*_??????_??????.bak"
'	XstFindFiles (xbasicBackupDir$, filter$, $$FALSE, @backupList$[])
'
' When deletAll is TRUE get list of all backup files for all filenames.
' When deletAll is FALSE get list backup files only for the current filename.
'
	IF deletAll THEN
		filter$ = xbasicBackupDir$ + "*_??????_??????.bak"
	ELSE
		XstGetPathComponents (editFile$, @path$, @drive$, @dir$, @editFilename$, @attributes)
'		IF ##XBDV THEN PRINT editFilename$
		filter$ = xbasicBackupDir$ + "*" + editFilename$ + "_??????_??????.bak"
	END IF
	filter = $$FileNormal
	maxLen = XstGetFilesAndAttributes (filter$, filter, @backupList$[], @fileInfo[])
'
'	IF ##XBDV THEN PRINT "EditCleanBackup()GetFiles", UBOUND(backupList$[]), filter$
END SUB
'
'
' *****  GetTime  *****
'
SUB GetTime
	day$$ = 864000000000
	hour$$ = 36000000000
	backHours$$ = backHours
	backDays$$  = backDays
	diff$$ = (backHours * hour$$) + (backDays * day$$)
	XstGetLocalDateAndTime (@year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
	XstDateAndTimeToFileTime (year, month, day, weekDay, hour, minute, second, nanos, @filetime$$)
	filetime$$ = filetime$$ - diff$$
	XstFileTimeToDateAndTime (filetime$$, @year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
'
	date$ = "_"   + FORMAT$("0#", year MOD 100)
	date$ = date$ + FORMAT$("0#", month)
	date$ = date$ + FORMAT$("0#", day)
	time$ = "_"   + FORMAT$("0#", hour)
	time$ = time$ + FORMAT$("0#", minute)
	time$ = time$ + FORMAT$("0#", second)
	deleteTime$ = date$ + time$ + ".bak"
END SUB
'
END FUNCTION
'
'
' ###############################
' #####  EditLoadBackup ()  #####
' ###############################
'
FUNCTION  EditLoadBackup (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	SHARED  backupBox
	SHARED  xitTextLower
	SHARED  xitWindow
	SHARED  editFile$
	SHARED  xbasicBackupDir$
	STATIC  backupFile$
	FILEINFO attrInfo[]
'
	$label		= 1
	$list			= 2
	$text			= 3
	$button0	= 4
	$button1	= 5
'
	IFZ backupBox THEN RETURN
	IF (grid != backupBox) THEN
		PRINT "EditLoadBackup()Invalid grid", grid
		RETURN
	END IF
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
		CASE ELSE           : PRINT "EditLoadBackup()Invalid message", message, message$
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (backupBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  Selection  *****  r0 = 2345 = List/Text/Button01
'
SUB Selection
	IFZ xbasicBackupDir$ THEN RETURN
	SELECT CASE r0
		CASE $list
					IF (v0 < 0) THEN
						XuiSendMessage (backupBox, #HideWindow, 0, 0, 0, 0, 0, 0)
						EXIT SUB
					END IF
					GOSUB LoadFromList
		CASE $text
					IF (v0{$$VirtualKey} = $$KeyEscape) THEN
						XuiSendMessage (backupBox, #HideWindow, 0, 0, 0, 0, 0, 0)
						EXIT SUB
					END IF
					GOSUB LoadFromList
		CASE $button0
					GOSUB LoadFromList
		CASE $button1
					XuiSendMessage (backupBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****
'
SUB DisplayWindow
'
	IFZ xbasicBackupDir$ THEN
		XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/help/misc.hlp:Edit -> Load Backup")
		RETURN
	END IF
	GOSUB FindBackupFiles
'
	uList = UBOUND(backupList$[])
	lDir = LEN(xbasicBackupDir$)
	FOR i = 0 TO uList
		s$ = backupList$[i]
		IF (LEFT$(s$, lDir) == xbasicBackupDir$) THEN
			s$ = LCLIP$(s$, lDir)
		END IF
		uColumn = UBOUND(s$)
		IF (uColumn > maxColumn) THEN maxColumn = uColumn
		backupList$[i] = s$
	NEXT i
	XstQuickSort (@backupList$[], @orderArray[], 0, uList, $$SortIncreasing)
'
	INC maxColumn
	INC uList
'
	XgrGetWindowPositionAndSize (xitWindow, @xXit, @yXit, @wXit, @hXit)
	XgrGetGridPositionAndSize (xitTextLower, @xLower, @yLower, @wLower, @hLower)
'
	XuiSendMessage (backupBox, #PokeTextArray, 0, 0, 0, 0, $list, @backupList$[])
	XuiSendMessage (backupBox, #GetSmallestSize, maxColumn, uList, @width, @height, 0, minWH)
	hLower = hLower - #windowTitleHeight - #windowBorderWidth
	IF (height > hLower) THEN height = hLower
	x = xXit + 100
	y = yXit + yLower + #windowTitleHeight + #windowBorderWidth
	IF (LEFT$(backupFile$, LEN(progName$)) != progName$) THEN
		backupFile$ = ""
		XuiSendMessage (backupBox, #SetTextCursor, 0, uList, -1, -1, $list, 0)
	END IF
	XuiSendMessage (backupBox, #SetTextString, 0, 0, 0, 0, $text, @backupFile$)
	XuiSendMessage (backupBox, #ResizeWindow, x, y, width, height, 0, 0)
	XuiSendMessage (backupBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
END SUB
'
'
' *****  LoadFromList  *****
'
SUB LoadFromList
	XuiSendMessage (backupBox, #GrabTextArray, 0, 0, 0, 0, $list, @name$[])
	XuiSendMessage (backupBox, #GetTextCursor, @cursorPos, @cursorLine, @topPos, @topLine, $list, 0)
	IF ((cursorLine < 0) OR (cursorLine > UBOUND(name$[]))) THEN
		XuiSendMessage (backupBox, #PokeTextArray, 0, 0, 0, 0, $list, @name$[])
		Message ("[EditLoadBackup( )]\n No file selected ")
		RETURN
	END IF
	backupFile$ = name$[cursorLine]
	XuiSendMessage (backupBox, #PokeTextArray, 0, 0, 0, 0, $list, @name$[])
	GOSUB LoadFile
	XuiSendMessage (backupBox, #HideWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  LoadFile  *****  backupFile$
'
SUB LoadFile
'
	XstGuessFilename (@editFile$, @file$, @fileName$, @attributes)
	XstGetPathComponents (fileName$, @path$, @drive$, @dir$, @progName$, @attributes)
	lProg = LEN(progName$)
	IF (LEFT$(backupFile$, lProg) != progName$) THEN
		PRINT "EditLoadBackup()LoadFile : file name mismatch", lProg, progName$, backupFile$
		EXIT SUB
	END IF
'
	backupFileName$ = xbasicBackupDir$ + backupFile$
	XstCopyFile (backupFileName$, editFile$)
	PRINT "Restored from Backup file : ", backupFile$
	FileListFuncSet ()
	FileRecentLoad (0)
END SUB
'
'
' *****  FindBackupFiles  *****
'
SUB FindBackupFiles
'
	XstGuessFilename (@editFile$, @file$, @fileName$, @attributes)
	XstGetPathComponents (fileName$, @path$, @drive$, @dir$, @progName$, @attributes)
	backup$ = xbasicBackupDir$ + progName$
	filter$ = progName$ + "*"
	XstFindFiles (xbasicBackupDir$, filter$, $$FALSE, @backupList$[])
'
END SUB
'
END FUNCTION
'
'
' #########################
' #####  ViewFunc ()  #####
' #########################
'
'	Set the function list and manage the View Function Box
'
FUNCTION  ViewFunc (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  editFunction
	SHARED  fileType
	SHARED  TOKEN prog[]
	SHARED  xitGrid
'
	$label		= 1
	$list			= 2
	$text			= 3
	$button0	= 4
	$button1	= 5
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow		' Direct
		CASE #View					: GOSUB View						' Direct
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****  'grid' unused : r1$ = default function name
'
SUB DisplayWindow
	IF (fileType != $$Program) THEN
		Message ("[ViewFunction( )]\n No program loaded ")
		RETURN
	END IF
'
	items = SortFunctionNames (@name$[], $$TRUE)					' include PROLOG
	IFZ r1$ THEN XxxFunctionName ($$XGET, @r1$, editFunction)
	viewLine = 0
	FOR i = 0 TO items - 1
		IF (r1$ = name$[i]) THEN
			viewLine = i
			EXIT FOR
		END IF
	NEXT i
	XuiSendMessage (grid, #SetTextArray, 0, viewLine, 0, 0, $list, @name$[])
	XuiSendMessage (grid, #GetTextCursor, 0, 0, 0, 0, $list, @rows)
	XuiSendMessage (grid, #SetTextCursor, 0, viewLine, 0, viewLine-(rows\2), $list, 0)
	XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, 1, 0)
END SUB
'
'
' *****  Selection  *****  r0 = 2345 = List/Text/Button01
'
SUB Selection
	SELECT CASE r0
		CASE $list
					IF (v0 < 0) THEN
						XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
						EXIT SUB
					END IF
					GOSUB ViewListFunction
		CASE $text
					IF (v0{$$VirtualKey} = $$KeyEscape) THEN
						XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
						EXIT SUB
					END IF
					GOSUB ViewListFunction
		CASE $button0
					GOSUB ViewListFunction
		CASE $button1
					XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
' *****  View  *****
'
SUB View
	func$ = r1$
	GOSUB ViewFunction
END SUB
'
' *****  ViewListFunction  *****
'
SUB ViewListFunction
	XuiSendMessage (grid, #GrabTextArray, 0, 0, 0, 0, $list, @name$[])
	XuiSendMessage (grid, #GetTextCursor, @viewPos, @viewLine, @topPos, @topLine, $list, 0)
	IF ((viewLine < 0) OR (viewLine > UBOUND(name$[]))) THEN
		XuiSendMessage (grid, #PokeTextArray, 0, 0, 0, 0, $list, @name$[])
		Message ("[ViewFunction( )]\n No function selected ")
		RETURN
	END IF
	func$ = name$[viewLine]
	XuiSendMessage (grid, #PokeTextArray, 0, 0, 0, 0, $list, @name$[])
	GOSUB ViewFunction
	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  ViewFunction  *****  func$
'
SUB ViewFunction
	XxxPassFunctionArrays ($$XGET, @funcSymbol$[], @funcToken[], @funcScope[])
'
'	Look for exact match
'
	funcNumber = editFunction + 1				' start looking forward
	endFunction = maxFuncNumber
	segment = 0
	DO UNTIL (segment > 1)
		DO UNTIL (funcNumber > endFunction)
			IF prog[funcNumber,] THEN
				IFZ funcNumber THEN
					funcName$ = "PROLOG"				' funcSymbol$[0] = "SYSTEMCALL"
				ELSE
					funcName$ = funcSymbol$[funcNumber]
				END IF
				IF (func$ = funcName$) THEN
					XxxPassFunctionArrays ($$XSET, @funcSymbol$[], @funcToken[], @funcScope[])
					IF (funcNumber == editFunction) THEN
						XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
						RETURN
					END IF
					Display (funcNumber, -1, -1, -1, -1)
					RETURN
				END IF
			END IF
			INC funcNumber
		LOOP
		funcNumber = 0
		endFunction = editFunction				' finish with front segment
		INC segment
	LOOP
'
'	Look for closest match
'
	lenFunc = LEN(func$)
	funcNumber = editFunction + 1				' start looking forward
	endFunction = maxFuncNumber
	segment = 0
	DO UNTIL (segment > 1)
		DO UNTIL (funcNumber > endFunction)
			IF prog[funcNumber,] THEN
				IFZ funcNumber THEN
					funcName$ = "PROLOG"				' funcSymbol$[0] = "SYSTEMCALL"
				ELSE
					funcName$ = funcSymbol$[funcNumber]
				END IF
'				test$ = LEFT$(funcName$, lenFunc)
'				IF (func$ = test$) THEN
				IF (func$ = LEFT$(funcName$, lenFunc)) THEN
					XxxPassFunctionArrays ($$XSET, @funcSymbol$[], @funcToken[], @funcScope[])
					Display (funcNumber, -1, -1, -1, -1)
					RETURN
				END IF
			END IF
			INC funcNumber
		LOOP
		funcNumber = 0
		endFunction = editFunction				' finish with front segment
		INC segment
	LOOP
	XxxPassFunctionArrays ($$XSET, @funcSymbol$[], @funcToken[], @funcScope[])
	Message ("[ViewFunction( )]\n No function name match for \n\n \"" + func$ + "\" ")
END SUB
END FUNCTION
'
'
' ##############################
' #####  ViewPriorFunc ()  #####
' ##############################
'
'	Display the prior function viewed
'
'	In:				none
'	Out:			none
'	Return:		none
'
FUNCTION  ViewPriorFunc ()
	SHARED  priorFunction,  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[ViewPriorFunction( )]\n No program loaded ")
		RETURN
	END IF
'
	Display (priorFunction, -1, -1, -1, -1)
END FUNCTION
'
'
' ############################
' #####  ViewNewFunc ()  #####
' ############################
'
'	Create and view a new function with name from View New Function box
'
'	Keeps current DECLARE in PROLOG if one exists.
'	Leaves duplicate declarations in PROLOG.
'
FUNCTION  ViewNewFunc (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	TOKEN   tok[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  uprog,  editFunction,  priorFunction
	SHARED  environmentActive
	SHARED  viewNewBox,  xitGrid,  fileType
'
	$label		= 1
	$textline	= 2
	$button0	= 3
	$button1	= 4
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
	END SELECT
	RETURN
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
' *****  DisplayWindow  *****  'grid' unused : r1$ = default function name
'
SUB DisplayWindow
	IF (fileType != $$Program) THEN
		Message ("[ViewNewFunction( )]\n No program loaded ")
		RETURN
	END IF
'
	XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, $textline, 0)
END SUB
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE r0
		CASE $textline
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
				EXIT SUB
			END IF
			GOSUB NewFunction
		CASE $button0
			GOSUB NewFunction
	END SELECT
'
	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
' ***** NewFunction *****
'
SUB NewFunction
	IF (fileType != $$Program) THEN
		Message ("[ViewNewFunction( )]\n No program loaded ")
		RETURN
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" new ", @"")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		XxxSetBlowback ()
		AddDispatch (&ViewNewFunc(), 0)
		RETURN
	END IF
'
	XuiSendMessage (viewNewBox, #GetTextString, 0, 0, 0, 0, $$DialogText, @func$)
	XuiSendMessage (viewNewBox, #SetTextString, 0, 0, 0, 0, $$DialogText, "")
	func$ = TRIM$(func$)
'
	IFZ func$ THEN
		Message ("[NewFunction( )]\n Received empty function name ")
		RETURN
	END IF
'
'	PRINT "ViewNewFunc(102)"
	cchar = func${0}
	IF ((cchar >= '0') AND (cchar <= '9')) THEN
		Message ("[NewFunction( )]\n Function name cannot begin with digit ")
		RETURN
	END IF
	lastChar = UBOUND(func$)
	FOR i = 0 TO lastChar
		cchar = func${i}
		IF ((cchar >= 'a') AND (cchar <= 'z')) THEN DO NEXT
		IF ((cchar >= 'A') AND (cchar <= 'Z')) THEN DO NEXT
		IF ((cchar >= '0') AND (cchar <= '9')) THEN DO NEXT
		IF (cchar = '_') THEN DO NEXT
		IF (cchar = '$') THEN									' only explicit type is STRING
			IF (i = lastChar) THEN EXIT FOR
		END IF
		Message ("[NewFunction( )]\n Function name contains invalid character ")
		RETURN
	NEXT i
'
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
'
'	PRINT "ViewNewFunc(124)"
	IF (func$ == "PROLOG") THEN
		Display (0, 0, 0, 0, 0)								' wise guy
		RETURN
	END IF
'
	token$ = func$ + " ("							' compiler assigns function number
'	PRINT "ViewNewFunc(131)"
	XxxParseSourceLine (@token$, @tok[])
'
	IFZ tok[] THEN RETURN
'
	IF (maxFuncNumber > uprog) THEN
		uprog = maxFuncNumber + (maxFuncNumber >> 2)
		REDIM prog[uprog,]
		REDIM funcAltered[uprog]
		REDIM funcBPAltered[uprog]
		REDIM funcNeedsTokenizing[uprog]
		REDIM funcCursorPosition[uprog, 5]
	END IF
	funcNumber = tok[1].tindex
'
	IF prog[funcNumber,] THEN
		Display (funcNumber, 0, 0, 0, 0)			' already exists; show it to user
		RETURN
	END IF
'
	redisplay = $$FALSE
	reportBogusRename = $$TRUE
	RestoreTextToProg (redisplay, reportBogusRename)
'
	XitGetDECLARE (@func$, @declare$)
	IFZ declare$ THEN
		declare$ = "DECLARE FUNCTION  " + func$ + " ()"
		XitSetDECLARE (@func$, @declare$)
	END IF
'
' add new function
'
	funcAltered[funcNumber] = $$TRUE
	funcBPAltered[funcNumber] = $$FALSE
	funcNeedsTokenizing[funcNumber] = $$FALSE
'
	funcCursorPosition[funcNumber, 0]	= 0				' zero cursorChar / topChar
	funcCursorPosition[funcNumber, 1]	= 0
	funcCursorPosition[funcNumber, 2]	= 0
	funcCursorPosition[funcNumber, 3]	= 0
	funcCursorPosition[funcNumber, 4]	= 0
	funcCursorPosition[funcNumber, 5]	= 0
'
	programAltered = $$TRUE
	DefaultFunctionText (funcNumber, @text$[])
	freeze = $$FALSE
'	PRINT "ViewNewFunc(177)"
	TextToTokenArray (@text$[], @func[], funcNumber, freeze)
'	PRINT "ViewNewFunc(179)"
	ATTACH func[] TO prog[funcNumber,]
'	PRINT "ViewNewFunc(181)"
	priorFunction = editFunction
	editFunction = funcNumber
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
'	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	UpdateFileFuncLabels (0, $$TRUE)							' reset function name
	ResetDataDisplays ($$ResetAssembly)
END SUB
END FUNCTION
'
'
' ###############################
' #####  ViewDeleteFunc ()  #####
' ###############################
'
'	Set the function list and manage the ViewDeleteFunction Box
'
'	Discussion:
'		Delete removes defined functions (ie user functions that have code defined
'			as opposed to functions merely DECLAREd or used).  It removes the code
'			as well as it's corresponding DECLARE in the PROLOG.
'		The compiler does NOT remove the function number or symbol from its arrays--
'			it will reside there until another PASS 0 tokenization.
'
FUNCTION  ViewDeleteFunc (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  editFunction,  fileType
	SHARED  xitGrid
'
	$label		= 1
	$list			= 2
	$text			= 3
	$button0	= 4
	$button1	= 5
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		message$ = "ViewDeleteFunction()\ncannot delete\nfunction while program executes"
		warningResponse = WarningResponse (@message$, @" terminate ", "")
		IF (warningResponse = $$WarningCancel) THEN RETURN
		XxxSetBlowback ()
	END IF
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****  'grid' unused : r1$ = default function name
'
SUB DisplayWindow
	IF (fileType != $$Program) THEN
		Message ("[ViewDeleteFunction( )]\n No program loaded ")
		RETURN
	END IF
'
	items = SortFunctionNames (@name$[], $$FALSE)				' don't include PROLOG
	IFZ items THEN
		Message ("[ViewDeleteFunction( )]\n No functions to delete ")
		RETURN
	END IF
'
	XxxFunctionName ($$XGET, @editFunction$, editFunction)
	IFZ r1$ THEN r1$ = editFunction$
	viewLine = -1
	FOR i = 0 TO items - 1
		IF (r1$ = name$[i]) THEN
			viewLine = i
			EXIT FOR
		END IF
	NEXT i
'
'	If no identical match, select match of first n chars
'
	IF (viewLine < 0) THEN
		lenR1 = LEN(r1$)
		IF lenR1 THEN
			IF (r1$ = LEFT$(editFunction$, lenR1)) THEN
				FOR i = 0 TO items - 1
					IF (editFunction$ = name$[i]) THEN
						viewLine = i
						EXIT FOR
					END IF
				NEXT i
			ELSE
				FOR i = 0 TO items - 1
					IF (r1$ = LEFT$(name$[i], lenR1)) THEN
						viewLine = i
						EXIT FOR
					END IF
				NEXT i
			END IF
		END IF
	END IF
	IF (viewLine < 0) THEN viewLine = 0
	XuiSendMessage (grid, #SetTextArray, 0, viewLine, 0, 0, $list, @name$[])
	XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, 1, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE r0
		CASE $list
			IF (v0 < 0) THEN
				XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
				EXIT SUB
			END IF
			GOSUB DeleteFunction
		CASE $text
			IF (v0{$$VirtualKey} == $$KeyEscape) THEN
				XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
				EXIT SUB
			END IF
			XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
			GOSUB DeleteFunction
		CASE $button0
			XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
			GOSUB DeleteFunction
		CASE $button1
			XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  DeleteFunction  *****
'
SUB DeleteFunction
	IF (fileType != $$Program) THEN
		Message ("[ViewDeleteFunction( )]\n No program ")
		RETURN
	END IF
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		message$ = "ViewDeleteFunction()\ncannot delete function\nwhile program executes"
		warningResponse = WarningResponse (@message$, @" terminate ", "")
		IF (warningResponse = $$WarningCancel) THEN EXIT SUB
		XxxSetBlowback ()
		RETURN
	END IF
	XuiSendMessage (grid, #GrabTextArray, 0, 0, 0, 0, $list, @name$[])
	XuiSendMessage (grid, #GetTextCursor, @viewPos, @viewLine, @viewTopPos, @viewTopLine, $list, 0)
	IF ((viewLine < 0) OR (viewLine > UBOUND(name$[]))) THEN
		XuiSendMessage (grid, #PokeTextArray, 0, 0, 0, 0, $list, @name$[])
		Message ("[ViewDeleteFunction( )]\n No function selected ")
		RETURN
	END IF
	funcName$ = name$[viewLine]
	XuiSendMessage (grid, #PokeTextArray, 0, 0, 0, 0, $list, @name$[])
'
	message$ = "ViewDeleteFunction()\nconfirm DELETE function\n" + funcName$ + "()"
	warningResponse = WarningResponse (@message$, @" delete ", "")
	IF (warningResponse = $$WarningCancel) THEN RETURN
'
	DIM text$[]																				' delete function
	error = XitSetFunction (@funcName$, @text$[])
	IF error THEN
		SELECT CASE error
			CASE $$XitFunctionUndefined		:	RETURN (0)		' not there
			CASE $$XitInvalidFunctionName	:	error$ = "invalid function name : " + funcName$
			CASE ELSE											:	error$ = "error : not deleted : " + funcName$
		END SELECT
		Message ("[ViewDeleteFunction( )]\n " + error$ + " ")
		RETURN
	END IF
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
	XitSetDECLARE (@funcName$, "")
'
'	Remove function name from delete list / redisplay
'
	XuiSendMessage (grid, #GrabTextArray, 0, 0, 0, 0, $list, @name$[])
	uName = UBOUND(name$[])
	IF (viewLine = uName) THEN
		IFZ uName THEN
			DIM name$[]
		ELSE
			REDIM name$[uName - 1]
		END IF
	ELSE
		FOR i = viewLine TO uName - 1
			SWAP name$[i], name$[i + 1]
		NEXT i
		REDIM name$[uName - 1]
	END IF
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $list, @name$[])
	XuiSendMessage (grid, #SetTextCursor, viewPos, viewLine, viewTopPos, viewTopLine, $list, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $list, 0)
'	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
END SUB
END FUNCTION
'
'
' ###############################
' #####  ViewRenameFunc ()  #####
' ###############################
'
'	Rename the editFunction with that specified in the View Rename Function box
'
'	In:				skipUpdate
'	Out:			none
'	Return:		none
'
'	Discussion:
'		NOT ##USERRUNNING
'
'		Not allowed if requested name matches a currently defined function.
'
'		The new function number is NOT the same as the old:  thus, all calls
'			to the original name will still use the original function number and name--
'			the defined code just "moves out from under these calls".
'		This keeps the user's calls and the associated code separate.  (User does
'			a global rename on the old names if he wants to match them up with the
'			new name.)
'		DECLARE for old name/funcNumber is not removed from PROLOG.
'
'
'	BAD TECHNIQUE:
'		Replaces the function name associated with this token.  Thus all program
'			references to this function instantly change to the new.  The function
'			number remains the same.
'
'		Problems with this approach:
'			User is building a program, not all modules defined.
'			He references fred(), but fred() is not written yet.  He references
'			mary(), and mary() is written.  Forgetting that he already was using
'			fred(), he renames function mary() to fred()--instantly merging the
'			two function references.  What a mess!
'
FUNCTION  ViewRenameFunc (skipUpdate)
	EXTERNAL /xxx/  maxFuncNumber,  errorCount
	TOKEN   token
	TOKEN   token1
	TOKEN   func[]
	TOKEN   tok[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[],  funcBPAltered[],  funcNeedsTokenizing[]
	SHARED  funcCursorPosition[],  errorFunc[]
	SHARED  environmentActive
	SHARED  uprog,  editFunction,  viewRenameBox,  xitGrid,  fileType
	SHARED  programAltered,  textAlteredSinceSave
	STATIC  GOADDR kinds[]
	AUTO    funcNumber,  line,  j,  newType
'
	IF (fileType != $$Program) THEN
		Message ("[ViewRenameFunction( )]\n No program loaded ")
		RETURN
	END IF
'
	IFZ editFunction THEN
		Message ("[ViewRenameFunction( )]\n Can't rename PROLOG ")
		RETURN
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" terminate ", @"")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		XxxSetBlowback ()
		AddDispatch (&ViewRenameFunc(), 0)
		RETURN
	END IF
'
	IFZ skipUpdate THEN
		XuiSendMessage (viewRenameBox, #SetTextString, 0, 0, 0, 0, $$DialogText, "")
	END IF
	response = 0
	XuiSendMessage (viewRenameBox, #GetModalInfo, @v0, 0, 0, 0, @response, @r1)
	SELECT CASE response
		CASE 0		:	IF (r1 == #CloseWindow) THEN RETURN
		CASE 2		:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
		CASE 3		:	' OK button
		CASE 4		:	RETURN
		CASE ELSE	:	PRINT "ViewRenameFunc() : unknown response ="; response, r1
								RETURN
	END SELECT
	XuiSendMessage (viewRenameBox, #GetTextString, 0, 0, 0, 0, $$DialogText, @func$)
	func$ = TRIM$(func$)
'
	IFZ func$ THEN
		Message ("[ViewRenameFunction( )]\n Received empty function name ")
		RETURN
	END IF
'
'	Confirm valid function name
'
	cchar = func${0}
	IF ((cchar >= '0') AND (cchar <= '9')) THEN
		Message ("[ViewRenameFunction( )]\n Function name cannot begin with digit")
		RETURN
	END IF
	lastChar = UBOUND(func$)
	FOR i = 0 TO lastChar
		cchar = func${i}
		IF ((cchar >= 'a') AND (cchar <= 'z')) THEN DO NEXT
		IF ((cchar >= 'A') AND (cchar <= 'Z')) THEN DO NEXT
		IF ((cchar >= '0') AND (cchar <= '9')) THEN DO NEXT
		IF (cchar = '_') THEN DO NEXT
		IF (cchar = '$') THEN									' only explicit type is STRING
			IF (i = lastChar) THEN EXIT FOR
		END IF
		Message ("[ViewRenameFunction( )]\n Function name contains invalid character ")
		RETURN
	NEXT i
'
' ****************************
' *****  GOOD TECHNIQUE  *****
' ****************************
'
	token$ = func$ + " ("										' compiler assigns function number
	XxxParseSourceLine (@token$, @tok[])
	IFZ tok[] THEN RETURN						' big problem
'
	IF (maxFuncNumber > uprog) THEN
		uprog = maxFuncNumber + (maxFuncNumber >> 2)
		REDIM prog[uprog,]
		REDIM funcAltered[uprog]
		REDIM funcBPAltered[uprog]
		REDIM funcNeedsTokenizing[uprog]
		REDIM funcCursorPosition[uprog, 5]
	END IF
	funcNumber = tok[1].tindex
	DIM tok[]
'
	IF prog[funcNumber,] THEN
		Message ("[ViewRenameFunction( )]\n New function name already exists ")
		RETURN
	END IF
'
	redisplay = $$FALSE								' retokenize text and prepare for rename
	reportBogusRename = $$FALSE
	RestoreTextToProg (redisplay, reportBogusRename)
'
'	Clean out any error codes, change to new funcNumber
'
	ATTACH prog[editFunction,] TO func[]		' removes old number's code
	numLines = UBOUND(func[])
	FOR line = 0 TO numLines
		ATTACH func[line,] TO tok[]
'		IFZ tok[] THEN DO NEXT								' don't blow up if no tokens
		tok[0].ti.errno = 0                   ' ensure no error number
		IFZ changedFunction THEN
			toks = tok[0].ti.ndex
			IF (toks > 1) THEN
				tokPtr = 1
				NextXitToken (@tok[], @tokPtr, toks, @token1)  ' Trimmed, so not blank
				SELECT CASE TRUE
					CASE TokenMatch (@token1, @#T_FUNCTION), TokenMatch (@token1, @#T_CFUNCTION), TokenMatch (@token1, @#T_SFUNCTION)
						DO UNTIL (tokPtr > toks)
							token = tok[tokPtr]
							IF (token.tp.kind = $$KIND_FUNCTIONS) THEN
								tok[tokPtr].tindex = funcNumber
								changedFunction = $$TRUE
								EXIT DO
							END IF
							INC tokPtr
						LOOP
				END SELECT
			END IF
		END IF
		ATTACH tok[] TO func[line,]
	NEXT line
'
	IF errorCount THEN
		FOR i = 1 TO errorCount
			func = errorFunc[i]
			IF (func = editFunction) THEN
				errorFunc[i] = -1
			ELSE
				IF (func != -1) THEN foundError = $$TRUE
			END IF
		NEXT i
		IFZ foundError THEN errorCount = 0
	END IF
'
'	If no DECLARE for new name, add one based on original name
'
	CloneDECLARE (editFunction, funcNumber)
'
'	Waste the old function number's existence from record
'
	funcAltered[editFunction]					= $$FALSE		' clear alteration flags
	funcBPAltered[editFunction]				= $$FALSE
	funcNeedsTokenizing[editFunction]	= $$FALSE
	funcCursorPosition[editFunction, 0]	= 0				' reset cursorChar / topChar
	funcCursorPosition[editFunction, 1]	= 0
	funcCursorPosition[editFunction, 2]	= 0
	funcCursorPosition[editFunction, 3]	= 0
	funcCursorPosition[editFunction, 4]	= 0
	funcCursorPosition[editFunction, 5]	= 0
	XxxDeleteFunction (editFunction)							' tell the compiler
	programAltered = $$TRUE
'
	XxxFunctionName ($$XGET, @funcName$, editFunction)
	XitSetDECLARE (funcName$, "")                 ' remove old DECLARE
'
' Display renamed function
'
	editFunction = funcNumber											' move over to the new number
	ATTACH func[] TO prog[editFunction,]					' move the tokens over
	TokenArrayToText (editFunction, @text$[])
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	funcCursorPosition[editFunction, 0]	= 0
	funcCursorPosition[editFunction, 1]	= 0
	funcCursorPosition[editFunction, 2]	= 0
	funcCursorPosition[editFunction, 3]	= 0
	funcCursorPosition[editFunction, 4]	= 0
	funcCursorPosition[editFunction, 5]	= 0
	funcAltered[editFunction]					= $$TRUE
	funcBPAltered[editFunction]				= $$FALSE
	funcNeedsTokenizing[editFunction]	= $$FALSE
	textAlteredSinceSave = $$TRUE
	UpdateFileFuncLabels ($$TRUE, $$TRUE)				' Reset function name
	ResetDataDisplays ($$ResetAssembly)
	RETURN
END FUNCTION
'
'
' ##############################
' #####  ViewCloneFunc ()  #####
' ##############################
'
'	Clone editFunction to name specified in View Clone Function box
'
'	In:				skipUpdate
'	Out:			none
'	Return:		none
'
'	Discussion:
'		If ##USERRUNNING, ignore rename.  (A blowback would be required--blowback
'			displays the function currently being executed--don't want to rename
'			THAT one.)
'
'		Uses currently existing DECLARE from PROLOG (if it exists) as pattern for
'			cloned function's DECLARE in PROLOG; doesn't remove duplicates from PROLOG
'
FUNCTION  ViewCloneFunc (skipUpdate)
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	TOKEN   temp[]
	TOKEN   tok[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  uprog,  editFunction,  priorFunction,  viewCloneBox
	SHARED  fileType,  programAltered
	SHARED  textAlteredSinceSave,  xitGrid
	SHARED  environmentActive
'
	IF (fileType != $$Program) THEN
		Message ("[ViewCloneFunction( )]\n No program loaded ")
		RETURN
	END IF
'
	IFZ editFunction THEN
		Message ("[ViewCloneFunction( )]\n Can't clone PROLOG ")
		RETURN
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		IF environmentActive THEN
			message$ = "??? terminate program execution ???"
			warningResponse = WarningResponse (@message$, @" clone ", "")
			IF (warningResponse = $$WarningCancel) THEN RETURN
		END IF
		XxxSetBlowback ()
		AddDispatch (&ViewCloneFunc(), 0)
		RETURN
	END IF
'
	IFZ skipUpdate THEN
		XuiSendMessage (viewCloneBox, #SetTextString, 0, 0, 0, 0, $$DialogText, "")
	END IF
	response = 0
	XuiSendMessage (viewCloneBox, #GetModalInfo, @v0, 0, 0, 0, @response, @r1)
	SELECT CASE response
		CASE 0		:	IF (r1 == #CloseWindow) THEN RETURN
		CASE 2    : IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
		CASE 3    : ' OK button
		CASE 4    : RETURN
		CASE ELSE : PRINT "ViewCloneFunc() : unknown response ="; response, r1
								RETURN
	END SELECT
'
	XuiSendMessage (viewCloneBox, #GetTextString, 0, 0, 0, 0, $$DialogText, @func$)
	func$ = TRIM$(func$)
'
	IFZ func$ THEN
		Message ("[ViewCloneFunction( )]\n Received empty function name ")
		RETURN
	END IF
'
	cchar = func${0}
	IF ((cchar >= '0') AND (cchar <= '9')) THEN
		Message ("[ViewCloneFunction( )]\n Function name cannot begin with digit ")
		RETURN
	END IF
	lastChar = UBOUND(func$)
	FOR i = 0 TO lastChar
		cchar = func${i}
		IF ((cchar >= 'a') AND (cchar <= 'z')) THEN DO NEXT
		IF ((cchar >= 'A') AND (cchar <= 'Z')) THEN DO NEXT
		IF ((cchar >= '0') AND (cchar <= '9')) THEN DO NEXT
		IF (cchar = '_') THEN DO NEXT
		IF (cchar = '$') THEN									' only explicit type is STRING
			IF (i = lastChar) THEN EXIT FOR
		END IF
		Message ("[ViewCloneFunction( )]\n Function name contains invalid character ")
		RETURN
	NEXT i
'
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
'
	IF (func$ = "PROLOG") THEN
		Message ("[ViewCloneFunction( )]\n Can't clone PROLOG ")
		RETURN
	END IF
'
	token$ = func$ + " ("									' compiler assigns function number
	XxxParseSourceLine (@token$, @tok[])
	IFZ tok[] THEN RETURN									' avert array disaster
	IF (maxFuncNumber > uprog) THEN
		uprog = maxFuncNumber + (maxFuncNumber >> 2)
		REDIM prog[uprog,]
		REDIM funcAltered[uprog]
		REDIM funcBPAltered[uprog]
		REDIM funcNeedsTokenizing[uprog]
		REDIM funcCursorPosition[uprog, 5]
	END IF
	funcNumber = tok[1].tindex
'
	IF prog[funcNumber,] THEN
		Message ("[ViewCloneFunction( )]\n New function name already exists ")
		RETURN
	END IF
'
	redisplay = $$FALSE
	reportBogusRename = $$TRUE
	RestoreTextToProg(redisplay, reportBogusRename)
'
'	If no DECLARE for new name, add one based on original name
'
	CloneDECLARE (editFunction, funcNumber)
'
'	Tokenize the current text for the new function
	priorFunction = editFunction
	editFunction = funcNumber
	XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	freeze = $$TRUE
	bogusFunction = TextToTokenArray (@text$[], @func[], editFunction, freeze)
'
'	Clean out error codes, if any
'
	numLines = UBOUND(func[])
	FOR line = 0 TO numLines
		func[line,0].ti.errno = 0
	NEXT line
	ATTACH prog[editFunction,] TO temp[]      ' out with the old...
	ATTACH func[] TO prog[editFunction,]      '   ...in with the new
'
' Display clone function
'
	TokenArrayToText (editFunction, @text$[])
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	funcCursorPosition[editFunction, 0] = 0
	funcCursorPosition[editFunction, 1] = 0
	funcCursorPosition[editFunction, 2] = 0
	funcCursorPosition[editFunction, 3] = 0
	funcCursorPosition[editFunction, 4] = 0
	funcCursorPosition[editFunction, 5] = 0
	funcBPAltered[editFunction]					= $$FALSE
	funcNeedsTokenizing[editFunction]		= $$FALSE
	funcAltered[editFunction]						= $$TRUE
	programAltered											= $$TRUE
'
	textAlteredSinceSave = $$TRUE
	UpdateFileFuncLabels ($$TRUE, $$TRUE)				' Reset function name
	ResetDataDisplays ($$ResetAssembly)
END FUNCTION
'
'
' #############################
' #####  ViewLoadFunc ()  #####
' #############################
'
FUNCTION  ViewLoadFunc (skipUpdate)
	SHARED  viewLoadBox
	SHARED  fileType,  xitGrid
	SHARED  lastSaveFunc$
	SHARED  lastSaveFile$
'
	IF (fileType != $$Program) THEN
		Message ("[ViewLoadFunction( )]\n No program loaded ")
		RETURN
	END IF
'
Browsed:
	IFZ skipUpdate THEN
		XuiSendMessage (viewLoadBox, #SetTextString, 0, 0, 0, 0, 2, lastSaveFunc$)
		XuiSendMessage (viewLoadBox, #SetTextString, 0, 0, 0, 0, 4, lastSaveFile$)
	END IF
	response = 0
	XuiSendMessage (viewLoadBox, #GetModalInfo, @v0, 0, 0, 0, @response, @r1)
	SELECT CASE response
		CASE 0		:	IF (r1 == #CloseWindow) THEN RETURN
		CASE 2,4	:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
		CASE 5		:	' OK button
		CASE 6		:	GOSUB FileBrowse
								GOTO Browsed
		CASE 7		:	RETURN   ' cancel
		CASE ELSE	:	PRINT "ViewLoadFunc() : unknown response ="; response, r1
								RETURN
	END SELECT
	XuiSendMessage (viewLoadBox, #GetTextString, 0, 0, 0, 0, 2, @funcName$)
	XuiSendMessage (viewLoadBox, #GetTextString, 0, 0, 0, 0, 4, @fileName$)
	funcName$ = TRIM$(funcName$)
	fileName$ = TRIM$(fileName$)
	IFZ funcName$ THEN
		Message ("[ViewLoadFunction( )]\n Received empty function name ")
		RETURN
	END IF
	IFZ fileName$ THEN
		Message ("[ViewLoadFunction( )]\n Received empty file name ")
		RETURN
	END IF
	funcNum = XxxFunctionNumber (funcName$)
	IF funcNum THEN
		message$ = "ViewLoadFunction()\nfunction name already exists\n" + funcName$
		warningResponse = WarningResponse (@message$, @" replace ", "")
		IF (warningResponse = $$WarningCancel) THEN RETURN
	END IF
	error = XitLoadFunction (@funcName$, @fileName$)
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
	IF error THEN
		SELECT CASE error
			CASE $$XitInvalidFunctionName
				Message ("[ViewLoadFunction( )]\n Function not loaded \n\n bad function name \n\n" + funcName$)
			CASE ELSE
				Message ("[ViewLoadFunction( )]\n Function not loaded \n\n bad file name \n\n" + fileName$ + " ")
		END SELECT
	ELSE
		XitSetDisplayedFunction (@funcName$)
	END IF
	RETURN
'
'
' *****  FileBrowse  *****
'
SUB FileBrowse
	IF lastSaveFile$ THEN
		XstDecomposePathname (lastSaveFile$, @path$, @parent$, @fileName$, @file$, @extent$)
	ELSE
		XstGetCurrentDirectory (@path$)
	END IF
	filter$ = "*.txt\n *"
	IF extent$ THEN
		IF (extent$ != ".txt") THEN
			filter$ = "*" + extent$ + ", *.txt\n *"
		END IF
	END IF
	XstFileSelectSetInfo (path$, filter$, xDisp, yDisp, width, height)
	XstFileSelect (windowTitle$, @file$)
	IFZ file$ THEN EXIT SUB
	readable = XstGetFileAttributes (file$, @attributes)
	IFF readable THEN EXIT SUB
	error = XstLoadStringArray (file$, @string$[])
	IF string$[] THEN
		string$ = string$[0]
	END IF
	DECLARE$ = XstParseWhitespace$ (string$, 1)
	SELECT CASE DECLARE$
		CASE "DECLARE"
		CASE "INTERNAL"
		CASE ELSE : Message ("[ViewLoadFunction( )]\n Invalid file format")
								EXIT SUB
	END SELECT
	FUNCTION$ = XstParseWhitespace$ (string$, 2)
	IF (FUNCTION$ != "FUNCTION") THEN
		Message ("[ViewLoadFunction( )]\n Invalid file format")
		EXIT SUB
	END IF
	function$ = XstParseWhitespace$ (string$, 3)
	lastSaveFunc$ = function$
	lastSaveFile$ = file$
END SUB
'
END FUNCTION
'
'
' #############################
' #####  ViewSaveFunc ()  #####
' #############################
'
FUNCTION  ViewSaveFunc (skipUpdate)
	SHARED  viewSaveBox
	SHARED  fileType,  xitGrid
	SHARED  editFunction
	SHARED  lastSaveFunc$
	SHARED  lastSaveFile$
'
	IF (fileType != $$Program) THEN
		Message ("[ViewSaveFunction( )]\n No program loaded ")
		RETURN
	END IF
	IFZ skipUpdate THEN
		XxxFunctionName ($$XGET, @func$, editFunction)
		XuiSendMessage (viewSaveBox, #SetTextString, 0, 0, 0, 0, 2, func$)
		XstGetCurrentDirectory (@directory$)
		file$ = directory$ + $$PathSlash$ + func$ + ".txt"
		XuiSendMessage (viewSaveBox, #SetTextString, 0, 0, 0, 0, 4, file$)
	END IF
	response = 0
	XuiSendMessage (viewSaveBox, #GetModalInfo, @v0, 0, 0, 0, @response, @r1)
	SELECT CASE response
		CASE 0		:	IF (r1 == #CloseWindow) THEN RETURN
		CASE 2,4	:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
		CASE 5		:	' OK button
		CASE 6		:	RETURN
		CASE ELSE	:	PRINT "ViewSaveFunc() : unknown response ="; response
								RETURN
	END SELECT
	XuiSendMessage (viewSaveBox, #GetTextString, 0, 0, 0, 0, 2, @funcName$)
	XuiSendMessage (viewSaveBox, #GetTextString, 0, 0, 0, 0, 4, @fileName$)
	funcName$ = TRIM$(funcName$)
	fileName$ = TRIM$(fileName$)
	IFZ funcName$ THEN
		Message ("[ViewSaveFunction( )]\n Received empty function name ")
		RETURN
	END IF
	IFZ fileName$ THEN
		Message ("[ViewSaveFunction( )]\n Received empty file name ")
		RETURN
	END IF
'
	XstGetFileAttributes (@fileName$, @attributes)
	IF (attributes AND $$FileDirectory) THEN
		Message ("[ViewSaveFunction( )]\n File not saved \n\n file name is a directory \n\n " + fileName$ + " ")
		RETURN
	END IF
	IF attributes THEN
		message$ = "ViewSaveFunction()\nfilename already exists"
		warningResponse = WarningResponse (@message$, @" save ", "")
		IF (warningResponse = $$WarningCancel) THEN RETURN
		XstDeleteFile (fileName$)
	END IF
'
	error = XitSaveFunction (@funcName$, @fileName$)
	IF error THEN
		SELECT CASE error
			CASE $$XitInvalidFunctionName
				Message ("[ViewSaveFunction( )]\n Function not saved \n\n invalid function name \n\n " + funcName$ + " ")
			CASE ELSE
				Message ("[ViewSaveFunction( )]\n Function not saved \n\n invalid file name \n\n " + fileName$ + " ")
		END SELECT
	ELSE
		lastSaveFunc$ = funcName$
		lastSaveFile$ = fileName$
	END IF
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
END FUNCTION
'
'
' ################################
' #####  ViewMergePROLOG ()  #####
' ################################
'
FUNCTION  ViewMergePROLOG (skipUpdate)
	SHARED  viewMergeBox
	SHARED  fileType,  xitGrid
'
	IF (fileType != $$Program) THEN
		Message ("[ViewMergePROLOG( )]\n No program loaded ")
		RETURN
	END IF
'

	XstFileSelectSetInfo ("$XBDIR/include", "*.dec", 50, 50, 30, 50)
	XstFileSelect ("file name to merge with PROLOG", @fileName$)

	fileName$ = TRIM$(fileName$)
	IFZ fileName$ THEN
		Message ("[ViewMergePROLOG( )]\n Received empty file name ")
		RETURN
	END IF
	error = XitMergePROLOG (@fileName$)
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
	IF error THEN
		Message ("[ViewMergePROLOG( )]\n *** not merged *** \n\n bad file name \n\n " + fileName$ + " ")
	ELSE
		XitSetDisplayedFunction (@"PROLOG")
	END IF
END FUNCTION
'
'
' ##############################################
' #####  ViewImportFunctionFromProgram ()  #####
' ##############################################
'
' import a function from a *.x file
' function ViewImportFunctionFromProgram is sensitive to exact
' number of spaces between keywords
' eg, in PROLOG :
'		DECLARE FUNCTION  Tally (SearchMe$, SearchFor$)
' and as shown in program:
'		FUNCTION  Tally (SearchMe$, SearchFor$)
' note that there are 2 spaces between FUNCTION and function name or type declaration
' there is also 1 space between function name and argument list ( ).
'
FUNCTION  ViewImportFunctionFromProgram (skipUpdate)
	SHARED  viewImportBox
	SHARED  fileType,  xitGrid
'
	IF (fileType != $$Program) THEN
		Message ("[ViewImportFunctionFromProgram( )]\n No program loaded ")
		RETURN
	END IF
'
	IFZ skipUpdate THEN
		XuiSendMessage (viewImportBox, #SetTextString, 0, 0, 0, 0, 2, "")
		XuiSendMessage (viewImportBox, #SetTextString, 0, 0, 0, 0, 4, "")
	END IF
	response = 0
	XuiSendMessage (viewImportBox, #GetModalInfo, @v0, 0, 0, 0, @response, @r1)
	SELECT CASE response
		CASE 0		:	IF (r1 == #CloseWindow) THEN RETURN
		CASE 2,4	:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
		CASE 5		:	' OK button
		CASE 6		:	RETURN
		CASE ELSE	:	PRINT "ViewImportFunctionFromProgram() : unknown response ="; response
								RETURN
	END SELECT
	XuiSendMessage (viewImportBox, #GetTextString, 0, 0, 0, 0, 2, @funcName$)
	XuiSendMessage (viewImportBox, #GetTextString, 0, 0, 0, 0, 4, @fileName$)
	funcName$ = TRIM$(funcName$)
	fileName$ = TRIM$(fileName$)
	IFZ funcName$ THEN
		Message ("[ViewImportFunctionFromProgram( )]\n Received empty function name ")
		RETURN
	END IF
	IFZ fileName$ THEN
		Message ("[ViewImportFunctionFromProgram( )]\n Received empty file name ")
		RETURN
	END IF
'
	fn$ = LCASE$(fileName$)
	IF RIGHT$(fn$, 2) <> ".x" THEN
		Message ("[ViewImportFunctionFromProgram( )]\n Function not loaded \n\n not *.x name \n\n" + fileName$)
		RETURN
	END IF
'
	error = XstLoadStringArray (@fileName$, @text$[])
	IF error THEN
		Message ("[ViewImportFunctionFromProgram( )]\n Function not loaded \n\n bad file name \n\n" + fileName$)
		RETURN
	END IF
'
	IFZ text$[] THEN
		Message ("[ViewImportFunctionFromProgram( )]\n Function not loaded \n\n bad file name \n\n" + fileName$)
		RETURN
	END IF
'
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
'
' find funcName$ in PROLOG in text$[]
'
	DIM type$[11]
	type$[0] = ""
	type$[1] = "SBYTE "
	type$[2] = "UBYTE "
	type$[3] = "SSHORT "
	type$[4] = "USHORT "
	type$[5] = "SLONG "
	type$[6] = "ULONG "
	type$[7] = "XLONG "
	type$[8] = "GIANT "
	type$[9] = "SINGLE "
	type$[10] = "DOUBLE "
	type$[11] = "STRING "
'
	FOR i = 0 TO UBOUND(type$[])
		find$ = "DECLARE FUNCTION  " + type$[i] + funcName$
		line = 0
		pos = 0
		XstFindArray (0, @text$[], @find$, @line, @pos, @match)
		IF match THEN
			declare$ = text$[line]
			type$ = type$[i]
			EXIT FOR
		END IF
	NEXT i
'
	IFZ match THEN
		FOR i = 0 TO UBOUND(type$[])
			line = 0
			pos = 0
			find$ = "INTERNAL FUNCTION  " + type$[i] + funcName$
			XstFindArray (0, @text$[], @find$, @line, @pos, @match)
			IF match THEN
				declare$ = text$[line]
				type$ = type$[i]
				EXIT FOR
			END IF
		NEXT i
'
		IFZ match THEN
			Message ("[ViewLoadFunctionFromProgram( )]\n Function not found in PROLOG \n\n" + funcName$)
			RETURN
		END IF
	END IF
'
' find function, get start and end lines in text$[]
'
	len = LEN(find$)
	pos = pos + len
	find$ = "FUNCTION  " + type$ + funcName$ + " "
	XstFindArray (0, @text$[], @find$, @line, @pos, @match)
	start = line
'
	IFZ match THEN
		Message ("[ViewImportFunctionFromProgram( )]\n Function not found \n\n" + funcName$)
		RETURN
	END IF
'
	len = LEN(find$)
	find$ = "END FUNCTION"
	pos = pos + len
	XstFindArray (0, @text$[], @find$, @line, @pos, @match)
	end = line
'
	IFZ match THEN
		Message ("[ViewImportFunctionFromProgram( )]\n End of function not found \n\n function \n\n" + funcName$)
		RETURN
	END IF
'
	upper = end-start+6-1
	DIM out$[upper]
	out$[0] = "'"
	out$[1] = "'"
	out$[2] = "' #######" + CHR$('#', LEN(funcName$)) + "##########"
	out$[3] = "' #####  " +					funcName$					+ " ()  #####"
	out$[4] = "' #######" + CHR$('#', LEN(funcName$)) + "##########"
	out$[5] = "'"
'
	FOR i = 6 TO upper
		out$[i] = text$[start+i-6]
	NEXT i
'
	XitSetDECLARE (@funcName$, @declare$)
	error = XitSetFunction (@funcName$, @out$[])
'
	XitSetDisplayedFunction (@funcName$)
END FUNCTION
'
'
' #################################
' #####  XitHelpIndexCode ()  #####
' #################################
'
FUNCTION  XitHelpIndexCode (grid, message, v0, v1, v2, v3, r0, r1)
	SHARED  helpIndexBox
	STATIC  helpIndex$[]
	STATIC  indexFind$[]
	STATIC  saveCursorLine, saveTopLine
'
	$Label   = 1
	$List    = 2
	$Text    = 3
	$Button0 = 4
	$Button1 = 5
'
	$StyleNotify  = 0x10
'
'	XgrMessageNumberToName (message, @message$)
'	IF (message = #Callback) THEN
'		XgrMessageNumberToName (r1, @r1$)
'	END IF
'	PRINT "XitHelpIndexCode(25)", grid, helpIndexBox, message$, HEX$(v0), HEX$(v1), HEX$(v2), HEX$(v3), r0, r1, r1$
'
	IF (message = #Callback) THEN message = r1
'
	SELECT CASE message
		CASE #CloseWindow   : GOSUB HideWindow
		CASE #Displayed     : GOSUB Displayed
		CASE #Hidden        : GOSUB Hidden
		CASE #Selection     : GOSUB Selection
		CASE #TextModified  : GOSUB TextModified
	END SELECT
	RETURN
'
'
' *****  Displayed  *****
'
SUB Displayed
	dir$ = "$XBDIR/help"
	indexFile$ = dir$ + "/index.hlp"
	error = XstLoadStringArray (indexFile$, @helpIndex$[])
	uindex = UBOUND(helpIndex$[])
	lastItem$ = helpIndex$[uindex]
	version$ = XitVersion$ ()
	version$ = "Version " + version$
	IF (lastItem$ <> version$) THEN
		message$ = "??? Help Index file is not " + version$ + " ???"
		warningResponse = WarningResponse (@message$, @" continue ", "")
		IF (warningResponse = $$WarningCancel) THEN
			GOSUB HideWindow
			RETURN
		END IF
	END IF
	DIM indexList$[uindex]
	DIM indexFind$[uindex]
	FOR i = 0 TO uindex
		indexItem$ = helpIndex$[i]
		splt = INSTR(indexItem$, " <")
		IF splt THEN
			item$ = LEFT$(indexItem$, splt-1)
			indexList$[i] = item$
			indexFind$[i] = item$
		END IF
	NEXT i
	XuiSendMessage (helpIndexBox, #SetTextArray, 0, 0, 0, 0, $List, @indexList$[])
	XuiSendMessage (grid, #GetStyle, @v0, 0, 0, 0, $List, 0)
'
	XgrGetTextSelectionGrid (@gridSelect)
	IF gridSelect THEN
		XuiSendMessage (gridSelect, #GetTextSelection, 0, 0, 0, 0, 0, @text$)
		IF (LEFT$(text$, 1) == "#") THEN text$ = LCLIP$(text$, 1)
		XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @text$)
	END IF
'
	IF (v0 AND $StyleNotify) THEN
		XuiSendMessage (helpIndexBox, #SetTextString, 0, 0, 0, 0, 1, @"Alphabetical List")
		XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @text$)
		IF text$ THEN
			flags = $$SortCaseInsensitive OR $$SortAlphaNumeric
			lenText = LEN(text$)
			uList = UBOUND(indexList$[])
			j = 1
			textCompare$ = LEFT$(text$, j)
			FOR line = 0 TO uList
				line$ = indexList$[line]
				lineCompare$ = LEFT$(line$, j)
				result = XstCompareStrings (&lineCompare$, $$GE, &textCompare$, flags)
				IF (result == $$GT) THEN EXIT FOR
				IF (result == $$EQ) THEN
					matchLine = line
					INC j
					IF (j > lenText) THEN EXIT FOR
					textCompare$ = LEFT$(text$, j)
					DO FOR
				END IF
			NEXT line
			XuiSendMessage (grid, #GetTextCursor, 0, 0, 0, 0, $List, @rows)
			saveCursorLine = matchLine
			saveTopLine = saveCursorLine - (rows >> 1)
		END IF
	ELSE
		XuiSendMessage (helpIndexBox, #SetTextString, 0, 0, 0, 0, 1, @"Find List")
		GOSUB TextModified
		EXIT SUB
	END IF
'
	XuiSendMessage (helpIndexBox, #SetTextCursor, 0, saveCursorLine, 0, saveTopLine, $List, 0)
	XuiSendMessage (helpIndexBox, #Redraw, 0, 0, 0, 0, $List, 0)
	XuiSendMessage (helpIndexBox, #SetKeyboardFocus, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	IF (v0 == -1) THEN EXIT SUB            ' cancel
	kid = r0
	SELECT CASE kid
		CASE $List     : GOSUB GetSelection
		CASE $Text     : GOSUB GetSelection
		CASE $Button0  : GOSUB GetSelection
		CASE $Button1  : GOSUB HideWindow
	END SELECT
'
END SUB
'
'
' *****  GetSelection  *****
'
SUB GetSelection
	IFZ helpIndex$[] THEN EXIT SUB
	XuiSendMessage (helpIndexBox, #GetTextCursor, 0, @saveCursorLine, 0, @saveTopLine, $List, 0)
	XuiSendToKid (grid, #GrabTextArray, 0, 0, 0, 0, $List, @list$[])
	IF (saveCursorLine > UBOUND(list$[])) THEN EXIT SUB
	find$ = list$[saveCursorLine]
	XuiSendToKid (grid, #PokeTextArray, 0, 0, 0, 0, $List, @list$[])
'
	findMode = $$FindCaseInsensitive
	line = 0
	pos = 0
	DO
		XstFindArray (findMode, @helpIndex$[], find$, @line, @pos, @match)
		IFZ match THEN EXIT SUB
		IFZ pos THEN EXIT DO     'match good if at beginning of line
		INC line
		pos = 0
	LOOP
'
	v0 = line
	GOSUB DisplaySection
END SUB
'
'
' *****  DisplaySection *****
'
SUB DisplaySection
	uHelpIndex = UBOUND (helpIndex$[])
	IF (v0 > uHelpIndex) THEN EXIT SUB
'
	selection$ = helpIndex$[v0]
	splt = INSTR(selection$, " <")
	colon = INSTR(selection$, ":", splt)
	gt = INSTR(selection$, ">", colon)
'
	dir$ = "$XBDIR/help"
	fileName$ = dir$ + "/" + MID$(selection$, splt+2, colon-splt-2) + ".hlp"
	IF (gt == (colon+1)) THEN
		section$ = LEFT$(selection$, splt-1)
	ELSE
		section$ = MID$(selection$, colon+1, gt-colon)
	END IF
	section$ = ":" + TRIM$(section$)
'
	XuiSendMessage (helpIndexBox, #SetHelp, 0, 0, 0, 0, 0, fileName$ + section$)
'
END SUB
'
'
' *****  Hidden  *****
'
SUB Hidden
	IF helpIndex$[] THEN
		XuiSendMessage (helpIndexBox, #GetTextCursor, 0, @saveCursorLine, 0, @saveTopLine, $List, 0)
		DIM helpIndex$[]
		DIM indexList$[]
		XuiSendMessage ( helpIndexBox, #SetTextArray, 0, 0, 0, 0, $List, @indexList$[])
	END IF
END SUB
'
'
' *****  HideWindow  *****
'
SUB HideWindow
	IF (message <> #Hidden) THEN
		XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END IF
END SUB
'
'
' *****  TextModified  *****
'
SUB TextModified
	XuiSendMessage (grid, #GetStyle, @v0, 0, 0, 0, $List, 0)
	IF (v0 AND $StyleNotify) THEN EXIT SUB
'
	XuiSendMessage (helpIndexBox, #SetTextCursor, 0, 0, 0, 0, $List, 0)
	XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @text$)
	IFZ text$ THEN EXIT SUB
	XuiSendToKid (grid, #GrabTextArray, 0, 0, 0, 0, $List, @list$[])
'
	IFZ indexFind$[] THEN EXIT SUB
	uList = UBOUND(indexFind$[])
	DIM list$[uList]
	lenText = LEN(text$)
	i = -1
	FOR line = 0 TO uList
		line$ = indexFind$[line]
		lenLine = LEN(line$)
		IF (lenLine < lenText) THEN DO NEXT
		match = INSTRI(line$, text$)
		IF match THEN
			INC i
			list$[i] = line$
		END IF
	NEXT line
	REDIM list$[i]
	XuiSendToKid (grid, #PokeTextArray, 0, 0, 0, 0, $List, @list$[])
	XuiSendMessage (helpIndexBox, #SetTextCursor, 0, 0, 0, 0, $List, 0)
	XuiSendMessage (helpIndexBox, #Redraw, 0, 0, 0, 0, $List, 0)
'
	r0 = $$TRUE                        'tell calling function, XuiListDialog2B(), to NOT modify the list
'
END SUB
'
END FUNCTION
'
'
' ##################################
' #####  XitOptionMiscCode ()  #####
' ##################################
'
FUNCTION  XitOptionMiscCode (grid, message, v0, v1, v2, v3, kid, r1)
	EXTERNAL /xxx/  checkBounds, autoUpperCase
	SHARED  saveCRLF, stopCompOnErr
	SHARED  makeBackupFile, reloadLastFile
	SHARED  saveBeforeCompile, saveBeforeRun
	SHARED	xitTextLower
	SHARED  consoleFont
'
	$Style1 = 1
	$Style2 = 2
	$Style3 = 3
	$Style4 = 4
	$Style5 = 5
	$Style6 = 6
	$Style7 = 7
'
	$XitOptionMisc          =   0  ' kid   0 grid type = XitOptionMisc
	$CheckBounds            =   1  ' kid   1 grid type = XuiCheckBox
	$CheckSaveNewline       =   2  ' kid   2 grid type = XuiCheckBox
	$CheckConsoleDarkColor  =   3  ' kid   3 grid type = XuiCheckBox
	$CheckCompileError      =   4  ' kid   4 grid type = XuiCheckBox
	$CheckConsoleLargeFont  =   5  ' kid   5 grid type = XuiCheckBox
	$CheckProgramLargeFont  =   6  ' kid   6 grid type = XuiCheckBox
	$CheckConsoleLargeBars  =   7  ' kid   7 grid type = XuiCheckBox
	$CheckProgramLargeBars  =   8  ' kid   8 grid type = XuiCheckBox
	$CheckAutoUpperCase     =   9  ' kid   9 grid type = XuiCheckBox
	$CheckProgramLineNumber =  10  ' kid  10 grid type = XuiCheckBox
	$CheckAutoIndent        =  11  ' kid  11 grid type = XuiCheckBox
	$CheckTabBlockIndent    =  12  ' kid  12 grid type = XuiCheckBox
	$CheckMakeBackupFile    =  13  ' kid  13 grid type = XuiCheckBox
	$CheckReloadLastFile    =  14  ' kid  14 grid type = XuiCheckBox
	$CheckSaveBeforeCompile =  15  ' kid  15 grid type = XuiCheckBox
	$CheckSaveBeforeRun     =  16  ' kid  16 grid type = XuiCheckBox
	$CheckProgramRuler      =  17  ' kid  17 grid type = XuiCheckBox
	$ButtonEnter            =  18  ' kid  18 grid type = XuiPushButton
	$UpperKid               =  18  ' kid maximum
'
'	XgrMessageNumberToName (r1, @mess$)
'	XgrMessageNumberToName (message, @message$)
'	PRINT "XitOptionMisc() : "; grid;; message$;; v0; v1; v2; v3; kid; r1;; mess$
'
	IF (message = #Callback) THEN message = r1
'
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
	RETURN
'
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE kid
	CASE $XitOptionMisc          :
	CASE $CheckBounds            : checkBounds = v0
	CASE $CheckSaveNewline       : saveCRLF = v0
	CASE $CheckConsoleDarkColor  : GOSUB ConsoleDarkColor
	CASE $CheckCompileError      : stopCompOnErr = v0
	CASE $CheckConsoleLargeFont  : GOSUB ConsoleLargeFont
	CASE $CheckProgramLargeFont  : GOSUB ProgramLargeFont
	CASE $CheckConsoleLargeBars  : GOSUB ConsoleLargeBars
	CASE $CheckProgramLargeBars  : GOSUB ProgramLargeBars
	CASE $CheckAutoUpperCase     : autoUpperCase = v0
	CASE $CheckProgramLineNumber : GOSUB ProgramLineNumbers
	CASE $CheckAutoIndent
		XuiSendMessage (xitTextLower, #SetTextFlag, $$TextFlagAutoIndent, v0, 0, 0, 0, 0)
	CASE $CheckTabBlockIndent
		XuiSendMessage (xitTextLower, #SetTextFlag, $$TextFlagTabBlockIndent, v0, 0, 0, 0, 0)
	CASE $CheckMakeBackupFile    : makeBackupFile = v0
	CASE $CheckReloadLastFile    : reloadLastFile = v0
	CASE $CheckSaveBeforeCompile : saveBeforeCompile = v0
	CASE $CheckSaveBeforeRun     : saveBeforeRun = v0
	CASE $CheckProgramRuler      : GOSUB ProgramRuler
	CASE $ButtonEnter            : XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  ConsoleDarkColor  *****
'
SUB ConsoleDarkColor
	XstGetConsoleGrid (@console)
	IF v0 THEN
		XuiSendMessage (console, #SetColor, $$Black, $$White, -1, -1, 1, 0)
	ELSE
		XuiGetGridProperty (console, 0, "backgroundColor", @bc)
		XuiGetGridProperty (console, 0, "drawingColor", @dc)
		XuiSendMessage (console, #SetColor, bc, dc, -1, -1, 1, 0)
	END IF
'	PRINT "XitOptionMiscCode() : ConsoleDarkColor : "; console;; v0, bc, dc
	XuiSendMessage (console, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  ConsoleLargeFont  *****
'
SUB ConsoleLargeFont
	XstGetConsoleGrid (@console)
'
	IF v0 THEN
		XuiSendMessage (console, #SetFont, 360, 700, 0, 0, 0, @"courier")
		XuiSendMessage (console, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		IFZ font THEN XuiSendMessage (console, #SetFont, 320, 700, 0, 0, 0, @"Courier")
		XuiSendMessage (console, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		IFZ font THEN XuiSendMessage (console, #SetFont, 360, 800, 0, 0, 0, @"Courier")
	ELSE
		XuiSendMessage (console, #SetFontNumber, consoleFont, 0, 0, 0, 0, 0)
	END IF
	XuiSendMessage (console, #Redraw, 0, 0, 0, 0, 0, 0)
'	PRINT "XitOptionMiscCode()ConsoleLargeFont", v0, console, gridType, font, font1
END SUB
'
'
' *****  ProgramLargeFont  *****
'
SUB ProgramLargeFont
	IF v0 THEN
		XuiSendMessage (xitTextLower, #SetFont, 360, 700, 0, 0, 0, @"courier")
		XuiSendMessage (xitTextLower, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		PRINT "XitOptionMiscCode(128)ProgramLargeFont", font
		IFZ font THEN XuiSendMessage (xitTextLower, #SetFont, 320, 700, 0, 0, 0, @"Courier")
		XuiSendMessage (xitTextLower, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		IFZ font THEN XuiSendMessage (xitTextLower, #SetFont, 360, 800, 0, 0, 0, @"Courier")
	ELSE
		XuiSendMessage (xitTextLower, #SetFontNumber, 0, 0, 0, 0, 0, 0)
		XuiSetGridProperties (xitTextLower, #SetGridProperties, 0, #SetFont, 0, 0, 0, 0)
	END IF
'	PRINT "XitOptionMiscCode()ProgramLargeFont", v0, font
	XuiSendMessage (xitTextLower, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  ConsoleLargeBars  *****
'
SUB ConsoleLargeBars
'
	IF v0 THEN
		style = 4
	ELSE
		style = 2
	END IF
	XstGetConsoleGrid (@console)
	XuiSendMessage (console, #GetStyle, @styleExisting, 0, 0, 0, 0, 0)
	IF (style <> styleExisting) THEN
		XuiSendMessage (console, #SetStyle, style, 0, 0, 0, 0, 0)
		XuiSendMessage (console, #Redraw, 0, 0, 0, 0, 0, 0)
	END IF
END SUB
'
'
' *****  ProgramLargeBars  *****
'
SUB ProgramLargeBars
	IF v0 THEN
		style = $Style4    'style for larger scroll bars
	ELSE
		style = $Style2    'style for smaller scroll bars
	END IF
	XuiSendMessage (xitTextLower, #GetStyle, @styleExisting, 0, 0, 0, 0, 0)
	IF (style <> (styleExisting AND $Style7)) THEN
		style = (styleExisting AND NOT $Style7) OR style
		XuiSendMessage (xitTextLower, #SetStyle, style, 0, 0, 0, 0, 0)
		XuiSendMessage (xitTextLower, #Redraw, 0, 0, 0, 0, 0, 0)
	END IF
END SUB
'
'
' *****  ProgramLineNumbers  *****
'
SUB ProgramLineNumbers
	XuiSendMessage (xitTextLower, #SetTextFlag, $$TextFlagLineNum, v0, 0, 0, 0, 0)
	XuiSendMessage (xitTextLower, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  ProgramLineNumbers  *****
'
SUB ProgramRuler
	XuiSendMessage (xitTextLower, #SetTextFlag, $$TextFlagRuler, v0, 0, 0, 0, 0)
	XuiSendMessage (xitTextLower, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
END FUNCTION
'
'
' ###############################
' #####  OptionTabWidth ()  #####
' ###############################
'
FUNCTION  OptionTabWidth (width)
	SHARED  xitGrid
	SHARED	stringBox
	SHARED	optTabBox
	SHARED	tabWidth
'
	skip = $$FALSE
	IF ((width >= 1) AND (width <= 256)) THEN tabWidth = width : skip = $$TRUE
	tabWidth$ = STRING (tabWidth)
	lenName = LEN (tabWidth$)
	XuiSendMessage (optTabBox, #SetTextString, lenName, 0, 0, 0, $$DialogText, tabWidth$)
	XuiSendMessage (optTabBox, #SetTextCursor, lenName, 0, 0, 0, $$DialogText, 0)
	IFZ width THEN
		response = 0
		XuiSendMessage (optTabBox, #GetModalInfo, @v0, 0, 0, 0, @response, 0)
		SELECT CASE response
			CASE 2		:	IF (v0{$$VirtualKey} = $$KeyEscape) THEN RETURN
			CASE 3		:	' OK button
			CASE 4		:	RETURN
			CASE ELSE	:	PRINT "OptionTabWidth() : unknown response ="; response
									RETURN
		END SELECT
		XuiSendMessage (optTabBox, #GetTextString, 0, 0, 0, 0, $$DialogText, @tabWidth$)
	END IF
'
	tabWidth = XLONG (tabWidth$)
'	IF (tabWidth < 2) THEN tabWidth = 2
	IF (tabWidth < 2) THEN
		XuiSendMessage (xitGrid, #GetFontNumber, @font, 0, 0, 0, $$xitTextLower, 0)
		XgrGetFontMetrics (font, @maxCharWidth, 0, 0, 0, 0, 0)
		tabWidth = maxCharWidth << 1
	END IF
'
	IF (tabWidth > 256) THEN tabWidth = 256
'
	XuiSendMessage (xitGrid, #SetTabWidth, tabWidth, 0, 0, 0, $$xitCommand, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitCommand, 0)
	XuiSendMessage (xitGrid, #SetTabWidth, tabWidth, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (stringBox, #SetTabWidth, tabWidth, 0, 0, 0, 3, 0)
	XuiSendMessage (stringBox, #RedrawText, 0, 0, 0, 0, 3, 0)
END FUNCTION
'
'
' #################################
' #####  OptionTextCursor ()  #####
' #################################
'
' Callbacks come from XitTextCursor()
'
' The text-cursor color is set in  all
' XuiTextArea and XuiTextLine grids.
' The cursor-line is only set in the
' PDE TextLower grid.
'
' See: XitTextCursor()
'
FUNCTION  OptionTextCursor (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED  textCursor
	SHARED  xitGrid
	SHARED  xitCursorColor
	SHARED  xitCursorLineColor
'
	IF ((message = #Callback) AND (r1 = #Selection)) THEN
		SELECT CASE v1                                      ' v1 is the kid number
			CASE 2 :	IF ((v0 >= 1) OR (v0 <= 124)) THEN
									XuiSendMessage (xitGrid, #GetColorExtra, -1, -1, -1, @curLineColor, $$xitTextLower, 0)
									v0 = v0 XOR curLineColor
									v0 = v0 -3
									xitCursorColor = v0
									XxxXuiTextCursor (v0)  'set cursor color on all grids
								END IF
								XuiSendMessage (textCursor, #RedrawGrid, 0, 0, 0, 0, 5, 0)
'
			CASE 4 :	xitCursorLineColor = v0
								XuiSendMessage (textCursor, #SetColor, v0, -1, -1, -1, 5, 0)
								XuiSendMessage (textCursor, #RedrawGrid, 0, 0, 0, 0, 5, 0)
								XuiSendMessage (xitGrid, #SetColorExtra, -1, -1, -1, v0, $$xitTextLower, 0)
								XuiSendMessage (xitGrid, #Redraw, 0, 0, 0, 0, $$xitTextLower, 0)
'
			CASE 6 :	XuiSendMessage (textCursor, #HideWindow, 0, 0, 0, 0, 0, 0)
								XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
		END SELECT
	END IF
END FUNCTION
'
'
' ###########################
' #####  OptionFont ()  #####
' ###########################
'
FUNCTION  OptionFont ()
	SHARED  xitGrid
	SHARED  optFontBox
	SHARED  popupGrids[]
'
	XuiSendMessage (optFontBox, #GetModalInfo, @font, 0, 0, 0, 0, 0)
	IF (font = -1) THEN RETURN						' KeyEscape or Cancel
'	PRINT "OptionFont:  selected font "; font
	XgrGetFontInfo (font, @fontName$, @fontSize, @fontWeight, @fontItalic, @fontAngle)
'	PRINT "  "; fontName$
'	PRINT "  "; fontSize / 20; "  Point"
'	PRINT "  "; fontWeight; "  Weight"
	IF fontItalic THEN PRINT "  Italic:  Yes" ELSE PRINT "  Italic:  No"
'	PRINT "  "; fontAngle / 10; "  Degrees"
'
	XuiSendMessage (xitGrid, #SetFontNumber, font, 0, 0, 0, -1, 0)		' All kids
	XuiSendMessage (xitGrid, #Resize, 0, 0, 0, 0, 0, 0)
	XuiSendMessage (xitGrid, #RedrawWindow, 0, 0, 0, 0, 0, 0)
	FOR i = 0 TO UBOUND(popupGrids[])
		grid = popupGrids[i]
		XuiSendMessage (grid, #SetFontNumber, font, 0, 0, 0, -1, 0)			' All kids
		XuiSendMessage (grid, #Resize, 0, 0, 0, 0, 0, 0)
		XuiSendMessage (grid, #RedrawWindow, 0, 0, 0, 0, 0, 0)
	NEXT i
END FUNCTION
'
'
' ################################
' #####  ClearForCompile ()  #####
' ################################
'
FUNCTION  ClearForCompile ()
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN prog[]
	SHARED  lineAddr[]
	SHARED  lineCode@@[]
	SHARED  lineUpper[]
	SHARED  lineLast[]
	SHARED  funcFirstAddr[]
	SHARED  funcAfterAddr[]
'
	ufunc = maxFuncNumber + 1			' last is for END PROGRAM
	DIM funcFirstAddr[ufunc]			' clear first-address in function array
	DIM funcAfterAddr[ufunc]			' clear after-address in function array
	DIM lineUpper[ufunc]					' clear upper bounds of lineaddr[]
	DIM lineLast[ufunc]						' clear next line # to compile in each func
	DIM lineAddr[ufunc,]					' addresses of lines in program
	DIM lineCode@@[ufunc,]					' 1st opcodes of lines in program
'
	uLine = 15
	funcNumber = 0
	DO UNTIL (funcNumber > ufunc)
		dimArrays = $$FALSE
		IF (funcNumber = ufunc) THEN
			dimArrays = $$TRUE
		ELSE
			IF prog[funcNumber,] THEN dimArrays = $$TRUE	' only dim defined functions
		END IF
		IF dimArrays THEN
			ATTACH lineAddr[funcNumber,] TO tempAddr[]
			ATTACH lineCode@@[funcNumber,] TO tempCode@@[]
			DIM tempAddr[uLine]						' clear addresses of all lines in pgm
			DIM tempCode@@[uLine]						' clear 1st opcodes of all lines in pgm
			ATTACH tempAddr[] TO lineAddr[funcNumber,]
			ATTACH tempCode@@[] TO lineCode@@[funcNumber,]
		END IF
		lineUpper[funcNumber] = uLine
		lineLast[funcNumber]  = 0
		INC funcNumber
	LOOP
END FUNCTION
'
'
' ################################
' #####  CompileAssembly ()  #####
' ################################
'
FUNCTION  CompileAssembly ()
	EXTERNAL /xxx/  i486asm,  i486bin,  maxFuncNumber,  entryFunction,  errorCount
	EXTERNAL /xxx/  checkBounds,  library
	TOKEN   func[]
	TOKEN   tok[]
	TOKEN   token
	SHARED  TOKEN prog[]
	SHARED  funcCursorPosition[],  errorFunc[],  errorRawPtr[]
	SHARED  xitGrid,  editFunction,  priorFunction,  fileType
	SHARED  errorBox,  editFile$
	SHARED  programAltered,  softInterrupt
	SHARED  currentCursor
'
	entryCursor = currentCursor
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN	 ' blowback before assembly
		AddDispatch (&RunAssembler(), 0)
		XxxSetBlowback ()
		RETURN
	END IF
'
	IF (fileType != $$Program) THEN
		Message ("[CompileAssembly( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF (LCASE$(RIGHT$(editFile$, 2)) != ".x") THEN
		Message ("[CompileAssembly( )]\n Filename must end with .x ")
		PRINT editFile$
		EXIT FUNCTION
	END IF
'
	softInterrupt = $$FALSE
	SetCurrentStatus ($$StatusAssembling, 0)
	IF softInterrupt THEN
		Message ("[CompileAssembly( )]\n Compilation aborted ")
		EXIT FUNCTION
	END IF
'
	redisplay = $$TRUE
	reportBogusRename = $$TRUE								' tokenize, set BPs (as necessary)
	RestoreTextToProg (redisplay, reportBogusRename)
'
'	Clear any error codes from the tokens
'
	ClearErrors ()
'
	IFZ entryFunction THEN
		Message ("[CompileAssembly( )]\n No entry function declared ")
		EXIT FUNCTION
	END IF
	IFZ prog[entryFunction,] THEN
		Message ("[CompileAssembly( )]\n Entry function not defined ")
		EXIT FUNCTION
	END IF
'	SetCursor ($$CursorWait)
'
' By assembling, the user is forced to recompile before running
'
	IFZ programAltered THEN
		programAltered = $$TRUE
		ResetDataDisplays ($$ResetAssembly)
	END IF
'
	bounds = checkBounds
	i486asm = $$TRUE
	i486bin = $$FALSE
	checkBounds = $$FALSE
'
'	PRINT "CompileAssembly(75):checkBounds", checkBounds
	XxxInitVariablesPass1 ()	' initialize variables in preparation for compilation
	XxxCompilePrep ()					' clear DECLARE and DEFINED bits in all function tokens
	BreakClearArrays()				' clear breakAddr[] and breakCode[]
	ClearForCompile()					' clear lineAddr[], lineCode@@[], etc...
'
	programName$ = RCLIP$(editFile$, 2)
	XxxSetProgramName (@programName$)
	programName$ = ""
	error = XxxCreateCompileFiles()
	IF error THEN
		PRINT "CompileAssembly():Unable to create compile files"
		RETURN
	END IF
'
	ATTACH prog[0,] TO func[]
	uLine = UBOUND(func[])
'
	DO
		ATTACH func[line,] TO tok[]
		toks = tok[0].ti.ndex
		INC pline
		asm$		= ""
		IF (toks > 1) THEN
			tokPtr	= 1
			IF NextXitToken(@tok[], @tokPtr, toks, @token) THEN
				IF (token.tp.kind != $$KIND_COMMENTS) THEN
					CompileLine (0, line, @tok[])
				END IF
			END IF
		END IF
'
		ATTACH tok[] TO func[line,]
		INC line
		SELECT CASE FALSE
			CASE (line AND 0x3FF):	SetCurrentStatus ($$StatusAssembling, line)
		END SELECT
		IF softInterrupt THEN
			ATTACH func[] TO prog[0,]
			IF (errorCount > 255) THEN
				Message ("[CompileAssembly( )]\n Compilation aborted \n\n too many errors ")
			ELSE
				Message ("[CompileAssembly( )]\n Compilation aborted ")
			END IF
			IF errorCount THEN GOTO ShowFirstError
			checkBounds = bounds
			EXIT FUNCTION
		END IF
	LOOP UNTIL (line > uLine)
	ATTACH func[] TO prog[0,]
	lineCount = uLine
'
	func = 1
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO
		ATTACH prog[func,] TO func[]
		uLine = UBOUND(func[])
		line = 0
		DO
			ATTACH func[line,] TO tok[]
			toks = tok[0].ti.ndex
			INC pline
			IF (toks > 1) THEN
				tokPtr = 1
				IF NextXitToken(@tok[], @tokPtr, toks, @token) THEN
					IF (token.tp.kind != $$KIND_COMMENTS) THEN
						CompileLine (func, line, @tok[])
					END IF
				END IF
			END IF
			ATTACH tok[] TO func[line,]
			INC line
			INC lineCount
			SELECT CASE FALSE
				CASE (lineCount AND 0x3FF):	SetCurrentStatus ($$StatusAssembling, lineCount)		' Update 1024
			END SELECT
			IF softInterrupt THEN
				ATTACH func[] TO prog[func,]
				IF (errorCount > 255) THEN
					Message ("[CompileAssembly( )]\n Compilation aborted \n\n too many errors ")
				ELSE
					Message ("[CompileAssembly( )]\n Compilation aborted ")
				END IF
				IF errorCount THEN GOTO ShowFirstError
				EXIT FUNCTION
			END IF
		LOOP UNTIL (line > uLine)
		ATTACH func[] TO prog[func,]
		INC func
	LOOP
	INC pline
	XxxParseSourceLine ("END PROGRAM", @tok[])
	CompileLine (maxFuncNumber + 1, 0, @tok[])
	Message ("[CompileAssembly( )]\n Encountered " + STRING$(errorCount) + " errors ")
	IF errorCount THEN GOTO ShowFirstError
'
	checkBounds = bounds
	RETURN
'
ShowFirstError:
	IF (errorFunc[1] != -2) THEN							' 1st is not Pass2
		priorFunction	= editFunction
		editFunction	= errorFunc[1]
		errorPos			= errorRawPtr[1]
		ATTACH prog[editFunction,] TO func[]			' huh???
		numLines = UBOUND(func[])
		FOR i = 0 TO numLines
			IF (func[i,0].ti.errno = 1) THEN
				errorLine = i
				EXIT FOR
			END IF
		NEXT i
		ATTACH func[] TO prog[editFunction,]
'
'		Deparse to display the error codes
'
		TokenArrayToText (editFunction, @text$[])
		XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, errorPos, errorLine, -1, -1, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
		funcCursorPosition[editFunction, 0] = cursorLine
		funcCursorPosition[editFunction, 1] = cursorPos
		funcCursorPosition[editFunction, 2] = topLine
		funcCursorPosition[editFunction, 3] = topIndent
		funcCursorPosition[editFunction, 4] = xCursor
		funcCursorPosition[editFunction, 5] = yCursor
		UpdateFileFuncLabels (0, $$TRUE)					' Reset function name
	END IF
	WizardCompErrors (errorBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	checkBounds = bounds
	RETURN (errorCount)
END FUNCTION
'
'
' ###############################
' #####  CompileProgram ()  #####
' ###############################
'
' Returns $$FALSE if no errors, else $$TRUE or # of errors
'
FUNCTION  CompileProgram ()
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##UCODE0,  ##UCODE,  ##UCODEX,  ##UCODEZ
	EXTERNAL /xxx/  i486asm,  i486bin,  maxFuncNumber,  entryFunction,  errorCount
	EXTERNAL /xxx/  checkBounds,  xpc
	EXTERNAL /xxx/	needMoreMemory
	TOKEN   func[]
	TOKEN   tok[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[],  funcBPAltered[],  funcNeedsTokenizing[]
	SHARED  funcCursorPosition[],  errorFunc[],  errorRawPtr[]
	SHARED  xitGrid,  editFunction,  priorFunction,  fileType
	SHARED  programAltered,  breakpointsAltered
	SHARED  softInterrupt,  codeSpaceResized,  errorBox
	SHARED  compiledCheckBounds
	SHARED  currentCursor
	SHARED  endProgram$[]
	SHARED  editFile$
	SHARED  resetCodeSize
	SHARED  progTotalLines
	SHARED  totalLines
	SHARED  stopCompOnErr
	STATIC  xpcFinish
'
	IF ##XBDV THEN
		prg$ = RIGHT$(editFile$, 5)
		SELECT CASE prg$
			CASE "xit.x", "xgr.x", "xst.x", "xui.x" :
						Message ("[CompileProgram( )]\n Not allowed for \n XBasic source file ")
						RETURN ($$TRUE)
		END SELECT
	END IF
'
	entryCursor = currentCursor
'
' Make sure editFile is a source program... must have ".x" suffix
'
	IF (fileType != $$Program) THEN
		Message ("[CompileProgram( )]\n No program loaded ")
		RETURN ($$TRUE)
	END IF
'
	redisplay = $$TRUE
	reportBogusRename = $$TRUE							' Retokenizes, sets BPs, if necessary
	RestoreTextToProg(redisplay, reportBogusRename)
'
	IFZ entryFunction THEN
		Message ("[CompileProgram( )]\n No entry function declared ")
		RETURN ($$TRUE)
	END IF
	IFZ prog[entryFunction,] THEN
		Message ("[CompileProgram( )]\n Entry function not defined ")
		RETURN ($$TRUE)
	END IF
	IFZ programAltered THEN
		IF (checkBounds = compiledCheckBounds) THEN RETURN ($$FALSE)
	END IF
'
'	Grab required amount of memory
'		Allocate memory size based on number of lines:
'			xx6e.x:  26548 lines
'				normal compilation:		0x98470 = 623728. bytes -->  24 bytes/line
'		Round up to 500Kb boundary (0x80000)
'
'	bytesPerLine = 25                                      '*cw* 230214-
	bytesPerLine = 30                                      '*cw* 230214+
	IF checkBounds THEN bytesPerLine = bytesPerLine + 40
	totalLines = 0
	FOR func = 0 TO maxFuncNumber
		IFZ prog[func,] THEN DO NEXT
		totalLines = totalLines + UBOUND(prog[func,]) + 1
	NEXT func
	FOR func = 0 TO maxFuncNumber
		IFZ prog[func,] THEN DO NEXT
	NEXT func
'
	progTotalLines = totalLines
	AddCommandItem (" compiling " + STRING$(totalLines) + " lines ")
'
'
' If compiling a new program, use the calculated size.
' If this program has been compiled successfully before
' use the actual memory used round up to the to 250KB
'
	IF resetCodeSize THEN xpcFinish = 0  ' recalculate code size
'
	IF xpcFinish THEN
		codeSize = (xpcFinish - ##UCODE0 + 0x40000) AND 0xFFFC0000
	ELSE
		codeSize = totalLines * bytesPerLine
		IF (codeSize < 0x80000) THEN
			codeSize = 0x80000
		ELSE
			codeSize = (codeSize + 0x80000) AND 0xFFF80000
		END IF
	END IF
'
	addr = ##UCODE0
	codeSize = codeSize AND 0xFFFF0000
	currentCodeSize = ##UCODEZ - ##UCODE0
	codeDiff = currentCodeSize - codeSize
'
	IF ((codeDiff < 0) OR (codeDiff > 0x80000)) THEN
		SharedMemory ($$MemoryDestroy, addr, currentCodeSize, 0)
		SharedMemory ($$MemoryCreate, @addr, @codeSize, $$OwnerReadWriteExecute)
		IFZ addr THEN
			PRINT "CompileProgram() : could not allocate code space : abort compile"
			RETURN ($$TRUE)
		END IF
	END IF
	##UCODE0 = addr
	##UCODEZ = addr + codeSize
'
'	SetCursor ($$CursorWait)
	status = $$StatusCompiling
'
startCompilation:
	codeSpaceResized = $$FALSE
'
'	Clear any error codes from the tokens
'
	ClearErrors ()
	softInterrupt = $$FALSE
	SetCurrentStatus (status, 0)
	IF softInterrupt THEN
		Message ("[CompileProgram( 123 )]\n compile aborted ")
		RETURN ($$TRUE)
	END IF
'
	i486asm = $$FALSE
	i486bin = $$TRUE
'
	XxxInitVariablesPass1 ()	' initialize variables in preparation for compilation
	XxxCompilePrep ()					' clear DECLARE and DEFINED bits in all function tokens
	BreakClearArrays()				' clear breakAddr[] and breakCode[]
	ClearForCompile()					' clear lineAddr[], lineCode@@[], etc...
'
	IF editFile$ THEN
		programName$ = RCLIP$ (editFile$, 2)
		XxxSetProgramName (programName$)
		programName$ = ""
	END IF
'
'	do Pass 1 on PROLOG
'
	ATTACH prog[0,] TO func[]
	uLine = UBOUND(func[])
	line = 0
	DO
		ATTACH func[line,] TO tok[]
		CompileLine (0, line, @tok[])
		ATTACH tok[] TO func[line,]
		IF codeSpaceResized THEN						' start over if code space resized
			ATTACH func[] TO prog[0,]
			status = $$StatusRecompiling
			GOTO startCompilation
		END IF
		INC line
		SELECT CASE FALSE
			CASE (line AND 0x3FF):	SetCurrentStatus (status, line)		' Update 1024
		END SELECT
		IF softInterrupt THEN
			ATTACH func[] TO prog[0,]
			IF (errorCount > 255) THEN
				Message ("[CompileProgram( )]\n Compilation aborted \n\n too many errors ")
			ELSE
				Message ("[CompileProgram( 164 )]\n Compilation aborted ")
			END IF
			IF errorCount THEN GOTO ShowFirstError
'			SetCursor (entryCursor)
			RETURN ($$TRUE)
		END IF
	LOOP UNTIL (line > uLine)
	ATTACH func[] TO prog[0,]
	totalLines = uLine
'
	ATTACH prog[entryFunction,] TO func[]		' Make entry function first in memory
	uLine = UBOUND(func[])
	line = 0
	DO
		ATTACH func[line,] TO tok[]
'		IFZ tok[] THEN INC line : INC totalLines : DO LOOP
		CompileLine (entryFunction, line, @tok[])
		ATTACH tok[] TO func[line,]
		IF codeSpaceResized THEN						' start over if code space resized
			ATTACH func[] TO prog[entryFunction,]
			status = $$StatusRecompiling
			GOTO startCompilation
		END IF
		INC line
		INC totalLines
'		PRINT (200) line
		IF (line = 61) THEN ##cw = 7  '*cw* testing ***********************************************
		IF (line > 63) THEN ##cw = 0  '*cw* testing ***********************************************
		SELECT CASE FALSE
			CASE (totalLines AND 0x3FF):	SetCurrentStatus (status, totalLines)		' Update 1024
		END SELECT
		IF softInterrupt THEN
			ATTACH func[] TO prog[entryFunction,]
			IF (errorCount > 255) THEN
				Message ("[CompileProgram( )]\n Compilation aborted \n\n too many errors ")
			ELSE
				Message ("[CompileProgram( 198 )]\n Compilation aborted ")
			END IF
			IF errorCount THEN GOTO ShowFirstError
			RETURN ($$TRUE)
		END IF
	LOOP UNTIL (line > uLine)
	ATTACH func[] TO prog[entryFunction,]
'
	IF errorCount THEN
		IF stopCompOnErr THEN
			softInterrupt = $$TRUE
			GOTO ShowFirstError
		END IF
	END IF
'
	func = 1
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO						' Skip empty slots
		IF (func = entryFunction) THEN INC func: DO DO	' entryFunction already done
'
		ATTACH prog[func,] TO func[]
		uLine = UBOUND(func[])
		line = 0
		DO UNTIL (line > uLine)
			ATTACH func[line,] TO tok[]
'			IFZ tok[] THEN INC line : INC totalLines : DO LOOP
			CompileLine (func, line, @tok[])
			ATTACH tok[] TO func[line,]
			IF codeSpaceResized THEN						' start over if code space resized
				ATTACH func[] TO prog[func,]
				status = $$StatusRecompiling
				GOTO startCompilation
			END IF
			INC line
			INC totalLines
			SELECT CASE FALSE
				CASE (totalLines AND 0x3FF):	SetCurrentStatus (status, totalLines)		' Update 1024
			END SELECT
			IF softInterrupt THEN
				ATTACH func[] TO prog[func,]
				IF (errorCount > 255) THEN
					Message ("[CompileProgram( )]\n Compilation aborted \n\n too many errors ")
				ELSE
					Message ("[CompileProgram( 236 )]\n Compilation aborted ")
				END IF
				IF errorCount THEN GOTO ShowFirstError
				RETURN ($$TRUE)
			END IF
		LOOP
		ATTACH func[] TO prog[func,]
'
		IF errorCount THEN
			IF stopCompOnErr THEN
				softInterrupt = $$TRUE
				GOTO ShowFirstError
			END IF
		END IF
'
		INC func
	LOOP
	XxxParseSourceLine ("END PROGRAM", @tok[])
	CompileLine (maxFuncNumber + 1, 0, @tok[])
	IF codeSpaceResized THEN						' start over if code space resized
		status = $$StatusRecompiling
		DIM tok[]
		GOTO startCompilation
	END IF
	LoadLineCodeArray ()
'
	AddCommandItem (" encountered " + STRING$(errorCount) + " errors ")
'
	IF errorCount THEN GOTO ShowFirstError
'
	xpcFinish = xpc           ' used to calculate actual of memory if compiled again
	resetCodeSize = $$FALSE   ' no neede to estimate code size
	programAltered = $$FALSE
	SetCurrentStatus ($$StatusCompiled, 0)
	DIM endProgram$[]
	IF checkBounds THEN
		compiledCheckBounds = $$TRUE
	ELSE
		compiledCheckBounds = $$FALSE
	END IF
	breakpointsAltered = $$FALSE
	func = 0
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO
		funcAltered[func] = $$FALSE
		funcBPAltered[func] = $$FALSE
		funcNeedsTokenizing[func] = $$FALSE
		INC func
	LOOP
'
	ResetDataDisplays ($$ResetAssembly)
	AddCommandItem (" compiled " + STRING$(totalLines) + " lines -> " + STRING$(xpc - ##UCODE) + " bytes ")
	RETURN ($$FALSE)
'
ShowFirstError:
	IF (errorFunc[1] != -2) THEN							' 1st is not Pass2
		priorFunction	= editFunction
		editFunction	= errorFunc[1]
		errorPos			= errorRawPtr[1]
		ATTACH prog[editFunction,] TO func[]			' huh???
		numLines = UBOUND(func[])
		FOR i = 0 TO numLines
			IF (func[i,0].ti.errno = 1) THEN
				errorLine = i
				EXIT FOR
			END IF
		NEXT i
		ATTACH func[] TO prog[editFunction,]
'
'		Deparse to display the error codes
'
		TokenArrayToText (editFunction, @text$[])
		XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, errorPos, errorLine, -1, -1, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
		funcCursorPosition[editFunction, 0] = cursorLine
		funcCursorPosition[editFunction, 1] = cursorPos
		funcCursorPosition[editFunction, 2] = topLine
		funcCursorPosition[editFunction, 3] = topIndent
		funcCursorPosition[editFunction, 4] = xCursor
		funcCursorPosition[editFunction, 5] = yCursor

		UpdateFileFuncLabels (0, $$TRUE)					' Reset function name
	END IF
'
'	SetCursor (entryCursor)
	WizardCompErrors (errorBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
	RETURN (errorCount)

END FUNCTION
'
'
' #############################
' #####  RunAssembler ()  #####
' #############################
'
FUNCTION  RunAssembler ()
	EXTERNAL /xxx/  library
	EXTERNAL /xxx/  runAssm
	SHARED  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[RunAssembler( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		Message ("[RunAssembler( )]\n Program is running ")
		EXIT FUNCTION
	END IF
'
	XxxXgrSysMessages ()                       ' process system messages
'
' When a user program is compiled in PDE, the compiler inserts calls
' to XxxCheckMessages_0, but not when compiled for standalone.
' Setting runAssm to $$TRUE causes them to be put in standalone also.
'
	runAssm = $$TRUE
	library = $$FALSE
	CompileAssembly ()
END FUNCTION
'
'
' ############################
' #####  RunContinue ()  #####
' ############################
'
FUNCTION  RunContinue ()
	SHARED  userContinue,  userStepType,  exitMainLoop
	SHARED  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[RunContinue( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	SELECT CASE TRUE
		CASE (##USERRUNNING AND ##SIGNALACTIVE)
				userStepType = $$BreakContinueRunning
				userContinue = $$TRUE
				exitMainLoop = $$TRUE
		CASE ##USERRUNNING
'				Message ("[RunContinue( )]\n Program already running ")
		CASE ELSE
				Message ("[RunContinue( )]\n Program not started ")
	END SELECT
END FUNCTION
'
'
' ########################
' #####  RunJump ()  #####
' ########################
'
'	Set execution address at text cursor line.
'
FUNCTION  RunJump ()
	SHARED  lineAddr[],  lineLast[]
	SHARED  exeFunction,  exeLine,  editFunction
	SHARED  fileType,  xitGrid
	SHARED  CPUCONTEXT  cpu
'
	IF (fileType != $$Program) THEN
		Message ("[RunJump( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	SELECT CASE TRUE
		CASE (##USERRUNNING AND ##SIGNALACTIVE)
				IF (editFunction != exeFunction) THEN
					Message ("[RunJump( )]\n Cannot jump outside currently executing function ")
					RETURN
				END IF
				IF (exeFunction > UBOUND(lineLast[])) THEN
					Message ("[RunJump( )]\n Invalid function number (internal error) ")
					RETURN
				END IF
				XuiSendMessage (xitGrid, #GetTextCursor, 0, @cursorLine, 0, 0, $$xitTextLower, 0)
				IF (cursorLine > lineLast[exeFunction]) THEN
					Message ("[RunJump( )]\n Invalid line number ")
					RETURN
				END IF
'210618-				cpu.rip = lineAddr[exeFunction, cursorLine]
				exeLine = cursorLine
				TokenArrayToText (exeFunction, @text$[])			' move '>'
				XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
				XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		CASE ##USERRUNNING
				Message ("[RunJump( )]\n Program currently running ")
		CASE ELSE
				Message ("[RunJump( )]\n Program not running ")
	END SELECT
END FUNCTION
'
'
' ########################
' #####  RunKill ()  #####
' ########################
'
FUNCTION  RunKill ()
	SHARED  blowback,  exitMainLoop,  fileType
	SHARED  haltedByEdit
'
	IF (fileType != $$Program) THEN
		Message ("[RunKill( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF ##USERRUNNING THEN
		IF ##SIGNALACTIVE THEN
			##USERWAITING = $$FALSE			' unblock waiting in INLINE$()
			##USERABORT = $$TRUE        ' unblock waiting in XstFindFiles
			##SOFTBREAK = $$TRUE
		ELSE
			##USERWAITING = $$FALSE			' unblock waiting in INLINE$()
			##USERABORT = $$TRUE        ' unblock waiting in XstFindFiles
			AddDispatch (&RunKill(), 0)
			XitSoftBreak()
			haltedByEdit = $$TRUE       ' do not change edit display
			RETURN
		END IF
		exitMainLoop = $$TRUE
		blowback = $$TRUE
	END IF
END FUNCTION
'
'
' ###########################
' #####  RunLibrary ()  #####
' ###########################
'
FUNCTION  RunLibrary ()
	EXTERNAL /xxx/  library
	SHARED  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[RunLibrary( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		Message ("[RunLibrary( )]\n Program is running ")
		EXIT FUNCTION
	END IF
'
	XxxXgrSysMessages ()                       ' process system messages
'
	library = $$TRUE
	CompileAssembly ()
	library = $$FALSE
END FUNCTION
'
'
' ########################
' #####  RunMake ()  #####
' ########################
'
FUNCTION  RunMake ()
	SHARED  fileType
	SHARED  editFile$
'
	IF (fileType != $$Program) THEN
		Message ("[RunMake( )]\n No program loaded ")
		RETURN
	END IF
'
	XstGetPathComponents (editFile$, @path$, @drive$, @dir$, @fileName$, @attributes)
	IF (LCASE$(RIGHT$(fileName$, 2)) != ".x") THEN
		Message ("[RunMake( )]\n Filename must end with .x ")
		RETURN
	END IF
	fileName$ = RCLIP$(fileName$, 2) + ".mak"
	error = XstGetFileAttributes (editFile$, @attributes)
	IFZ (attributes AND ($$FileNormal OR $$FileReadOnly)) THEN
		Message ("[RunMake( )]\n " + fileName$ + "\n does not exist ")
		RETURN
	END IF
	SHELL ("cd " + path$ + " ; make -f " + fileName$ + " > mak.log")
	XstLoadString (path$ + "mak.log", @maklog$)
	PRINT maklog$;
'
END FUNCTION
'
'
' #########################
' #####  RunPause ()  #####
' #########################
'
FUNCTION  RunPause ()
	SHARED  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[RunPause( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	XitSoftBreak ()
END FUNCTION
'
'
' #############################
' #####  RunRecompile ()  #####
' #############################
'
FUNCTION  RunRecompile ()
	SHARED  programAltered
	SHARED  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[RunRecompile( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF (##USERRUNNING OR ##SIGNALACTIVE) THEN
		Message ("[RunRecompile( )]\n Program already compiled \n and is running ")
		EXIT FUNCTION
	END IF
'
	programAltered = $$TRUE                    ' force recompilation
	CompileProgram ()
'
END FUNCTION
'
'
' ##############################
' #####  RunStandalone ()  #####
' ##############################
'
FUNCTION  RunStandalone ()
	SHARED  fileType
	SHARED  editFile$
'
	IF (fileType != $$Program) THEN
		Message ("[RunStandalone( )]\n No program loaded ")
		RETURN
	END IF
'
	XstGetPathComponents (editFile$, @path$, @drive$, @dir$, @fileName$, @attributes)
	IF (LCASE$(RIGHT$(fileName$, 2)) != ".x") THEN
		Message ("[RunStandalone( )]\n Filename must end with .x ")
		RETURN
	END IF
	fileName$ = RCLIP$(fileName$, 2)
	error = XstGetFileAttributes (path$ + fileName$, @attributes)
	IFZ (attributes AND $$FileExecutable) THEN
		Message ("[RunStandalone( )]\n " + fileName$ + "\n does not exist ")
		RETURN
	END IF
'
	IFZ (attributes AND $$FileExecutable) THEN
		Message ("[RunStandalone( )]\n " + fileName$ + "\n is not executable ")
		RETURN
	END IF
'
	SHELL ("cd " + path$ + " ; ./" + fileName$ + " &")  ' run in background
'
END FUNCTION
'
'
' #########################
' #####  RunStart ()  #####
' #########################
'
'	Start execution of a PROGRAM
'
'	In:				none
'	Out:			none
'	Return:		none
'
FUNCTION  RunStart ()
	SHARED  blowback,  userRun,  exitMainLoop
	SHARED  fileType,  xitGrid
	SHARED  userStepType
'
	XxxXgrSysMessages ()                     ' process system messages
'
	IF (fileType != $$Program) THEN
		Message ("[RunStart( )]\n No program loaded ")
		RETURN
	END IF
'
	IF ##USERRUNNING THEN
		message$ = " RunStart() \n\n program already started "
		warningResponse = WarningResponse (@message$, @"Restart", @"")
		IF (warningResponse == $$WarningCancel) THEN RETURN
	END IF
'
	SELECT CASE TRUE
		CASE (##USERRUNNING AND (NOT ##SIGNALACTIVE))
					XitSoftBreak()
					blowback = $$TRUE
		CASE ##SIGNALACTIVE
					##SOFTBREAK = $$TRUE			' used in SYSTEMCALLs
					blowback = $$TRUE
	END SELECT
'
	userStepType = $$BreakContinueRunning
	userRun				= $$TRUE
	exitMainLoop	= $$TRUE
'
'	Turn off GuiDesigner
'
	XxxGuiDesignerOnOff (0)
	XuiSendMessage (xitGrid, #SetValues, 0, 0, 0, 0, 21, 0)
END FUNCTION
'
'
' ###########################
' #####  BPTraceOff ()  #####
' ###########################
'
FUNCTION  BPTraceOff ()
	SHARED  traceActive

	traceActive = $$FALSE

END FUNCTION
'
'
' ##########################
' #####  BPTraceOn ()  #####
' ##########################
'
FUNCTION  BPTraceOn ()
	SHARED  traceActive
	SHARED  currentStatus

	traceActive = $$TRUE
	IF (currentStatus == $$StatusPaused) THEN UpdateFrames ()

END FUNCTION
'
'
' ############################
' #####  DebugToggle ()  #####
' ############################
'
'	Program mode only
'
FUNCTION  DebugToggle ()
	SHARED  TOKEN prog[]
	SHARED  lineAddr[]
	SHARED  funcBPAltered[]
	SHARED  editFunction,  xitGrid,  breakpointsAltered
	SHARED  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[DebugToggleBreakpoint( )]\n No program loaded ")
		RETURN
	END IF
	IFZ prog[] THEN
		Message ("[DebugToggleBreakpoint( )]\n No program loaded ")
		RETURN
	END IF
	IFZ editFunction THEN
		Message ("[DebugToggleBreakpoint( )]\n Breakpoints invalid in PROLOG ")
		RETURN
	END IF
'
	XxxFunctionName ($$XGET, @funcName$, editFunction)
	IF (funcName$ == "Blowback") THEN
		Message ("[DebugToggleBreakpoint( )]\n Breakpoints invalid in Blowback ")
		RETURN
	END IF
'
	XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #GetTextCursor, 0, @cursorLine, 0, 0, $$xitTextLower, 0)
	IFZ text$[] THEN
		Message ("[DebugToggle( )]\n Empty function ")
		EXIT FUNCTION
	END IF
	text$ = text$[cursorLine]
'
	linePos = 0
	lenLine = LEN(text$)
	IFZ lenLine THEN
		text$[cursorLine] = ":"
		BPOn = $$TRUE
	ELSE
		cchar = text${0}
		SELECT CASE TRUE
			CASE (('0' <= cchar) AND (cchar <= '9'))				' errorCode
				linePos = 3
			CASE (cchar = '>')
				linePos = 1
		END SELECT
		IF (linePos < lenLine) THEN
			IF (text${linePos} = ':') THEN
				BPOn = $$FALSE
				text$[cursorLine] = LEFT$(text$, linePos) + MID$(text$, linePos + 2)
			ELSE
				BPOn = $$TRUE
				text$[cursorLine] = LEFT$(text$, linePos) + ":" + MID$(text$, linePos + 1)
			END IF
		END IF
	END IF
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	breakpointsAltered = $$TRUE
	funcBPAltered[editFunction] = $$TRUE
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN	' Add BP on the fly...
		lineAddr = lineAddr[editFunction, cursorLine]
'		MakeUserCodeRW ()																' NT/SCO : not required
		IF BPOn THEN
			IF BreakProgrammer ($$BreakSetOne, lineAddr, 0) THEN
				UBYTEAT (lineAddr) = $$Breakpoint
			END IF
		ELSE
			BreakProgrammer ($$BreakClearOne, lineAddr, 0)
		END IF
'		MakeUserCodeRX ()																' NT: Not required
	END IF
END FUNCTION
'
'
' ###########################
' #####  DebugClear ()  #####
' ###########################
'
'	Program mode only
'
FUNCTION  DebugClear ()
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	SHARED  TOKEN prog[]
	SHARED  funcBPAltered[]
	SHARED  editFunction,  xitGrid
	SHARED  breakpointsAltered,  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[DebugClearBreakpoints( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IFZ prog[] THEN
		Message ("[DebugClearBreakpoints( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	funcNumber = 0
	DO UNTIL (funcNumber > maxFuncNumber)
		IFZ prog[funcNumber,] THEN INC funcNumber: DO DO
		ATTACH prog[funcNumber,] TO func[]			' clear token arrays
		uLine = UBOUND(func[])
		line = 0
		DO UNTIL (line > uLine)
			bpexe = func[line, 0].ti.bpexe
			IF (bpexe AND $$BP) THEN
				func[line, 0].ti.bpexe = bpexe AND $$EXE   'clear BP, preserve EXE
				breakpointsAltered = $$TRUE
				funcBPAltered[funcNumber] = $$TRUE
			END IF
			INC line
		LOOP
		ATTACH func[] TO prog[funcNumber,]
'
		IF (funcNumber = editFunction) THEN			' clear editFunction text
			XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			IFZ text$[] THEN
				INC funcNumber
				DO DO
			END IF
'
			FOR line = 0 TO UBOUND(text$[])
				IFZ text$[line] THEN DO NEXT
				linePos = 0
				lenLine = LEN(text$[line])
				cchar = text$[line]{0}
				SELECT CASE TRUE
					CASE (('0' <= cchar) AND (cchar <= '9'))				' errorCode
						linePos = 3
					CASE (cchar = '>')
						linePos = 1
				END SELECT
				IF (linePos >= lenLine) THEN DO NEXT
				IF (text$[line]{linePos} != ':') THEN DO NEXT			' no BP
				text$[line] = LEFT$(text$[line], linePos) + MID$(text$[line], linePos + 2)
'
				breakpointsAltered = $$TRUE
				funcBPAltered[editFunction] = $$TRUE
			NEXT line
			XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		END IF
		INC funcNumber
	LOOP
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN		' Remove BPs on the fly...
'		MakeUserCodeRW ()																	' NT: Not required
		BreakProgrammer ($$BreakClearAll, 0, 0)
'		MakeUserCodeRX ()																	' NT: Not required
	END IF
END FUNCTION
'
'
' ###########################
' #####  DebugErase ()  #####
' ###########################
'
'	Program mode only
' Clear breakpoints in editFunction only
'
FUNCTION  DebugErase ()
	TOKEN   func[]
	SHARED  TOKEN prog[]
	SHARED  funcBPAltered[]
	SHARED  editFunction,  xitGrid
	SHARED  breakpointsAltered,  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[DebugEraseLocalBreakpoints( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IFZ prog[] THEN
		Message ("[DebugEraseLocalBreakpoints( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	ATTACH prog[editFunction,] TO func[]			' clear token arrays
	uLine = UBOUND(func[])
	line = 0
	DO UNTIL (line > uLine)
		bpexe = func[line, 0].ti.bpexe
		IF (bpexe AND $$BP) THEN
			func[line, 0].ti.bpexe = bpexe AND $$EXE   'clear BP, preserve EXE
			breakpointsAltered = $$TRUE
			funcBPAltered[funcNumber] = $$TRUE
			PRINT "DebugErase(36)", editFunction, line
		END IF
		INC line
	LOOP
	ATTACH func[] TO prog[editFunction,]
'
	XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	IFZ text$[] THEN RETURN
'
	FOR line = 0 TO UBOUND(text$[])
		IFZ text$[line] THEN DO NEXT
		linePos = 0
		lenLine = LEN(text$[line])
		cchar = text$[line]{0}
		SELECT CASE TRUE
			CASE (('0' <= cchar) AND (cchar <= '9'))				' errorCode
				linePos = 3
			CASE (cchar = '>')
				linePos = 1
		END SELECT
		IF (linePos >= lenLine) THEN DO NEXT
		IF (text$[line]{linePos} != ':') THEN DO NEXT			' no BP
		text$[line] = LEFT$(text$[line], linePos) + MID$(text$[line], linePos + 2)
'
		breakpointsAltered = $$TRUE
		funcBPAltered[editFunction] = $$TRUE
	NEXT line
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN		' Remove BPs on the fly...
'		MakeUserCodeRW ()																	' NT: Not required
		BreakProgrammer ($$BreakClearFunc, 0, editFunction)
'		MakeUserCodeRX ()																	' NT: Not required
	END IF
END FUNCTION
'
'
' ############################
' #####  DebugMemory ()  #####
' ############################
'
'	Debug Memory box
'
'	Discussion:
'		Clear       c             Display     d [<hexAddr> [<hexBytes>]]
'		Registers   r             Assembly    a [<hexAddr> [<hexBytes>]]
'		Memory Map  m             Fill        f <hexAddr> <hexBytes> <hexValue>
'		Locate      l <hexValue>  Substitute  s [<hexAddr>] <hexValue>
'
FUNCTION  DebugMemory (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
'	ULONG  ##UCODE0,  ##UCODE,  ##UCODEX,  ##UCODEZ
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
	STATIC  lastSubAddr
	STATIC  UBYTE charsetHexChar[]
'
	$textArea	= 1
	$textLine	= 2
	$button0	= 3
	$button1	= 4
'
	IFZ charsetHexChar[] THEN GOSUB Initialize
'
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Callback			: GOSUB Callback
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #Selection:			GOSUB Selection
	END SELECT
END SUB
'
'
' *****  Selection  *****  r0 = 1234 = TextArea/Command/Button01
'
SUB Selection
	SELECT CASE r0
		CASE $textLine, $button0
					IF (r0 = $textLine) THEN
						IF (v0{$$VirtualKey} = $$KeyEscape) THEN
							XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
							EXIT SUB
						END IF
					END IF
					XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $textLine, @command$)
					XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $textLine, "")
					XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textLine, 0)
					GOSUB ProcessCommand
		CASE $button1
					XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  ProcessCommand  *****
'
SUB ProcessCommand
	command$ = TRIM$(command$)
	IFZ command$ THEN EXIT SUB
'
	ParseLine$(command$, @args$[])
	IF (UBOUND(args$[]) < 6) THEN
		REDIM args$[6]
	END IF
'
	c$ = LCASE$(LEFT$(args$[0], 1))
	text$ = args$[0]
	arg1$ = args$[1]
	arg1 = MakeStringHex (@arg1$)
	arg2$ = args$[2]
	arg2 = MakeStringHex (@arg2$)
	arg3$ = args$[3]
	arg3 = MakeStringHex (@arg3$)
	IF arg1$ THEN text$ = text$ + " " + arg1$
	IF arg2$ THEN text$ = text$ + " " + arg2$
	IF arg3$ THEN text$ = text$ + " " + arg3$
'
	SELECT CASE	c$
		CASE "a":		text$ = text$ + "\n" + XxxAsm$ (arg1, arg2)
		CASE "c":		DIM text$[]
								XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @text$[])
								XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $textArea, 0)
								XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
								EXIT SUB
		CASE "d":		text$ = text$ + "\n" + Dump$ (arg1$, arg2$)
		CASE "x":		text$ = text$ + "\n" + DumpXlong$ (arg1$, arg2$)
		CASE "f":		error = Fill (arg1$, arg2$, arg3$)
								SELECT CASE error
									CASE  0
									CASE -1			: text$ = text$ + "\n  Byte value only (0 - 0xFF)"
									CASE ELSE		: text$ = text$ + "\n  Invalid address"
								END SELECT
		CASE "h":		t1$ = " Clear         c             Display       d [<hexAddr> [<hexBytes>]]\n"
								t2$ = " Registers     r             Assembly      a [<hexAddr> [<hexBytes>]]\n"
								t3$ = " Memory Map    m             Fill          f <hexAddr> <hexBytes> <hexValue>\n"
							'	t4$ = " Substitute    s <hexAddr>   Locate        l <hexValue>\n"
								t4$ = " Locate        l <hexValue>  Substitute    s [<hexAddr>] <hexValue>\n"
								t5$ = " DynoLinkCheck y             Display XLONG x [<hexAddr> [<hexBytes>]]\n"
								text$ = t1$ + t2$ + t3$ + t4$ + t5$
		CASE "l":		Locate (arg1$, @locate$[])
								XstStringArrayToString (@locate$[], @locate$)
								text$ = text$ + "\n" + locate$
		CASE "m":		text$ = MemoryMap$ ()
		CASE "r":		text$ = RegisterString$()
		CASE "s":		SELECT CASE TRUE
									CASE arg2$											' have both address and value
												addr = arg1
												value$ = TRIM$(UCASE$(arg2$))
									CASE arg1$
												addr = lastSubAddr + 1
												value$ = TRIM$(UCASE$(arg1$))
									CASE ELSE
												text$ = text$ + "  <<<   Syntax Error"
												EXIT SELECT 2
								END SELECT
'
								lastSubAddr = addr
								sectionAddr = AddressOk (addr)
								SELECT CASE sectionAddr
									CASE 0
'										text$ = text$ + "\n  ^^^  Invalid address:  " + HEX$(addr,8)  '*cw* 230306-
										text$ = text$ + "\n  ^^^  Invalid address:  " + HEX$(addr,9)  '*cw* 230306+
										EXIT SELECT 2
'
									CASE ##CODEZ
										text$ = text$ + "\n  ^^^  Cannot substitute in code space"
										EXIT SELECT 2
'
									CASE ##UCODEZ
										IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN
											text$ = text$ + "\n  ^^^  Cannot substitute in user space while running"
											EXIT SELECT 2
										END IF
								END SELECT
'
								lastChar = LEN(value$) - 1
								i = 0
								DO UNTIL (i > lastChar)
									oldValue = UBYTEAT(addr)
									c = value${i}:  INC i
									digit = charsetHexChar[c]
									IFZ digit THEN EXIT DO
									value = digit - '0'
									IF (i <= lastChar) THEN
										c = value${i}:  INC i
										digit = charsetHexChar[c]
										IF digit THEN
											value = (value << 4) + digit - '0'
										ELSE
											i = lastChar + 1				' Do this then exit
										END IF
									END IF
									UBYTEAT(addr) = value{8,0}
									newValue = UBYTEAT(addr)
									text$ = text$ + "\n" + HEX$(addr, 8) + ": " + HEX$(oldValue, 2) + " -> " + HEX$(newValue, 2)
									IF (newValue != value) THEN
										text$ = text$ + "\n    ^^^  Warning:  substitute failed!"
										EXIT DO
									END IF
									lastSubAddr = addr
									INC addr
								LOOP
		CASE "u":		text$ = text$ + "\n" + XxxAnyAsm$ (arg1, arg2)
		CASE "y":		DynoLinkCheck ()
		CASE ELSE:	text$ = text$ + "   <<<   Invalid command"
	END SELECT
'
'	Append new text
'
	XuiSendMessage (grid, #GrabTextArray, 0, 0, 0, 0, $textArea, @text$[])
	line = 0
	pos = 0
	cursorLine = 0
	IF text$[] THEN
		text$ = "\n" + text$
		line = UBOUND(text$[])
		pos = LEN(text$[line])
		cursorLine = line + 1
	END IF
	XuiSendMessage (grid, #PokeTextArray, 0, 0, 0, 0, $textArea, @text$[])
	XuiSendMessage (grid, #TextReplace, pos, line, pos, line, $textArea, @text$)
	XuiSendMessage (grid, #SetTextCursor, 0, cursorLine, 0, cursorLine, $textArea, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	DIM charsetHexChar[255]
	FOR i = '0' TO '9'
		charsetHexChar[i] = i									' 0-9
	NEXT i
	FOR i = 'A' TO 'F'
		charsetHexChar[i] = i - 'A' + 0x3A		' 10-15
	NEXT i
END SUB
END FUNCTION
'
'
' ##############################
' #####  DebugAssembly ()  #####
' ##############################
'
'	Debug Assembly box
'
FUNCTION  DebugAssembly (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1$[]))
	SHARED  xitGrid,  editFunction,  programAltered,  fileType
'
	$label		= 1
	$textArea	= 2
	$button0	= 3
	$button1	= 4
	$button2	= 5
	$button3	= 6
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****  v0 = justUpdate
'
SUB DisplayWindow
	command = 0
	GOSUB ProcessCommand
	IFZ v0 THEN XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, 1, 0)
END SUB
'
'
' *****  Selection  *****  r0 = 3456 = Button0123
'
SUB Selection
	SELECT CASE r0
		CASE $button0:	command = 1
										GOSUB ProcessCommand
		CASE $button1:	command = 0
										GOSUB ProcessCommand
		CASE $button2:	command = -1
										GOSUB ProcessCommand
		CASE $button3:	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE $textArea:
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
			ELSE
				command = 1
				GOSUB ProcessCommand
			END IF
	END SELECT
END SUB
'
'
' *****  ProcessCommand  *****
'
SUB ProcessCommand
	SELECT CASE TRUE
		CASE (fileType != $$Program)
				asm$ = "* Unavailable:  TEXT mode *"
				label$ = ""
		CASE programAltered
				asm$ = "* Unavailable:  Code requires compilation *"
				label$ = ""
		CASE ELSE
				XuiSendMessage (xitGrid, #GetTextArrayBounds, 0, 0, @lastPos, @lastLine, $$xitTextLower, 0)
				XuiSendMessage (xitGrid, #GetTextCursor, 0, @lineNumber, 0, 0, $$xitTextLower, 0)
				startLine = lineNumber
				SELECT CASE command
					CASE 1														' next
								INC lineNumber
								IF (lineNumber > lastLine) THEN lineNumber = lastLine
					CASE -1														' back
								DEC lineNumber
								IF (lineNumber < 0) THEN lineNumber = 0
				END SELECT
				IF (startLine != lineNumber) THEN		' Move text cursor to the new line
					XuiSendMessage (xitGrid, #SetTextCursor, 0, @lineNumber, -1, -1, $$xitTextLower, 0)
					XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
				END IF
				asm$ = AssemblyString$ (editFunction, lineNumber)
				XxxFunctionName ($$XGET, @funcName$, editFunction)
				IF (LEN(funcName$) > 26) THEN
					funcName$ = LEFT$(funcName$, 25) + "*"
				END IF
				label$ = "FUNCTION:  " + funcName$ + "  LINE:  " + STRING(lineNumber + 1)
	END SELECT
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $label, @label$)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $label, 0)
	XstStringToStringArray (@asm$, @asm$[])
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @asm$[])
	XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $textArea, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
END SUB
END FUNCTION
'
'
' ###############################
' #####  DebugRegisters ()  #####
' ###############################
'
FUNCTION  DebugRegisters (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1$[]))
	SHARED  lineAddr[]
	SHARED  fileType,  exeFunction,  exeLine
	SHARED  CPUCONTEXT  cpu
	SHARED  CPUCONTEXT  cpuOrig
'
	$label		= 1
	$textArea	= 2
	$textLine	= 3
	$button0	= 4
	$button1	= 5
	$button2	= 6
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****  v0 = justUpdate
'
SUB DisplayWindow
	IF (fileType = $$Program) THEN
		cpuOrig = cpu                   ' save original values for possible reset
		sxip = cpu.rip
		IF exeFunction THEN
			IF exeLine THEN
				IF (sxip = lineAddr[exeFunction, exeLine]) THEN
					XxxFunctionName ($$XGET, @funcName$, exeFunction)
					IF (LEN(funcName$) > 45) THEN
						funcName$ = LEFT$(funcName$, 44) + "*"
					END IF
					label$ = "FUNCTION:  " + funcName$ + "  LINE:  " + STRING(exeLine + 1)
				END IF
			END IF
		END IF
		IFZ label$ THEN
			label$ = "address = " + HEX$(sxip, 8) + "   (not interior function line boundary)"
		END IF
	ELSE
		label$ = "address = " + HEX$(sxip, 8)
	END IF
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $label, @label$)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $label, 0)
'
	reg$ = RegisterString$()
	XstStringToStringArray (@reg$, @reg$[])
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @reg$[])
	XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $textArea, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
	IFZ v0 THEN XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, 1, 0)
END SUB
'
'
' *****  Selection  *****  r0 = 3456 = Command/Button012
'
SUB Selection
	SELECT CASE r0
		CASE $button0:		GOSUB SetCommand
		CASE $button1:		GOSUB ResetCommand
		CASE $button2:		XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE $textLine:
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
			ELSE
				GOSUB SetCommand
			END IF
	END SELECT
END SUB
'
'
' *****  SetCommand  *****
'			SET reads the register text and assigns the register's new value.
'				Redisplay registers
'			RESET restores all registers to initial values.
'
SUB SetCommand
	IFZ ((fileType = $$Program) AND (##USERRUNNING AND ##SIGNALACTIVE)) THEN
		ResetDataDisplays (0)
		temp$ = "program not active : cannot alter registers"
		XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $textLine, @temp$)
		XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textLine, 0)
		EXIT SUB
	END IF
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $textLine, @command$)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $textLine, "")		' Clear
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textLine, 0)
'
'	One register at a time; value is in HEX
'
	colon = INSTR(command$, ":")
	IF (colon <= 1) THEN GOTO RegSyntax
	reg$ = LCASE$(LEFT$(command$, colon - 1))
	value$ = LCASE$(TRIM$(MID$(command$, colon + 1)))
	IF (LEFT$(value$,2) = "0x") THEN
		value = XLONG(value$)
	ELSE
		value = XLONG("0x" + value$)
	END IF
'
	SELECT CASE reg$
		CASE "rax"	: cpu.rax = value
		CASE "rbx"	: cpu.rbx = value
		CASE "rcx"	: cpu.rcx = value
		CASE "rdx"	: cpu.rdx = value
		CASE "rdi"	: cpu.rdi = value
		CASE "rsi"	: cpu.rsi = value
		CASE "rbp"	: cpu.rbp = value
		CASE "rsp"	: cpu.rsp = value
		CASE "rip"	: cpu.rip = value
'		CASE "flg"	: cpu.efl = value
		CASE "cs"		: cpu.cs = value
'		CASE "ds"		: cpu.ds = value
'		CASE "es"		: cpu.es = value
'		CASE "fs"		: cpu.fs = value
'		CASE "gs"		: cpu.gs = value
		CASE "ss"		: cpu.ss = value
		CASE ELSE		: GOTO RegSyntax
	END SELECT
'
'	Display new values
'
	reg$ = RegisterString$()
	XstStringToStringArray (@reg$, @reg$[])
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @reg$[])
	XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $textArea, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
	EXIT SUB
'
RegSyntax:
	temp$ = "* Syntax =  reg: hexValue *"
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $textArea, @temp$)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
END SUB
'
'
' *****  ResetCommand  *****  RESET restores all registers to initial values, redisplay registers.
'
SUB ResetCommand
	IF (cpuOrig.rip != lineAddr[exeFunction, exeLine]) THEN
		temp$ = "Oridinal values look invalis : registers not altered"
		XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $textLine, @temp$)
		XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textLine, 0)
		EXIT SUB
	END IF

	cpu = cpuOrig
	reg$ = RegisterString$()
	XstStringToStringArray (@reg$, @reg$[])
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @reg$[])
	XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $textArea, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
END SUB
END FUNCTION
'
'
' ############################
' #####  ClearErrors ()  #####
' ############################
'
'	Clear all error numbers from the token array
' Reset the compilation error box
'
FUNCTION  ClearErrors ()
	EXTERNAL /xxx/ maxFuncNumber,  errorCount
	TOKEN   func[]
	SHARED  TOKEN prog[]
	SHARED  errorCurrent
	SHARED  xitGrid,  editFunction,  fileType
	SHARED  currentCursor
'
	IF (fileType != $$Program) THEN EXIT FUNCTION
	IFZ prog[] THEN EXIT FUNCTION
'
	entryCursor = currentCursor
'
	redisplay = $$FALSE
	reportBogusRename = $$TRUE                        ' tokenize, set BPs (as necessary)
	RestoreTextToProg (redisplay, reportBogusRename)
'
	FOR func = 0 TO maxFuncNumber
		IFZ prog[func,] THEN DO NEXT
		ATTACH prog[func,] TO func[]
		numLines = UBOUND(func[])
		FOR line = 0 TO numLines
				func[line,0].ti.errno = 0
		NEXT line
		ATTACH func[] TO prog[func,]
	NEXT func
'
'	Redisplay editFunction in case any changes occured
'
	TokenArrayToText (editFunction, @text$[])
	XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	errorCount = 0
	errorCurrent = 0
	UpdateErrors (0, 0)
END FUNCTION
'
'
' #############################
' #####  UpdateErrors ()  #####
' #############################
'
'	Update the compilation error box with the requested func/line.  Manage the box.
'
'	In:				func			function number containing this error
'						line			function line with this error
'	Out:			none			(args unchanged)
'	Return:		none
'
'	Discussion:
'		Minor kludge:		func == -2								END PROGRAM
'
FUNCTION  UpdateErrors (func, line)
	EXTERNAL /xxx/ errorCount
	SHARED  errorXerror[],  errorRawPtr[]
	SHARED  errorSrcPtr[],  errorSrcLine$[]
	SHARED  errorCurrent
	SHARED  errorBox
'
	SELECT CASE TRUE
		CASE (errorCount = 0)
			XuiSendMessage (errorBox, #SetTextString, 0, 0, 0, 0, 1, @" no errors detected ")
			XuiSendMessage (errorBox, #SetTextString, 0, 0, 0, 0, 2, "")
		CASE (func = -2)																' END PROGRAM
			symbol$	= errorSrcLine$[errorCurrent]
'			token		= errorRawPtr[errorCurrent]
			addr		= errorSrcPtr[errorCurrent]
			xerror	= errorXerror[errorCurrent]
			srcLine$ = RIGHT$("00" + STRING(errorCurrent), 3) + ":  " + HEXX$(addr, 8) + "  "
			pointer = LEN(srcLine$) + 1
			srcLine$ = srcLine$ + symbol$
			XuiSendMessage (errorBox, #SetTextString, 0, 0, 0, 0, 1, @srcLine$)
			errMsg$ = LEFT$(XxxGetXerror$(xerror), 32)
			label$ = SPACE$(pointer - 1) + "^-- " + errMsg$
			XuiSendMessage (errorBox, #SetTextString, 0, 0, 0, 0, 2, @label$)
		CASE ELSE
			srcLine$ = errorSrcLine$[errorCurrent]
			pointer = errorSrcPtr[errorCurrent]
			xerror = errorXerror[errorCurrent]
			lenSrc = LEN(srcLine$)
			IF (pointer < 78) THEN
				IF (lenSrc >= 78) THEN
					srcLine$ = LEFT$(srcLine$, 77) + "..."
				END IF
			ELSE
				IF (ABS(lenSrc - pointer) < 40) THEN
					srcLine$ = "..." + RIGHT$(srcLine$, 77)			' Show tail end of line
					pointer = 3 + (pointer - (lenSrc - 77))
				ELSE
					middle$ = MID$(srcLine$, pointer - 36, 74)
					srcLine$ = "..." + middle$ + "..."					' Show line middle
					pointer = 40
				END IF
			END IF
			srcLine$ = RIGHT$("00" + STRING(errorCurrent), 3) + ":  " + srcLine$
			pointer = pointer + 6
			XuiSendMessage (errorBox, #SetTextString, 0, 0, 0, 0, 1, @srcLine$)
'
'			Error messages to the right or left of pointer
'
			errMsg$ = LEFT$(XxxGetXerror$ (xerror), 32)			' msgs <= 32 chars)
			IF (pointer > 40) THEN
				label$ = RJUST$(errMsg$, pointer - 4) + " --^"
			ELSE
				label$ = SPACE$(pointer - 1) + "^-- " + errMsg$
			END IF
			XuiSendMessage (errorBox, #SetTextString, 0, 0, 0, 0, 2, @label$)
'
'			Show the function/line. Move pointer to the raw character offset.
'				Note: Once user edits this line, raw offset will be goofy.  This is why
'							I provide the offset in the error box with the original source line.
'
			cursorPos = 3 + errorRawPtr[errorCurrent]				' 3 digit error code
			Display (func, line, cursorPos, -1, -1)
	END SELECT
'
	XuiSendMessage (errorBox, #GetSize, 0, 0, @width, @height, 0, 0)
	XuiSendMessage (errorBox, #GetSmallestSize, 0, 0, @v2, @v3, 0, 0)
	IF (width < v2) THEN
		XuiSendMessage (errorBox, #Resize, -1, -1, v2, v3, 0, 0)
		XuiSendMessage (errorBox, #Redraw, 0, 0, 0, 0, 0, 0)
	ELSE
		XuiSendMessage (errorBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
		XuiSendMessage (errorBox, #RedrawGrid, 0, 0, 0, 0, 2, 0)
	END IF
END FUNCTION
'
'
' #################################
' #####  WizardCompErrors ()  #####
' #################################
'
FUNCTION  WizardCompErrors (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	EXTERNAL /xxx/  maxFuncNumber,  errorCount
	TOKEN   func[]
	SHARED  TOKEN prog[]
	SHARED  errorFunc[]
	SHARED  errorCurrent
	SHARED  fileType
	SHARED  uError
'
	$label0		= 1
	$label1		= 2
	$button0	= 3
	$button1	= 4
	$button2	= 5
	$button3	= 6
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow : GOSUB DisplayWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****
'
SUB DisplayWindow
	showError = 1
	GOSUB ShowError
	XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, 1, 0)
END SUB
'
'
' *****  Selection  *****  r0 = 3456 = Button0123
'
SUB Selection
	SELECT CASE r0
		CASE $button0:	showError =  1:		GOSUB ShowError
		CASE $button1:	showError =  0:		GOSUB ShowError
		CASE $button2:	showError = -1:		GOSUB ShowError
		CASE $button3:	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE 0:
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
			ELSE
				showError = 1:		GOSUB ShowError
			END IF
	END SELECT
END SUB
'
'
' *****  ShowError  *****
'
SUB ShowError
	IF (fileType != $$Program) THEN GOTO NoErrorsDetected
	IFZ prog[] THEN GOTO NoErrorsDetected
'
	IF (errorCount > uError) THEN errorCount = uError
'
	IF errorCount THEN
		redisplay = $$TRUE
		reportBogusRename = $$TRUE							' tokenize, set BPs (as necessary)
		RestoreTextToProg (redisplay, reportBogusRename)
'
'		Check the "forward" half of the error list
'
		SELECT CASE showError
			CASE 1:
				firstError = errorCurrent + 1
				IF (firstError > errorCount) THEN firstError = 1
				lastError = errorCount
				errorStep = 1
			CASE 0:
				firstError = errorCurrent
				lastError = errorCount
				errorStep = 1
			CASE ELSE:
				firstError = errorCurrent - 1
				IF (firstError < 1) THEN firstError = errorCount
				lastError = 1
				errorStep = -1
		END SELECT
'
		FOR i = firstError TO lastError STEP errorStep
			func = errorFunc[i]
			IF (func = -2) THEN									' -2 == END PROGRAM
				errorCurrent = i
				GOTO ShowError
			END IF
			IF (func < 0) THEN DO NEXT					' This error has been fixed
			IF (func > maxFuncNumber) THEN
				errorFunc[i] = -1
				DO NEXT
			END IF
			IFZ prog[func,] THEN
				errorFunc[i] = -1
				DO NEXT
			END IF
'
			ATTACH prog[func,] TO func[]
			numLines = UBOUND(func[])
			FOR line = 0 TO numLines
				thisError = func[line,0].ti.errno
				IF (thisError = i) THEN
					ATTACH func[] TO prog[func,]
					errorCurrent = i
					GOTO ShowError
				END IF
			NEXT line
			ATTACH func[] TO prog[func,]
'
			errorFunc[i] = -1										' error code has been removed
		NEXT i
'
'		Check the "behind" half of the error list
'
		SELECT CASE showError
			CASE 1:
				IF (firstError = 1) THEN GOTO NoErrorsDetected
				firstError = 1
				lastError = errorCurrent
				errorStep = 1
			CASE 0:
				IF (firstError = 1) THEN GOTO NoErrorsDetected
				firstError = 1
				lastError = errorCurrent - 1
				errorStep = 1
			CASE ELSE:
				IF (firstError = errorCount) THEN GOTO NoErrorsDetected
				firstError = errorCount
				lastError = errorCurrent
				errorStep = -1
		END SELECT
'
		FOR i = firstError TO lastError STEP errorStep
			func = errorFunc[i]
			IF (func = -2) THEN									' -2 == END PROGRAM
				errorCurrent = i
				GOTO ShowError
			END IF
			IF (func < 0) THEN DO NEXT					' This error has been fixed
			IF (func > maxFuncNumber) THEN
				errorFunc[i] = -1
				DO NEXT
			END IF
			IFZ prog[func,] THEN
				errorFunc[i] = -1
				DO NEXT
			END IF
'
			ATTACH prog[func,] TO func[]
			numLines = UBOUND(func[])
			FOR line = 0 TO numLines
				thisError = func[line,0].ti.errno
				IF (thisError = i) THEN
					ATTACH func[] TO prog[func,]
					errorCurrent = i
					GOTO ShowError
				END IF
			NEXT line
			ATTACH func[] TO prog[func,]
			errorFunc[i] = -1										' error code has been removed
		NEXT i
	END IF
'
NoErrorsDetected:
	errorCount = 0
	errorCurrent = 0
'
ShowError:
	UpdateErrors (func, line)
END SUB
END FUNCTION
'
'
' ################################
' #####  WizardRunErrors ()  #####
' ################################
'
FUNCTION  WizardRunErrors (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
'
	$label0	= 1
	$label1	= 2
	$button	= 3
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  Selection  *****  r0 = 3 = Button
'
SUB Selection
	SELECT CASE r0
		CASE 0, $button:	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
END FUNCTION
'
'
' ##################################
' #####  ClearRuntimeError ()  #####
' ##################################
'
'	Clear the Runtime Error box
'
FUNCTION  ClearRuntimeError ()
	SHARED  environmentActive,  runtimeErrorBox
'
	##USERABORT = $$FALSE
'
	IF environmentActive THEN
		XuiSendMessage (runtimeErrorBox, #SetTextString, 0, 0, 0, 0, 1, "")
		XuiSendMessage (runtimeErrorBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
		XuiSendMessage (runtimeErrorBox, #SetTextString, 0, 0, 0, 0, 2, "")
		XuiSendMessage (runtimeErrorBox, #RedrawGrid, 0, 0, 0, 0, 2, 0)
	END IF
END FUNCTION
'
'
' ###################################
' #####  UpdateRuntimeError ()  #####
' ###################################
'
FUNCTION  UpdateRuntimeError ()
	SHARED  environmentActive,  runtimeErrorBox
'
	showMsg = GetRuntimeError (@runtimeInfo$, @runtimeMsg$)
	IFZ environmentActive THEN
		IF showMsg THEN
			PRINT runtimeInfo$
			PRINT runtimeMsg$
			a$ = INLINE$("  PRESS RETURN TO CONTINUE (q to quit) ")
			IF (a$ = "q") THEN XxxXitQuit(0)
		END IF
	ELSE
		XuiSendMessage (runtimeErrorBox, #SetTextString, 0, 0, 0, 0, 1, @runtimeInfo$)
		XuiSendMessage (runtimeErrorBox, #SetTextString, 0, 0, 0, 0, 2, @runtimeMsg$)
		XuiSendMessage (runtimeErrorBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
		XuiSendMessage (runtimeErrorBox, #RedrawGrid, 0, 0, 0, 0, 2, 0)
		XuiSendMessage (runtimeErrorBox, #GetSmallestSize, 0, 0, @v2, 0, 0, 0)
		XuiSendMessage (runtimeErrorBox, #GetSize, 0, 0, @width, @height, 0, 0)
		IF (width < v2) THEN
			XuiSendMessage (runtimeErrorBox, #Resize, -1, -1, v2, v3, 0, 0)
			XuiSendMessage (runtimeErrorBox, #Redraw, 0, 0, 0, 0, 0, 0)
		END IF
		IF showMsg THEN
			XuiSendMessage (runtimeErrorBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		END IF
	END IF
	oldError = ERROR (0)  ' zero the error
	##WHERE = 0
END FUNCTION
'
'
' ##########################
' #####  HelpIndex ()  #####
' ##########################
'
FUNCTION  HelpIndex ()
	STATIC state
'
'	PRINT "*****  HelpIndex  *****"
	state = NOT state
'	PRINT "HelpIndex:  Toggle GuiDesigner ";
'	IF state THEN PRINT "On" ELSE PRINT "Off"
	XxxGuiDesignerOnOff(state)
END FUNCTION
'
'
' #############################
' #####  HelpContents ()  #####
' #############################
'
FUNCTION  HelpContents ()
	PRINT "*****  HelpContents  *****"
END FUNCTION
'
'
' ##############################
' #####  HelpHighlight ()  #####
' ##############################
'
FUNCTION  HelpHighlight ()
	SHARED  teston
'
	PRINT "*****  HelpHighlight  *****"
	PRINT "  Test TestHeaders()  CountHeaders()"
'
	entryTeston = teston
	teston = $$TRUE
	TestHeaders ()
	teston = entryTeston
'
	CountHeaders ()
END FUNCTION
'
'
' ##########################
' #####  HelpAbout ()  #####
' ##########################
'
FUNCTION  HelpAbout (display)
	SHARED  about$
	SHARED  aboutGrid
	SHARED  aboutFont
'	SHARED  romanFont
'	SHARED  messageFont
'	SHARED  courierFont
'	SHARED  verdanaFont
'	SHARED	comicFont
'	SHARED  labelFont
'	SHARED	buttonFont
'	SHARED  comicBigFont
'
'	SELECT CASE TRUE
'		CASE aboutFont		: aboutFont = aboutFont
'		CASE comicFont		: aboutFont = comicFont
'		CASE comicBigFont	: aboutFont = comicBigFont
'		CASE verdanaFont	: aboutFont = verdanaFont
'		CASE messageFont	: aboutFont = messageFont
'		CASE romanFont		: aboutFont = romanFont
'		CASE courierFont	: aboutFont = courierFont
'		CASE ELSE					: aboutFont = 0
'	END SELECT
'
	IFZ #displayWidth THEN XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
'
	IFZ aboutGrid THEN
		left = #windowBorderWidth
		upper = #windowBorderWidth + #windowTitleHeight
		halfWidth = (#displayWidth >> 1) - #windowBorderWidth - #windowBorderWidth
		halfHeight = (#displayHeight >> 1) - #windowBorderWidth - #windowBorderWidth - #windowTitleHeight
		XuiMessage1B   (@aboutGrid, #CreateWindow, left, upper, halfWidth, halfHeight, 0, 0)
		XuiSendMessage ( aboutGrid, #SetGridName, 0, 0, 0, 0, 0, @"aboutGrid")
		XuiSendMessage ( aboutGrid, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:About")
		XuiSendMessage ( aboutGrid, #SetHintString, -1, 0, 0, 0, 0, @"help about")
		XuiSendMessage ( aboutGrid, #SetCallback, aboutGrid, &WelcomeWindowCode(), -1, -1, -1, aboutGrid)
		XuiSendMessage ( aboutGrid, #SetColor, $$BrightBlue, $$Yellow, $$Black, $$BrightYellow, 1, 0)
		XuiSendMessage ( aboutGrid, #SetColorExtra, $$Cyan, $$Yellow, $$Black, $$BrightYellow, 1, 0)
		XuiSendMessage ( aboutGrid, #SetColor, $$BrightCyan, -1, -1, -1, 2, 0)
		XuiSendMessage ( aboutGrid, #SetWindowTitle, 0, 0, 0, 0, 0, @" initialize ")
		XuiSendMessage ( aboutGrid, #SetTexture, $$TextureShadow, 0, 0, 0, 1, 0)
		XuiSendMessage ( aboutGrid, #SetFontNumber, aboutFont, 0, 0, 0, 1, 0)
		XuiSendMessage ( aboutGrid, #SetTextString, 0, 0, 0, 0, 1, @about$)
		XuiSendMessage ( aboutGrid, #SetTextSpacing, 0, -4, 0, 0, 1, 0)
		XuiSendMessage ( aboutGrid, #SetGridProperties, -1, 0, 0, 0, 0, 0)
		XuiSendMessage ( aboutGrid, #GetSmallestSize, 0, 0, @ww, @hh, 0, 0)
		XuiSendMessage ( aboutGrid, #Resize, 0, 0, ww, hh, 0, 0)
		XuiSendMessage ( aboutGrid, #ResizeWindow, left, upper, ww, hh, 0, 0)
	END IF
'
	IF display THEN
		XuiSendMessage (aboutGrid, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		XxxXgrSysMessages ()                       ' process system messages
	END IF
END FUNCTION
'
'
' ############################
' #####  HotToCursor ()  #####
' ############################
'
FUNCTION  HotToCursor ()
	SHARED  userRun,  userContinue,  userStepType,  programAltered
	SHARED  exitMainLoop,  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[HotToCursor( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN
'		Message ("[HotToCursor( )]\n Program already running ")
		EXIT FUNCTION
	END IF
'
	userStepType = $$BreakContinueToCursor
	IF (##USERRUNNING AND (NOT programAltered)) THEN
		userContinue = $$TRUE
	ELSE
		userRun = $$TRUE
	END IF
	exitMainLoop = $$TRUE
END FUNCTION
'
'
' #############################
' #####  HotStepLocal ()  #####
' #############################
'
FUNCTION  HotStepLocal ()
	SHARED  userRun,  userContinue,  userStepType,  programAltered
	SHARED  exitMainLoop,  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[HotStepLocal( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN
'		Message ("[HotStepLocal( )]\n Program already running ")
		EXIT FUNCTION
	END IF
'
	userStepType = $$BreakContinueStepLocal
	IF (##USERRUNNING AND (NOT programAltered)) THEN
		userContinue = $$TRUE
	ELSE
		userRun = $$TRUE
	END IF
	exitMainLoop = $$TRUE
END FUNCTION
'
'
' ##############################
' #####  HotStepGlobal ()  #####
' ##############################
'
FUNCTION  HotStepGlobal ()
	SHARED  userRun,  userContinue,  userStepType,  programAltered
	SHARED  exitMainLoop,  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[HotStepGlobal( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	IF (##USERRUNNING AND (NOT ##SIGNALACTIVE)) THEN
		EXIT FUNCTION
	END IF
'
	userStepType = $$BreakContinueStepGlobal
	IF (##USERRUNNING AND (NOT programAltered)) THEN
		userContinue = $$TRUE
	ELSE
		userRun = $$TRUE
	END IF
	exitMainLoop = $$TRUE
END FUNCTION
'
'
' #############################
' #####  HotVariables ()  #####
' #############################
'
' See: XitVariables
'
FUNCTION  HotVariables (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	SHARED  variableFuncRow[]
	SHARED	variableBox
	SHARED  variableUp,  arrayUp,  arrayBox,  exeFunction
	SHARED  stringUp,  stringBox,  compositeUp,  compositeBox
	SHARED	varShowType, varShowLocation, varShowHex
	SHARED  fileType
	SHARED  varDetailActive
'
	$functionLabel	=  1
	$columnLabel		=  2
	$list						=  3
	$findLabel			=  4
	$findText				=  5
	$valueLabel			=  6
	$valueText			=  7
	$button0				=  8
	$button1				=  9
	$button2				= 10
	$CheckShowType	= 11
	$CheckShowLocation	= 12
	$CheckShowHex		= 13
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
		CASE #HideWindow		: GOSUB HideWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****  from XitVariables
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: GOSUB HideWindow
		CASE #Selection			: GOSUB Selection
		CASE #TextModified	: IF (r0 == $findText) THEN VariablesFind ()
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****  Raise to top if already up : v0 = update
'
SUB DisplayWindow
	IF (fileType = $$Program) THEN
		IF v0 THEN UpdateVariables ()
		IF arrayUp THEN VariablesArray (arrayBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		IF stringUp THEN VariablesString (stringBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		IF compositeUp THEN VariablesComposite (compositeBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	END IF
	XuiSendToKid (grid, #DisplayWindow, 0, 0, 0, 0, 1, 0)
	variableUp = $$TRUE
END SUB
'
'
' *****  HideWindow  *****
'
SUB HideWindow
	IF arrayUp THEN VariablesArray (arrayBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	IF stringUp THEN VariablesString (stringBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	IF compositeUp THEN VariablesComposite (compositeBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	IF variableUp THEN
		XuiSendMessage (grid, #GetTextCursor, 0, @cursorLine, 0, @topLine, $list, 0)
		IF variableFuncRow[] THEN
			variableFuncRow[exeFunction, 0] = topLine
			variableFuncRow[exeFunction, 1] = cursorLine
		END IF
		XuiSendToKid (grid, #HideWindow, 0, 0, 0, 0, 1, 0)
		variableUp = $$FALSE
		varDetailActive = $$FALSE
	END IF
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE r0
		CASE $list
			IF variableFuncRow[] THEN
				XuiSendMessage (grid, #GetTextCursor, 0, @cursorLine, 0, @topLine, $list, 0)
				variableFuncRow[exeFunction, 0] = topLine
				variableFuncRow[exeFunction, 1] = cursorLine
				VariablesDetail ()
				varDetailActive = NOT cursorLine
			END IF
		CASE $findText
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				GOSUB HideWindow
			ELSE
				VariablesFind ()
			END IF
		CASE $valueText
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				GOSUB HideWindow
			ELSE
				IF variableFuncRow[] THEN
					XuiSendMessage (grid, #GetTextCursor, 0, @cursorLine, 0, @topLine, $list, 0)
					variableFuncRow[exeFunction, 0] = topLine
					variableFuncRow[exeFunction, 1] = cursorLine
					VariablesNewValue ()
				END IF
			END IF
		CASE $button0
			IF variableFuncRow[] THEN
				XuiSendMessage (grid, #GetTextCursor, 0, @cursorLine, 0, @topLine, $list, 0)
				variableFuncRow[exeFunction, 0] = topLine
				variableFuncRow[exeFunction, 1] = cursorLine
				VariablesNewValue ()
			END IF
		CASE $button1
			IF variableFuncRow[] THEN
				XuiSendMessage (grid, #GetTextCursor, 0, @cursorLine, 0, @topLine, $list, 0)
				variableFuncRow[exeFunction, 0] = topLine
				variableFuncRow[exeFunction, 1] = cursorLine
				VariablesDetail ()
				varDetailActive = NOT cursorLine
			END IF
		CASE $button2
			GOSUB HideWindow
		CASE $CheckShowType
			varShowType = v0
			updateVariables = $$TRUE
		CASE $CheckShowLocation
			varShowLocation = v0
			updateVariables = $$TRUE
		CASE $CheckShowHex
			varShowHex = v0
			updateVariables = $$TRUE
	END SELECT
	IF updateVariables THEN
		IF varShowType THEN text$ = "type      " ELSE text$ = ""
		text$ = text$ + "symbol                "
		IF varShowLocation THEN text$ = text$ + "location    "
		IF varShowHex THEN text$ = text$ + "hex                "
		text$ = text$ + "value      "
		XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, $columnLabel, @text$)
		XuiSendMessage (variableBox, #RedrawGrid, 0, 0, 0, 0, $columnLabel, 0)
		XuiSendMessage (variableBox, #GetSize, @x, @y, @w, @h, kid, 0)
		XuiSendMessage (variableBox, #GetSmallestSize, 0, 0, @width, @height, kid, 0)
		IF (w < width) THEN w = width
		IF (h < height) THEN h = height
		XuiSendMessage ( variableBox, #Resize, x, y, w, h, 0, 0)
		UpdateVariables ()
	END IF
END SUB
END FUNCTION
'
'
' ################################
' #####  UpdateVariables ()  #####
' ################################
'
FUNCTION  UpdateVariables ()
'	ULONG  ##UCODE0,  ##UCODE,  ##UCODEX,  ##UCODEZ
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
'	ULONG  ##DYNO0,  ##DYNO,  ##DYNOX,  ##DYNOZ
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   token
	SHARED  TOKEN  varTok[]
	SHARED  lineAddr[],  lineLast[],  variableFuncRow[]
	SHARED  varSymbol$[],  varReg[],  varAddr[],  varDataAddr[]
	SHARED  varTypes$[],  reg86$[]
	SHARED  variableBox,  framesBox
	SHARED  arrayBox,  stringBox,  compositeBox
	SHARED  arrayUp,  stringUp,  compositeUp
	SHARED	varShowType, varShowLocation, varShowHex
	SHARED  FRAMEINFO  frameInfo[]
	SHARED  FRAMEINFO  variableFrame
	SHARED  softInterrupt
	SHARED  currentCursor
	SHARED  varDetailActive
	SHARED  lastFrame$
	SHARED 	traceActive
	SHARED  variableSaved$[]
	STATIC  typeSuffix$[]
	STATIC  FRAMEINFO  zero
	AUTOX   copyString$,  topPosition
'
	IFZ typeSuffix$[] THEN GOSUB InitArrays
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		EXIT FUNCTION
	END IF
'
	entryCursor = currentCursor
'
' Clear New Value
'
	XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 7, "")
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 7, 0)
	XuiSendMessage (framesBox, #GetTextCursor, 0, @viewLine, 0, 0, 2, 0)
	XuiSendMessage (framesBox, #GetTextArrayLine, viewLine, 0, 0, 0, 2, @view$)
'
	frameItem = XLONG(view$)
	showFuncNumber	= frameInfo[frameItem].funcNumber
	IF (showFuncNumber <= 0) THEN GOTO Invalid
	IF (showFuncNumber != variableFrame.funcNumber) THEN
		IF arrayUp THEN VariablesArray (arrayBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		IF stringUp THEN VariablesString (stringBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		IF compositeUp THEN VariablesComposite (compositeBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	END IF
'
	up0 = UBOUND (frameInfo[])
	up1 = UBOUND (lineLast[])
	up2 = UBOUND (lineAddr[])
'
	variableFrame = zero
	showFrameAddr = frameInfo[frameItem].frameAddr
	showFuncAddr = frameInfo[frameItem].funcAddr
	showFuncLine = frameInfo[frameItem].funcLine
'	PRINT "UpdateVariables(66)", HEXX$(showFrameAddr), HEXX$(showFuncAddr), HEXX$(showFuncLine)
'
	softInterrupt = $$FALSE
	lastLine = lineLast[showFuncNumber]
	lineAddr = lineAddr[showFuncNumber, showFuncLine]
	firstAddr = lineAddr[showFuncNumber, 0]
	FOR line = 0 TO lastLine
		secondAddr = lineAddr[showFuncNumber, line]
		IF (secondAddr != firstAddr) THEN EXIT FOR
	NEXT line
'
'	Can't access variables:
'		showFuncAddr not in current function
'				Intrinsics create new frames, etc
'		First line (the FUNCTION line):
'				This is a branch to the function entry point.
'					Cannot access variables because function frame is not set up yet.
'					This can be hit in the entry function, but never in other functions.
'		showFuncAddr = ##UCODE
'				Can't yield variables at the ##UCODE, nothing is set up yet.  This is
'					only hit in the entry function where no code is emitted in the prolog.
'		showFuncAddr != lineAddr
'				- NOT OK if last line (exit code)
'				- NT:  everything else OK
'						BECAUSE all variables are either absolute address or
'							offset from rbp
'
	nextAddr = lineAddr[showFuncNumber, showFuncLine + 1]
	IF ((showFuncAddr < lineAddr) OR (showFuncAddr >= nextAddr)) THEN
		error$ = "* Outside function:  variable state unknown *"
		GOTO ShowError
	END IF
'
	IF (lineAddr < secondAddr) THEN
		error$ = "* Unavailable on FUNCTION line *"
		GOTO ShowError
	END IF
'
	IF (showFuncAddr = ##UCODE) THEN
		error$ = "* Unavailable on first PROGRAM line *"
		GOTO ShowError
	END IF
'
'	Not OK if inside last line
'
	IF (showFuncAddr != lineAddr) THEN
		IF (showFuncLine = lastLine) THEN
			error$ = "* Not line boundary:  unavailable inside END FUNCTION *"
			GOTO ShowError
		END IF
'
'		Tests for prior to function call not necessary for NT:
'			- OK if no function call in this line
'			- If function call, ok if prior to first push/rsp/call
'					- NEVER ok if after call (may have pass by reference stuff)
'
'		ATTACH prog[showFuncNumber, showFuncLine, ] TO tok[]
'		IFZ tok[] THEN EXIT FUNCTION													' avoid access error
'		toks = tok[0]{$$BYTE0}
'		IF toks THEN
'			tokPtr = 1
'			DO
'				IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN EXIT DO
'				IF (token{$$KIND} = $$KIND_FUNCTIONS) THEN
'
'					Is showFuncAddr prior to first push/rsp/call?
'
'					IF (showFuncAddr > lineAddr + 12) THEN
'						FOR addr = lineAddr TO (showFuncAddr - 16) STEP 4
'							i$ = XxxDisassemble64$(addr, $$FALSE)
'							IF (INSTRI(i$, "push") || INSTRI(i$, "rsp") || INSTRI(i$, "call")) THEN
'								ATTACH tok[] TO prog[showFuncNumber, showFuncLine, ]
'								error$ = "* Not line boundary:  unavailable during function call *"
'								GOTO ShowError
'							END IF
'						NEXT addr
'					END IF
'					EXIT DO
'				END IF
'			LOOP
'			ATTACH tok[] TO prog[showFuncNumber, showFuncLine, ]
'		END IF
	END IF
'
'	Get the current user composite type names
'
	XxxGetUserTypes (@varTypes$[])
'
'	Just get variables and arrays for now
'
	DIM kinds[1]
	kinds[0] = $$KIND_VARIABLES
	kinds[1] = $$KIND_ARRAYS
	numVars = XxxGetFunctionVariables (showFuncNumber, @kinds[], @varTok[], @varSymbol$[], @varReg[], @varAddr[])
	DIM varDataAddr[numVars - 1]
	IFZ numVars THEN
		DIM textArray$[0]
		textArray$[0] = "* No variables or arrays in this function *"
		DIM kinds[]
		DIM varTok[]
		DIM varSymbol$[]
		DIM varReg[]
		DIM varAddr[]
	ELSE
		VariableSort (@varTok[], @varSymbol$[], @varReg[], @varAddr[], 0, numVars - 1)
		DIM textArray$[numVars - 1]
		FOR i = 0 TO (numVars - 1)
			token = varTok[i]
			kind = token.tp.kind
			tt = XxxTheType (token, showFuncNumber)      'XxxTheType() is in xcol.x
'
			validType = $$TRUE
			IF (tt < 0x20) THEN						' check for non-supported simple types
				IFZ varTypes$[tt] THEN
					validType = $$FALSE
				END IF
			ELSE
				IF (tt > UBOUND(varTypes$[])) THEN				' This is a compiler error
					validType = $$FALSE
				END IF
			END IF
			IF varReg[i] THEN
				register = varReg[i]
				IF (register != 31) THEN
					error$ = "* Error:  Register offset from " + reg86$[register] + " (not rbp) *"
					GOTO ShowError
				END IF
				base		= showFrameAddr
				offset	= varAddr[i]
'				location$ = LJUST$(reg86$[register] + SIGNED$(offset), 10)		' pad  *cw* 230306-
				location$ = LJUST$(reg86$[register] + SIGNED$(offset), 11)		' pad  *cw* 230306+
			ELSE
				base	= varAddr[i]
				offset = 0
'				location$ = HEXX$(base,8)   '*cw* 230306-
				location$ = HEXX$(base,9)  '*cw* 230306+
			END IF
			word1 = XLONGAT(base, offset)
			wordAddr = base + offset
'			PRINT "UpdateVariables(205)", HEXX$(base), HEXX$(offset), offset, HEXX$(wordAddr)
'
			IFZ validType THEN
				type$ = "        "
				hexValue$ = "                 "
				value$ = "<unsupported>"
			ELSE
				type$ = varTypes$[tt]
				IF (tt > 0x21) THEN
					lenType = LEN(type$)
					SELECT CASE TRUE
						CASE (lenType > 8)
							type$ = LEFT$(type$, 7) + "*"
						CASE (lenType < 8)
							type$ = LJUST$(type$, 8)
					END SELECT
				END IF
'
				hexValue$ = " " + LJUST$(HEX$(word1, 8), 16)
				IF (token.tp.kind = $$KIND_ARRAYS) THEN
					varDataAddr[i] = word1									' array data addr
					value$ = " <array>"
					IFZ word1 THEN
						hexValue$ = " EMPTY           "
					ELSE
						hexValue$ = "@" + LJUST$(HEX$(word1,8), 16)
					END IF
				ELSE
'					VariableTypeToValue (tt, $$FALSE, wordAddr, @hexValue$, @value$)  '*cw* 230306-
					VariableTypeToValue (tt, $$TRUE, wordAddr, @hexValue$, @value$)   '*cw* 230306+
				END IF  ' kind = array
			END IF	' unsupported type
'
			symbol$ = varSymbol$[i]
			lenSymbol = LEN(symbol$)
			SELECT CASE TRUE
				CASE (lenSymbol < 20)							' pad symbol to 20 chars
					symbol$ = LJUST$(symbol$, 20)
'
				CASE (lenSymbol > 20)							' truncate symbol to 20 chars
					IF (token.tp.kind = $$KIND_ARRAYS) THEN		' Retain type suffix and []
						symbol$ = RCLIP$(symbol$, 2)	' strip []
						top = 18
					ELSE
						top = 20
					END IF
					SELECT CASE tt
						CASE $$UBYTE, $$USHORT, $$ULONG, $$GIANT
							IF (RIGHT$(symbol$, 2) = typeSuffix$[tt]) THEN
								symbol$ = LEFT$(symbol$, top - 3) + "*" + typeSuffix$[tt]
							ELSE
								symbol$ = LEFT$(symbol$, top - 1) + "*"
							END IF
						CASE ELSE
							IF (tt < 0x20) THEN
								IF (RIGHT$(symbol$, 1) = typeSuffix$[tt]) THEN
									symbol$ = LEFT$(symbol$, top - 2) + "*" + typeSuffix$[tt]
									EXIT SELECT
								END IF
							END IF
							symbol$ = LEFT$(symbol$, top - 1) + "*"
					END SELECT
					IF (token.tp.kind = $$KIND_ARRAYS) THEN
						symbol$ = symbol$ + "[]"								' add []
					END IF
					varSymbol$[i] = symbol$				' varSymbol$ is 20 chars max
					lenSymbol = 20
			END SELECT
'
'			textArray$[i] = type$ + "  " + symbol$ + "  " + location$ + "  " + hexValue$ + " " + value$
			IF varShowType THEN text$ = type$ + "  " ELSE text$ = ""
			text$ = text$ + symbol$ + "  "
			IF varShowLocation THEN text$ = text$ + location$ + "  "
			IF varShowHex THEN text$ = text$ + hexValue$ + "  "
			textArray$[i] = text$ + value$
'
			IFZ (i AND 0xFF) THEN												' Update every 64 lines
				SetCurrentStatus ($$StatusFormatting, i)
				IF softInterrupt THEN
					Message ("[UpdateVariables( )]\n Variable update aborted ")
					RETURN
				END IF
			END IF
		NEXT i
	END IF		' numVars > 0
	variableFrame.frameAddr		= showFrameAddr
	variableFrame.funcNumber	= showFuncNumber
	variableFrame.funcAddr		= showFuncAddr
	variableFrame.funcLine		= showFuncLine
'
ShowVars:
	XxxFunctionName ($$XGET, @funcName$, showFuncNumber)
	IF (LEN(funcName$) > 50) THEN
		funcName$ = LEFT$(funcName$, 49) + "*"
	END IF
	label$ = "FUNCTION:    " + funcName$ + "    LINE:  " + STRING(showFuncLine + 1)
	XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 1, @label$)
	XuiSendMessage (variableBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
	IFZ variableFuncRow[] THEN
		DIM variableFuncRow[maxFuncNumber, 1]
		FOR i = 0 TO UBOUND(textArray$[])
			IF (LEFT$(textArray$[i], 11) != "XLONG     #") THEN
				topLine = i - 1
				cursorLine = i
				EXIT FOR
			END IF
		NEXT i
	ELSE
		utop = UBOUND(variableFuncRow[])
		IF (utop < maxFuncNumber) THEN
			REDIM variableFuncRow[maxFuncNumber, 1]
		END IF
		func = variableFuncRow[0, 0]						' PROLOG slot used for current func
		IF func THEN														' top character / cursor
			XuiSendMessage (variableBox, #GetTextCursor, 0, @cursorLine, 0, @topLine, 3, 0)
			variableFuncRow[func, 0] = topLine
			variableFuncRow[func, 1] = cursorLine
		END IF
		topLine = variableFuncRow[showFuncNumber, 0]
		cursorLine = variableFuncRow[showFuncNumber, 1]
	END IF
	IFZ (cursorLine OR topLine OR cursorPos) THEN
		FOR i = 0 TO UBOUND(textArray$[])
			IF (LEFT$(textArray$[i], 11) != "XLONG     #") THEN
				topLine = i - 1
				cursorLine = i
				EXIT FOR
			END IF
		NEXT i
	END IF
	variableFuncRow[0, 0] = showFuncNumber
	XuiSendMessage (variableBox, #SetTextArray, 0, 0, 0, 0, 3, @textArray$[])
	XuiSendMessage (variableBox, #SetTextCursor, 0, cursorLine, 0, topLine, 3, 0)
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 3, 0)
	IF varDetailActive THEN
		IF (varDetailActive == NOT cursorLine) THEN VariablesDetail()
	END IF
'
' IF traceActive is TRUE, Print variables that have changed since last update
'
	IF traceActive
		IF (UBOUND(variableSaved$[]) < showFuncNumber) THEN
			REDIM variableSaved$[showFuncNumber,]
			ATTACH textArray$[] TO variableSaved$[showFuncNumber,]
		ELSE
			uSaved = UBOUND(variableSaved$[showFuncNumber,])
			uNew = UBOUND(textArray$[])
			IF (uNew == uSaved) THEN
				cursorSet = $$FALSE
				FOR i = 0 TO uNew
					IF (textArray$[i] != variableSaved$[showFuncNumber,i]) THEN
						IFZ cursorSet THEN
							XuiSendMessage (variableBox, #SetTextCursor, 0, i, 0, -1, 3, 0)
							XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 3, 0)
							cursorSet = $$TRUE
						END IF
						savedValue$ = variableSaved$[showFuncNumber,i]
						savedValuePos = RINSTR(savedValue$, " ")
						savedValue$ = "   (" + MID$(savedValue$, savedValuePos+1) + ")"
						PRINT "-"; CHR$(32, 10); textArray$[i], savedValue$
					END IF
				NEXT i
			END IF
			SWAP textArray$[], variableSaved$[showFuncNumber,]
		END IF
		IF lastFrame$ THEN  PRINT lastFrame$
	END IF
'
	RETURN
'
ShowError:
	DIM textArray$[0]
	ATTACH error$ TO textArray$[0]
	GOTO ShowVars
'
Invalid:
	DIM text$[0]
	text$[0] = "* Unavailable: No variables in PROLOG *"
	XuiSendMessage (variableBox, #SetTextArray, 0, 0, 0, 0, 3, @text$[])
	XuiSendMessage (variableBox, #SetTextCursor, 0, 0, 0, 0, 3, 0)
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 3, 0)
	XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 1, "")
	XuiSendMessage (variableBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
'	SetCursor (entryCursor)
	RETURN
'
'
' *****  InitArrays  *****
'
SUB InitArrays
	DIM varTypes$[0x21]															' Establish accessible types
	DIM typeSuffix$[0x21]
	varTypes$[$$SBYTE]		= "SBYTE   "	: typeSuffix$[$$SBYTE]  = "@"
	varTypes$[$$UBYTE]		= "UBYTE   "	: typeSuffix$[$$UBYTE]  = "@@"
	varTypes$[$$SSHORT]		= "SSHORT  "	: typeSuffix$[$$SSHORT] = "%"
	varTypes$[$$USHORT]		= "USHORT  "	: typeSuffix$[$$USHORT] = "%%"
	varTypes$[$$SLONG]		= "SLONG   "	: typeSuffix$[$$SLONG]  = "&"
	varTypes$[$$ULONG]		= "ULONG   "	: typeSuffix$[$$ULONG]  = "&&"
	varTypes$[$$XLONG]		= "XLONG   "	: typeSuffix$[$$XLONG]  = "~"
	varTypes$[$$GOADDR]		= "GOADDR  "
	varTypes$[$$SUBADDR]	= "SUBADDR "
	varTypes$[$$FUNCADDR]	= "FUNCADDR"
	varTypes$[$$GIANT]		= "GIANT   "	: typeSuffix$[$$GIANT]  = "$$"
	varTypes$[$$SINGLE]		= "SINGLE  "	: typeSuffix$[$$SINGLE] = "!"
	varTypes$[$$DOUBLE]		= "DOUBLE  "	: typeSuffix$[$$DOUBLE] = "#"
	varTypes$[$$STRING]		= "STRING  "	: typeSuffix$[$$STRING] = "$"
	varTypes$[$$SCOMPLEX]	= "SCOMPLEX"
	varTypes$[$$DCOMPLEX]	= "DCOMPLEX"
'
	DIM reg86[31]
	DIM reg86$[31]
	reg86$[ 1] = "rsp"
	reg86$[ 2] = "al"
	reg86$[ 3] = "dl"
	reg86$[ 4] = "bl"
	reg86$[ 5] = "cl"
	reg86$[ 6] = "ax"
	reg86$[ 7] = "dx"
	reg86$[ 8] = "bx"
	reg86$[ 9] = "cx"
	reg86$[10] = "rax"
	reg86$[11] = "rdx"
	reg86$[12] = "rbx"
	reg86$[13] = "rcx"
	reg86$[26] = "rsi"
	reg86$[27] = "rdi"
	reg86$[28] = "rcx"
	reg86$[29] = "rdx"
	reg86$[31] = "rbp"
END SUB
'
SUB LoadRegisterValues
END SUB
END FUNCTION
'
'
' ##############################
' #####  VariablesFind ()  #####
' ##############################
'
FUNCTION  VariablesFind ()
	SHARED  varSymbol$[],  variableFuncRow[]
	SHARED  exeFunction
	SHARED  variableBox
'
' Get the symbol to find
'
	XuiSendMessage (variableBox, #GetTextString, 0, 0, 0, 0, 5, @findSymbol$)
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 5, 0)
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		EXIT FUNCTION
	END IF
'
	IFZ varSymbol$[] THEN RETURN
	IFZ findSymbol$ THEN RETURN
'
'	Which symbol?
'
	lenFind = LEN(findSymbol$)
	lastVar = UBOUND(varSymbol$[])
	FOR index = 0 TO lastVar
		IF (findSymbol$ = LEFT$(varSymbol$[index], lenFind)) THEN EXIT FOR
	NEXT index
	IF (index > lastVar) THEN          ' no exact match, try to get close
		FOR index = 0 TO lastVar
			IF (UCASE$(findSymbol$) < UCASE$(varSymbol$[index])) THEN EXIT FOR
		NEXT index
		DEC index
	END IF
	'
	XuiSendMessage (variableBox, #SetTextCursor, -1, index, -1, index-1, 3, 0)
	XuiSendMessage (variableBox, #GetTextCursor, 0, @cursorLine, 0, @topLine, 3, 0)
'
	variableFuncRow[exeFunction, 0] = topLine
	variableFuncRow[exeFunction, 1] = cursorLine
END FUNCTION
'
'
' ##################################
' #####  VariablesNewValue ()  #####
' ##################################
'
'	Assign the specified simple variable the requested new value
'
'	Discussion:
'		Engaged by: RETURN in variable NewValue grid
'			Valid for all simple types (including STRING), but not arrays and composites
'
FUNCTION  VariablesNewValue ()
	TOKEN   token
	SHARED  TOKEN   varTok[]
'	ULONG  ##UCODE0,  ##UCODE,  ##UCODEX,  ##UCODEZ
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  varSymbol$[],  varReg[],  varAddr[],  varTypes$[]
	SHARED  reg86$[]
	SHARED  FRAMEINFO  variableFrame
	SHARED  funcFirstAddr[],  funcAfterAddr[]
	SHARED  exeFunction
	SHARED  variableBox
	SHARED	varShowType, varShowLocation, varShowHex
	AUTOX  newValue$
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
'	Get the new value
'
	XuiSendMessage (variableBox, #GetTextString, 0, 0, 0, 0, 7, @newValue$)
	newValue$ = TRIM$(newValue$)
'	PRINT "New value: '"; newValue$; "'"
'
	IFZ newValue$ THEN													' no new value
		RETURN
	END IF
'
' Get the variable
'
	XuiSendMessage (variableBox, #GetTextCursor, 0, @cursorLine, 0, 0, 3, 0)
	index = cursorLine
	lastVar = UBOUND(varSymbol$[])
	symbol$ = varSymbol$[index]
'
	token = varTok[index]											' better be simple type
	IF (token.tp.kind != $$KIND_VARIABLES) THEN GOTO SimpleTypesOnly
'
	tt = XxxTheType (token, exeFunction)
	IF ((kind = $$KIND_ARRAYS) OR (tt >= 0x20)) THEN
		GOTO SimpleTypesOnly
	END IF
	IFZ varTypes$[tt] THEN GOTO UnsupportedType
'
'	Prepare new values for memory (word1/word2) AND new hexValue$, value$
'		for Variables display
'
'	PRINT "VariablesNewValue(62)"
	SELECT CASE tt
		CASE $$STRING
			IF (newValue$ = "\"\"") THEN			' "" = empty
				word1 = 0
				value$ = " \"\""
				hexValue$ = " EMPTY           "
			ELSE															' strip leading/trailing "
				IF (newValue${0} = '"') THEN
					newValue$ = MID$(newValue$, 2)
					newLen = UBOUND(newValue$)		' offset and new length, if applicable
					IF (newValue${newLen} = '"') THEN newValue$ = LEFT$(newValue$, newLen)
				END IF
				newValue$ = XstBackStringToBinString$ (@newValue$)
				value$ = XstBinStringToBackString$ (@newValue$)
				IF (LEN(value$) > 61) THEN
					value$ = " \"" + LEFT$(value$, 60) + "\"*"
				ELSE
					value$ = " \"" + value$ + "\""
				END IF
'
				word1 = &newValue$							' get address of new data
				handle = &&newValue$						' clear AUTOX handle so it isn't freed
				XLONGAT(handle) = 0
				hexValue$ = "@" + LJUST$(HEX$(word1, 8), 16)
			END IF
'
		CASE $$GIANT
			value$$ = GIANT(newValue$)
			word2 = GHIGH(value$$)
			word1 = GLOW(value$$)
			hexValue$ = " " + HEX$(word2, 8) + HEX$(word1, 8)
			value$ = STR$(value$$)
'
		CASE $$SINGLE
			value! = SINGLE(newValue$)
			word1 = XMAKE(value!)
			hexValue$ = " " + LJUST$(HEX$(word1, 8), 16)
			value$ = STR$(value!)
'
		CASE $$DOUBLE
			value# = DOUBLE(newValue$)
			word2 = DHIGH(value#)
			word1 = DLOW(value#)
			hexValue$ = " " + HEX$(word2, 8) + HEX$(word1, 8)
			value$ = STR$(value#)
'
		CASE $$GOADDR, $$SUBADDR, $$FUNCADDR
			IF (newValue${0} = '&') THEN newValue$ = LCLIP$(newValue$)
			IF (RIGHT$(newValue$) = ":") THEN newValue$ = RCLIP$(newValue$)
			SELECT CASE TRUE
				CASE (newValue${0} = '0')				' 0 or 0x...
					word1 = XLONG(newValue$)
					IFZ word1 THEN EXIT SELECT
					SELECT CASE tt
						CASE $$GOADDR, $$SUBADDR		' Must be inside exeFunction
							startAddr = funcFirstAddr[exeFunction]
							endAddr = funcAfterAddr[exeFunction] - 4
							IF (word1 < startAddr) THEN GOTO OutsideFunction
							IF (word1 > endAddr)   THEN GOTO OutsideFunction
'
						CASE ELSE															' Must be inside code space
							IF ((word1 >= ##CODE0)  AND (word1 <= ##CODEZ))  THEN EXIT SELECT
							IF ((word1 >= ##UCODE0) AND (word1 <= ##UCODEZ)) THEN EXIT SELECT
							GOTO OutsideCode
					END SELECT
'
				CASE ELSE
					SELECT CASE tt
						CASE $$GOADDR
							label$ = "_g_" + newValue$ + "_" + HEX$(exeFunction)
						CASE $$SUBADDR
							label$ = "_s_" + newValue$ + "_" + HEX$(exeFunction)
						CASE ELSE
							leftParen = INSTR(newValue$, "(")
							IF leftParen THEN
								label$ = LEFT$(newValue$, leftParen - 1)
							ELSE
								label$ = newValue$
							END IF
					END SELECT
					word1 = XxxGetAddressGivenLabel(label$)
					IFZ word1 THEN GOTO LabelNotFound
			END SELECT
			hexValue$ = " " + LJUST$(HEX$(word1, 8), 16)
'
'			convert back for redisplay...
'
			value$ = " " + HEXX$(word1, 8)			' addr if can't match label
'
			IF word1 THEN
				wordAddr = &word1
				VariableTypeToValue (tt, $$FALSE, wordAddr, @hexValue$, @value$)
			END IF
'
		CASE ELSE
			word1 = XLONG(newValue$)
			hexValue$ = " " + LJUST$(HEX$(word1, 8), 16)
			value$ = STR$(word1)
'
	END SELECT		' type
'
	IF varReg[index] THEN
'		Register offset:  varReg[index]		= register used (usually rbp)
'											varAddr[index]	= signed offset (eg -8)
		register = varReg[index]
		IF (register != 31) THEN GOTO InvalidRegister
		base		= variableFrame.frameAddr
		offset	= varAddr[index]
	ELSE
'		EXTERNAL
		base		= varAddr[index]
		offset	= 0
	END IF
'
	oldWord1 = XLONGAT(base, offset)
	XLONGAT(base, offset) = word1
'
	SELECT CASE tt
		CASE $$GIANT, $$DOUBLE
			offset = offset + 4
			XLONGAT(base, offset) = word2
	END SELECT
'
	IF (tt = $$STRING) THEN
		IF AddressOk(oldWord1) THEN
			IFZ (oldWord1 AND 3) THEN
				infoWord = SLONGAT (oldWord1, -8)				' new alloc word 1
				IF (infoWord < 0) THEN xb_5_free(oldWord1)  '*cw* 210909+
			END IF
		END IF
	END IF
'
	XuiSendMessage (variableBox, #GetTextArrayLine, index, 0, 0, 0, 3, @oldText$)
	IF varShowType THEN leftPos = 32 ELSE leftPos = 22
	IF varShowLocation THEN leftPos = leftPos + 12
	IF varShowHex THEN
		newText$ = LEFT$(oldText$, leftPos) + hexValue$ + "  " + value$
	ELSE
		newText$ = LEFT$(oldText$, leftPos) + value$
	END IF
	XuiSendMessage (variableBox, #SetTextArrayLine, index, 0, 0, 0, 3, @newText$)
	XuiSendMessage (variableBox, #SetTextCursor, 0, index, 0, 0, 3, 0)
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 3, 0)
'
	message$ = ""																' Clear the new value box
	GOTO DisplayMessage
'
InvalidRegister:
	message$ = "New value invalid register:  " + reg86$[register]
	GOTO DisplayMessage
'
LabelNotFound:
	message$ = "New value label not found:  " + label$
	GOTO DisplayMessage
'
OutsideCode:
	message$ = "New value address not in code space:  " + label$
	GOTO DisplayMessage
'
OutsideFunction:
	message$ = "New value address outside current function:  " + label$
	GOTO DisplayMessage
'
UnsupportedType:
	message$ = "New value unsupported data type"
	GOTO DisplayMessage
'
SimpleTypesOnly:
	message$ = "New value for simple types only (use DETAIL for arrays, etc)"
'
DisplayMessage:
	XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 7, @message$)
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 7, 0)
END FUNCTION
'
'
' ################################
' #####  VariablesDetail ()  #####
' ################################
'
'	Respond to Variables Detail
'
'	Discussion:
'		NewValue and Detail both valid for STRING
'
FUNCTION  VariablesDetail ()
	TOKEN   token
	SHARED  TOKEN  varTok[]
	SHARED  varSymbol$[],  varReg[],  varAddr[]
	SHARED  FRAMEINFO  variableFrame
	SHARED  reg86$[]
	SHARED  exeFunction
	SHARED  variableBox
	SHARED  arrayBox,  arrayUp,  arrayIndex
	SHARED  stringBox,  stringUp
	SHARED  stringSource,  stringSymbol$,  stringHandle$,  stringFixed
	SHARED  compositeBox,  compositeUp
	SHARED  compositeType,  compositeSymbol$,  compositeHandle$,  compositeElement$
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
'	who rang?
'
	XuiSendMessage (variableBox, #GetTextCursor, 0, @cursorLine, 0, 0, 3, 0)
	index = cursorLine
	token = varTok[index]
	tt = XxxTheType(token, exeFunction)
	kind = token.tp.kind
'
	IF ((kind = $$KIND_ARRAYS) OR (tt = $$STRING) OR (tt >= 0x20)) THEN
		XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 7, "")
		XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 7, 0)
		arrayIndex = index
'
		IF (kind = $$KIND_ARRAYS) THEN
			VariablesArray (arrayBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
			RETURN
		END IF
'
'		location:  register offset ("rbp-8") or absolute address ("0xHHHHHHHH")
'
		IF varReg[index] THEN
'			Register offset:  varReg[index]		= register used (usually rbp)
'												varAddr[index]	= signed offset (eg -8)
			register = varReg[index]
			IF (register != 31) THEN
				Message ("[VariablesDetail( )]\n Invalid register " + reg86$[register] + " ")
				RETURN
			END IF
			base = variableFrame.frameAddr
'			location$ = HEXX$(base + varAddr[index],8)  '*cw* 230306-
			location$ = HEXX$(base + varAddr[index],9)  '*cw* 230306+
		ELSE
			location$ = HEXX$(varAddr[index],8)  '*cw* 230306-
'			location$ = HEXX$(varAddr[index],9)  '*cw* 230306+
		END IF
'
'		PRINT "VariablesDetail(65)", tt
		SELECT CASE TRUE
			CASE (tt = $$STRING)										' string
				IF arrayUp THEN
					VariablesArray (arrayBox, #HideWindow, 0, 0, 0, 0, 0, 0)
				END IF
				IF compositeUp THEN
					VariablesComposite (compositeBox, #HideWindow, 0, 0, 0, 0, 0, 0)
				END IF
'
				stringSource = $$SourceVariables
				stringSymbol$ = varSymbol$[index]
				stringHandle$ = location$
				stringFixed	= 0												' not a FIXED STRING
				VariablesString (stringBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
			CASE ELSE																' composite
				IF arrayUp THEN
					VariablesArray (arrayBox, #HideWindow, 0, 0, 0, 0, 0, 0)
				END IF
				IF stringUp THEN
					VariablesString (stringBox, #HideWindow, 0, 0, 0, 0, 0, 0)
				END IF
'
				compositeType = tt
				compositeSymbol$ = varSymbol$[index]
				compositeHandle$ = location$
				compositeElement$ = ""
				VariablesComposite (compositeBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		END SELECT
	ELSE
		IF arrayUp THEN
			VariablesArray (arrayBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		END IF
		IF stringUp THEN
			VariablesString (stringBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		END IF
		IF compositeUp THEN
			VariablesComposite (compositeBox, #HideWindow, 0, 0, 0, 0, 0, 0)
		END IF
		error$ = "DETAIL valid for arrays, strings, composites only"
		XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 7, @error$)
		XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 7, 0)
	END IF
END FUNCTION
'
'
' ###############################
' #####  VariablesArray ()  #####
' ###############################
'
FUNCTION  VariablesArray (grid, message, v0, v1, v2, v3, r0, (r1, r1$))
	SHARED  arrayUp, arrayBox
	SHARED  varDetailActive
'
	$functionLabel	= 1
	$symbolLabel		= 2
	$columnLabel		= 3
	$list						= 4
	$higherButton		= 5
	$lowerButton		= 6
	$indexLabel			= 7
	$indexText			= 8
	$elementLabel		= 9
	$elementText		= 10
	$button0				= 11
	$button1				= 12
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
		CASE #HideWindow		: GOSUB HideWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: GOSUB HideWindow
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****
'
SUB DisplayWindow
	VariablesArrayDisplay (0)
	XuiSendMessage (grid, #DisplayWindow, 0, 0, 0, 0, 0, 0)  ' display the window
	XuiSendMessage (grid, #DisplayWindow, 0, 0, 0, 0, 0, 0)  ' raise the window
	arrayUp = $$TRUE
END SUB
'
'
' *****  HideWindow  *****
'
SUB HideWindow
	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	arrayUp = $$FALSE
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
	SELECT CASE r0
		CASE $list
			XuiSendMessage (arrayBox, #GetTextString, 0, 0, 0, 0, 2, @label$)
			last2$ = RIGHT$(label$, 2)
			SELECT CASE last2$
				CASE ",]"		:VariablesArrayDisplay (1)
				CASE "i]"		:VariablesArrayDetail ()
			END SELECT
		CASE $higherButton	:	VariablesArrayDisplay (2)
		CASE $lowerButton		:	VariablesArrayDisplay (1)
		CASE $button0				:	VariablesArrayDetail ()
		CASE $button1				:	varDetailActive = $$FALSE : GOSUB HideWindow
		CASE $indexText
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				GOSUB HideWindow
			ELSE
				VariablesArrayIndex ()
			END IF
		CASE $elementText
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				GOSUB HideWindow
			ELSE
				VariablesArrayElement ()
			END IF
	END SELECT
END SUB
END FUNCTION
'
'
' ######################################
' #####  VariablesArrayDisplay ()  #####
' ######################################
'
'	Control the Array box based on the action requested
'
'	In:		action =	0	- display new symbol
'									1 - step down
'									2 - step up
'									3 - View element (from ArrayElement)
'									4 - Redisplay
'
FUNCTION  VariablesArrayDisplay (action)
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   pEleToken[]
	TOKEN   pToken[]
	SHARED  TOKEN  varTok[]
	SHARED  varSymbol$[],  varDataAddr[]
	SHARED  varTypes$[]
	SHARED  exeFunction,  exeLine
	SHARED  arrayBox,  arrayUp
	SHARED  arrayIndex
	SHARED  arrayViewIndices[],  arrayNumViewIndices
	STATIC  arrayLevel,  arrayIndices[]
	STATIC  lastFunction,  lastLine
	AUTOX  copyString$
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
'	IF ##XBDV THEN PRINT "VariablesArrayDisplay(35)", tt, wordAdd, hexValue$, value$
	IF ((arrayUp = $$FALSE) OR (lastFunction != exeFunction) OR (lastLine != exeLine)) THEN
		XxxFunctionName ($$XGET, @funcName$, exeFunction)
		IF (LEN(funcName$) > 30) THEN funcName$ = LEFT$(funcName$, 29) + "*"
		label$ = "FUNCTION:    " + funcName$ + "    LINE:  " + STRING$(exeLine + 1)
		XuiSendMessage (arrayBox, #SetTextString, 0, 0, 0, 0, 1, @label$)
		XuiSendMessage (arrayBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
		lastFunction = exeFunction
		lastLine = exeLine
	END IF
'
	XuiSendMessage (arrayBox, #GetTextCursor, 0, @cursorLine, 0, 0, 4, 0)
'
'	IF ##XBDV THEN PRINT "VariablesArrayDisplay(*1):action =", action
	cursorIndex = 0													' default: cursor on first line
	SELECT CASE action
		CASE 0																' display top level
			arrayLevel = 0
			DIM arrayIndices[7]
		CASE 1																' step down
			stepDownIndex = cursorLine
		CASE 2																' step up
			IF arrayLevel THEN
				arrayIndices[arrayLevel] = 0
				DEC arrayLevel
				cursorIndex = arrayIndices[arrayLevel]
			END IF
		CASE 3																' View Element
			arrayLevel = 0											' Reset array level info
			DIM arrayIndices[7]
'			cursorIndex = arrayViewIndices[0]
		CASE 4																' Redisplay
			cursorIndex = cursorLine
	END SELECT
'
	tt = XxxTheType (varTok[arrayIndex], exeFunction)
	type$ = TRIM$(varTypes$[tt])						' guaranteed valid type
	symbol$ = varSymbol$[arrayIndex]
	symbol$ = RCLIP$(symbol$, 1)						' strip ] for now
'
'	IF ##XBDV THEN PRINT "VariablesArrayDisplay(B):type$, symbol$ =", tt, type$, symbol$
'
	dataAddr = varDataAddr[arrayIndex]
	level = 0
	DO WHILE (level <= arrayLevel)
		IFZ dataAddr THEN
			IFZ notLowDim THEN
				symbol$ = symbol$ + "]"
			ELSE
				symbol$ = symbol$ + ",]"
			END IF
			label$ = type$ + "  " + symbol$
			XuiSendMessage (arrayBox, #SetTextString, 0, 0, 0, 0, 2, @label$)
			XuiSendMessage (arrayBox, #RedrawGrid, 0, 0, 0, 0, 2, 0)
			viewLabel$ = LJUST$("View Index []", 27)
			XuiSendMessage (arrayBox, #SetTextString, 0, 0, 0, 0, 7, @viewLabel$)
			XuiSendMessage (arrayBox, #RedrawGrid, 0, 0, 0, 0, 7, 0)
			DIM text$[0]
			text$[0] = "EMPTY array"
			XuiSendMessage (arrayBox, #SetTextArray, 0, 0, 0, 0, 4, @text$[])
			XuiSendMessage (arrayBox, #SetTextCursor, 0, 0, 0, 0, 4, 0)
			XuiSendMessage (arrayBox, #RedrawText, 0, 0, 0, 0, 4, 0)
			RETURN
		END IF
		elements = XLONGAT(dataAddr, -16)
		infoWord = ULONGAT(dataAddr, -8)
'	IF ##XBDV THEN PRINT "VariablesArrayDisplay(101)", HEXX$(infoWord), elements
		eleSize = infoWord{$$ELESIZE}
'
'		infoWord:	bit 29 = NON-LOW-DIM  (1 = non-low-dim, 0 = lowest dimension)
'							Byte 2 = Data Type  (0 - 0xFF)
'											= 0x1F means composite user Data type number exceeds 0xFF
'												(problem if user ATTACHes a different composite to
'														a node where both type numbers exceed 0xFF.
'														If the info word eleSize is different than the
'														array type eleSize, then I KNOW an ATTACH has been
'														done.  Otherwise, interpret the data as the same
'														type, but issue the user a warning.)
'
		notLowDim = infoWord{{$$NOT_LOWEST_DIM}}
		dataType = infoWord{$$BYTE2}
'
		IF (level = arrayLevel) THEN
			IF (action = 1) THEN										' step down
				IF notLowDim THEN											' only if not lowest Dim
					uArray = UBOUND(arrayIndices[])
					IF (arrayLevel >= uArray) THEN
						uArray = arrayLevel + (arrayLevel >> 1)
						REDIM arrayIndices[uArray]
					END IF
					arrayIndices[arrayLevel] = stepDownIndex
					INC arrayLevel
					offset = stepDownIndex * eleSize
					dataAddr = XLONGAT(dataAddr, offset)
					IFZ level THEN
						symbol$ = symbol$ + STRING$(stepDownIndex)
					ELSE
						symbol$ = symbol$ + "," + STRING$(stepDownIndex)
					END IF
					INC level
					action = 0
					DO DO
				END IF
			END IF
'	IF ##XBDV THEN PRINT "VariablesArrayDisplay(*3.9):dataType, tt ", dataType, tt, UBOUND(varTypes$[])
'
			IF (action = 3) THEN										' View Element
				IF notLowDim THEN											' keep going only if more Dims
					IF (arrayNumViewIndices > arrayLevel) THEN
						uArray = UBOUND(arrayIndices[])
						IF (arrayLevel >= uArray) THEN
							uArray = arrayLevel + (arrayLevel >> 1)
							REDIM arrayIndices[uArray]
						END IF
						index = arrayViewIndices[arrayLevel]
						IF (index > elements - 1) THEN		' requested index is out of bounds
							index = elements - 1						'		stop here
							arrayNumViewIndices = arrayLevel + 1
						END IF
						arrayIndices[arrayLevel] = index
						INC arrayLevel
						offset = index * eleSize
						dataAddr = XLONGAT(dataAddr, offset)
						IFZ dataAddr THEN									' Empty node, stop here
							arrayNumViewIndices = arrayLevel + 1
						END IF
						IFZ level THEN
							symbol$ = symbol$ + STRING$(index)
						ELSE
							symbol$ = symbol$ + "," + STRING$(index)
						END IF
						INC level
						DO DO
					END IF
				END IF
			END IF
'
			IFZ notLowDim THEN												' low dim
				IFZ level THEN
					symbol$ = symbol$ + "i]"
				ELSE
					symbol$ = symbol$ + ",i]"
				END IF
				IF (dataType != tt) THEN								' node may be a dIfferent type
					IF (dataType != 0x1F) THEN						' identifiable type in info word
					IF (dataType <= UBOUND(varTypes$[])) THEN
						tt = dataType
					END IF
					IF (tt <= UBOUND(varTypes$[])) THEN
						type$ = TRIM$(varTypes$[tt])
					END IF
						statusComposite = 1
					ELSE																	' info word is unknown composite
'						Default: unsure if same composite
						statusComposite = 2
						IF (tt <= 0xFF) THEN								' array type is known
'							Array type is known, info type isn't:  definitely a different type
							statusComposite = 3
							type$ = "??? "
						ELSE
'							If array size != info size:  definitely a different type
'
'							Get size of array element
'
			XxxPassTypeArrays ($$XGET, @pSize[], @pSize$[], @pAlias[], @pAlign[], @pSymbol$[], @pToken[], @pEleCount[], @pEleSymbol$[], @pEleToken[], @pEleAddr[], @pEleSize[], @pEleType[], @pEleStringSize[], @pEleUBound[])
			typeSize = pSize[tt]
			XxxPassTypeArrays ($$XSET, @pSize[], @pSize$[], @pAlias[], @pAlign[], @pSymbol$[], @pToken[], @pEleCount[], @pEleSymbol$[], @pEleToken[], @pEleAddr[], @pEleSize[], @pEleType[], @pEleStringSize[], @pEleUBound[])
'
'							Get size of this node's element
'
							infoSize = infoWord{$$WORD0}
'
							IF (infoSize != typeSize) THEN
								statusComposite = 3
								type$ = "??? "
							END IF
						END IF
					END IF
				END IF
			ELSE																			' not low dim
				IFZ level THEN
					symbol$ = symbol$ + "i,]"
				ELSE
					symbol$ = symbol$ + ",i,]"
				END IF
				tt = $$XLONG
			END IF
			EXIT DO
		END IF
		nextIndex = arrayIndices[level]							' get next level dataAddr
		offset = nextIndex * eleSize
		dataAddr = XLONGAT(dataAddr, offset)
		IFZ level THEN
			symbol$ = symbol$ + STRING$(nextIndex)
		ELSE
			symbol$ = symbol$ + "," + STRING$(nextIndex)
		END IF
		INC level
	LOOP
'
'	Maybe display dataAddr (base array address) as label
'   - maybe UBOUND, handle...
'
	label$ = type$ + "  " + symbol$
	XuiSendMessage (arrayBox, #GetTextString, 0, 0, 0, 0, 2, @oldLabel$)
	IF (label$ != oldLabel$) THEN
		XuiSendMessage (arrayBox, #SetTextString, 0, 0, 0, 0, 2, @label$)
		XuiSendMessage (arrayBox, #RedrawGrid, 0, 0, 0, 0, 2, 0)
	END IF
'
	lastElement = elements - 1
	label$ = LJUST$("View Index [0-" + STRING$(lastElement) + "]", 27)
	XuiSendMessage (arrayBox, #GetTextString, 0, 0, 0, 0, 7, @oldLabel$)
	IF (label$ != oldLabel$) THEN
		XuiSendMessage (arrayBox, #SetTextString, 0, 0, 0, 0, 7, @label$)
		XuiSendMessage (arrayBox, #RedrawGrid, 0, 0, 0, 0, 7, 0)
	END IF
'
	DIM arrayText$[lastElement]
	indexAddr = dataAddr
	FOR index = 0 TO lastElement
		index$ = LJUST$(STRING$(index), 10)
		loc$ = HEX$(indexAddr, 8)
		IF notLowDim THEN
			word1 = XLONGAT(indexAddr)
			IFZ word1 THEN
				arrayText$[index] = index$ + " " + loc$ + "     EMPTY"
			ELSE
				arrayText$[index] = index$ + " " + loc$ + "    @" + HEX$(word1, 8)
'				PRINT "VariablesArrayDisplay(268)", arrayText$[index]
			END IF
		ELSE
			VariableTypeToValue (tt, $$TRUE, indexAddr, @hexValue$, @value$)
			arrayText$[index] = index$ + " " + loc$ + "    " + hexValue$ + " " + value$
		END IF		' notLowDim
'
		indexAddr = indexAddr + eleSize
	NEXT index
	XuiSendMessage (arrayBox, #SetTextArray, 0, 0, 0, 0, 4, @arrayText$[])
	XuiSendMessage (arrayBox, #SetTextCursor, 0, cursorIndex, 0, 0, 4, 0)
	XuiSendMessage (arrayBox, #RedrawText, 0, 0, 0, 0, 4, 0)
END FUNCTION
'
'
' ####################################
' #####  VariablesArrayIndex ()  #####
' ####################################
'
'	View the requested array index in the Array box
'
FUNCTION  VariablesArrayIndex ()
	SHARED  arrayBox
'
' Get the requested index
'
	XuiSendMessage (arrayBox, #GetTextString, 0, 0, 0, 0, 8, @index$)
	XuiSendMessage (arrayBox, #SetTextString, 0, 0, 0, 0, 8, "")
	XuiSendMessage (arrayBox, #RedrawText, 0, 0, 0, 0, 8, 0)
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
	index$ = TRIM$(index$)
	index# = DOUBLE(index$)
	SELECT CASE TRUE
		CASE (index# < 0):					index = 0
		CASE (index# > 0x7FFFFFFF):	index = 0x7FFFFFFF
		CASE ELSE:									index = index#
	END SELECT
'
	XuiSendMessage (arrayBox, #SetTextCursor, 0, index, -1, 0, 4, 0)
	XuiSendMessage (arrayBox, #RedrawText, 0, 0, 0, 0, 4, 0)
END FUNCTION
'
'
' ######################################
' #####  VariablesArrayElement ()  #####
' ######################################
'
'	Display the requested array element ([1,2,3,]) in the Array box
'
'	Discussion:
'		Should this display 'Syntax Error'?  (currently just returns)
'
FUNCTION  VariablesArrayElement ()
	SHARED  arrayBox
	SHARED  arrayViewIndices[],  arrayNumViewIndices
'
' Get the requested element
'
	XuiSendMessage (arrayBox, #GetTextString, 0, 0, 0, 0, 10, @rawElement$)
	XuiSendMessage (arrayBox, #SetTextString, 0, 0, 0, 0, 10, "")
	XuiSendMessage (arrayBox, #RedrawText, 0, 0, 0, 0, 10, 0)
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
PRINT "VariablesArrayElement(27)", rawlement$
	rawElement$ = TRIM$(rawElement$)
	IFZ rawElement$ THEN
		VariablesArrayDisplay (0)
		RETURN
	END IF
'
'	Clean up syntax (keep only 0-9 and ,)
	lenRawElement = LEN(rawElement$)
	element$ = NULL$ (lenRawElement)
	j = 0
	FOR i = 0 TO (lenRawElement - 1)
		cchar = rawElement${i}
		IF ( ((cchar >= '0') AND (cchar <= '9')) OR (cchar = ',')) THEN
			element${j} = cchar
			INC j
		ELSE
			IF (cchar = ' ') THEN DO NEXT
			IF ((i = 0) AND (cchar = '[')) THEN DO NEXT
			IF ((i = lenRawElement - 1) AND (cchar = ']')) THEN DO NEXT
			RETURN																' Syntax error
		END IF
	NEXT i
	IFZ j THEN RETURN
	IF (element${0} = ',') THEN RETURN				' Syntax error
	IF INSTR(element$, ",,") THEN RETURN			' Syntax error
'
	lenElement = j
	arrayNumViewIndices = 0
	uArray = UBOUND(arrayViewIndices[])
	ptr = 1
'
	DO WHILE (ptr <= lenElement)
		index# = DOUBLE(MID$(element$, ptr))
		SELECT CASE TRUE
			CASE (index# < 0):					index = 0
			CASE (index# > 0x7FFFFFFF):	index = 0x7FFFFFFF
			CASE ELSE:									index = index#
		END SELECT
'
		IF (arrayNumViewIndices > uArray) THEN
			uArray = (uArray + (uArray >> 1)) OR 3
			REDIM arrayViewIndices[uArray]
		END IF
		arrayViewIndices[arrayNumViewIndices] = index
		INC arrayNumViewIndices
'
		comma = INSTR(element$, ",", ptr)
		IFZ comma THEN EXIT DO
		ptr = comma + 1
	LOOP
	VariablesArrayDisplay (3)
END FUNCTION
'
'
' #####################################
' #####  VariablesArrayDetail ()  #####
' #####################################
'
'	Show detail on composite or STRING array element
'
FUNCTION  VariablesArrayDetail ()
	SHARED  varTypes$[]
	SHARED  arrayBox,  stringBox,  compositeBox
	SHARED  stringSource,  stringSymbol$,  stringHandle$,  stringFixed
	SHARED  compositeType,  compositeSymbol$,  compositeHandle$,  compositeElement$
	STATIC  arrayCompositeHandle
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
'	Symbol label
'
	XuiSendMessage (arrayBox, #GetTextString, 0, 0, 0, 0, 2, @label$)
'
'	Detail on lowest dimension only
'
	last2$ = RIGHT$(label$, 2)
	IF (last2$ = ",]") THEN RETURN							' not lowest dimension
	IF (last2$ != "i]") THEN RETURN			' huh???
'
'	Identify the type
'
	sp = INSTR (label$, " ")
	IFZ sp THEN RETURN													' unknown type
	type$ = LEFT$(label$, sp - 1)
	symbol$ = TRIM$(MID$(label$, sp))
'
	uType = UBOUND (varTypes$[])
	FOR i = 0 TO uType
		IF (type$ = TRIM$(varTypes$[i])) THEN
			tt = i
			EXIT FOR
		END IF
	NEXT i
'
	IFZ tt THEN RETURN													' unknown type
'
'	Detail on STRING and composite only
'
	IF ((tt != $$STRING) AND (tt < 0x20)) THEN
		RETURN																		' no detail on this type
	END IF
'
'
'	Get requested line
'
	XuiSendMessage (arrayBox, #GetTextCursor, 0, @cursorLine, 0, 0, 4, 0)
	IF (cursorLine < 0) THEN RETURN
	XuiSendMessage (arrayBox, #GetTextArrayLine, @cursorLine, 0, 0, 0, 4, @line$)
'
'	Get index (column 1)
'
	sp = INSTR (line$, " ")
	index$ = LEFT$(line$, sp - 1)
	IF (index$ = "EMPTY") THEN RETURN						' "empty array"
	symbol$ = RCLIP$(symbol$, 2) + index$ + "]"	' specify index in symbol$
'
'
'	Get Location (column 12)
'
	sp = INSTR (line$, " ", 12)
	location$ = "0x" + MID$(line$, 12, sp - 12)
	location = XLONG (location$)
	IFZ location THEN RETURN										' shouldn't happen
'
	IF (tt = $$STRING) THEN											' string
		stringSource = $$SourceArrays
		stringSymbol$ = symbol$
		stringHandle$ = location$
		stringFixed = 0														' not a FIXED STRING
		VariablesString (stringBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	ELSE																				' composite
		compositeType = tt
		compositeSymbol$ = symbol$
'
'		location points to the DATA, need a fake handle
'
		arrayCompositeHandle = location
		compositeHandle$ = HEXX$(&arrayCompositeHandle, 8)
		compositeElement$ = ""
		VariablesComposite (compositeBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	END IF
END FUNCTION
'
'
' ################################
' #####  VariablesString ()  #####
' ################################
'
'	Give detail on the specified string
'
'	Discussion:
'		stringSymbol$, stringHandle$ contain the symbol and handle to work with
'
FUNCTION  VariablesString (grid, message, v0, v1, v2, v3, r0, r1)
	SHARED  exeFunction,  exeLine
	SHARED  stringUp,  compositeBox
	SHARED  stringSource,  stringSymbol$,  stringHandle$,  stringFixed
	SHARED  varDetailActive
	STATIC  stringBackMode
	AUTOX  text$
'
	$functionLabel	= 1
	$symbolLabel		= 2
	$textArea				= 3
	$toggle					= 4
	$button0				= 5
	$button1				= 6
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
		CASE #HideWindow		: GOSUB HideWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: GOSUB HideWindow
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****  'grid' unused : stringHandle$ (NOT text) is used to enable alteration
'
SUB DisplayWindow
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		RETURN
	END IF
'
	XxxFunctionName ($$XGET, @funcName$, exeFunction)
	IF (LEN(funcName$) > 30) THEN funcName$ = LEFT$(funcName$, 29) + "*"
	label$ = "FUNCTION:    " + funcName$ + "    LINE:  " + STRING$(exeLine + 1)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $functionLabel, @label$)
	XuiSendMessage (grid, #RedrawGrid, 0, 0, 0, 0, $functionLabel, 0)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $symbolLabel, @stringSymbol$)
	XuiSendMessage (grid, #RedrawGrid, 0, 0, 0, 0, $symbolLabel, 0)
'
' get the string data
'
	IF stringFixed THEN
		textAddr = XLONG (stringHandle$)						' actually, data address
	ELSE
		IF (stringHandle${0} = 'r') THEN						' handle is a register
			register = XLONG (MID$(stringHandle$, 2))	'		guaranteed valid register
'			textAddr = ##REG[register]
		ELSE																				' specific address (0x...)
			handleAddr = XLONG (stringHandle$)
			textAddr = XLONGAT (handleAddr)
		END IF
	END IF
'
'	PRINT "String:  '"; stringHandle$; "'", HEXX$(textAddr)
'
' make a copy
'
	text$ = ""
	IF stringFixed THEN														' composite Fixed String = data address
		text$ = NULL$ (stringFixed + 1)							' copy original text, add EMPTY
		FOR i = 0 TO (stringFixed - 1)
			text${i} = UBYTEAT(textAddr, i)
		NEXT i
	ELSE
		IF textAddr THEN
			lenText = XLONGAT (textAddr, -16)
			IF lenText THEN
				text$ = NULL$ (lenText)									' copy original text
				FOR i = 0 TO lenText - 1
					text${i} = UBYTEAT (textAddr, i)
				NEXT i
			END IF
		END IF
	END IF
'
	IF stringBackMode THEN text$ = XstBinStringToBackStringNL$ (@text$)
	XstStringToStringArray (@text$, @text$[])
'
'	PRINT "Detail String '"; text$; "'"
'	PRINT "Detail Array:"
'	FOR i = 0 TO UBOUND(text$[])
'		PRINT "  "; i; "'"; text$[i]; "'"
'	NEXT i
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @text$[])
	XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $textArea, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
	XuiSendMessage (grid, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	stringUp = $$TRUE
END SUB
'
'
' *****  HideWindow  *****
'
SUB HideWindow
	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	stringUp = $$FALSE
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE r0
		CASE $toggle	:	XuiSendMessage (grid, #GetValues, @newMode, 0, 0, 0, $toggle, 0)
										GOSUB NewStringMode
		CASE $button0	:	GOSUB NewStringValue
		CASE $button1	:	varDetailActive = $$FALSE : GOSUB HideWindow
	END SELECT
END SUB
'
'
' *****  NewStringMode  *****  Convert detail string from binary to back
'
SUB NewStringMode
	IF (newMode = stringBackMode) THEN EXIT SUB
	stringBackMode = newMode
	XuiSendMessage (grid, #GetTextArray, 0, 0, 0, 0, $textArea, @text$[])
	XuiSendMessage (grid, #GetTextCursor, 0, @cursorLine, 0, @topLine, $textArea, 0)
	IFZ text$[] THEN EXIT SUB
	XstStringArrayToString (@text$[], @text$)		' No CRLF
	IF stringBackMode THEN											' Convert from bin to back
		text$ = XstBinStringToBackStringNL$ (@text$)		' leave \n
	ELSE																				' Convert from back to bin
		text$ = XstBackStringToBinString$ (@text$)
	END IF
	XstStringToStringArray (@text$, @text$[])
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @text$[])
	XuiSendMessage (grid, #SetTextCursor, 0, cursorLine, 0, topLine, $textArea, 0)
	XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $textArea, 0)
END SUB
'
'
' *****  NewStringValue  *****
'		Replace displayed detail string with current text
'			- Uses handle to replace the original string data!
'
SUB NewStringValue
	XuiSendMessage (grid, #GetTextArray, 0, 0, 0, 0, $textArea, @text$[])
	text$ = ""
	IF text$[] THEN
		XstStringArrayToString (@text$[], @text$)		' No CRLF
		IF stringBackMode THEN											' Convert from back to bin
			text$ = XstBackStringToBinString$ (@text$)
		END IF
	END IF
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $textArea, @text$[])
	XuiSendMessage (grid, #SetTextCursor, 0, 0, 0, 0, $textArea, 0)
'	PRINT "NewValue$: '"; text$; "'"
'
	IF stringFixed THEN														' stringFixed = size
		text$ = LJUST$(text$, stringFixed)					' pad/truncate with spaces
		oldTextAddr = XLONG (stringHandle$)					' actually, fixed data address
		FOR i = 0 TO (stringFixed - 1)
			UBYTEAT (oldTextAddr, i) = text${i}
		NEXT i
	ELSE
		IF (stringHandle${0} = 'r') THEN						' handle is a register
			register = XLONG (MID$(stringHandle$, 2))	'		guaranteed valid register
'			oldTextAddr = ##REG[register]
'			IF oldTextAddr THEN free (oldTextAddr)
'			##REG[register] = &text$
		ELSE																				' specific address (0x...)
			handleAddr = XLONG (stringHandle$)
			oldTextAddr = XLONGAT (handleAddr)
			IF oldTextAddr THEN free (oldTextAddr)
			XLONGAT (handleAddr) = &text$
		END IF
		textHandle = &&text$												' don't free text$
		XLONGAT(textHandle) = 0
	END IF
'
	SELECT CASE stringSource											' update displays
		CASE $$SourceVariables	: UpdateVariables()
		CASE $$SourceArrays			: VariablesArrayDisplay (4)
		CASE $$SourceComposites	: VariablesComposite (compositeBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
END FUNCTION
'
'
' ###################################
' #####  VariablesComposite ()  #####
' ###################################
'
'	Composite box
'
FUNCTION  VariablesComposite (grid, message, v0, v1, v2, v3, r0, r1)
	SHARED  compositeElement$
	SHARED  varDetailActive
	SHARED  compositeUp
'
	$functionLabel	= 1
	$symbolLabel		= 2
	$columnLabel		= 3
	$list						= 4
	$higherButton		= 5
	$lowerButton		= 6
	$viewLabel			= 7
	$viewText				= 8
	$button0				= 9
	$button1				= 10
'
'IF ##XBDV THEN PRINT "VariablesComposite(*):"grid, message, v0, v1, v2, v3, r0, r1
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
		CASE #HideWindow		: GOSUB HideWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: GOSUB HideWindow
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****
'
SUB DisplayWindow
	VariablesCompositeDisplay (0)
	XuiSendMessage (grid, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	compositeUp = $$TRUE
END SUB
'
'
' *****  HideWindow  *****
'
SUB HideWindow
'	PRINT "VariablesComposite() : HideWindow : "; grid; "#HideWindow"
	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	compositeUp = $$FALSE
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		SELECT CASE r0
			CASE $button1		: GOSUB HideWindow
			CASE $viewText	: IF (v0{$$VirtualKey} = $$KeyEscape) THEN GOSUB HideWindow
		END SELECT
		RETURN
	END IF
'
	SELECT CASE r0
		CASE $higherButton:		VariablesCompositeDisplay (2)
		CASE $lowerButton:		VariablesCompositeDisplay (1)
		CASE $button0:				VariablesCompositeDisplay (3)
		CASE $button1:				varDetailActive = $$FALSE : GOSUB HideWindow
		CASE $viewText
			IF (v0{$$VirtualKey} = $$KeyEscape) THEN
				GOSUB HideWindow
			ELSE
				XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $viewText, @compositeElement$)
				XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $viewText, "")
				XuiSendMessage (grid, #RedrawText, 0, 0, 0, 0, $viewText, 0)
				VariablesCompositeDisplay (0)
			END IF
	END SELECT
END SUB
END FUNCTION
'
'
' ##########################################
' #####  VariablesCompositeDisplay ()  #####
' ##########################################
'
'	Display detail on a composite variable in the Composite box
'
'	In:				action		0	- display element
'											1 - step down
'											2 - step up
'											3 - Detail (fixed STRINGs only)
'	Discussion:
'		The type arrays (from the compiler):
'		typeName$					[type]			' "sbyte", "ubyte"...
'		typeSize					[type]			' size in bytes
'		typeSize$					[type]			' "2", "4", "8", "16"...
'		typeAlias					[type]			' normal type that user-type is alias for
'		typeAlign					[type]			' alignment for this type
'		typeSuffix$				[type]			' @  @@  %  %%  &  &&  ~  !  #  $$  $
'		typeSymbol$				[type]			' SBYTE, UBYTE...  SCOMPLEX, DCOMPLEX, USERTYPE...
'		typeToken					[type]			' #T_TYPE token, low word = type #
'		typeEleCount			[type]			' # of elements in this type
'		typeEleSymbol$		[type,n]		' symbol for each n elements
'		typeEleToken			[type,n]		' token for each n elements
'		typeEleAddr				[type,n]		' offset address of each n elements
'		typeEleSize				[type,n]		' size of each n elements ([]: typesize*(dim+1))
'		typeEleType				[type,n]		' type of each n elements
'		typeElePtr				[type,n]		' # indirection levels for each n elements
'		typeEleVal				[type,n]		' init value of each n elements
'		typeEleStringSize	[type,n]		' # bytes in fixed string for element n
'		typeEleUBound			[type,n]		' Upper bound of 1D array for element n
'
FUNCTION  VariablesCompositeDisplay (action)
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   token
	TOKEN   pEleToken[]
	TOKEN   pToken[]
	SHARED  varTypes$[]
	SHARED  exeFunction,  exeLine
	SHARED  compositeBox,  compositeUp
	SHARED  compositeType,  compositeSymbol$,  compositeHandle$,  compositeElement$
	SHARED  stringBox,  stringSource,  stringSymbol$,  stringHandle$,  stringFixed
	STATIC  lastFunction,  lastLine
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		EXIT FUNCTION
	END IF
'
	IF ((compositeUp = $$FALSE) OR (lastFunction != exeFunction) OR (lastLine != exeLine)) THEN
		XxxFunctionName ($$XGET, @funcName$, exeFunction)
		IF (LEN(funcName$) > 30) THEN funcName$ = LEFT$(funcName$, 29) + "*"
		label$ = "FUNCTION:    " + funcName$ + "    LINE:  " + STRING(exeLine + 1)
		XuiSendMessage (compositeBox, #SetTextString, 0, 0, 0, 0, 1, @label$)
		XuiSendMessage (compositeBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
		lastFunction = exeFunction
		lastLine = exeLine
	END IF
	XuiSendMessage (compositeBox, #SetTextString, 0, 0, 0, 0, 2, @compositeSymbol$)
	XuiSendMessage (compositeBox, #RedrawGrid, 0, 0, 0, 0, 2, 0)
'
'	Get the composite data address
'		composite data is always contiguous--no composite pointers
'
	IF (compositeHandle${0} = 'r') THEN							' handle is a register
		register = XLONG (MID$(compositeHandle$, 2))	'		guaranteed valid register
'		dataAddr = ##REG[register]
	ELSE																						' specific address (0x...)
		handleAddr = XLONG (compositeHandle$)
		dataAddr = XLONGAT (handleAddr)
	END IF
'
	IFZ dataAddr THEN
		DIM text$[0]
		text$[0] = "EMPTY"
		XuiSendMessage (compositeBox, #SetTextArray, 0, 0, 0, 0, 4, @text$[])
		XuiSendMessage (compositeBox, #SetTextCursor, 0, 0, 0, 0, 4, 0)
		XuiSendMessage (compositeBox, #RedrawText, 0, 0, 0, 0, 4, 0)
		RETURN
	END IF
'
	SELECT CASE action
		CASE 1																' step down
			XuiSendMessage (compositeBox, #GetTextCursor, 0, @cursorLine, 0, 0, 4, 0)
			stepDownIndex = cursorLine
		CASE 2																' step up
			IF compositeElement$ THEN
				IF (RIGHT$(compositeElement$, 1) = "]") THEN				' array
					IF (RIGHT$(compositeElement$, 3) != "[i]") THEN		' show full array
						bracket = RINSTR (compositeElement$, "[")
						compositeElement$ = LEFT$(compositeElement$, bracket - 1) + "[i]"
						EXIT SELECT
					END IF
				END IF
				dot = RINSTR (compositeElement$, ".")
				IF (dot <= 1) THEN
					compositeElement$ = ""
				ELSE
					compositeElement$ = LEFT$(compositeElement$, dot - 1)
				END IF
			END IF
		CASE 3																' Detail Fixed string
			XuiSendMessage (compositeBox, #GetTextCursor, 0, @cursorLine, 0, 0, 4, 0)
			detailIndex = cursorLine
	END SELECT
'
'	Get type arrays (pass them back before exiting!!!)
	XxxPassTypeArrays ($$XGET, @pSize[], @pSize$[], @pAlias[], @pAlign[], @pSymbol$[], @pToken[], @pEleCount[], @pEleSymbol$[], @pEleToken[], @pEleAddr[], @pEleSize[], @pEleType[], @pEleStringSize[], @pEleUBound[])
'
'	step down compositeElement$ (".A.B.C")
'
	viewType			= compositeType						' start at the top
	viewDataAddr	= dataAddr
	viewElement$	= ""
	element$ = compositeElement$
'
	DO WHILE (LEN(element$) OR (action = 1))
		IFZ element$ THEN
			IF (action = 1) THEN
				IF (RIGHT$(viewElement$, 3) = "[i]") THEN
					IF (viewType < 0x20) THEN EXIT DO				' Can't step into simple types
					lenViewElement = LEN(viewElement$)
					viewElement$ = LEFT$(viewElement$, lenViewElement - 3)
					viewElement$ = viewElement$ + "[" + STRING(stepDownIndex) + "]"
					IF (viewType = $$STRING) THEN
						arrayElementSize = fixedStringSize
					ELSE
						arrayElementSize = pSize[viewType]
					END IF
					viewDataAddr = viewDataAddr + stepDownIndex * arrayElementSize
				ELSE
					IF (stepDownIndex > pEleCount[viewType]) THEN EXIT DO
					stepDownType = pEleType[viewType, stepDownIndex]
					token = pEleToken[viewType, stepDownIndex]
					IF (token.tp.kind = $$KIND_ARRAY_SYMBOLS) THEN
						viewElement$ = viewElement$ + pEleSymbol$[viewType, stepDownIndex] + "[i]"
						arrayUBound = pEleUBound[viewType, stepDownIndex]
						'
						IF (stepDownType = $$STRING) THEN
							fixedStringSize = pEleStringSize[viewType, stepDownIndex]
						END IF
					ELSE
						IF (stepDownType < 0x20) THEN EXIT DO		' Can't step into simple types
						viewElement$ = viewElement$ + pEleSymbol$[viewType, stepDownIndex]
					END IF
					viewDataAddr = viewDataAddr + pEleAddr[viewType, stepDownIndex]
					viewType = stepDownType
				END IF
			END IF
			EXIT DO
		END IF
'
'		Get next requested subelement
'
		IF (element${0} != '.') THEN EXIT DO		' abort on syntax error
		dot2 = INSTR (element$, ".", 2)
		IF dot2 THEN
			nextElement$ = TRIM$(LEFT$(element$, dot2 - 1))
			element$ = MID$(element$, dot2)
		ELSE
			nextElement$ = TRIM$(element$)
			element$ = ""
		END IF
'
'		Strip out []
'
		bracket = INSTR(nextElement$, "[")
		IF bracket THEN
			testElement$ = LEFT$(nextElement$, bracket - 1)
		ELSE
			testElement$ = nextElement$
		END IF
'
'		Identify type
'
		IF pEleCount[] THEN
			lastIndex = pEleCount[viewType] - 1
			FOR index = 0 TO lastIndex
				IF (testElement$ = pEleSymbol$[viewType, index]) THEN EXIT FOR
			NEXT index
			IF (index > lastIndex) THEN EXIT DO			' abort if not found
			nextType = pEleType[viewType, index]
			IF (nextType = $$STRING) THEN
				fixedStringSize = pEleStringSize[viewType, index]
			END IF
		END IF
'
' if array, add in index offset to requested element (1D only)
'
		IF (viewType > UBOUND(pEleToken[])) THEN
			PRINT "VariablesCompositeDisplay(192)", viewType, UBOUND(pEleToken[])
			EXIT DO
		END IF
		IF (index > UBOUND(pEleToken[viewType,])) THEN
			PRINT "VariablesCompositeDisplay(196)", index, UBOUND(pEleToken[viewType,])
			EXIT DO
		END IF
		token = pEleToken[viewType, index]
		IF (bracket OR (token.tp.kind = $$KIND_ARRAY_SYMBOLS)) THEN
			IF (token.tp.kind != $$KIND_ARRAY_SYMBOLS) THEN EXIT DO		' not an array
'
			arrayUBound = pEleSize[viewType, index]
'
			IF (nextType < 0x20) THEN							' can't step into simple types
				viewElement$	= viewElement$ + testElement$ + "[i]"
				viewDataAddr	= viewDataAddr + pEleAddr[viewType, index]
				viewType			= nextType
				EXIT DO
			END IF
'
			IFZ bracket THEN nextElement$ = nextElement$ + "[i]"
			lenNextElement = LEN(nextElement$)
			IF (nextElement${lenNextElement - 1} != ']') THEN
				IF (bracket != lenNextElement) THEN EXIT DO							' syntax error
'
'				add matching ']', then stop here
'
				viewElement$	= viewElement$ + nextElement$ + "i]"
				viewDataAddr	= viewDataAddr + pEleAddr[viewType, index]
				viewType			= nextType
				IF (action = 1) THEN								' step into array
					element$ = ""
					DO DO
				END IF
				EXIT DO
			END IF
'
'			stop here if no index ([])
'
			arrayIndex$ = MID$(nextElement$, bracket + 1, (lenNextElement - bracket -1))
			arrayIndex$ = TRIM$(arrayIndex$)
			IFZ arrayIndex$ THEN
				viewElement$	= viewElement$ + testElement$ + "[i]"
				viewDataAddr	= viewDataAddr + pEleAddr[viewType, index]
				viewType			= nextType
				IF (action = 1) THEN								' step into array
					element$ = ""
					DO DO
				END IF
				EXIT DO
			END IF
'
'			test for syntax error
'
			lenArrayIndex = LEN(arrayIndex$)
			FOR i = 0 TO lenArrayIndex - 1
				cchar = arrayIndex${i}
				IF ((cchar < '0') OR (cchar > '9')) THEN							' syntax error
					viewElement$	= viewElement$ + testElement$ + "[i]"
					viewDataAddr	= viewDataAddr + pEleAddr[viewType, index]
					viewType			= nextType
					IF (action = 1) THEN								' step into array
						element$ = ""
						DO DO
					END IF
					EXIT DO
				END IF
			NEXT i
'
'			get array index
'
			arrayIndex# = DOUBLE (arrayIndex$)
			IF (arrayIndex# > 0x7FFFFFFF) THEN											' index too large
				viewElement$	= viewElement$ + testElement$ + "[i]"
				viewDataAddr	= viewDataAddr + pEleAddr[viewType, index]
				viewType			= nextType
				EXIT DO
			END IF
			arrayIndex&& = arrayIndex#
			IF (arrayIndex&& > arrayUBound) THEN EXIT DO							' index too large
			arrayElementSize = pSize[nextType]
			arrayOffset = arrayIndex&& * arrayElementSize
'
'			add in offset to array element
'
			viewElement$	= viewElement$ + testElement$ + "[" + STRING(arrayIndex&&) + "]"
			viewDataAddr	= viewDataAddr + pEleAddr[viewType, index] + arrayOffset
			viewType			= nextType
			DO LOOP
		END IF
'
		IF (nextType < 0x20) THEN EXIT DO						' can't step into simple types
'
		viewElement$	= viewElement$ + nextElement$
		viewDataAddr	= viewDataAddr + pEleAddr[viewType, index]
		viewType			= nextType
	LOOP
'
' detail fixed string?
'
	IF (action = 3) THEN
		dispString = $$FALSE
		IF (viewType >= 0) THEN
			IF (viewType <= UBOUND(pEleType[])) THEN
				IF (detailIndex >= 0) THEN
					IF (detailIndex <= UBOUND(pEleType[viewType,])) THEN
						IF (pEleType[viewType, detailIndex] = $$STRING) THEN
							stringSource = $$SourceComposites
							stringFixed = pEleStringSize[viewType, detailIndex]
							IF (RIGHT$(viewElement$, 3) = "[i]") THEN
								stringSymbol$ = compositeSymbol$ + RCLIP$(viewElement$, 2) + STRING(detailIndex) + "]"
							ELSE
								stringSymbol$ = compositeSymbol$ + viewElement$ + pEleSymbol$[viewType, detailIndex]
							END IF
							stringDataAddr = viewDataAddr + pEleAddr[viewType, detailIndex]
							stringHandle$ = HEXX$(stringDataAddr, 8)		' actually, data address
							dispString = $$TRUE
						END IF
					END IF
				END IF
			END IF
		END IF
		XxxPassTypeArrays ($$XSET, @pSize[], @pSize$[], @pAlias[], @pAlign[], @pSymbol$[], @pToken[], @pEleCount[], @pEleSymbol$[], @pEleToken[], @pEleAddr[], @pEleSize[], @pEleType[], @pEleStringSize[], @pEleUBound[])
		IF dispString THEN
			VariablesString (stringBox, #DisplayWindow, 0, 0, 0, 0, 0, 0)
		END IF
		RETURN
	END IF
'
' display the element
'
	compositeElement$ = viewElement$
	XuiSendMessage (compositeBox, #SetTextString, 0, 0, 0, 0, 8, @compositeElement$)
	XuiSendMessage (compositeBox, #RedrawText, 0, 0, 0, 0, 8, 0)
'
	IF (RIGHT$(viewElement$, 3) = "[i]") THEN
		displayArray = $$TRUE
		currentType = viewType
		IF (currentType = $$STRING) THEN
			arrayElementSize = fixedStringSize
		ELSE
			arrayElementSize = pSize[currentType]
		END IF
		lastIndex = arrayUBound
		type$ = varTypes$[currentType]
		IF (currentType > 0x21) THEN
			lenType = LEN(type$)
			SELECT CASE TRUE
				CASE (lenType > 8)
					type$ = LEFT$(type$, 7) + "*"
				CASE (lenType < 8)
					type$ = LJUST$(type$, 8)
			END SELECT
		END IF
		location = viewDataAddr
	ELSE
		IF (viewType > UBOUND(pEleCount[])) THEN
			PRINT "VariablesCompositeDisplay(349)", viewType, UBOUND(pEleCount[])
			RETURN
		END IF
		lastIndex = pEleCount[viewType] - 1
	END IF
'
	DIM textArray$[lastIndex]
	FOR index = 0 TO lastIndex
		IF displayArray THEN
			token = #T_ZERO														' type set above (same for all elements)
			symbol$ = LJUST$(STRING(index), 20)
		ELSE
			token = pEleToken[viewType, index]
			currentType	= pEleType[viewType, index]
			type$ = varTypes$[currentType]
			IF (currentType > 0x21) THEN
				lenType = LEN(type$)
				SELECT CASE TRUE
					CASE (lenType > 8)
						type$ = LEFT$(type$, 7) + "*"
					CASE (lenType < 8)
						type$ = LJUST$(type$, 8)
				END SELECT
			END IF
'
			symbol$ = pEleSymbol$[viewType, index]
			IF (token.tp.kind = $$KIND_ARRAY_SYMBOLS) THEN
				symbol$ = symbol$ + "[]"
			END IF
			lenSymbol = LEN(symbol$)
			SELECT CASE TRUE
				CASE (lenSymbol < 20)							' pad symbol to 20 chars
					symbol$ = LJUST$(symbol$, 20)
'
				CASE (lenSymbol > 20)							' truncate symbol to 20 chars
					IF (token.tp.kind = $$KIND_ARRAY_SYMBOLS) THEN		' Retain []
						symbol$ = LEFT$(symbol$, 17) + "*[]"
					ELSE
						symbol$ = LEFT$(symbol$, 19) + "*"
					END IF
			END SELECT
			location = viewDataAddr + pEleAddr[viewType, index]
		END IF
'
'		location$	= HEX$(location,8)  '*cw* 230306-
		location$	= HEX$(location,9)  '*cw* 230306+
		IF (token.tp.kind = $$KIND_ARRAY_SYMBOLS) THEN
			value$ = " <array>"
			hexValue$ = "                 "
		ELSE
			IF (currentType = $$STRING)	THEN				' Fixed STRING
				IF displayArray THEN
					eleSize = fixedStringSize
				ELSE
					eleSize = pEleStringSize[viewType, index]
				END IF
				fixedType$ = "STRING*" + STRING(eleSize)
				hexValue$ = " " + LJUST$(fixedType$, 16)
'
'					value is first few characters of string
'
				IF (eleSize > 61) THEN
					firstFew = 60
				ELSE
					firstFew = eleSize
				END IF
				value$ = NULL$ (firstFew)
				FOR i = 0 TO firstFew - 1
					value${i} = UBYTEAT (location, i)
				NEXT i
				value$ = " \"" + XstBinStringToBackString$ (@value$)
'
				IF (LEN(value$) > 63) THEN
					value$ = LEFT$(value$, 62) + "\"*"
				ELSE
					value$ = value$ + "\""
				END IF
			ELSE
				VariableTypeToValue (currentType, $$TRUE, location, @hexValue$, @value$)
			END IF
'
		END IF  ' kind = array
'
		textArray$[index] = type$ + "  " + symbol$ + "  " + location$ + "  " + hexValue$ + " " + value$
'
		IF displayArray THEN
			location = location + arrayElementSize
		END IF
	NEXT index
'
	XxxPassTypeArrays ($$XSET, @pSize[], @pSize$[], @pAlias[], @pAlign[], @pSymbol$[], @pToken[], @pEleCount[], @pEleSymbol$[], @pEleToken[], @pEleAddr[], @pEleSize[], @pEleType[], @pEleStringSize[], @pEleUBound[])
'
	XuiSendMessage (compositeBox, #SetTextArray, 0, 0, 0, 0, 4, @textArray$[])
	XuiSendMessage (compositeBox, #SetTextCursor, 0, 0, 0, 0, 4, 0)
	XuiSendMessage (compositeBox, #RedrawText, 0, 0, 0, 0, 4, 0)
END FUNCTION
'
'
' #############################
' #####  VariableSort ()  #####
' #############################
'
' Uses XstQuickSort with ignore case mode
'
FUNCTION  VariableSort (TOKEN tok[], symbol$[], reg[], addr[], Low, High)
	TOKEN tokTmp[]
'
	DIM orderArray[0]
	XstQuickSort(@symbol$[], @orderArray[], Low, High, $$SortCaseInsensitive OR $$SortAlphaNumeric)
	u = UBOUND(orderArray[])
	DIM tokTmp[u]
	DIM regTmp[u]
	DIM addrTmp[u]
'
	IF (u <> High) THEN PRINT "VariableSort()u, High", u, High : RETURN
	IF Low THEN PRINT "VariableSort()low", Low : RETURN

	DIM orderTmp[u]
	DIM symTmp$[u]
'
' The following code moves symbols that do not start with an
' alphabetical character (i.e. "#") to the bottom of the list.
'
	FOR i = 0 TO u
		IF (LEFT$(symbol$[i]) >= "A") THEN EXIT FOR
	NEXT i
	IF i THEN
		k = 0
		FOR j = i TO u
			orderTmp[k] = orderArray[j]
			SWAP symTmp$[k], symbol$[j]
			INC k
		NEXT j
		FOR j = 0 TO i-1
			orderTmp[k] = orderArray[j]
			SWAP symTmp$[k], symbol$[j]
			INC k
		NEXT j
		SWAP orderTmp[], orderArray[]
		SWAP symTmp$[], symbol$[]
	END IF
'
	FOR i = Low TO High
		SWAP tokTmp[i], tok[orderArray[i]]
		SWAP regTmp[i], reg[orderArray[i]]
		SWAP addrTmp[i], addr[orderArray[i]]
	NEXT i
'
	SWAP tok[], tokTmp[]
	SWAP reg[], regTmp[]
	SWAP addr[], addrTmp[]
'
END FUNCTION
'
'
' ##########################
' #####  HotFrames ()  #####
' ##########################
'
FUNCTION  HotFrames (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1$[]))
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  FRAMEINFO  frameInfo[]
	SHARED  fileType,  variableUp
'
	$label				= 1
	$list					= 2
	$button0			= 3
	$button1			= 4
	$button2			= 5
'
	SELECT CASE message
		CASE #Callback			: GOSUB Callback
		CASE #DisplayWindow	: GOSUB DisplayWindow
	END SELECT
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	SELECT CASE message
		CASE #CloseWindow		: XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE #Selection			: GOSUB Selection
	END SELECT
END SUB
'
'
' *****  DisplayWindow  *****  r1$ = default function name
'
SUB DisplayWindow
	IF (fileType != $$Program) THEN
		Message ("[HotFrames( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
	UpdateFrames ()
	XuiSendMessage (grid, #DisplayWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Selection  *****  r0 = 2345 = List/Button012
'
SUB Selection
	SELECT CASE r0
		CASE $list
			IF (v0 < 0) THEN
				XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
				EXIT SUB
			END IF
			NEXT CASE
		CASE $list, $button0, $button1
			IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
				ResetDataDisplays (0)
				EXIT FUNCTION
			END IF
			XuiSendMessage (grid, #GetTextCursor, 0, @viewLine, 0, 0, $list, 0)
			XuiSendMessage (grid, #GetTextArrayLine, viewLine, 0, 0, 0, $list, @view$)
			funcPtr = XLONG(view$)
			funcNumber = frameInfo[funcPtr].funcNumber
			IF (funcNumber < 0) THEN EXIT SUB
			line = frameInfo[funcPtr].funcLine
			Display (funcNumber, line, 0, -1, -1)		' Display checks validity of funcNumber
			IF variableUp THEN UpdateVariables()
		CASE $button2
			XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
END FUNCTION
'
'
' #############################
' #####  UpdateFrames ()  #####
' #############################
'
'	Update the Frame box
'
'	In:				none
'	Out:			none
'	Return:		none
'
'	Discussion:
'		88k requires the use of a WALK array to save function base frame address
'		NT:	previous rbp = [rbp]
'				return addr  = [rbp + 8]
'
'		Update assumes that frame functions do not include XIT functions invoked
'			after a signal.  So DON'T generate walker code when compiling Blowback,
'			XitMain, etc.
'
'		Compare frame return address (0x6C) with previous frame's "call" addr (0x64)
'			- If not equal, insert * Alien between them
'
'		##ALARMWALKER
'			- 0 if alarm is not engaged
'			- else, it is the WALKOFFSET at the alarm time
'					- If alarm is engaged, insert alarm entries after ALARMWALKER
'
'		SXIP:
'			1)  SXIP not in user function
'					- identify function called by last frame function
'							- frame x64 - 8 = bsr/jsr to called routine
'							- decode jump address, get name from XxxGetLabelGivenAddress ()
'									- If not found, use <Alien>
'					- no idea where SXIP is (not necessarily in called function)
'							- optional:  display  "addr  SXIP"
'
'			2)  SXIP in body of last frame function (line 1 to n)
'					- SXIP function IS last frame function
'					- replace its line number with SXIP line number
'
'			3)  SXIP in EPILOG of last frame function (n < addr < PROLOG)
'					- last frame function is SXIP function  (addr < PROLOG - 8)
'							- replace its line number with "exit"
'					- SXIP function frame has been removed  (addr >= PROLOG - 8)
'							- add in an "exit" frame with this function
'
'			4)  SXIP in PROLOG of last frame function (n >= PROLOG)
'					- SXIP function may not be on frame yet
'					- If it is, then line number is "entry"
'					- TEST:
'							- last frame function != SXIP function
'									- SXIP function not on frame yet
'									- ADD frame entry:  "entry  (SXIP-function)"
'							- last frame function = SXIP function
'									- If line number is "entry":  this is SXIP function (done)
'									- Else, this is NOT SXIP function (a recursive call)
'											- (recursive call can't be initiated from PROLOG/EPILOG)
'											- ADD frame entry:  "entry  (SXIP-function)"
'
'		NOTES:
'			- ALL branches/jumps OUT of function store r1 in walk array
'
'		Can't see giving user access to variables in other that last user frame
'			and then only if SXIP on a line boundary (breakpoint or break key) or
'			in inline code where variables are in a determined state
'			- Can't give source line debugger that works on non-boundary
'			- problems with prior frames:
'					1) calls other user X functions
'							r14-r25 are saved only when needed.  Would have to bop down line
'							of called functions checking for the first saving of that variable
'							on a frame and record its location.
'					2) above is destroyed if a non-X function is in the sequence (and
'							executes a call to a user X function) because the location of
'							r14-r25 is unknown
'					3) a signal yanks out of a function, then calls another user
'							function which breaks.  Variables in the original function are
'							in an indeterminate state (e.g. signal executed during an
'							intrinsic creating a stack and using r14..., alarm dispatcher)
'
' To do elsewhere:
'		Breakpoints:
'			- move ":" on comment or blank to next non-comment/blank line
'
FUNCTION  UpdateFrames ()
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  lineAddr[],  lineLast[]
	SHARED  FRAMEINFO  frameInfo[]
	SHARED  framesBox,  frameDetail,  variableUp
	SHARED  exeFunction,  exeLine
	SHARED  userGoFrame
	SHARED  CPUCONTEXT  cpu
	SHARED  xitGrid
	SHARED  lastFrame$
	SHARED  traceActive
	STATIC  item$[]
	STATIC  FRAMEINFO  tempInfo[]
'
	IFZ (##USERRUNNING AND ##SIGNALACTIVE) THEN
		ResetDataDisplays(0)
		EXIT FUNCTION
	END IF
'
	IFZ item$[] THEN DIM item$[31]
'
	uitem		= UBOUND(item$[])
	uframe	= UBOUND(frameInfo[])
'
	exeFunction	= 0
	exeLine			= 0
	frame				= cpu.rbp
	funcAddress	= cpu.rip
	itemPtr			= -1
	item$[0]		= ""
'	IF ##CAPSLOCK THEN PRINT "UpdateFrames(116)", HEXX$(frame), HEXX$(userGoFrame)
	DO WHILE (frame < userGoFrame)
		INC itemPtr
		IF ((itemPtr > uitem) OR (itemPtr > uframe)) THEN
			uitem = (itemPtr + (itemPtr >> 1)) OR 7
			REDIM item$[uitem]
			uframe = uitem
			REDIM frameInfo[uframe]
		END IF
		frameFuncNumber = GetFuncNumberGivenAddress (funcAddress)
		frame$ = ""																' Number inserted on reorder below
		IF (frameFuncNumber >= 0) THEN
			line = 0
			frameFuncLine = 0
			lastLine = lineLast[frameFuncNumber]
			lineAddr = lineAddr[frameFuncNumber, 0]
			DO UNTIL (line > lastLine)
				nextAddr = lineAddr[frameFuncNumber, line + 1]
				IF ((lineAddr <= funcAddress) AND (funcAddress < nextAddr)) THEN
					frameFuncLine = line
					EXIT DO
				END IF
				lineAddr = nextAddr
				INC line
			LOOP
			IF (frameFuncLine = lastLine) THEN			' start of last line is OK
				IF (funcAddress != lineAddr) THEN
					frameFuncLine = 0										' User can't see transit lines
					XxxFunctionName ($$XGET, @funcName$, frameFuncNumber)
					label$ = "_" + funcName$
					prologAddr = XxxGetAddressGivenLabel(label$)
					IF (funcAddress < prologAddr) THEN
						frame$ = frame$ + "    exit  "		' function EPILOG
						IFZ (exeFunction OR exeLine) THEN
							exeFunction = frameFuncNumber
							exeLine = lastLine
						END IF
					ELSE
						frame$ = frame$ + "   entry  "		' function PROLOG
						IFZ (exeFunction OR exeLine) THEN
							exeFunction = frameFuncNumber
							exeLine = 0
						END IF
					END IF
				END IF
			END IF
			IF frameFuncLine THEN
				frame$ = frame$ + RJUST$(STRING(frameFuncLine+1), 8) + "  "
				IFZ (exeFunction OR exeLine) THEN
					exeFunction = frameFuncNumber
					exeLine = frameFuncLine
				END IF
			END IF
			XxxFunctionName ($$XGET, @funcName$, frameFuncNumber)
			IF (LEN(funcName$) > 32) THEN
				funcName$ = LEFT$(funcName$, 31) + "*"
			END IF
			item$[itemPtr] = frame$ + funcName$
			frameInfo[itemPtr].frameAddr	= frame
			frameInfo[itemPtr].funcAddr		= funcAddress
			frameInfo[itemPtr].funcNumber	= frameFuncNumber
			frameInfo[itemPtr].funcLine		= frameFuncLine
		ELSE
'			It's not a user's function
			tag$ = "  < * Alien * >"
'
			item$[itemPtr] = frame$ + HEX$(funcAddress, 8) + tag$
			frameInfo[itemPtr].frameAddr	= frame
			frameInfo[itemPtr].funcAddr		= funcAddress
			frameInfo[itemPtr].funcNumber	= -1
			frameInfo[itemPtr].funcLine		= -1
		END IF
		funcAddress = XLONGAT(frame,8)				' return address in calling function
		frame = XLONGAT(frame)								' calling frame address = [frame]
	LOOP
'
	lastItem = 0
	IFZ item$[0] THEN
		DIM item$[]
		view$ = ""
	ELSE
		showItem = 0
		DIM tempItem$[itemPtr]
		DIM tempInfo[itemPtr]
		itemCount = 0															' detail and reverse order
		FOR i = itemPtr TO 0 STEP -1
			j = itemPtr - i
			tempInfo[j] = frameInfo[i]
			IF (frameInfo[i].funcNumber < 0) THEN
				IFZ frameDetail THEN DO NEXT
			ELSE
				showItem = itemCount
			END IF
			tempItem$[itemCount] = RJUST$(STRING(j), 5) + "  " + item$[i]
			INC itemCount
		NEXT i
		IFZ itemCount THEN
			DIM item$[]
			view$ = ""
		ELSE
			SWAP tempItem$[], item$[]
			lastItem = itemCount - 1
			REDIM item$[lastItem]
			view$ = item$[showItem]
		END IF
		SWAP tempInfo[], frameInfo[]
	END IF
'
	XuiSendMessage (framesBox, #SetTextArray, 0, 0, 0, 0, 2, @item$[])
	XuiSendMessage (framesBox, #SetTextCursor, 0, showItem, 0, 0, 2, 0)
	XuiSendMessage (framesBox, #RedrawText, 0, 0, 0, 0, 2, 0)
	funcPtr = XLONG (view$)
	funcNumber = frameInfo[funcPtr].funcNumber
	line = XLONG (MID$(view$, 6))	-1				' transit --> line 0
	Display (funcNumber, line, 0, -1, -1)		' Display checks validity of funcNumber
'
' If breakpoint trace is active and variables window is not displayed,
' print the last frame text information here.
'
	IF traceActive THEN
		XuiSendMessage (xitGrid, #GetTextArrayLine, line, @lineRead, 0, @upper, $$xitTextLower, @text$)
		IF (LEFT$(text$) == ">") THEN
			text$ = LCLIP$(text$)
		END IF
		stringInto$ = " - - - - - - - - - - - - - - -"
		lastFrame$ = item$[lastItem]
		lastFrame$ = STUFF$(stringInto$, lastFrame$ + " ", 1)
		lastFrame$ = lastFrame$ + " - " + text$
		IFZ variableUp THEN
			PRINT lastFrame$
			lastFrame$ = ""
		END IF
	END IF
	IF variableUp THEN UpdateVariables()
	XstGetConsoleGrid (@consoleGrid)
	XuiSendMessage (consoleGrid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
'
END FUNCTION
'
'
' ############################
' #####  Pop16Frames ()  #####
' ############################
'
'	Called by XitMain after stack overflow
'
FUNCTION  Pop16Frames (signal, exception)
	SHARED  CPUCONTEXT  cpu
	SHARED  userGoFrame
'
	frame = cpu.rbp
	funcAddress = cpu.rip
	FOR i = 0 TO 16
		IF (frame >= userGoFrame) THEN EXIT FOR
'		PRINT i, HEX$(frame,9), HEX$(funcAddress,9)
		funcAddress = XLONGAT(frame,8)		' return address in calling function
		frame = XLONGAT(frame)						' calling frame address = [frame]
	NEXT i
	cpu.rip = funcAddress
	XxxSetRbpRsp (frame, frame-64)
END FUNCTION
'
'
' ##############################
' #####  XitGetDECLARE ()  #####
' ##############################
'
' Get DECLARE line for funcName$
'
'	In:				funcName$
'	Out:			declare$
' Return:		error				0 no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												$$XitProgramRunning
'												$$XitInvalidFunctionName
'
FUNCTION  XitGetDECLARE (funcName$, declare$)
	TOKEN   func[]
	TOKEN   tok[]
	SHARED  TOKEN prog[]
	SHARED  environmentActive,  fileType,  editFunction
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	IF ##USERRUNNING THEN RETURN ($$XitProgramRunning)
	error = FunctionNameToNumber(@funcName$, @funcNumber)
	IF (error = $$XitInvalidFunctionName) THEN RETURN (error)
	IFZ funcNumber THEN RETURN (0)
'
	IFZ editFunction THEN
		redisplay = $$FALSE								' prepare for PROLOG alterations
		reportBogusRename = $$FALSE
		RestoreTextToProg (redisplay, reportBogusRename)
	END IF
'
	declare$ = ""
	IFZ prog[0,] THEN RETURN (0)
'
	uLine = UBOUND(prog[0,])						' Initialize for FindDECLARE
	line = uLine
	foundDeclare	= $$FALSE							' not used
	firstDeclare	= -1
	lastDeclare		= -1
	GOSUB FindDECLARE
	IF (line >= 0) THEN
		ATTACH prog[0,line,] TO tok[]
'		IF tok[] THEN
			IFZ tok[0].tproto THEN PRINT "XitGetDECLARE(48)"
			XxxDeparser(@tok[], @declare$)
			ATTACH tok[] TO prog[0,line,]
'		END IF
	END IF
	RETURN (0)
'
'	Same  subroutine in XitSetDECLARE
'
'	*****  FindDECLARE  *****
'		In:				funcNumber
'							uLine						= UBOUND(prog[0,])
'							line						= start line number (for continuations)
'							foundDeclare		= initialized
'							firstDeclare
'							lastDeclare
'
'		Out:			line					= #   line number of declare for funcNumber
'															-1  not present
'							tokPtr				= token index to func token
'					If not present:
'							foundDeclare	= at least 1 DECLARE exists
'							firstDeclare	= line number of first DECLARE
'							lastDeclare		= line number of last DECLARE
'
'		Discussion:
'			DECLARE and INTERNAL only.  This allows user application to
'			"overwrite" library function.
'
SUB FindDECLARE
	ATTACH prog[0,] TO func[]
	DO UNTIL (line < 0)
		toks = func[line, 0].ti.ndex
		IF (toks < 2) THEN DEC line: DO DO			' newLine
'
		ATTACH func[line,] TO tok[]
'		IFZ tok[] THEN DEC line : DO LOOP
		isDeclare = CheckDECLARE (@tok[], @declareFuncNumber)
		ATTACH tok[] TO func[line,]
		IF isDeclare THEN
			IF (funcNumber = declareFuncNumber) THEN
				ATTACH func[] TO prog[0,]
				EXIT SUB
			END IF
			foundDeclare = $$TRUE
			firstDeclare = line
			IF (lastDeclare < 0) THEN lastDeclare = line
		END IF
		DEC line
	LOOP
	ATTACH func[] TO prog[0,]
END SUB
END FUNCTION
'
'
' ########################################
' #####  XitGetDisplayedFunction ()  #####
' ########################################
'
'	Get currently displayed function
'
'	In:				funcName$
'	Out:			none
'	Return:		error				0 = no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'
FUNCTION  XitGetDisplayedFunction (funcName$)
	SHARED  editFunction,  fileType
	SHARED  environmentActive
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
'
	XxxFunctionName ($$XGET, @funcName$, editFunction)
	RETURN (0)
END FUNCTION
'
'
' ###############################
' #####  XitGetFunction ()  #####
' ###############################
'
'	Get function
'
'	In:				funcName$
'	Out:			text$[]
'	Return:		error				0 = no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												$$XitInvalidFunctionName
'												$$XitFunctionUndefined
'
FUNCTION  XitGetFunction (funcName$, text$[])
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN  func[]
	TOKEN  startToken
	TOKEN  tok[]
	SHARED  TOKEN prog[]
	SHARED  editFunction,  fileType,  environmentActive
'
	DIM text$[]
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	error = FunctionNameToNumber(@funcName$, @funcNumber)
	IF error THEN RETURN (error)
'
	IF ((funcNumber = editFunction) AND (NOT ##USERRUNNING)) THEN
		redisplay = $$TRUE
		reportBogusRename = $$TRUE
		RestoreTextToProg (redisplay, reportBogusRename)
	END IF
'
	ATTACH prog[funcNumber,] TO func[]
	lastLine = UBOUND(func[])
	DIM text$[lastLine]
	FOR line = 0 TO lastLine
		ATTACH func[line,] TO tok[]
'		IFZ tok[] THEN DO NEXT
		startToken = tok[0]                   ' save first token for line
		tok[0].ti.errno = 0                   ' strip errno from token line
		tok[0].ti.bpexe = $$BPEXECLR          ' strip BP/EXE from token line
		IFZ tok[0].tproto THEN PRINT "XitGetFunction(46)"
		XxxDeparser(@tok[], @lineText$)
		tok[0] = startToken										' restore first token for line
		ATTACH lineText$ TO text$[line]
		ATTACH tok[] TO func[line,]
	NEXT line
	ATTACH func[] TO prog[funcNumber,]
	RETURN (0)
END FUNCTION
'
'
' ################################
' #####  XitLoadFunction ()  #####
' ################################
'
'	Load function from file
'
'	In:				funcName$
'						fileName$
'	Out:			none
'	Return:		error				0 = no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												$$XitInvalidFunctionName
'												##ERROR...  (for file operations)
'
FUNCTION  XitLoadFunction (funcName$, fileName$)
	TOKEN   token
	TOKEN   tok[]
	SHARED  fileType
	SHARED  environmentActive
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	error = FunctionNameToNumber (@funcName$, @funcNumber)
	IF (error = $$XitInvalidFunctionName) THEN RETURN (error)
'
	error = ERROR (0)
	error = XstLoadStringArray (@fileName$, @text$[])
	IF error THEN RETURN (##ERROR)
	IFZ text$[] THEN RETURN (0)
	declare$ = text$[0]
	XxxParseSourceLine (@declare$, @tok[])
	isDeclare = CheckDECLARE (@tok[], @declareFuncNumber)
	IFZ isDeclare THEN
		declare$ = "DECLARE FUNCTION  " + funcName$ + " ()"
	ELSE
		IF (funcNumber != declareFuncNumber) THEN
			toks = tok[0].ti.ndex
			FOR i = 1 TO toks
				token = tok[i]
				IF (token.tp.kind = $$KIND_FUNCTIONS) THEN
					tok[i].tindex = funcNumber
					EXIT FOR
				END IF
			NEXT i
			IFZ tok[0].tproto THEN PRINT "XitLoadFunction(48)"
			XxxDeparser(@tok[], @declare$)
		END IF
		uText = UBOUND(text$[])
		IF (uText = 0) THEN
			DIM text$[]
		ELSE
			FOR line = 0 TO uText - 1
				SWAP text$[line], text$[line + 1]
			NEXT line
			REDIM text$[uText - 1]
		END IF
	END IF
	XitSetDECLARE (@funcName$, @declare$)
	error = XitSetFunction (@funcName$, @text$[])
	RETURN (error)
END FUNCTION
'
'
' ###############################
' #####  XitMergePROLOG ()  #####
' ###############################
'
'	Merge file into PROLOG (usually a .dec file)
'
'	In:				fileName$
'	Out:			none
'	Return:		error				0 = no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												##ERROR...  (for file operations)
'	Discussion:
'		Sections:	COMPOSITE Declarations
'								First line to last END TYPE
'							EXTERNAL FUNCTION Declarations
'								After last END TYPE to last EXTERNAL FUNCTION
'							CONSTANT Declarations
'								After last EXTERNAL FUNCTION to last line
'			TYPES and CONSTANTS are not required.
'
FUNCTION  XitMergePROLOG (fileName$)
	TOKEN   func[]
	TOKEN   prolog[]
	TOKEN   token
	TOKEN   t1
	TOKEN   tok[]
	SHARED  TOKEN prog[]
	SHARED  funcAltered[]
	SHARED  funcCursorPosition[],  funcNeedsTokenizing[]
	SHARED  xitGrid,  editFunction,  fileType,  environmentActive
	SHARED  programAltered,  textAlteredSinceSave
'	SHARED  T_DECLARE,  T_INTERNAL,  T_EXTERNAL
'	SHARED  T_FUNCTION, T_CFUNCTION,  T_SFUNCTION,  T_END,  T_TYPE
'
	$endType	= 1
	$function	= 2
	$constant	= 3
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
'
	error = XstLoadStringArray (@fileName$, @text$[])
	IF error THEN RETURN (##ERROR)
	IFZ text$[] THEN RETURN (0)
'
	IFZ editFunction THEN
		redisplay = $$FALSE								' prepare for PROLOG alterations
		reportBogusRename = $$FALSE
		RestoreTextToProg (redisplay, reportBogusRename)
	END IF
	TextToTokenArray (@text$[], @func[], 0, $$FALSE)
	uFunc = UBOUND(func[])
'
'	*****  TYPE Declarations  *****
'
	insertProlog	= 0
	firstFuncLine	= 0
	lastFuncLine	= -1											' find func[] TYPEs
	FOR line = firstFuncLine TO uFunc
		ATTACH func[line,] TO tok[]
'		IFZ tok[] THEN DO NEXT
		GOSUB CheckTok
		ATTACH tok[] TO func[line,]
		SELECT CASE lineType
			CASE $endType:		lastFuncLine = line
			CASE $function:		EXIT FOR					' no TYPEs after FUNCTION
		END SELECT
	NEXT line
	IF (lastFuncLine >= 0) THEN							' Insertion point
		IF prog[0,] THEN
			ATTACH prog[0,] TO prolog[]
			uProlog = UBOUND(prolog[])
			insertLine = -1
			FOR line = insertProlog TO uProlog
				ATTACH prolog[line,] TO tok[]
'				IFZ tok[] THEN DO NEXT
				GOSUB CheckTok
				ATTACH tok[] TO prolog[line,]
				SELECT CASE lineType
					CASE $endType:		insertLine = line + 1
					CASE $function:		EXIT FOR
				END SELECT
			NEXT line
			IF (insertLine < 0) THEN insertLine = line
			insertProlog = insertLine
			ATTACH prolog[] TO prog[0,]
		END IF
		GOSUB MergeFunc
		IF (lastFuncLine >= uFunc) THEN GOTO Done
		firstFuncLine	= lastFuncLine + 1
	END IF
'
'	*****  FUNCTION Declarations  *****
'
	lastFuncLine = -1												' find func[] FUNCTIONs
	FOR line = firstFuncLine TO uFunc
		ATTACH func[line,] TO tok[]
'		IFZ tok[] THEN DO NEXT
		GOSUB CheckTok
		ATTACH tok[] TO func[line,]
		SELECT CASE lineType
			CASE $function:		lastFuncLine = line
			CASE $constant:		EXIT FOR					' no FUNCTIONs after Constant
		END SELECT
	NEXT line
	IF (lastFuncLine >= 0) THEN							' Insertion point
		IF prog[0,] THEN
			ATTACH prog[0,] TO prolog[]
			uProlog = UBOUND(prolog[])
			insertLine = -1
			FOR line = insertProlog TO uProlog
				ATTACH prolog[line,] TO tok[]
'				IFZ tok[] THEN DO NEXT
				GOSUB CheckTok
				ATTACH tok[] TO prolog[line,]
				SELECT CASE lineType
					CASE $function:		insertLine = line + 1
					CASE $constant:		EXIT FOR			' no FUNCTIONs after Constant
				END SELECT
			NEXT line
			IF (insertLine < 0) THEN insertLine = line
			insertProlog = insertLine
			ATTACH prolog[] TO prog[0,]
		END IF
		GOSUB MergeFunc
		IF (lastFuncLine >= uFunc) THEN GOTO Done
		firstFuncLine	= lastFuncLine + 1
	END IF
'
'	*****  Constant Declarations  *****
'
	lastFuncLine = uFunc
	IF prog[0,] THEN
		ATTACH prog[0,] TO prolog[]
		uProlog = UBOUND(prolog[])
		insertLine = -1
		FOR line = insertProlog TO uProlog
			ATTACH prolog[line,] TO tok[]
'			IFZ tok[] THEN DO NEXT
			GOSUB CheckTok
			ATTACH tok[] TO prolog[line,]
			SELECT CASE lineType
				CASE $constant:		insertLine = line + 1
			END SELECT
		NEXT line
		IF (insertLine >= 0) THEN insertProlog = insertLine
		ATTACH prolog[] TO prog[0,]
	END IF
	GOSUB MergeFunc
'
Done:
	funcAltered[0] = $$TRUE
	funcNeedsTokenizing[0] = $$FALSE
	programAltered = $$TRUE
	textAlteredSinceSave = $$TRUE
	UpdateFileFuncLabels ($$TRUE, $$FALSE)
	SetEntryFunction ()
	IFZ editFunction THEN
		TokenArrayToText (0, @text$[])
		cursorLine	= funcCursorPosition[0, 0]
		cursorPos		= funcCursorPosition[0, 1]
		topLine			= funcCursorPosition[0, 2]
		topIndent		= funcCursorPosition[0, 3]
		XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, cursorLine, topIndent, topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
		funcCursorPosition[0, 0] = cursorLine
		funcCursorPosition[0, 1] = cursorPos
		funcCursorPosition[0, 2] = topLine
		funcCursorPosition[0, 3] = topIndent
		funcCursorPosition[0, 4] = xCursor
		funcCursorPosition[0, 5] = yCursor
	END IF
	RETURN (0)
'
'
'	*****  CheckTok  *****
'
SUB CheckTok
	lineType = 0
	IFZ tok[] THEN EXIT SUB
	toks = tok[0].ti.ndex
	IF (toks < 2) THEN EXIT SUB
	tokPtr = 1
	IFZ NextXitToken(@tok[], @tokPtr, toks, @t1) THEN EXIT SUB
	SELECT CASE TRUE
		CASE TokenMatch (@t1, @#T_DECLARE), TokenMatch (@t1, @#T_INTERNAL), TokenMatch (@t1, @#T_EXTERNAL)
			IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN EXIT SUB
			SELECT CASE TRUE
				CASE  TokenMatch (@token, @#T_FUNCTION), TokenMatch (@token, @#T_CFUNCTION), TokenMatch (@token, @#T_SFUNCTION)
				CASE  ELSE:			EXIT SUB
			END SELECT
			DO UNTIL (tokPtr > toks)
				token = tok[tokPtr]
				IF (token.tp.kind = $$KIND_FUNCTIONS) THEN
					lineType = $function
					EXIT SUB
				END IF
				INC tokPtr
			LOOP
		CASE TokenMatch (@t1, @#T_END)
			IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN EXIT SUB
			IF TokenMatch (@token, @#T_TYPE) THEN lineType = $endType
		CASE ELSE
			IF (t1.tp.kind = $$KIND_SYSCONS) THEN lineType = $constant
	END SELECT
END SUB
'
'
'	*****  MergeFunc  *****
'
'		insertProlog	= insertion line in prog[0,]
'											(return: first line after merge)
'		firstFuncLine	= first line in func[]
'		lastFuncLine	= last line in func[]
'
SUB MergeFunc
	newLines = lastFuncLine - firstFuncLine + 1
	IFZ prog[0,] THEN
		DIM prolog[newLines - 1,]
		FOR line = firstFuncLine TO lastFuncLine
			ATTACH func[line,] TO prolog[insertProlog,]
			INC insertProlog
		NEXT line
		ATTACH prolog[] TO prog[0,]
	ELSE
		ATTACH prog[0,] TO prolog[]
		uProlog = UBOUND(prolog[])
		uPrologNew = uProlog + newLines
		REDIM prolog[uPrologNew,]
		IF (insertProlog <= uProlog) THEN				' create gap
			p = uPrologNew
			FOR i = uProlog TO insertProlog STEP -1
				SWAP prolog[i,], prolog[p,]
				DEC p
			NEXT i
		END IF
		FOR line = firstFuncLine TO lastFuncLine
			ATTACH func[line,] TO prolog[insertProlog,]
			INC insertProlog
		NEXT line
		ATTACH prolog[] TO prog[0,]
	END IF
END SUB
END FUNCTION
'
'
' ##############################
' #####  XitNewProgram ()  #####
' ##############################
'
'	Create new PROGRAM.  Erase current source unconditionally.
'
'	In:				none
'	Out:			none
'	Return:		error			0 = no error
'											$$XitEnvironmentInactive
'											$$XitProgramRunning
'
'	Discussion:
'		For external manipulation of environment program (eg GUI)
'
FUNCTION  XitNewProgram ()
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN  prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  jump[]
	SHARED  uprog,  environmentActive,  programAltered
	SHARED  xitGrid,  fileType
	SHARED  editFunction,  priorFunction,  textAlteredSinceSave
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF ##USERRUNNING THEN RETURN ($$XitProgramRunning)
'
	ResetDataDisplays ($$ResetAssembly)
	ClearRuntimeError ()
	editFunction  = 0													' PROLOG
	priorFunction = 0
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
'
	InitializeCompiler ()				' Initialize compiler arrays/variables
'
	fileType = $$Program
	programAltered = $$TRUE
	uprog = maxFuncNumber
	DIM prog[uprog,]
	DIM funcAltered[uprog]										' these have same DIM as prog[]
	DIM funcBPAltered[uprog]
	DIM funcNeedsTokenizing[uprog]
	DIM funcCursorPosition[uprog, 5]
'
	textAlteredSinceSave = $$FALSE
	UpdateFileFuncLabels ($$TRUE, $$TRUE)
	DIM jump[25,1]														' Clear jump tags
	RETURN (0)
END FUNCTION
'
'
' #################################
' #####  XitQueryFunction ()  #####
' #################################
'
'	Report if funcName$ currently exists
'
'	In:				funcName$
'	Out:			exists
'	Return:		error			0 = no error
'											$$XitEnvironmentInactive
'											$$XitTextMode
'											$$XitInvalidFunctionName
'	Discussion:
'		For external manipulation of environment program (eg GUI)
'
FUNCTION  XitQueryFunction (funcName$, exists)
	SHARED  fileType,  environmentActive
'
	exists = $$FALSE
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	error = FunctionNameToNumber(@funcName$, @funcNumber)
	IF (error = $$XitInvalidFunctionName) THEN RETURN (error)
	IFZ error THEN exists = $$TRUE
	RETURN (0)
END FUNCTION
'
'
' ################################
' #####  XitQueryProgram ()  #####
' ################################
'
'	Report if current program status
'
'	In:				none
'	Out:			status	bit
'										0				XitActive		0 = not,	1 = active
'										1				mode				0 = Text,	1 = Program
'										2				running			0 = not,	1 = Running
'										3				saved				0 = not,	1 = Saved
'	Return:		0		no error
'
'	Discussion:
'		For external manipulation of environment program (eg GUI)
'
FUNCTION  XitQueryProgram (status)
	SHARED  textAlteredSinceSave
	SHARED  environmentActive
	SHARED  fileType
'
	status = 0
	IF environmentActive THEN							status = status OR 0x01
	IF (fileType = $$Program) THEN				status = status OR 0x02
	IF ##USERRUNNING THEN									status = status OR 0x04
	IF NOT textAlteredSinceSave THEN	status = status OR 0x08
	RETURN (0)
END FUNCTION
'
'
' ##############################
' #####  XitSetDECLARE ()  #####
' ##############################
'
' Replace DECLARE line for funcName$ with declare$
'
'	In:				funcName$
'						declare$		Assumes NO NEWLINES
'	Out:			none
' Return:		error				0 no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												$$XitProgramRunning
'												$$XitInvalidFunctionName
'												$$XitMismatchedArguments
'	Discussion:
'		Delete it if declare$ empty
'		Add it if funcName$ DECLARE doesn't exist.
'		If editFunction = PROLOG, redisplay.
'
FUNCTION  XitSetDECLARE (funcName$, declare$)
	TOKEN   func[]
	TOKEN   newTok[]
	TOKEN   tok[]
	SHARED  TOKEN  prog[]
	SHARED  funcAltered[]
	SHARED  funcCursorPosition[]
	SHARED  funcNeedsTokenizing[]
	SHARED  xitGrid,  environmentActive,  fileType,  editFunction
	SHARED  programAltered,  textAlteredSinceSave
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	IF ##USERRUNNING THEN RETURN ($$XitProgramRunning)
	error = FunctionNameToNumber(@funcName$, @funcNumber)
	IF (error = $$XitInvalidFunctionName) THEN RETURN (error)
	IFZ funcNumber THEN RETURN (0)
	IF declare$ THEN
		XxxInitParse ()										' Reset got.function for PROLOG
		XxxParseSourceLine (@declare$, @newTok[])
		isDeclare = CheckDECLARE (@newTok[], @declareFuncNumber)
		IFZ isDeclare THEN RETURN ($$XitMismatchedArguments)
		IF (funcNumber != declareFuncNumber) THEN RETURN ($$XitMismatchedArguments)
	END IF
'
	IFZ editFunction THEN
		redisplay = $$FALSE								' prepare for PROLOG alterations
		reportBogusRename = $$FALSE
		RestoreTextToProg (redisplay, reportBogusRename)
	END IF
	altered = $$FALSE
	IFZ prog[0,] THEN
		IFZ declare$ THEN RETURN (0)
		XstStringToStringArray (@text$, @text$[])
		TextToTokenArray (@text$[], @func[], 0, 0)
		ATTACH func[] TO prog[0,]
		altered = $$TRUE
	ELSE
		uLine = UBOUND(prog[0,])					' Initialize for FindDECLARE
		line = uLine
		foundDeclare	= $$FALSE						' (not used in remove)
		firstDeclare	= -1
		lastDeclare		= -1
		IFZ declare$ THEN									' remove all funcNumber DECLAREs
			DO
				GOSUB FindDECLARE
				IF (line < 0) THEN EXIT DO
				GOSUB RemoveDECLARE
				altered = $$TRUE
				DEC line
			LOOP
		ELSE
			GOSUB FindDECLARE
			GOSUB AddDECLARE
			altered = $$TRUE
		END IF
	END IF
	IFZ altered THEN RETURN (0)
'
	funcAltered[0] = $$TRUE
	funcNeedsTokenizing[0] = $$FALSE
	programAltered = $$TRUE
	textAlteredSinceSave = $$TRUE
	UpdateFileFuncLabels ($$TRUE, $$FALSE)
	SetEntryFunction ()
	IFZ editFunction THEN
		TokenArrayToText (0, @text$[])
		cursorLine	= funcCursorPosition[0, 0]
		cursorPos		= funcCursorPosition[0, 1]
		topLine			= funcCursorPosition[0, 2]
		topIndent		= funcCursorPosition[0, 3]
		XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, cursorLine, topIndent, topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
		funcCursorPosition[0, 0] = cursorLine
		funcCursorPosition[0, 1] = cursorPos
		funcCursorPosition[0, 2] = topLine
		funcCursorPosition[0, 3] = topIndent
		funcCursorPosition[0, 4] = xCursor
		funcCursorPosition[0, 5] = yCursor
	END IF
	RETURN (0)
'
'	FindDECLARE:  same subroutine in XitGetDECLARE
'
'
'	*****  FindDECLARE  *****
'		In:				funcNumber
'							uLine						= UBOUND(prog[0,])
'							line						= start line number (for continuations)
'							foundDeclare		= initialized
'							firstDeclare
'							lastDeclare
'
'		Out:			line					= #   line number of declare for funcNumber
'															-1  not present
'							tokPtr				= token index to func token
'					If not present:
'							foundDeclare	= at least 1 DECLARE exists
'							firstDeclare	= line number of first DECLARE
'							lastDeclare		= line number of last DECLARE
'
'		Discussion:
'			DECLARE and INTERNAL only.  This allows user application to "overwrite"
'				library function.
'
SUB FindDECLARE
	ATTACH prog[0,] TO func[]
	DO UNTIL (line < 0)
		toks = func[line, 0].ti.ndex
		IF (toks < 2) THEN DEC line: DO DO			' newLine
'
		ATTACH func[line,] TO tok[]
'		IFZ tok[] THEN DEC line : DO LOOP
		isDeclare = CheckDECLARE (@tok[], @declareFuncNumber)
		ATTACH tok[] TO func[line,]
		IF isDeclare THEN
			IF (funcNumber = declareFuncNumber) THEN
				ATTACH func[] TO prog[0,]
				EXIT SUB
			END IF
			foundDeclare = $$TRUE
			firstDeclare = line
			IF (lastDeclare < 0) THEN lastDeclare = line
		END IF
		DEC line
	LOOP
	ATTACH func[] TO prog[0,]
END SUB
'
'
'	*****  AddDECLARE  *****
'
SUB AddDECLARE
	IF (line >= 0) THEN											' replace existing line
		SWAP newTok[], prog[0,line,]
		DIM newTok[]
	ELSE
		IF foundDeclare THEN
			declareLine = lastDeclare + 1
		ELSE
			declareLine = uLine + 1
		END IF
		ATTACH prog[0,] TO func[]
		REDIM func[uLine+1,]							' Make room for one more line in PROLOG
		IF (declareLine <= uLine) THEN		' Open slot for new line
			line = uLine
			DO UNTIL (line < declareLine)
				ATTACH func[line,] TO func[line+1,]
				DEC line
			LOOP
		END IF
		ATTACH newTok[] TO func[declareLine,]
		ATTACH func[] TO prog[0,]
	END IF
END SUB
'
'
'	*****  RemoveDECLARE  *****
'
SUB RemoveDECLARE
	ATTACH prog[0,] TO func[]
	IFZ uLine THEN
		DIM func[]
		EXIT SUB
	ELSE
		iline = line
		ATTACH func[line,] TO tok[]:  DIM tok[]
		DO WHILE (iline < uLine)					' compress PROLOG
			ATTACH func[iline+1,] TO func[iline,]
			INC iline
		LOOP
		DEC uLine
		REDIM func[uLine,]
	END IF
	ATTACH func[] TO prog[0,]
END SUB
END FUNCTION
'
'
' ########################################
' #####  XitSetDisplayedFunction ()  #####
' ########################################
'
'	Set currently displayed function
'
'	In:				funcName$
'	Out:			none
'	Return:		error				0 = no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												$$XitInvalidFunctionName
'												$$XitFunctionUndefined
'
FUNCTION  XitSetDisplayedFunction (funcName$)
	SHARED  fileType
	SHARED  environmentActive
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	error = FunctionNameToNumber(@funcName$, @funcNumber)
	IF error THEN RETURN (error)
'
	Display (funcNumber, -1, -1, -1, -1)
	RETURN (0)
END FUNCTION
'
'
' ###############################
' #####  XitSetFunction ()  #####
' ###############################
'
'	Set function to text$[]
'
'	In:				funcName$
'						text$[]
'	Out:			none
'	Return:		error				0 = no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												$$XitProgramRunning
'												$$XitInvalidFunctionName
'												$$XitFunctionUndefined
'
FUNCTION  XitSetFunction (funcName$, text$[])
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	TOKEN   temp[]
	SHARED  TOKEN  prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  editFunction,  fileType
	SHARED  programAltered,  textAlteredSinceSave
	SHARED  environmentActive
	SHARED  xitGrid
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	IF ##USERRUNNING THEN RETURN ($$XitProgramRunning)
	error = FunctionNameToNumber(@funcName$, @funcNumber)
	IF (error = $$XitInvalidFunctionName) THEN RETURN (error)
'
	IFZ text$[] THEN															' Delete
		ATTACH prog[funcNumber,] TO func[]:  DIM func[]
		funcAltered[funcNumber]					= $$FALSE		' clear alteration flags
		funcBPAltered[funcNumber]				= $$FALSE
		funcNeedsTokenizing[funcNumber]	= $$FALSE
		funcCursorPosition[funcNumber, 0] = 0				' reset cursorChar / topChar
		funcCursorPosition[funcNumber, 1] = 0
		funcCursorPosition[funcNumber, 2]	= 0
		funcCursorPosition[funcNumber, 3]	= 0
		funcCursorPosition[funcNumber, 4]	= 0
		funcCursorPosition[funcNumber, 5]	= 0
'
		XxxDeleteFunction (funcNumber)							' Tell compiler
'
'		If removing editFunction, display PROLOG
'
		IF (funcNumber = editFunction) THEN
			TokenArrayToText (0, @text$[])
			cursorLine	= funcCursorPosition[0, 0]
			cursorPos		= funcCursorPosition[0, 1]
			topLine			= funcCursorPosition[0, 2]
			topIndent		= funcCursorPosition[0, 3]
			XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, cursorLine, topIndent, topLine, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
			editFunction = 0
			funcCursorPosition[0, 0] = cursorLine
			funcCursorPosition[0, 1] = cursorPos
			funcCursorPosition[0, 2] = topLine
			funcCursorPosition[0, 3] = topIndent
			funcCursorPosition[0, 4] = xCursor
			funcCursorPosition[0, 5] = yCursor
		END IF
		programAltered = $$TRUE
		textAlteredSinceSave = $$TRUE
		UpdateFileFuncLabels ($$TRUE, $$TRUE)				' altered
		ResetDataDisplays ($$ResetAssembly)
	ELSE
		freeze = $$TRUE
		TextToTokenArray (@text$[], @func[], funcNumber, freeze)
'
		ATTACH prog[funcNumber,] TO temp[]					' out with the old...
		DIM temp[]
		ATTACH func[] TO prog[funcNumber,]					' ...in with the new
		funcAltered[funcNumber]					= $$TRUE
		funcBPAltered[funcNumber]				= $$TRUE
		funcNeedsTokenizing[funcNumber]	= $$FALSE
		funcCursorPosition[funcNumber, 0] = 0				' reset cursorChar / topChar
		funcCursorPosition[funcNumber, 1] = 0
		funcCursorPosition[funcNumber, 2]	= 0
		funcCursorPosition[funcNumber, 3]	= 0
		funcCursorPosition[funcNumber, 4]	= 0
		funcCursorPosition[funcNumber, 5]	= 0
		IF (funcNumber = editFunction) THEN
			TokenArrayToText (funcNumber, @text$[])		' convert function to text$
			XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
			XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
		END IF
		programAltered = $$TRUE
		textAlteredSinceSave = $$TRUE
		UpdateFileFuncLabels ($$TRUE, $$FALSE)
	END IF
'
	RETURN (0)
END FUNCTION
'
'
' ################################
' #####  XitSaveFunction ()  #####
' ################################
'
'	Save function and its DECLARE to file
'
'	In:				funcName$
'						fileName$
'	Out:			none
'	Return:		error				0 = no error
'												$$XitEnvironmentInactive
'												$$XitTextMode
'												$$XitInvalidFunctionName
'												##ERROR...  (for file operations)
'
FUNCTION  XitSaveFunction (funcName$, fileName$)
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	TOKEN   startToken
	TOKEN   tok[]
	SHARED  TOKEN prog[]
	SHARED  editFunction,  fileType,  environmentActive
'
	IFZ environmentActive THEN RETURN ($$XitEnvironmentInactive)
	IF (fileType != $$Program) THEN RETURN ($$XitTextMode)
	error = FunctionNameToNumber(@funcName$, @funcNumber)
	IF (error = $$XitInvalidFunctionName) THEN RETURN (error)
'
	IF ((funcNumber = editFunction) AND (NOT ##USERRUNNING)) THEN
		redisplay = $$TRUE
		reportBogusRename = $$TRUE
		RestoreTextToProg (redisplay, reportBogusRename)
	END IF
	DIM text$[0]
	XitGetDECLARE (@funcName$, @declare$)
	IFZ declare$ THEN declare$ = "DECLARE FUNCTION  " + funcName$ + " ()"
	ATTACH declare$ TO text$[0]
	IF prog[funcNumber,] THEN
		ATTACH prog[funcNumber,] TO func[]
		lastLine = UBOUND(func[])
		REDIM text$[lastLine + 1]
		FOR line = 0 TO lastLine
			ATTACH func[line,] TO tok[]
'			IFZ tok[] THEN DO NEXT
			startToken = tok[0]                   ' save first token for line
			tok[0].ti.errno = 0                   ' strip errno from token line
			tok[0].ti.bpexe = $$BPEXECLR          ' strip BP/EXE from token line
			IFZ tok[0].tproto THEN PRINT "XitSaveFunction(50)"
			XxxDeparser(@tok[], @lineText$)
			tok[0] = startToken										' restore first token for line
			ATTACH lineText$ TO text$[line + 1]
			ATTACH tok[] TO func[line,]
		NEXT line
		ATTACH func[] TO prog[funcNumber,]
	END IF
	error = XstSaveStringArrayCRLF (@fileName$, @text$[])	' NT: CRLF
	RETURN (error)
END FUNCTION
'
'
' #############################
' #####  XitSoftBreak ()  #####
' #############################
'
' A Soft Break is a Ctrl-Pause.
' It is used as a normal means to break out of the user code execution,
'   returning to the environment.
' It just set breakpoints at every line in the user code and continues
'		allowing the breakpoint to stop the code.  Thus a break becomes a trap
'		and halts at the next line in the USER's code.
'
' Question:  Is there any command that will screw up by never reaching
'		a trap (i.e. a beginning of line)?
'		- All loops are required to be the first on the line, so OK (DO etc)
'		- Systemcalls are a problem:  INC x:  a$ = INLINE$("")
'			- compiler now emits code to check for a softbreak on a signal
'
'		- PROBLEM:  any linked assembly or C code SYSTEMCALLs/loops can hang
'			- SOLUTION:		enter xterm and issue a SIGQUIT
'				- SIGINT is only a softBreak
'				- reinstalling the HardBreak not foolproof if the dispatcher
'						gets hung up in a botched function
'				- having to flip to the xterm is crude...  any ideas?
'			- Recovering from such a break is frought with danger as C/assembly
'					system calls typically don't have code to recover from signals,
'					but continue, skipping the systemcall
'
'	softInterrupt is used to abort find/replace/compile/variable update routines
'
FUNCTION  XitSoftBreak ()
	SHARED  softInterrupt
'
	softInterrupt = $$TRUE
	IFZ ##USERRUNNING THEN RETURN										' ignore unless ##USERRUNNING
	IF ##SIGNALACTIVE THEN RETURN									  ' ignore if signal active
'
	IF ##USERWAITING THEN
		##USERWAITING = $$FALSE			' unblock waiting in INLINE$()
	ELSE
		##SOFTBREAK = $$TRUE
	END IF
'	MakeUserCodeRW()															' NT: Not required
	BreakInternal ($$BreakInstallAll, 0, 0, 0)		' Set traps
'	MakeUserCodeRX()															' NT: Not required
END FUNCTION
'
'
' ########################
' #####  XxxAsm$ ()  #####
' ########################
'
FUNCTION  XxxAsm$ (addr, length)
'	ULONG  ##UCODE0,  ##UCODE,  ##UCODEX,  ##UCODEZ
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
	SHARED  termaddr
'
	IF (length <= 0) THEN length = 0x0080			' prevent negative lengths
	IF (length > 4096) THEN length = 4096			' prevent too long lengths
	IFZ termaddr THEN termaddr = ##CODE
'	addr = addr AND 0xFFFFFFFC								' 32-bit code aligned CPUs
	IFZ addr THEN addr = termaddr
	IFZ AddressOk (addr) THEN
		RETURN ("Invalid start address: " + HEX$(addr, 8))
	END IF
	IF length THEN
		last =  addr + length
	ELSE
		last =  addr + 0x0020
	END IF
	IFZ AddressOk (last) THEN
		IF (last > ##UCODEZ) THEN
			last = ##UCODEZ
		ELSE
			last = ##CODEZ
		END IF
	END IF
	DO WHILE (addr < last)
		labels = XxxGetLabelGivenAddress (addr, @label$[])
		IF labels THEN
			FOR i = 0 TO labels-1
				asm$ = asm$ + HEXX$(addr, 8) + ": " + label$[i] + ":" + "\n"
			NEXT i
		END IF
		GetFuncAndLineNumberAtThisAddress (addr)
		asm$ = asm$ + HEXX$(addr, 8) + ":   " + XxxDisassemble64$ (@addr, $$TRUE) + "\n"
	LOOP
	termaddr = addr
	RETURN (asm$)
END FUNCTION
'
'
' ###########################
' #####  XxxAnyAsm$ ()  #####
' ###########################
'
FUNCTION  XxxAnyAsm$ (addr, length)
'	ULONG  ##UCODE0,  ##UCODE,  ##UCODEX,  ##UCODEZ
'	ULONG  ##CODE0,  ##CODE,  ##CODEX,  ##CODEZ
	SHARED  termaddr
'
	IF (length <= 0) THEN length = 0x0020			' prevent negative lengths
	IFZ termaddr THEN termaddr = ##CODE
'
'	addr = addr AND 0xFFFFFFFC								' 32-bit code aligned CPUs
'
	IFZ addr THEN addr = termaddr
	last =  addr + length
'
	DO WHILE (addr < last)
		labels = XxxGetLabelGivenAddress (addr, @label$[])
		IF labels THEN
			FOR i = 0 TO labels-1
				asm$ = asm$ + HEXX$(addr, 8) + ":   " + label$[i] + ":" + "\n"
			NEXT i
		END IF
		GetFuncAndLineNumberAtThisAddress (addr)
		asm$ = asm$ + HEXX$(addr, 8) + ":   " + XxxDisassemble64$ (@addr, $$TRUE) + "\n"
	LOOP
	termaddr = addr
	RETURN (asm$)
END FUNCTION
'
'
' ##########################################
' #####  XxxGetFuncNumGivenAddress ()  #####
' ##########################################
'
' funcNumber = XxxGetFuncNumGivenAddress (addr)
'
FUNCTION  XxxGetFuncNumGivenAddress (addr)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN  prog[]
	SHARED  funcFirstAddr[]
	SHARED  funcAfterAddr[]
'
	IFZ funcFirstAddr[] THEN RETURN (-1)
	IFZ funcAfterAddr[] THEN RETURN (-1)
'
	funcNumber = 0
	DO WHILE (funcNumber <= maxFuncNumber)
		IFZ prog[funcNumber,] THEN INC funcNumber: DO DO
		firstAddr = funcFirstAddr[funcNumber]
		afterAddr = funcAfterAddr[funcNumber]
'		PRINT "xit205-23", funcNumber, HEXX$(firstAddr), HEXX$(afterAddr)
		IF ((firstAddr <= addr) AND (addr < afterAddr)) THEN RETURN (funcNumber)
		INC funcNumber
	LOOP
	RETURN (-1)
END FUNCTION
'
'
' ###############################
' #####  XxxSetBlowback ()  #####
' ###############################
'
FUNCTION  XxxSetBlowback ()
	SHARED  blowback
	SHARED  exitMainLoop
'
	SELECT CASE TRUE
		CASE (##USERRUNNING AND (NOT ##SIGNALACTIVE))
					XitSoftBreak()
		CASE ##SIGNALACTIVE
					##SOFTBREAK = $$TRUE
	END SELECT
'
	exitMainLoop = $$TRUE
	blowback = $$TRUE
'
END FUNCTION
'
'
' #########################################
' #####  XxxXitGetUserProgramName ()  #####
' #########################################
'
FUNCTION  XxxXitGetUserProgramName (@program$)
	SHARED  editFile$
'
	program$ = editFile$
END FUNCTION
'
'
' ###########################
' #####  XxxXitExit ()  #####
' ###########################
'
FUNCTION  XxxXitExit (status)
'	ULONG  ##UCODE0,  ##UCODE,  ##UCODEX,  ##UCODEZ
'
	##UCODE0 = 0 : ##UCODE = 0 : ##UCODEX = 0 : ##UCODEZ = 0
	SharedMemory ($$MemoryDestroyAll, 0, 0, 0)
	##INEXIT = $$TRUE
	exit (status)
END FUNCTION
'
'
' #############################
' #####  CheckDECLARE ()  #####
' #############################
'
'		Return:		$$TRUE		tok[] is a declare line
'							$$FALSE		it isn't
'
FUNCTION  CheckDECLARE (TOKEN tok[], declareFuncNumber)
	TOKEN   token
	TOKEN   t1
'
'	IFZ tok[] THEN RETURN ($$FALSE)
	declareFuncNumber = 0
	toks = tok[0].ti.ndex
	IF (toks < 2) THEN RETURN ($$FALSE)
	tokPtr = 1
	IFZ NextXitToken(@tok[], @tokPtr, toks, @t1) THEN RETURN ($$FALSE)
	SELECT CASE TRUE
		CASE TokenMatch (@t1, @#T_DECLARE), TokenMatch (@t1, @#T_INTERNAL)
			IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN RETURN ($$FALSE)
			SELECT CASE TRUE
'				CASE  #T_FUNCTION, #T_CFUNCTION, #T_SFUNCTION
				CASE  TokenMatch (@token, @#T_FUNCTION), TokenMatch (@token, @#T_CFUNCTION), TokenMatch (@token, @#T_SFUNCTION)
				CASE  ELSE:			RETURN ($$FALSE)
			END SELECT
			DO UNTIL (tokPtr > toks)
				token = tok[tokPtr]
				IF (token.tp.kind = $$KIND_FUNCTIONS) THEN
					declareFuncNumber = token.tindex
					RETURN ($$TRUE)
				END IF
				INC tokPtr
			LOOP
	END SELECT
	RETURN ($$FALSE)
END FUNCTION
'
'
' #############################
' #####  CloneDECLARE ()  #####
' #############################
'
' If DECLARE already exists, leave it
'	IF srcFuncNumber's DECLARE/INTERNAL exists, copy it with newFuncNumber
'	ELSE:  use "DECLARE FUNCTION  funcName ()"
'
FUNCTION  CloneDECLARE (srcFuncNumber, newFuncNumber)
	TOKEN   token
	TOKEN   tok[]
'
	XxxFunctionName ($$XGET, @newFuncName$, newFuncNumber)
	XitGetDECLARE (@newFuncName$, @declare$)
	IF declare$ THEN RETURN
'
	XxxFunctionName ($$XGET, @srcFuncName$, srcFuncNumber)
	XitGetDECLARE (@srcFuncName$, @srcFuncDeclare$)
	declare$ = ""
	IF srcFuncDeclare$ THEN
		XxxParseSourceLine (@srcFuncDeclare$, @tok[])
		IFZ tok[] THEN EXIT FUNCTION											' disaster !!!
		toks = tok[0].ti.ndex
		FOR i = 1 TO toks
			token = tok[i]
			IF (token.tp.kind = $$KIND_FUNCTIONS) THEN
				tok[i].tindex =  newFuncNumber
				EXIT FOR
			END IF
		NEXT i
		IFZ tok[0].tproto THEN PRINT "CloneDECLARE(33)"
		XxxDeparser(@tok[], @declare$)
	END IF
	IFZ declare$ THEN declare$ = "DECLARE FUNCTION  " + newFuncName$ + " ()"
	XitSetDECLARE (@newFuncName$, @declare$)
END FUNCTION
'
'
' ############################
' #####  CompileLine ()  #####
' ############################
'
'	CompileLine (funcNumber, lineNumber, tok[])
'		If i486bin, then notes the current value of xpc.
'		Compiles line of tokens by calling XxxCheckLine (@tok[], lineNumber).
'		If no error and breakpoint marker is set in tok[0] (START token),
'			then set breakpoint at noted address.
'
'	In binary mode, compiler emits a call to XxxCheckMessages() after every
'	DO, FOR, label:, and function entry - to process environment messages.
'	Look for EmitCheckMessageCall() or XxxCheckMessages() in compiler.
'
FUNCTION  CompileLine (funcNumber, lineNumber, TOKEN tok[])
	EXTERNAL /xxx/  i486bin,  i486asm,  xpc,  maxFuncNumber,  errorCount
	EXTERNAL /xxx/	needMoreMemory
	SHARED  lineAddr[],  lineCode@@[],  lineUpper[],  lineLast[]
	SHARED  funcFirstAddr[],  funcAfterAddr[]
	SHARED  errorXerror[],  errorFunc[],  errorRawPtr[]
	SHARED  errorSrcPtr[],  errorSrcLine$[]
	SHARED  uError,  softInterrupt,  codeSpaceResized
	SHARED  progTotalLines
	SHARED  totalLines
	STATIC  haveNestingError
'
	SELECT CASE TRUE
		CASE i486bin:  GOSUB CompileLineBinary
		CASE i486asm:  GOSUB CompileLineAssembly
	END SELECT
	RETURN
'
'
' *****  Compile Line into Binary  *****
'
SUB CompileLineBinary
'	IFZ tok[] THEN EXIT SUB
'
'	PRINT "CompileLine(41)", HEXX$(##UCODEZ), HEXX$(xpc), HEXX$(##UCODE), HEXX$(##UCODE0)
'
	IF ((##UCODEZ - xpc) < 0x1000) THEN 				' Run out of UCODE room?
		needMoreMemory = $$TRUE
	ELSE
		spc = xpc
		IFZ lineNumber THEN funcFirstAddr[funcNumber] = xpc
		xerror = XxxCheckLine (lineNumber, @tok[])
	END IF
'
	IF needMoreMemory THEN
		needMoreMemory = $$FALSE
		currentCodeSize = ##UCODEZ - ##UCODE
		bytesPerLine = (currentCodeSize / totalLines) + 1
		linesRemaining = progTotalLines - totalLines
		bytesNeeded = bytesPerLine * linesRemaining
		bytesNeeded = bytesNeeded + 0x40000 AND 0xFFFC0000                      ' Add at least 250KB
		addr = ##UCODE0
		size = ##UCODEZ - ##UCODE0
		SharedMemory ($$MemoryDestroy, addr, size, 0)
		size = size + bytesNeeded
		SharedMemory ($$MemoryCreate, @addr, @size, $$OwnerReadWriteExecute)
		##UCODE0 = addr
		##UCODEZ = ##UCODE0 + size
		##UCODE = ##UCODE0 + 0x100
		IFZ addr THEN
			Message ("[CompileLine( )]\n Could not allocate memory \n\n abort compile ")
			softInterrupt = $$TRUE
		END IF
		codeSpaceResized = $$TRUE									' restart compilation
		RETURN
	END IF
'
	funcAfterAddr[funcNumber] = xpc				' will end up with "AfterAddr"
	GOSUB LogLineAddrAndCode
'
	IFZ xerror THEN
		IF (tok[0].ti.bpexe AND $$BP) THEN BreakProgrammer ($$BreakSetOne, spc, 0)
		EXIT SUB
	END IF
'
' (funcNumber > maxFuncNumber) means that END PROGRAM is being processed.
' If Nesting errors have occurred, do not log pass2errors that have
' probably been generated as a result.
'
	IF ((funcNumber > maxFuncNumber) && !!haveNestingError) THEN EXIT SUB
'
	IFZ errorCount THEN haveNestingError = 0
	GOSUB LogError
'
END SUB
'
'
' *****  Compile Line into Assembly  *****
'
SUB CompileLineAssembly
	xerror = XxxCheckLine (lineNumber, @tok[])
'	IFZ tok[] THEN EXIT FUNCTION
	IF xerror THEN GOSUB LogError
END SUB
'
'
'	*****  Log the error into info arrays  *****
'
SUB LogError
	IF (errorCount > 254) THEN													' too many errors...
		softInterrupt = $$TRUE
		EXIT SUB
	END IF
'
'	Get error(s)
'
	IF (funcNumber > maxFuncNumber) THEN								' END PROGRAM
		count = XxxGetPatchErrors (@symbol$[], @token[], @addr[])
		IF (errorCount + count > 255) THEN
			count = 255 - errorCount
		END IF
	ELSE
		count = 1
		XxxErrorInfo (xerror, @rawPtr, @srcPtr, @srcLine$)
	END IF
'
	IF (errorCount + count >= uError) THEN
		uError = (errorCount + count) << 1
		IF (uError < 31) THEN uError = 31
		IF (uError > 200) THEN uError = 255
		REDIM errorXerror[uError]			' holds error info:  error code
		REDIM errorFunc[uError]				' func number
		REDIM errorRawPtr[uError]			' raw source line 0 offset
		REDIM errorSrcPtr[uError]			' "compressed" source line pointer (offset 1)
		REDIM errorSrcLine$[uError]		' "compressed" source line (no tabs)
	END IF
'
	IF (funcNumber > maxFuncNumber) THEN								' END PROGRAM
		FOR i = 0 TO count - 1
			INC errorCount
			errorXerror[errorCount]		= xerror
			errorFunc[errorCount]			= -2									' -2 == END PROGRAM
			errorRawPtr[errorCount]		= token[i]
			errorSrcPtr[errorCount]		= addr[i]
			errorSrcLine$[errorCount]	= symbol$[i]
		NEXT i
	ELSE
'
'		Insert the error number into the token
'
		INC errorCount
		tok[0].ti.errno = errorCount
		errorXerror[errorCount]		= xerror
		errorFunc[errorCount]			= funcNumber
		errorRawPtr[errorCount]		= rawPtr
		errorSrcPtr[errorCount]		= srcPtr
		errorSrcLine$[errorCount]	= srcLine$
	END IF
'
' Nesting errors found during the first pass of the compiler often
' results in a lot of Undefined label errors at the end of compiling.
' Skip logging those errors if there are nesting errors.
'
	IFZ haveNestingError THEN
		xerr$ = XxxGetXerror$ (xerror)
		IF (LEFT$(xerr$, 13) == "Nesting Error") THEN
			haveNestingError = $$TRUE
		END IF
	END IF
END SUB
'
'
' *****  Log address and opcode for this line in lineAddr[] and lineCode@@[]
'
SUB LogLineAddrAndCode
	ufunc = UBOUND(lineAddr[])					' Required for function-wise compile only
	IF (maxFuncNumber >= ufunc) THEN
		ufunc = maxFuncNumber + 1					' last is for END PROGRAM
		REDIM lineAddr[ufunc,]
		REDIM lineCode@@[ufunc,]
		REDIM lineLast[ufunc]
		REDIM lineUpper[ufunc]
		REDIM funcFirstAddr[ufunc]
		REDIM funcAfterAddr[ufunc]
	END IF
	IFZ lineAddr[funcNumber,] THEN
		ATTACH lineAddr[funcNumber,] TO tempAddr[]
		ATTACH lineCode@@[funcNumber,] TO tempCode@@[]
		uLine = 15
		DIM tempAddr[uLine]
		DIM tempCode@@[uLine]
		lineLast[funcNumber] = 0
		lineUpper[funcNumber] = uLine
		ATTACH tempAddr[] TO lineAddr[funcNumber,]
		ATTACH tempCode@@[] TO lineCode@@[funcNumber,]
	END IF
	uLine = lineUpper[funcNumber]
	IF (lineNumber >= uLine) THEN
		ATTACH lineAddr[funcNumber,] TO tempAddr[]
		ATTACH lineCode@@[funcNumber,] TO tempCode@@[]
		uLine = uLine + 16
		REDIM tempAddr[uLine]
		REDIM tempCode@@[uLine]
		lineUpper[funcNumber] = uLine
		ATTACH tempAddr[] TO lineAddr[funcNumber,]
		ATTACH tempCode@@[] TO lineCode@@[funcNumber,]
	END IF
'
' Log address of line in lineAddr[funcNumber, lineNumber]
' (Note:  opcodes logged into lineCode@@[funcNumber, lineNumber] during Pass 2)
'
	lineAddr[funcNumber, lineNumber] = spc				' 1st addr for this line
	lineAddr[funcNumber, lineNumber + 1] = xpc		' For last line of function
	lineLast[funcNumber] = lineNumber
END SUB
END FUNCTION
'
'
' ##################################
' #####  ConvertProgToText ()  #####
' ##################################
'
'	Assumes:
'		- fileType is $$Program
'		- tokens are up to date (e.g. editFunction restored)
'
'	RETURNS TRUE if conversion aborted, else FALSE
'		(empty string returned on abort)
'
FUNCTION  ConvertProgToText (mode, crlf, abortAllowed, (text$, text$[]))
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   func[]
	TOKEN   startToken
	TOKEN   tok[]
	TOKEN   tokcw
	STATIC  cwline
	SHARED  TOKEN  prog[]
	SHARED  uprog
	SHARED  funcAltered[],  funcBPAltered[],  funcNeedsTokenizing[]
	SHARED  funcCursorPosition[]
	SHARED  softInterrupt
	SHARED  currentCursor
'
	softInterrupt = $$FALSE
	IF (mode = $$TextArray) THEN
		DIM text$[]
	ELSE
		text$ = ""
	END IF
'
	SetCurrentStatus ($$StatusDeparsing, 0)
	IF (abortAllowed AND softInterrupt) THEN
		RETURN ($$TRUE)
	END IF
'
	entryCursor = currentCursor
'	SetCursor ($$CursorWait)
'
	IF (maxFuncNumber > uprog) THEN						' Sync up in case of crash
		uprog = maxFuncNumber + (maxFuncNumber >> 2)
		REDIM prog[uprog,]
		REDIM funcAltered[uprog]
		REDIM funcBPAltered[uprog]
		REDIM funcNeedsTokenizing[uprog]
		REDIM funcCursorPosition[uprog, 5]
	END IF
'
	SELECT CASE mode
		CASE $$TextString	: GOSUB ConvertToString
		CASE $$TextArray	: GOSUB ConvertToArray
	END SELECT
'
'	SetCursor (entryCursor)
	RETURN ($$FALSE)
'
'
'
SUB ConvertToString
	lineCount = 0
	lastTotal = 0
	totalChars = 0
	DIM textArray$[maxFuncNumber + 1]
	IFZ crlf THEN flags = 0x01 ELSE flags = 0x03				' clearBP_EXE, maybe crlf
'
	FOR funcNumber = 0 TO maxFuncNumber
		IFZ prog[funcNumber,] THEN DO NEXT
		ATTACH prog[funcNumber,] TO func[]
		lastLine = UBOUND(func[])
		XxxDeparseFunction (@text$, @func[], lastLine, flags)
		totalChars = totalChars + LEN(text$)
		ATTACH text$ TO textArray$[funcNumber]
		ATTACH func[] TO prog[funcNumber,]
'
		lineCount = lineCount + lastLine + 1
		IF (lineCount > lastTotal + 1024) THEN						' Update every 1024 lines
			lastTotal = lineCount
			SetCurrentStatus ($$StatusDeparsing, lineCount)
			IF (abortAllowed AND softInterrupt) THEN EXIT SUB
		END IF
	NEXT funcNumber
'
	IFZ crlf THEN
		textArray$[maxFuncNumber + 1] = "END PROGRAM\n"
		text$ = NULL$ (totalChars + 12)											' room for END PROGRAM\n
	ELSE
		textArray$[maxFuncNumber + 1] = "END PROGRAM\r\n"
		text$ = NULL$ (totalChars + 13)											' room for END PROGRAM\r\n
	END IF
	destAddr = &text$
'
	offset = 0
	FOR funcNumber = 0 TO maxFuncNumber + 1
		IFZ textArray$[funcNumber] THEN DO NEXT
		srcAddr  = &textArray$[funcNumber]
		lastOffset = UBOUND(textArray$[funcNumber])				' offset from 0
		FOR j = 0 TO lastOffset
			UBYTEAT(destAddr, offset) = UBYTEAT(srcAddr, j)
			INC offset
		NEXT j
	NEXT funcNumber
END SUB
'
'
'
SUB ConvertToArray
	lines = 0
	FOR funcNumber = 0 TO maxFuncNumber
		IFZ prog[funcNumber,] THEN DO NEXT
		lines = lines + UBOUND(prog[funcNumber,]) + 1
	NEXT funcNumber
	IFZ lines THEN EXIT SUB
'
	uText = lines + 1																	' Add END PROGRAM
	DIM text$[uText]
'
' Loop through all functions
'
	line			= 0
	lastTotal	= 0
	FOR funcNumber = 0 TO maxFuncNumber
		IFZ prog[funcNumber,] THEN DO NEXT
		ATTACH prog[funcNumber,] TO func[]
		FOR i = 0 TO UBOUND(func[])
			ATTACH func[i,] TO tok[]
'			IFZ tok[] THEN INC line : DO NEXT
			startToken = tok[0]                   ' save first token for line
			tok[0].ti.errno = 0                   ' strip errno from token line
			tok[0].ti.bpexe = $$BPEXECLR          ' strip BP/EXE from token line
			IFZ tok[0].tproto THEN PRINT "ConvertProgToText(133)"
			XxxDeparser(@tok[], @lineText$)
			tok[0] = startToken										' restore first token for line
'
			ATTACH lineText$ TO text$[line]
			INC line
			ATTACH tok[] TO func[i,]
		NEXT i
		ATTACH func[] TO prog[funcNumber,]
'
		IF (line > lastTotal + 1024) THEN				' Update every 1024 lines
			lastTotal = line
			SetCurrentStatus ($$StatusDeparsing, line)
			IF (abortAllowed AND softInterrupt) THEN
				DIM text$[]
				EXIT SUB
			END IF
		END IF
	NEXT funcNumber
	text$[line] = "END PROGRAM"
END SUB
END FUNCTION
'
'
' ##################################
' #####  ConvertTextToProg ()  #####
' ##################################
'
' Converts source text into prog[func, line, token]
'
'	RETURNS TRUE if aborted, ELSE FALSE
'
'	The upper bound of prog[] is equal to the number of functions in the loaded
'		program.  The upper bound of prog[func] is equal to the number of lines in
'		func[].  The upper bound of prog[func, line] is equal to the number of
'		tokens on the specified line in func[].
'
' ConvertTextToProg() parses source text lines into token arrays, then
'		attaches them to the active func array at the current line number.
'		It switches to the next function when it detects the beginning of the
'		next function--lines beginning with FUNCTION or CFUNCTION and containing a
'		valid function name.
'		To avoid syntax errors, any END FUNCTION in the current function is ignored.
'		When the beginning of the next function is detected, an END FUNCTION is
'		manually inserted after the last non-comment line, any intervening comments
'		are placed at the beginning of the new function, followed by the FUNCTION
'		or CFUNCTION line.
'		Duplicate function definitions are appended to the original function.
'		The PROLOG does not receive an END FUNCTION.  FUNCTION or CFUNCTION lines
'		without a valid function name are considered part of the currently active
'		function.
'		Lines beginning with END or END PROGRAM tokens end the conversion,
'		as does reaching the end of the text.
'
' The PROLOG is named "PROLOG".  The names of all functions following
'		the PROLOG are taken from the FUNCTION or CFUNCTION line.
'
' The index into prog[] is the function number returned from the compiler.
'		As such, prog may contain gaps.
'
' END PROGRAM is eliminated from prog[]
'
'	END CFUNCTION is converted to END FUNCTION.
'
'	Sets the entryFunction
'
'	Discussion:
'		text$[] is mangled
'
FUNCTION  ConvertTextToProg (mode, (text$, text$[]), abortAllowed)
	EXTERNAL /xxx/  maxFuncNumber,  entryFunction
	TOKEN   endfunctoken[]
	TOKEN   endtok[]
	TOKEN   func[]
	TOKEN   oldFunc[]
	TOKEN   temp[]
	TOKEN   token
	TOKEN   token1
	TOKEN   token2
	TOKEN   tok[]
	SHARED  TOKEN  prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  UBYTE  charsetNonWhiteChar[]
	SHARED  uprog,  xitGrid,  editFunction,  priorFunction
	SHARED  programAltered,  softInterrupt
	SHARED  currentCursor
	SHARED  editFile$
'
	XxxXgrSysMessages ()                            ' process system messages
	softInterrupt = $$FALSE
'
	IF editFile$ THEN
		programName$ = RCLIP$ (editFile$, 2)
		XxxSetProgramName (programName$)
		programName$ = ""
	END IF
'
	entryCursor = currentCursor
'
	programAltered = $$TRUE
	ResetDataDisplays ($$ResetAssembly)
	ClearRuntimeError ()
'
' Initialize arrays
'
	uprog = 127									' uprog updated in Xit to track maxFuncNumber
	DIM prog[uprog,]						' start with room for uprog functions
	uLine = 255
	DIM func[uLine,]						' start with room for uLine lines in PROLOG
'
	InitializeCompiler ()				' Initialize compiler arrays/variables
'
	SetCurrentStatus ($$StatusParsing, lineCount)
	IF (abortAllowed AND softInterrupt) THEN
'		SetCursor (entryCursor)
		RETURN ($$TRUE)
	END IF
'
' Read in lines, look for FUNCTION / END FUNCTION statements
'
	IF (mode = $$TextArray) THEN
		uTextArray = UBOUND(text$[])
		textIndex = 0
	END IF
	lineCount				= 0
	lineNumber			= 0
	funcNumber			= 0
	nonCommentLine	= 0
	entryFunction		= 0
	index = 1
	DO UNTIL done
		funcLine = $$FALSE
		endFuncLine = $$FALSE
'
		IF (mode = $$TextArray) THEN
			IF (textIndex > uTextArray) THEN EXIT DO
			SWAP text$[textIndex], rawLine$
			INC textIndex
		ELSE
			rawLine$ = XstNextLine$ (@text$, @index, @done)
			IF done THEN EXIT DO
		END IF
'
		IF rawLine$ THEN														' quick RTRIM non-printables
			IFZ charsetNonWhiteChar[rawLine${UBOUND(rawLine$)}] THEN
				i = UBOUND(rawLine$)
				DO
					DEC i
					IF (i < 0) THEN EXIT DO
				LOOP UNTIL charsetNonWhiteChar[rawLine${i}]
				IF (i < 0) THEN
					rawLine$ = ""
				ELSE
					rawLine${i + 1} = 0										' NULL terminates
					xAddr = &rawLine$											' Ahem...
					XLONGAT (xAddr, -16) = i + 1
				END IF
			END IF
		END IF
		INC lineCount
		XxxParseSourceLine (@rawLine$, @tok[])	' convert source text to token array
		IFZ tok[] THEN GOTO DoLoop
		toks = tok[0].ti.ndex                   ' number of tokens for this line
		tok[0].ti.errno = 0                     ' strip errno from token line
		tok[0].ti.bpexe = $$BPEXECLR            ' strip BP/EXE from token line
'
		IF (maxFuncNumber > uprog) THEN
			uprog = maxFuncNumber << 1
			REDIM prog[uprog,]
		END IF
		IF (lineNumber > uLine) THEN					' make room for more lines in func[]
			uLine = uLine << 1
			REDIM func[uLine,]
		END IF
'
' Put blank lines into func[lineNumber,]
'
		IF (toks <= 1) THEN									' only START token (newline: toks = 0)
			ATTACH tok[] TO func[lineNumber,]
			INC lineNumber
			GOTO DoLoop
		END IF
'
' Put comment lines into func[lineNumber,]
'
		tokPtr = 1
		NextXitToken(@tok[], @tokPtr, toks, @token1)		' Trimmed, so not blank
		IF (token1.tp.kind = $$KIND_COMMENTS) THEN
			ATTACH tok[] TO func[lineNumber,]
			INC lineNumber
			GOTO DoLoop
		END IF
'
' Non-blank, non-comment lines ...
'
		SELECT CASE TRUE
			CASE TokenMatch (@token1, @#T_FUNCTION)  :	funcLine = $$TRUE
			CASE TokenMatch (@token1, @#T_CFUNCTION) :	funcLine = $$TRUE
			CASE TokenMatch (@token1, @#T_SFUNCTION) :	funcLine = $$TRUE
			CASE TokenMatch (@token1, @#T_END)
				IF NextXitToken(@tok[], @tokPtr, toks, @token2) THEN
					SELECT CASE TRUE
						CASE TokenMatch (@token2, @#T_PROGRAM)		:	EXIT DO               ' END PROGRAM
						CASE TokenMatch (@token2, @#T_FUNCTION)		:	endFuncLine = $$TRUE
						CASE TokenMatch (@token2, @#T_CFUNCTION)	:	endFuncLine = $$TRUE
						CASE TokenMatch (@token2, @#T_SFUNCTION)	:	endFuncLine = $$TRUE
					END SELECT
				END IF
		END SELECT
'
		IF endFuncLine THEN													' Ignore END FUNCTION
			DIM endfunctoken[]
			ATTACH tok[] TO endfunctoken[]
			lastNonCommentLine = nonCommentLine
			IF lineNumber THEN nonCommentLine = lineNumber - 1
			GOTO DoLoop
		ELSE
			lastNonCommentLine = nonCommentLine
			nonCommentLine = lineNumber
		END IF
'
		IF funcLine THEN
'
'			Get FUNCTION name:
'				PROLOG(), though an illegal function name (PASS 1),
'					returns a non-zero function number
'
			DO WHILE NextXitToken(@tok[], @tokPtr, toks, @token)
				SELECT CASE token.tp.kind
					CASE $$KIND_FUNCTIONS
						nextFuncNumber = token.tindex
						EXIT DO
					CASE $$KIND_TYPES					' Skip type name
						DO DO
				END SELECT
				SELECT CASE TRUE
'					CASE TokenMatch (@token, @#T_VOID)
					CASE TokenMatch (@token, @#T_SBYTE)
					CASE TokenMatch (@token, @#T_UBYTE)
					CASE TokenMatch (@token, @#T_SSHORT)
					CASE TokenMatch (@token, @#T_USHORT)
					CASE TokenMatch (@token, @#T_SLONG)
					CASE TokenMatch (@token, @#T_ULONG)
					CASE TokenMatch (@token, @#T_XLONG)
					CASE TokenMatch (@token, @#T_GIANT)
					CASE TokenMatch (@token, @#T_SINGLE)
					CASE TokenMatch (@token, @#T_DOUBLE)
					CASE TokenMatch (@token, @#T_STRING)
					CASE ELSE
						EXIT DO
				END SELECT
			LOOP
			IF nextFuncNumber THEN
				XxxFunctionName ($$XGET, @nextFuncName$, nextFuncNumber)
			ELSE
				funcLine = $$FALSE					' no name--stay with this function
			END IF
		END IF
'
' funcNumber = 0 is PROLOG, which takes dIfferent checking
'
		IFZ funcNumber THEN
			SELECT CASE TRUE
				CASE funcLine AND (nextFuncNumber != funcNumber)
					IFZ lineNumber THEN												' Whiz up a PROLOG
						DefaultFunctionText (0, @text$[])
						freeze = $$FALSE
						TextToTokenArray (@text$[], @func[], 0, freeze)
						lineNumber = UBOUND(func[]) + 1
						lastNonCommentLine = lineNumber - 1
					END IF
					lastPrologLine = lineNumber - 1
					GOSUB nextProgramFunc
					funcName$ = nextFuncName$
					funcNumber = nextFuncNumber
					IF (lastNonCommentLine + 1 <= lastPrologLine) THEN
						FOR n = lastNonCommentLine+1 TO lastPrologLine
							ATTACH prog[0,n,] TO func[lineNumber,]
							INC lineNumber
							IF (lineNumber > uLine) THEN
								uLine = uLine << 1
								REDIM func[uLine,]
							END IF
						NEXT n
					END IF
					ATTACH prog[0,] TO temp[]
					REDIM temp[lastNonCommentLine,]
					ATTACH temp[] TO prog[0,]
					ATTACH tok[] TO func[lineNumber,]
					INC lineNumber
					lastNonCommentLine = lineNumber
					nonCommentLine = lineNumber
				CASE ELSE
					IFZ entryFunction THEN							' set entry function
						IF (TokenMatch (@token1, @#T_DECLARE) OR TokenMatch (@token1, @#T_INTERNAL)) THEN
							IF NextXitToken(@tok[], @tokPtr, toks, @token) THEN
								SELECT CASE TRUE
									CASE  TokenMatch (@token, @#T_FUNCTION), TokenMatch (@token, @#T_CFUNCTION), TokenMatch (@token, @#T_SFUNCTION)
										DO WHILE NextXitToken(@tok[], @tokPtr, toks, @token)
											SELECT CASE token.tp.kind
												CASE $$KIND_FUNCTIONS
													entryFunction = token.tindex
													EXIT DO
												CASE $$KIND_TYPES					' Skip type name
													DO DO
											END SELECT
											SELECT CASE TRUE
'												CASE TokenMatch (@token, @#T_VOID
												CASE TokenMatch (@token, @#T_SBYTE)
												CASE TokenMatch (@token, @#T_UBYTE)
												CASE TokenMatch (@token, @#T_SSHORT)
												CASE TokenMatch (@token, @#T_USHORT)
												CASE TokenMatch (@token, @#T_SLONG)
												CASE TokenMatch (@token, @#T_ULONG)
												CASE TokenMatch (@token, @#T_XLONG)
												CASE TokenMatch (@token, @#T_GIANT)
												CASE TokenMatch (@token, @#T_SINGLE)
												CASE TokenMatch (@token, @#T_DOUBLE)
												CASE TokenMatch (@token, @#T_STRING)
												CASE ELSE		:	EXIT DO
											END SELECT
										LOOP
								END SELECT
							END IF
						END IF
					END IF
					ATTACH tok[] TO func[lineNumber,]
					INC lineNumber
			END SELECT
		ELSE														' funcNumber is not PROLOG
			SELECT CASE TRUE
				CASE funcLine AND (nextFuncNumber != funcNumber)
					lastFunctionLine = lineNumber - 1
					GOSUB nextProgramFunc
'
'					Transfer trailing comments to next function
'
					IF (lastNonCommentLine + 1 <= lastFunctionLine) THEN
						FOR n = lastNonCommentLine + 1 TO lastFunctionLine
							ATTACH prog[funcNumber, n,] TO func[lineNumber,]
							INC lineNumber
							IF (lineNumber > uLine) THEN
								uLine = uLine << 1
								REDIM func[uLine,]
							END IF
						NEXT n
					END IF
'
'					Attach END FUNCTION, REDIM old function array
'
					IF endfunctoken[] THEN
						upend = UBOUND(endfunctoken[])
						DIM endtok[upend]
						FOR et = 0 TO upend
							endtok[et] = endfunctoken[et]
						NEXT et
					ELSE
						DIM endtok[3]												' last token must be ZERO
						endtok[0] = #T_STARTS					' start of line token (3 tokens)
						endtok[0].tindex = 3					' start of line token (3 tokens)
						endtok[1] = #T_END			' add 1 space after end
						endtok[1].tp.stsp = 1			' add 1 space after end
						endtok[2] = #T_FUNCTION							' synthesized line = END FUNCTION
					END IF
'
					line = lastNonCommentLine + 1
					ATTACH prog[funcNumber,] TO oldFunc[]
					ATTACH oldFunc[line,] TO temp[]
					IF temp[] THEN DIM temp[]
					ATTACH endtok[] TO oldFunc[line,]
					REDIM oldFunc[line,]
					ATTACH oldFunc[] TO prog[funcNumber,]
'
'					Set up next function
'
					funcName$ = nextFuncName$
					funcNumber = nextFuncNumber
					ATTACH tok[] TO func[lineNumber,]
					INC lineNumber
					nonCommentLine = lineNumber
					lastNonCommentLine = lineNumber
'
				CASE ELSE
					ATTACH tok[] TO func[lineNumber,]
					INC lineNumber
			END SELECT
		END IF
'
DoLoop:
		SELECT CASE FALSE
			CASE (lineCount AND 0xFFF):	SetCurrentStatus ($$StatusParsing, lineCount)		' Update 4096
			CASE (lineCount AND 0x3FF):	ClearMessageQueue ()
		END SELECT
		IF (abortAllowed AND softInterrupt) THEN
			RETURN ($$TRUE)
		END IF
	LOOP
'
' attach last function to prog[], display PROLOG in text widget
'
	IF funcNumber THEN
		IF endfunctoken[] THEN
			upend = UBOUND(endfunctoken[])
			DIM temp[upend]
			FOR et = 0 TO upend
				temp[et] = endfunctoken[et]
			NEXT et
		ELSE
			DIM temp[3]															' Attach END FUNCTION
			temp[0] = #T_STARTS
			temp[0].tindex =  3
			temp[1] = #T_END
			temp[1].tp.stsp = 1
			temp[2] = #T_FUNCTION
		END IF
		ATTACH temp[] TO func[lineNumber,]
		INC lineNumber
	END IF
	REDIM func[lineNumber-1,]
	ATTACH func[] TO prog[funcNumber,]				' put last function in prog[]
'
	IF (uprog > maxFuncNumber + 7) THEN
		uprog = maxFuncNumber + 7
		REDIM prog[uprog,]
	END IF
'
	DIM funcAltered[uprog]										' these have same DIM as prog[]
	DIM funcBPAltered[uprog]
	DIM funcNeedsTokenizing[uprog]
	DIM funcCursorPosition[uprog, 5]
'
	FOR funcNumber = 0 TO maxFuncNumber
		IFZ prog[funcNumber,] THEN DO NEXT
		funcAltered[funcNumber] = $$TRUE				' all need compilation
	NEXT funcNumber
'
	editFunction  = 0													' PROLOG
	priorFunction = 0
	TokenArrayToText (editFunction, @text$[])	' convert PROLOG into source text$
	XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	XuiSendMessage (xitGrid, #SetTextCursor, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetKeyboardFocus, 0, 0, 0, 0, $$xitTextLower, 0)
	RETURN ($$FALSE)
'
'
SUB nextProgramFunc
'
' Put loaded function in prog[], initializes func[]
'		lineNumber points to FUNCTION/CFUNCTION line which is NOT added to current
'			function
'
	ATTACH func[] TO prog[funcNumber,]
	IFZ prog[nextFuncNumber,] THEN
		uLine = 255
		DIM func[uLine,]
		lineNumber = 0
	ELSE
		ATTACH prog[nextFuncNumber,] TO func[]		' Append to existing function
		uLine = UBOUND(func[])
		ATTACH func[uLine,] TO temp[]: DIM temp[]	' Remove END FUNCTION
		lineNumber = uLine												' Next available line number
		uLine = uLine << 1
		REDIM func[uLine,]
	END IF
END SUB
END FUNCTION
'
'
'
' #################################
' #####  DefaultFunctionText  #####
' #################################
'
FUNCTION  DefaultFunctionText (funcNumber, text$[])
'
' funcNumber = 0 means PROLOG
'
	IFZ funcNumber THEN
		DIM text$[25]
		text$[ 0] = "'"
		text$[ 1] = "' ####################"
		text$[ 2] = "' #####  PROLOG  #####"
		text$[ 3] = "' ####################"
		text$[ 4] = "'"
		text$[ 5] = "' Programs contain:  PROLOG             no executable code"
		text$[ 6] = "'                    Entry function     start execution"
		text$[ 7] = "' * = optional       Other functions    everything else"
		text$[ 8] = "'"
		text$[ 9] = "' The PROLOG contains (in this order):"
		text$[10] = "' * 1. Library directives, if any       IMPORT \"libraryName\""
		text$[11] = "' * 2. Composite type definitions       TYPE <typename> ... END TYPE"
		text$[12] = "'   3. Internal function declarations   DECLARE/INTERNAL FUNCTION FuncName (args)"
		text$[13] = "' * 4. External function declarations   EXTERNAL FUNCTION FuncName (args)"
		text$[14] = "' * 5. Shared constant definitions      $$ConstantName = <constant or literal value>"
		text$[15] = "' * 6. Shared variable declarations     SHARED  variable"
		text$[16] = "'"
		text$[17] = "' ******  Comment in libraries as needed  *****"
		text$[18] = "'"
		text$[19] = "'	IMPORT  \"xst\"   ' standard library : required by most programs"
		text$[20] = "'	IMPORT  \"xgr\"   ' GraphicsDesigner : required by GuiDesigner programs"
		text$[21] = "'	IMPORT  \"xui\"   ' GuiDesigner      : required by GuiDesigner programs"
		text$[22] = "'	IMPORT  \"xma\"   ' math library     : SIN/ASIN/SINH/ASINH/LOG/EXP/SQRT..."
		text$[23] = "'	IMPORT  \"xcm\"   ' complex library  : complex number library  (trig, etc)"
		text$[24] = "'"
		text$[25] = "'"
	ELSE
		XxxFunctionName ($$XGET, @funcName$, funcNumber)
		DIM text$[9]
		text$[0] = "'"
		text$[1] = "'"
		text$[2] = "' #######" + CHR$('#', LEN(funcName$)) + "##########"
		text$[3] = "' #####  " +					funcName$					+ " ()  #####"
		text$[4] = "' #######" + CHR$('#', LEN(funcName$)) + "##########"
		text$[5] = "'"
		text$[6] = "FUNCTION  " + funcName$ + " ()"
		text$[7] = ""
		text$[8] = ""
		text$[9] = "END FUNCTION"
	END IF
END FUNCTION
'
'
' ########################
' #####  Display ()  #####
' ########################
'
'	If -1, use old value
'
FUNCTION  Display (funcNumber, cursorLine, cursorPos, topLine, topIndent)
	SHARED  TOKEN  prog[]
	SHARED  fileType
	SHARED  funcCursorPosition[]
	SHARED  editFunction,  priorFunction,  xitGrid
	SHARED  currentCursor
	STATIC  oldFuncNumber
'
	IF (fileType != $$Program) THEN RETURN
	IF (funcNumber < 0) THEN funcNumber = editFunction		' 11/04/93
'
' Code added in the next few lines to determine cause of runtime crash in this line:  IFZ prog[funcNumber,] THEN
'
	IF (editFunction != funcNumber) THEN
		IFZ prog[] THEN PRINT "Display() : error : prog[] is empty" : RETURN
		u = UBOUND(prog[])
		IF ((funcNumber < 0) OR (funcNumber > u)) THEN
			PRINT "Display() : funcNumber ="; funcNumber; "  :  UBOUND(prog[]) ="; u
			RETURN
		END IF
		IFZ prog[funcNumber,] THEN
			Message ("[Display( )]\n No function at # " + STRING$(funcNumber) + " ")
			EXIT FUNCTION
		END IF
'
		entryCursor = currentCursor
		TokenArrayToText (funcNumber, @text$[])		' convert function to text$
		redisplay = $$FALSE
		reportBogusRename = $$TRUE								' tokenize, resets BPs
		RestoreTextToProg (redisplay, reportBogusRename)
'
		IF (cursorLine	= -1) THEN cursorLine	= funcCursorPosition[funcNumber, 0]
		IF (cursorPos		= -1) THEN cursorPos	= funcCursorPosition[funcNumber, 1]
		IF (topLine			= -1) THEN topLine		= funcCursorPosition[funcNumber, 2]
		IF (topIndent		= -1) THEN topIndent	= funcCursorPosition[funcNumber, 3]
'
		XuiSendMessage (xitGrid, #GetTextCursor, 0, 0, 0, 0, $$xitTextLower, @rows)   'get rows
		topLineTmp = cursorLine-(rows*3\4)
		IF (topLineTmp > topLine) THEN topLine = topLineTmp
'
		XuiSendMessage (xitGrid, #SetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, cursorLine, topIndent, topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
		priorFunction = editFunction
		editFunction  = funcNumber
		funcCursorPosition[editFunction, 0] = cursorLine
		funcCursorPosition[editFunction, 1] = cursorPos
		funcCursorPosition[editFunction, 2] = topLine
		funcCursorPosition[editFunction, 3] = topIndent
		funcCursorPosition[editFunction, 4] = xCursor
		funcCursorPosition[editFunction, 5] = yCursor
		UpdateFileFuncLabels (0, $$TRUE)					' Reset function name
		oldFuncNumber = funcNumber
'		SetCursor (entryCursor)
		RETURN
	END IF
'
	xCursor = -1
	yCursor = -1
	IF ((cursorLine AND cursorPos AND topLine AND topIndent) = -1) THEN
		xCursor = funcCursorPosition[funcNumber, 4]
		yCursor = funcCursorPosition[funcNumber, 5]
	END IF
	IF (cursorLine	= -1) THEN cursorLine	= funcCursorPosition[funcNumber, 0]
	IF (cursorPos		= -1) THEN cursorPos	= funcCursorPosition[funcNumber, 1]
	IF (topLine			= -1) THEN topLine		= funcCursorPosition[funcNumber, 2]
	IF (topIndent		= -1) THEN topIndent	= funcCursorPosition[funcNumber, 3]
'
		XuiSendMessage (xitGrid, #GetTextCursor, 0, 0, 0, 0, $$xitTextLower, @rows)        'get @rows
		topLineTmp = cursorLine-(rows*3\4)
		IF (topLineTmp > topLine) THEN topLine = topLineTmp
'
	XuiSendMessage (xitGrid, #SetTextCursor, cursorPos, cursorLine, topIndent, topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #SetCursorXY, xCursor, yCursor, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
'
	funcCursorPosition[editFunction, 0] = cursorLine
	funcCursorPosition[editFunction, 1] = cursorPos
	funcCursorPosition[editFunction, 2] = topLine
	funcCursorPosition[editFunction, 3] = topIndent
	funcCursorPosition[editFunction, 4] = xCursor
	funcCursorPosition[editFunction, 5] = yCursor
END FUNCTION
'
'
' ##########################
' #####  FindArray ()  #####
' ##########################
'
FUNCTION  FindArray (mode, text$[], find$, line, pos, reps, skip, matches[])
'
	IF (mode AND 0x01) THEN dir = -1 ELSE dir = +1
	slot = -1
	upper = 255
	DIM matches[upper,1]
	lp = line : cp = pos
	IF skip THEN
		IFZ cp THEN
			IF (dir == -1) THEN lp = lp + dir
		END IF
		cp = cp + dir
		IF INSTR(find$, "\n") THEN
			IF (dir == 1) THEN
				lp = lp + dir
				cp = 0
			END IF
		END IF
	END IF
'
	DO WHILE reps
		XstFindArray (mode, @text$[], @find$, @lp, @cp, @match)
		IF match THEN
			INC slot
			DEC reps
			IF (slot > upper) THEN upper = slot + 256 : REDIM matches[upper,1]
			matches[slot,0] = lp
			matches[slot,1] = cp
			cp = cp + dir
		END IF
	LOOP WHILE match
	IF (slot < 0) THEN
		DIM matches[]
	ELSE
		line = lp
		pos = cp - dir
		REDIM matches[slot,1]
	END IF
END FUNCTION
'
'
' #####################################
' #####  FunctionNameToNumber ()  #####
' #####################################
'
'	Test function name for validity, return funcNumber
'
'	In:				funcName$
'	Out:			funcNumber
'	Return:		error			0 = valid
'											$$XitInvalidFunctionName
'											$$XitFunctionUndefined
'
'	Discussion:
'		Assumes environmentActive, ProgramMode
'
FUNCTION  FunctionNameToNumber (funcName$, funcNumber)
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   tok[]
	SHARED  TOKEN  prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  uprog
'
	IFZ funcName$ THEN RETURN ($$XitInvalidFunctionName)
	cchar = funcName${0}
	IF ((cchar >= '0') AND (cchar <= '9')) THEN RETURN ($$XitInvalidFunctionName)
	lastChar = UBOUND(funcName$)
	FOR i = 0 TO lastChar
		cchar = funcName${i}
		IF ((cchar >= 'a') AND (cchar <= 'z')) THEN DO NEXT
		IF ((cchar >= 'A') AND (cchar <= 'Z')) THEN DO NEXT
		IF ((cchar >= '0') AND (cchar <= '9')) THEN DO NEXT
		IF (cchar = '_') THEN DO NEXT
		IF (cchar = '$') THEN									' only explicit type is STRING
			IF (i = lastChar) THEN EXIT FOR
		END IF
		RETURN ($$XitInvalidFunctionName)
	NEXT i
'
	IF (funcName$ = "PROLOG") THEN
		funcNumber = 0
	ELSE
		token$ = funcName$ + " ("									' compiler assigns function number
		XxxParseSourceLine (@token$, @tok[])
		IF (maxFuncNumber > uprog) THEN
			uprog = maxFuncNumber + (maxFuncNumber >> 2)
			REDIM prog[uprog,]
			REDIM funcAltered[uprog]
			REDIM funcBPAltered[uprog]
			REDIM funcNeedsTokenizing[uprog]
			REDIM funcCursorPosition[uprog, 5]
		END IF
		funcNumber = tok[1].tindex
	END IF
	IFZ prog[funcNumber,] THEN RETURN ($$XitFunctionUndefined)
	RETURN (0)
END FUNCTION
'
'
' ##########################################
' #####  GetFuncNumberGivenAddress ()  #####
' ##########################################
'
FUNCTION  GetFuncNumberGivenAddress (addr)
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN  prog[]
	SHARED  funcFirstAddr[]
	SHARED  funcAfterAddr[]
'
	IFZ funcFirstAddr[] THEN RETURN (-1)
	IFZ funcAfterAddr[] THEN RETURN (-1)
'
	funcNumber = 0
	DO WHILE (funcNumber <= maxFuncNumber)
		IFZ prog[funcNumber,] THEN INC funcNumber: DO DO
		firstAddr = funcFirstAddr[funcNumber]
		afterAddr = funcAfterAddr[funcNumber]
		IF ((firstAddr <= addr) AND (addr < afterAddr)) THEN RETURN (funcNumber)
		INC funcNumber
	LOOP
	RETURN (-1)
END FUNCTION
'
'
' ###################################
' #####  InitializeCompiler ()  #####
' ###################################
'
FUNCTION  InitializeCompiler ()
	TOKEN   tok[]
	STATIC  notFirstPass
'
	SetCurrentStatus ($$StatusInitializing, 0)
	XxxInitAll ()									' Initialize compiler arrays/variables/tokens
'
	IF notFirstPass THEN RETURN
	notFirstPass = $$TRUE
'
' Define some useful tokens
'
	tokens$ = "DECLARE INTERNAL EXTERNAL FUNCTION CFUNCTION SFUNCTION"
	tokens$ = tokens$ + " END TYPE PROGRAM : /"
	tokens$ = tokens$ + " AUTO AUTOX STATIC SHARED"
	tokens$ = tokens$ + " SBYTE UBYTE SSHORT USHORT SLONG ULONG XLONG"
	tokens$ = tokens$ + " GIANT SINGLE DOUBLE STRING ' xxx"
	XxxParseSourceLine (tokens$, @tok[])
'
	FOR i = 0 TO UBOUND(tok[])
		tok[i].tp.stsp = 0
	NEXT i
'
	i = 1
	#T_DECLARE   = tok[i] : INC i
	#T_INTERNAL  = tok[i] : INC i
	#T_EXTERNAL  = tok[i] : INC i
	#T_FUNCTION  = tok[i] : INC i
	#T_CFUNCTION = tok[i] : INC i
	#T_SFUNCTION = tok[i] : INC i
	#T_END       = tok[i] : INC i
	#T_TYPE      = tok[i] : INC i
	#T_PROGRAM   = tok[i] : INC i
	#T_COLON     = tok[i] : INC i
	#T_DIV       = tok[i] : INC i
	#T_AUTO      = tok[i] : INC i
	#T_AUTOX     = tok[i] : INC i
	#T_STATIC    = tok[i] : INC i
	#T_SHARED    = tok[i] : INC i
	#T_SBYTE     = tok[i] : INC i
	#T_UBYTE     = tok[i] : INC i
	#T_SSHORT    = tok[i] : INC i
	#T_USHORT    = tok[i] : INC i
	#T_SLONG     = tok[i] : INC i
	#T_ULONG     = tok[i] : INC i
	#T_XLONG     = tok[i] : INC i
	#T_GIANT     = tok[i] : INC i
	#T_SINGLE    = tok[i] : INC i
	#T_DOUBLE    = tok[i] : INC i
	#T_STRING    = tok[i] : INC i
	#T_COMMENT   = tok[i] : INC i
'
	#T_STARTS.tp.kind = $$KIND_STARTS
'
END FUNCTION
'
'
' ##################################
' #####  LoadLineCodeArray ()  #####
' ##################################
'
' LoadLineCodeArray ()
'   After programs are compiled to executable binary in memory, the 1st opcode
'   on each line must be logged into lineCode@@[].  The address of the first
'   opcode on each line is found in lineAddr[].  Note that this must be done
'   after complete compilation (not within CompileLine() for example), because
'   some opcodes are not complete until PASS 2 completes, because PASS 2
'   patches several kinds of incomplete opcodes, including foreward references.
'
'		NT/SCO: "opcode" refers to the FIRST BYTE of the opcode.  It simply needs to
'   be the length of the $$BREAK instruction (1 byte).
'   ##WIN32S = 2 byte breakpoint instruction !!!!!!!!
'
FUNCTION  LoadLineCodeArray ()
	EXTERNAL /xxx/  maxFuncNumber
	SHARED  TOKEN  prog[]
	SHARED  lineAddr[]
	SHARED  lineCode@@[]
	SHARED  lineLast[]
'
	funcNumber = 0
	DO UNTIL (funcNumber > maxFuncNumber)
		IFZ prog[funcNumber,] THEN INC funcNumber: DO DO
		lineLast = lineLast[funcNumber]
		line = 0
		DO UNTIL (line > lineLast)
			lineAddr = lineAddr[funcNumber, line]
			IF (lineAddr < ##UCODE) THEN
				PRINT "LoadLineCodeArray(34)", funcNumber, line
				EXIT DO
			END IF
			IF (lineAddr > ##UCODEZ) THEN
				PRINT "LoadLineCodeArray(38)", funcNumber, line
				EXIT DO
			END IF
			lineCode = UBYTEAT (lineAddr)
			lineCode@@[funcNumber, line] = lineCode
			INC line
		LOOP
		INC funcNumber
	LOOP
END FUNCTION
'
'
' ##############################
' #####  MakeStringHex ()  #####
' ##############################
'
'         MakeStringHex (@numstr$) 'pass by reference to make string hex
' value = MakeStringHex (numstr$)  'returns the value as a hex string
' value = MakeStringHex (@numstr$) 'returns the value and make string hex
'
FUNCTION  MakeStringHex (numstr$)

	IF numstr$  THEN
		IFF LCASE$(LEFT$(numstr$,2)) == "0x" THEN  '*cw* 230824-+
			numstr$ = "0x" + numstr$
		END IF
	END IF
	IF numstr$  THEN value = XLONG (numstr$)
	RETURN value

END FUNCTION
'
'
' #############################
' #####  NextXitToken ()  #####
' #############################
'
'	Return:  $$FALSE if no meaty tokens remaining (done)
'
FUNCTION  NextXitToken (TOKEN tok[], tokPtr, lastTok, TOKEN token)
'
'	IFZ tok[] THEN RETURN ($$FALSE)
'	upper = UBOUND(tok[])
'	IF (upper < lastTok) THEN lastTok = upper
'
	DO WHILE (tokPtr <= lastTok)
		token = tok[tokPtr]
		token.tp.stsp = 0
		INC tokPtr
		kind = token.tp.kind
		IF (kind != $$KIND_WHITES) THEN
			IF (kind = $$KIND_COMMENTS) THEN
				RETURN ($$FALSE)
			ELSE
				RETURN ($$TRUE)
			END IF
		END IF
	LOOP
	RETURN ($$FALSE)
END FUNCTION
'
'
' #################################
' #####  RemoveExeLinePtr ()  #####
' #################################
'
FUNCTION  RemoveExeLinePtr ()
	TOKEN   func[]
	SHARED  TOKEN  prog[]
	SHARED  editFunction,  exeFunction,  exeLine,  xitGrid
'
	IFZ exeFunction THEN GOTO done
	IFZ prog[exeFunction,] THEN GOTO done
	ATTACH prog[exeFunction,] TO func[]
	IF (exeLine <= UBOUND(func[])) THEN
'
		SELECT CASE func[exeLine, 0].ti.bpexe
			CASE $$BPEXECLR :
			CASE $$BP       :
			CASE $$EXE      : func[exeLine, 0].ti.bpexe = $$BPEXECLR
												exeChanged = $$TRUE
			CASE $$BPEXE    : func[exeLine, 0].ti.bpexe = $$BP
												exeChanged = $$TRUE
			CASE ELSE       : PRINT "SetExeLinePtr():Invalid .ti.bpexe", func[exeLine, 0].ti.bpexe
		END SELECT
'
		IF (exeFunction = editFunction) THEN
			XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
			IF text$[] THEN
				XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, 0, 0, $$xitTextLower, 0)
				modified = $$FALSE
				FOR line = 0 TO UBOUND(text$[])
					IFZ text$[line] THEN DO NEXT
					IF (text$[line]{0} = '>') THEN
						text$[line] = MID$(text$[line], 2)
						modified = $$TRUE
						IFZ exeChanged THEN PRINT "RemoveExeLinePtr(38): modified/exeChanged", modified, exeChanged
						IF (line == cursorLine) THEN cursorLineModified = $$TRUE
					END IF
				NEXT line
				XuiSendMessage (xitGrid, #PokeTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
				IF (cursorLineModified && cursorPos) THEN
					XuiSendMessage (xitGrid, #SetTextCursor, cursorPos-1, cursorLine, 0, 0, $$xitTextLower, 0)
				END IF
				IF modified THEN
					XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
				END IF
			END IF
		END IF
	END IF
	ATTACH func[] TO prog[exeFunction,]
'
done:
	exeFunction = 0
	exeLine = 0
END FUNCTION
'
'
' #############################
' #####  ReplaceArray ()  #####
' #############################
'
FUNCTION  ReplaceArray (mode, text$[], find$, replace$, line, pos, reps, skip)
'
	dir = 1
	reverse = $$FALSE
	IF (mode AND 0x01) THEN dir = -1 : reverse = $$TRUE
	mached = $$FALSE
	lp = line : cp = pos
	length = LEN (replace$)
	IF skip THEN cp = cp + dir
	upper = UBOUND (text$[])
	IF (cp < 0) THEN
		lp = lp - 1
		IF (lp < 0) THEN lp = upper
		t$ = text$[lp]
		cp = LEN (t$)
	END IF
'
	DO WHILE reps
		XstReplaceArray (mode, @text$[], @find$, @replace$, @lp, @cp, @match)
		IF match THEN
			IFZ reverse THEN cp = cp + length
			mached = $$TRUE
			DEC reps
		END IF
	LOOP WHILE match
	IF mached THEN pos = cp : line = lp
END FUNCTION
'
'
' ##################################
' #####  ResetDataDisplays ()  #####
' ##################################
'
'	action{1,0} = reset the assembly window
'				{1,1} = initiating run
'
FUNCTION  ResetDataDisplays (action)
	SHARED  variableFuncRow[]
	SHARED  programAltered,  fileType
	SHARED  assemblyBox,  framesBox
	SHARED  variableBox
	SHARED  arrayUp,  arrayBox
	SHARED  stringUp,  stringBox,  compositeUp,  compositeBox
	SHARED  exeFunction
	SHARED  variableSaved$[]
'
	$RESET_ASSEMBLY = BITFIELD (1, 0)
	$INITIATING_RUN  = BITFIELD (1, 1)
'
	IF exeFunction THEN RemoveExeLinePtr()					' waste >
'
	IF action{$RESET_ASSEMBLY} THEN
		justUpdate = $$TRUE
		DebugAssembly (assemblyBox, #DisplayWindow, justUpdate, 0, 0, 0, 0, 0)
	END IF
'
	SELECT CASE TRUE
		CASE (fileType != $$Program)
					unavailable$ = "* Unavailable: TEXT mode *"
					DIM variableFuncRow[]
		CASE programAltered							' TextModify doesn't reset ##USERRUNNING
					unavailable$ = "* Program requires compilation *"
					DIM variableFuncRow[]
					DIM variableSaved$[]
		CASE action{$INITIATING_RUN}
					unavailable$ = "* Program executing *"
		CASE (##USERRUNNING AND (NOT ##SIGNALACTIVE))
					unavailable$ = "* Program executing *"
		CASE ELSE												' not ##USERRUNNING or ???
					unavailable$ = "* Program not running *"
					DIM variableSaved$[]
	END SELECT
'
	IF variableFuncRow[] THEN
		func = variableFuncRow[0, 0]		' PROLOG slot used for current func
		IF func THEN										' top character / cursor
			XuiSendMessage (variableBox, #GetTextCursor, 0, @cursorLine, 0, @topLine, 3, 0)
			variableFuncRow[func, 0] = topLine
			variableFuncRow[func, 1] = cursorLine
		END IF
		variableFuncRow[0, 0] = 0				' Say last function = PROLOG
	END IF
'
' Max: During FileLoad, XuiSendMessage() gets "(grid <= 0)" error below
'
	IF (framesBox <= 0) THEN PRINT "ResetDataDisplays(): Error: (framesBox <= 0) "; framesBox
'
'	Frames:
'
	DIM item$[0]
	item$[0] = unavailable$
	XuiSendMessage (framesBox, #SetTextArray, 0, 0, 0, 0, 2, @item$[])
	XuiSendMessage (framesBox, #SetTextCursor, 0, 0, 0, 0, 2, 0)
	XuiSendMessage (framesBox, #RedrawText, 0, 0, 0, 0, 2, 0)
'
'	Variables:
'
	DIM text$[0]
	text$[0] = unavailable$
	XuiSendMessage (variableBox, #SetTextArray, 0, 0, 0, 0, 3, @text$[])
	XuiSendMessage (variableBox, #SetTextCursor, 0, 0, 0, 0, 3, 0)
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 3, 0)
	XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 1, "")
	XuiSendMessage (variableBox, #RedrawGrid, 0, 0, 0, 0, 1, 0)
	XuiSendMessage (variableBox, #SetTextString, 0, 0, 0, 0, 7, "")
	XuiSendMessage (variableBox, #RedrawText, 0, 0, 0, 0, 7, 0)
	IF arrayUp THEN VariablesArray (arrayBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	IF stringUp THEN VariablesString (stringBox, #HideWindow, 0, 0, 0, 0, 0, 0)
	IF compositeUp THEN	VariablesComposite (compositeBox, #HideWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ##################################
' #####  RestoreTextToProg ()  #####
' ##################################
'
'	Note:  can't rename or remove a function by editing
'					(attempts are overridden).  Use Menu functions.
'
' TextModify determines differences
'
' Tokenize the text
'		- Tokenizing discards trailing newlines, removes currentexe/BP from PROLOG,
'				and RTRIMs each line
'
FUNCTION  RestoreTextToProg (redisplay, reportBogusRename)
	TOKEN   func[]
	TOKEN   temp[]
	SHARED  TOKEN  prog[]
	SHARED  funcBPAltered[],  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  editFunction,  xitGrid
'
	IF (editFunction > UBOUND(funcCursorPosition[])) THEN
		PRINT "RestoreTextToProg():invalid editFunction", editFunction, UBOUND(funcCursorPosition[])
	END IF
'
'	Always reset current cursor location, top character (prep for changing text)
'
	XuiSendMessage (xitGrid, #GetTextCursor, @cursorPos, @cursorLine, @topIndent, @topLine, $$xitTextLower, 0)
	XuiSendMessage (xitGrid, #GetCursorXY, @xCursor, @yCursor, 0, 0, $$xitTextLower, 0)
	funcCursorPosition[editFunction, 0] = cursorLine
	funcCursorPosition[editFunction, 1] = cursorPos
	funcCursorPosition[editFunction, 2] = topLine
	funcCursorPosition[editFunction, 3] = topIndent
	funcCursorPosition[editFunction, 4] = xCursor
	funcCursorPosition[editFunction, 5] = yCursor
'
	IFZ funcNeedsTokenizing[editFunction] THEN			' No text changes
		IFZ funcBPAltered[editFunction] THEN RETURN		' No BP changes
'
'		Update BP list
'
		IFZ prog[editFunction,] THEN RETURN									' Nothing to do
		XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
		IFZ text$[] THEN RETURN
'
		ATTACH prog[editFunction,] TO func[]
		ufunc = UBOUND(func[])
		IF (ufunc != UBOUND(text$[])) THEN
			Message ("[RestoreTextToProgram( )]\n Internal error \n\n editFunction not in sync with prog ")
			RETURN
		END IF
		FOR line = 0 TO ufunc
			IFZ text$[line] THEN
				func[line,0].ti.bpexe = $$BPEXECLR
				DO NEXT
			END IF
'
			cchar = text$[line]{0}
			SELECT CASE TRUE
				CASE (cchar = '>')															' >?
					IF (LEN(text$[line]) < 2) THEN
						func[line,0].ti.bpexe = $$BPEXECLR
						func[line,0].ti.errno = 0
						DO NEXT
					END IF
					cchar = text$[line]{1}
'
				CASE (('0' <= cchar) AND (cchar <= '9'))				' errorCode?
					IF (LEN(text$[line]) < 4) THEN
						func[line,0].ti.bpexe = $$BPEXECLR
						func[line,0].ti.errno = 0
						DO NEXT
					END IF
					cchar = text$[line]{3}
			END SELECT
'
			IF (cchar = ':') THEN
				func[line,0].ti.bpexe = func[line,0].ti.bpexe OR $$BP     ' Set BP bit
			ELSE
				func[line,0].ti.bpexe = func[line,0].ti.bpexe AND $$EXE   ' Clear BP bit
			END IF
		NEXT line
'
		ATTACH func[] TO prog[editFunction,]
		XuiSendMessage (xitGrid, #SetTextArray, cursorPos, cursorLine, topIndent, topLine, $$xitTextLower, @text$[])
		funcBPAltered[editFunction] = $$FALSE
		RETURN
	END IF
'
'
' Function needs tokenizing
'
	XuiSendMessage (xitGrid, #GetTextArray, 0, 0, 0, 0, $$xitTextLower, @text$[])
	IFZ TextHasNonWhites ($$TextArray, @text$[]) THEN			' fix empty
		DefaultFunctionText (editFunction, @text$[])
	END IF
	freeze = $$TRUE
	bogusFunction = TextToTokenArray (@text$[], @func[], editFunction, freeze)
	ATTACH prog[editFunction,] TO temp[]						' out with the old...
	ATTACH func[] TO prog[editFunction,]						'   ...in with the new
	TokenArrayToText (editFunction, @text$[])				' sync text with tokens
	XuiSendMessage (xitGrid, #SetTextArray, cursorPos, cursorLine, topIndent, topLine, $$xitTextLower, @text$[])
	IF redisplay THEN
		XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
	END IF
	funcBPAltered[editFunction] = $$FALSE
	funcNeedsTokenizing[editFunction] = $$FALSE
	IF (bogusFunction AND reportBogusRename) THEN
		XxxFunctionName ($$XGET, @funcName$, editFunction)
		Message ("[RestoreTextToProgram( )]\n Function not renamed \n\n try ViewRenameFunction " + funcName$ + " ")
	END IF
'
END FUNCTION
'
'
' #################################
' #####  SetCurrentStatus ()  #####
' #################################
'
FUNCTION  SetCurrentStatus (status, line)
	EXTERNAL /xxx/ errorCount, library
	SHARED  xitGrid
	SHARED  currentStatus
	STATIC  currentErrorCount
'
	IF (errorCount != currentErrorCount) THEN
		newError = $$TRUE
		IFZ errorCount THEN
			error$ = " status/errors "
			UpdateErrors (0, 0)
		ELSE
			error$ = "errors: " + RJUST$(STRING(errorCount), 7)
		END IF
		XuiSendMessage (xitGrid, #SetTextString, 0, 0, 0, 0, $$xitErrorLabel, @error$)
		XuiSendMessage (xitGrid, #RedrawGrid, 0, 0, 0, 0, $$xitErrorLabel, 0)
		currentErrorCount = errorCount
	END IF
'
	newStatus = $$TRUE
	IFZ line THEN
		IF (status = currentStatus) THEN newStatus = $$FALSE
	END IF
'
	IFZ (newError OR newStatus) THEN RETURN
	IFZ newStatus THEN GOTO ShowChanges
'
	currentStatus = status
	SELECT CASE currentStatus
		CASE  $$StatusAssembling	: IF library THEN
																	status$ = "compile lib"
																ELSE
																	status$ = "compile asm"
																END IF
		CASE $$StatusCompiled			: status$ = "compiled   "
		CASE $$StatusCompiling		: status$ = "compiling"
		CASE $$StatusDecoding			: status$ = "decoding   "
		CASE $$StatusDeparsing		: status$ = "deparsing"
		CASE $$StatusEditing      : status$ = "editing    "
		CASE $$StatusFormatting		: status$ = "formatting "
		CASE $$StatusInitializing	: status$ = "initializing"
		CASE $$StatusInline				: status$ = "waiting INLINE$()"
		CASE $$StatusLoading			: status$ = "loading    "
		CASE $$StatusParsing			: status$ = "parsing"
		CASE $$StatusPaused				: status$ = "paused     "
		CASE $$StatusQuitting			: status$ = "quitting   "
		CASE $$StatusRecompiling	: status$ = "recompiling"
		CASE $$StatusRunning			: status$ = "running    "
		CASE $$StatusSaving				: status$ = "saving     "
		CASE $$StatusSearching		: status$ = "searching  "
		CASE $$StatusText         : status$ = "text       "
		CASE ELSE									: status$ = " "
	END SELECT
'
'	Parsing, Deparsing, Compiling, Recompiling, Assembling, Decoding:  add line
'
	IF line THEN
		SELECT CASE currentStatus
			CASE $$StatusDecoding,  $$StatusFormatting,  $$StatusSearching
				IF (line < 10000) THEN
					status$ = status$ + RJUST$(STRING(line), 4)
					GOTO ShowStatus
				END IF
		END SELECT
'
		SELECT CASE TRUE
			CASE (line < 1000000)
				line = line >> 10																		' divide by 1K
				status$ = status$ + RJUST$(STRING$(line), 3) + "K"
			CASE ELSE:
				line = line >> 20																		' divide by 1M
				status$ = status$ + RJUST$(STRING$(line), 3) + "M"
		END SELECT
	END IF
'
ShowStatus:
	XuiSendMessage (xitGrid, #SetTextString, 0, 0, 0, 0, $$xitStatusLabel, @status$)
	XuiSendMessage (xitGrid, #RedrawGrid, 0, 0, 0, 0, $$xitStatusLabel, 0)
'
ShowChanges:
	ClearMessageQueue ()
END FUNCTION
'
'
' ##########################
' #####  SetCursor ()  #####
' ##########################
'
'	Change the cursor in each Xit widget
'
'	In:				cursorID			new X-Windows cursor ID
'	Out:			none					arg unchanged
'	Return:		none
'
FUNCTION  SetCursor (cursorID)
	SHARED  popupGrids[]
	SHARED  currentCursor
'
	IF (cursorID = currentCursor) THEN RETURN
	currentCursor = cursorID
'
	FOR i = 0 TO UBOUND(popupGrids[])
		grid = popupGrids[i]
		IF grid THEN
			XgrGetGridWindow (grid, @window)			' xxx
'			XgrSetWindowCursor (window, cursor)		' xxx
		END IF
	NEXT i
END FUNCTION
'
'
' ################################
' #####  SetDataDisplays ()  #####
' ################################
'
' Frames updated elsewhere
'
FUNCTION  SetDataDisplays ()
	SHARED  assemblyBox,  registerBox
'
	justUpdate = $$TRUE
	DebugAssembly (assemblyBox, #DisplayWindow, justUpdate, 0, 0, 0, 0, 0)
	DebugRegisters (registerBox, #DisplayWindow, justUpdate, 0, 0, 0, 0, 0)
	XstGetConsoleGrid (@consoleGrid)
	XuiSendMessage (consoleGrid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
'
END FUNCTION
'
'
' #################################
' #####  SetEntryFunction ()  #####
' #################################
'
FUNCTION  SetEntryFunction ()
	EXTERNAL /xxx/  entryFunction
	TOKEN   func[]
	TOKEN   tok[]
	TOKEN   token
	TOKEN   t1
	SHARED  TOKEN  prog[]
'
	entryFunction = 0
	IFZ prog[] THEN RETURN
	IFZ prog[0,] THEN RETURN
	ATTACH prog[0,] TO func[]
	FOR line = 0 TO UBOUND(func[])
		ATTACH func[line,] TO tok[]
		IFZ tok[] THEN GOTO nextLine
		toks = tok[0].ti.ndex
		IF (toks < 2) THEN GOTO nextLine
		tokPtr = 1
		IFZ NextXitToken(@tok[], @tokPtr, toks, @t1) THEN GOTO nextLine
		SELECT CASE TRUE
			CASE TokenMatch (@t1, @#T_DECLARE), TokenMatch (@t1, @#T_EXTERNAL), TokenMatch (@t1, @#T_INTERNAL)
				IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN GOTO nextLine
				SELECT CASE TRUE
					CASE  TokenMatch (@token, @#T_FUNCTION), TokenMatch (@token, @#T_CFUNCTION), TokenMatch (@token, @#T_SFUNCTION)
					CASE  ELSE:			GOTO nextLine
				END SELECT
				DO UNTIL (tokPtr > toks)
					token = tok[tokPtr]
					IF (token.tp.kind = $$KIND_FUNCTIONS) THEN
						entryFunction = token.tindex
						ATTACH tok[] TO func[line,]
						EXIT FOR
					END IF
					INC tokPtr
				LOOP
		END SELECT
nextLine:
		ATTACH tok[] TO func[line,]
	NEXT line
	ATTACH func[] TO prog[0,]
END FUNCTION
'
'
' ##############################
' #####  SetExeLinePtr ()  #####
' ##############################
'
FUNCTION  SetExeLinePtr ()
	TOKEN   func[]
	SHARED  TOKEN  prog[]
	SHARED  exeFunction,  exeLine,  xitGrid,  editFunction
'
	IFZ exeFunction THEN RETURN
	IFZ prog[exeFunction,] THEN RETURN
'
	ATTACH prog[exeFunction,] TO func[]
	IF (exeLine <= UBOUND(func[])) THEN
'
		SELECT CASE func[exeLine, 0].ti.bpexe
			CASE $$BPEXECLR : func[exeLine, 0].ti.bpexe = $$EXE
												exeChanged = $$TRUE                     ' set ">"
			CASE $$BP       : func[exeLine, 0].ti.bpexe = $$BPEXE
												exeChanged = $$TRUE                     ' set ">"
			CASE $$EXE      :
			CASE $$BPEXE    :
			CASE ELSE       : PRINT "SetExeLinePtr():Invalid .ti.bpexe", func[exeLine, 0].ti.bpexe
		END SELECT
		IF exeChanged THEN
			IF (exeFunction = editFunction) THEN
				XuiSendMessage (xitGrid, #TextReplace, 0, exeLine, 0, exeLine, $$xitTextLower, @">")
				XuiSendMessage (xitGrid, #RedrawText, 0, 0, 0, 0, $$xitTextLower, 0)
			END IF
		END IF
	END IF
'
	ATTACH func[] TO prog[exeFunction,]
END FUNCTION
'
'
' ##################################
' #####  SortFunctionNames ()  #####
' ##################################
'
'	return number of function names in name$[]
'	PROLOG is always first, Entry() is always second,
' the rest are in alphabetic order
'
FUNCTION  SortFunctionNames (name$[], includePROLOG)
	EXTERNAL /xxx/  maxFuncNumber,  entryFunction
	SHARED  TOKEN  prog[]
'
	DIM name$[maxFuncNumber]
	IF includePROLOG THEN
		name$[0] = "PROLOG"
		IFZ maxFuncNumber THEN
			REDIM name$[0]
			RETURN (1)
		END IF
		item = 1															' PROLOG is #1
		startSortItem = 2
	ELSE
		IFZ maxFuncNumber THEN
			DIM name$[]
			RETURN (0)
		END IF
		item = 0
		startSortItem = 1
	END IF
'
	IF entryFunction THEN										' Entry function is first
		IF prog[entryFunction,] THEN					' (only if it is defined)
			XxxFunctionName ($$XGET, @funcName$, entryFunction)
			IF funcName$ THEN
				ATTACH funcName$ TO name$[item]
				INC item
				INC startSortItem
			END IF
		END IF
	END IF
'
	XxxPassFunctionArrays ($$XGET, @funcSymbol$[], @funcToken[], @funcScope[])
	func = 1																' skip PROLOG
	DO UNTIL (func > maxFuncNumber)
		IFZ prog[func,] THEN INC func: DO DO
		IF (func = entryFunction) THEN INC func: DO DO
		name$[item] = funcSymbol$[func]
		INC func
		INC item
	LOOP
	XxxPassFunctionArrays ($$XSET, @funcSymbol$[], @funcToken[], @funcScope[])
	IFZ item THEN
		DIM name$[]
		RETURN (0)
	END IF
	lastItem = item - 1
	REDIM name$[lastItem]
	IF (item > startSortItem) THEN							' sort by index
		XstQuickSort (@name$[], @null[],  startSortItem - 1, lastItem, $$SortIncreasing OR $$SortCaseInsensitive OR $$SortAlphaNumeric)
	END IF
	RETURN (item)
END FUNCTION
'
'
' #################################
' #####  TextHasNonWhites ()  #####
' #################################
'
FUNCTION  TextHasNonWhites (mode, (text$, text$[]))
	SHARED  UBYTE charsetNonWhiteChar[]
'
	IF (mode = $$TextString) THEN
		IFZ text$ THEN RETURN (0)
		FOR i = 0 TO UBOUND(text$)
			cchar = text${i}
			IF charsetNonWhiteChar[cchar] THEN RETURN (cchar)
		NEXT i
'
	ELSE
		IFZ text$[] THEN RETURN (0)
		FOR line = 0 TO UBOUND(text$[])
			IFZ text$[line] THEN DO NEXT
			ATTACH text$[line] TO a$
			FOR i = 0 TO UBOUND(a$)
				cchar = a${i}
				IF charsetNonWhiteChar[cchar] THEN
'					PRINT "TextHasNonWhites(25)", i, a$
					ATTACH a$ TO text$[line]
					RETURN (cchar)
				END IF
			NEXT i
			ATTACH a$ TO text$[line]
		NEXT line
	END IF
'
	RETURN (0)
END FUNCTION
'
'
' #################################
' #####  TextToTokenArray ()  #####
' #################################
'
' TextToTokenArray (text$[], func[], funcNumber, freeze)
'   - Converts a source text array for an function into an irregular
'				array of tokens.
'   - "freeze" instructs compiler not to allow function renames.
'		- Removes trailing newlines and RTRIMs each line.
'   - If not PROLOG
'				- removes currentexe from func[]
'				- forces END FUNCTION to end of func[]
'   - If PROLOG
'				- removes BP/currentexe from func[]
'				- sets entryFunction:
'						- First function DECLAREd in PROLOG
'								(may or may not exist in code yet)
'						- Entry function cannot be INTERNAL or EXTERNAL
'
'	text$[] is returned MODIFIED to be identical with func[]
'
'	Return $$TRUE if bogus function rename was attempted
'
FUNCTION  TextToTokenArray (text$[], TOKEN func[], funcNumber, freeze)
	EXTERNAL /xxx/  bogusFunction,  freezeFlag,  freezeFunction,  entryFunction
	EXTERNAL /xxx/  maxFuncNumber
	TOKEN   blankTok[]
	TOKEN   endFunctionTok[]
	TOKEN   token
	TOKEN   tok[]
	SHARED  UBYTE charsetNonWhiteChar[]
	SHARED  TOKEN  prog[]
	SHARED  funcAltered[]
	SHARED  funcBPAltered[]
	SHARED  funcNeedsTokenizing[],  funcCursorPosition[]
	SHARED  uprog
	SHARED  currentCursor
'
	IFZ text$[] THEN
		DIM func[]
		RETURN (freeze)										' empty and 'freeze' = 'renamed'
	END IF
'
	entryCursor = currentCursor
'	SetCursor ($$CursorWait)
'
	IF freeze THEN
		bogusFunction = $$FALSE						' Don't allow rename
		freezeFlag = $$TRUE
		freezeFunction = funcNumber
	ELSE
		freezeFlag = $$FALSE
	END IF
'
	IFZ funcNumber THEN
		entryFunction = 0
		XxxInitParse ()										' Reset got.function for PROLOG
	END IF
	nullText = $$TRUE
'
	uText = UBOUND(text$[])
	tLine = 0
	uLine = uText
	DIM func[uLine,]
	DIM newText$[uLine]
'
	FOR i = 0 TO uText
		SWAP text$[i], text$
		IF text$ THEN															' quick RTRIM non-printables
			IFZ charsetNonWhiteChar[text${UBOUND(text$)}] THEN
				j = UBOUND(text$)
				DO
					DEC j
					IF (j < 0) THEN EXIT DO
				LOOP UNTIL charsetNonWhiteChar[text${j}]
				IF (j < 0) THEN
					text$ = ""
				ELSE
					text${j + 1} = 0										' null terminates
					xAddr = &text$											' Ahem...
					XLONGAT (xAddr, -16) = j + 1        'string length
				END IF
			END IF
		END IF
'
		IFZ text$ THEN
			INC blankLines
			DO NEXT
		END IF
		nullText = $$FALSE
'
		DO UNTIL (blankLines = 0)
			XxxParseSourceLine ("\n", @blankTok[])
			IF (tLine > uLine) THEN
				uLine = (uLine + (uLine >> 1)) OR 7
				REDIM func[uLine,]
				REDIM newText$[uLine]
			END IF
			ATTACH blankTok[] TO func[tLine,]				' newText$[] already empty
			INC tLine
			DEC blankLines
		LOOP
'
		XxxParseSourceLine (text$, @tok[])
		IF (tLine > uLine) THEN
			uLine = uLine + (uLine >> 1)
			REDIM func[uLine,]
			REDIM newText$[uLine]
		END IF
'
		IFZ tok[] THEN PRINT "tok[] empty!" : GOTO NextLine
'
		IFZ funcNumber THEN
			tok[0].ti.bpexe = $$BPEXECLR                ' clear both BP and EXE in PROLOG
		ELSE
			tok[0].ti.bpexe = tok[0].ti.bpexe AND $$BP  ' clear EXE in functions
		END IF
		IFZ tok[0].tproto THEN PRINT "TextToTokenArray(121)"
		XxxDeparser (@tok[], @text$)
		toks = tok[0].ti.ndex
'
		IF (toks <= 1) THEN GOTO NextLine
		tokPtr = 1
		IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN GOTO NextLine
		IFZ funcNumber THEN										' PROLOG:  set entryFunction
			IF entryFunction THEN GOTO NextLine
			IF (TokenMatch (@token, @#T_DECLARE) OR TokenMatch (@token, @#T_INTERNAL)) THEN
				IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN GOTO NextLine
				SELECT CASE TRUE
					CASE  TokenMatch (@token, @#T_FUNCTION), TokenMatch (@token, @#T_CFUNCTION), TokenMatch (@token, @#T_SFUNCTION)
					CASE  ELSE:			GOTO NextLine
				END SELECT
				DO
					IFZ NextXitToken(@tok[], @tokPtr, toks, @token) THEN GOTO NextLine
					IF (token.tp.kind = $$KIND_FUNCTIONS) THEN
						entryFunction = token.tindex
						EXIT DO
					END IF
				LOOP
			END IF
		ELSE																	' Not PROLOG:  END FUNCTION?
			IF TokenMatch (@token, @#T_END) THEN
				IF NextXitToken(@tok[], @tokPtr, toks, @token) THEN
					SELECT CASE TRUE
						CASE  TokenMatch (@token, @#T_FUNCTION), TokenMatch (@token, @#T_CFUNCTION), TokenMatch (@token, @#T_SFUNCTION)
							DIM endFunctionTok[]				' Save END FUNCTION for later
							ATTACH tok[] TO endFunctionTok[]
							DO NEXT
					END SELECT
				END IF
			END IF
		END IF
'
NextLine:
		ATTACH tok[] TO func[tLine,]
		ATTACH text$ TO newText$[tLine]
		INC tLine
	NEXT i
'
	IF (maxFuncNumber > uprog) THEN
		uprog = maxFuncNumber + (maxFuncNumber >> 2)
		REDIM prog[uprog,]
		REDIM funcAltered[uprog]
		REDIM funcBPAltered[uprog]
		REDIM funcNeedsTokenizing[uprog]
		REDIM funcCursorPosition[uprog, 5]
	END IF
'
	bogus = bogusFunction
	IF freeze THEN
		bogusFunction = $$FALSE
		freezeFlag = $$FALSE
		freezeFunction = 0
	END IF
'
	IF nullText THEN
		DIM func[]
		DIM text$[]
'		SetCursor (entryCursor)
		RETURN (bogus)
	END IF
'
	IF funcNumber THEN												' non-PROLOG needs END FUNCTION
		IF (tLine > uLine) THEN
			uLine = uLine + 1
			REDIM func[uLine,]
		END IF
		IFZ endFunctionTok[] THEN
			DIM endFunctionTok[3]									' last token must be null
			endFunctionTok[0] = #T_STARTS
			endFunctionTok[0].tindex = 3
			endFunctionTok[1] = #T_END
			endFunctionTok[1].tp.stsp = 1
			endFunctionTok[2] = #T_FUNCTION
		END IF
		XxxDeparser (@endFunctionTok[], @text$)
		ATTACH endFunctionTok[] TO func[tLine,]
		ATTACH text$ TO newText$[tLine]
		IF (tLine < uLine) THEN
			REDIM func[tLine,]
			REDIM newText$[tLine]
		END IF
	ELSE
		IF ((tLine - 1) < uLine) THEN
			REDIM func[tLine-1,]
			REDIM newText$[tLine-1]
		END IF
	END IF
	SWAP newText$[], text$[]
'
'	SetCursor (entryCursor)
	RETURN (bogus)
END FUNCTION
'
'
' #################################
' #####  TokenArrayToText ()  #####
' #################################
'
'	Convert token array to text array
'		Does not remove blank lines
'		Does not test for excess END FUNCTIONS (done in TextToTokenArray())
'
FUNCTION  TokenArrayToText (funcNumber, text$[])
	TOKEN   func[]
	TOKEN   tok[]
	SHARED  TOKEN  prog[]
	SHARED  programAltered,  exeFunction,  exeLine
'
	IFZ prog[funcNumber,] THEN
		DIM text$[]
		RETURN
	END IF
'
'	entryCursor = currentCursor
'	SetCursor ($$CursorWait)
'
	ATTACH prog[funcNumber,] TO func[]
	uLine = UBOUND(func[])
	DIM text$[uLine]
	FOR line = 0 TO uLine
		ATTACH func[line,] TO tok[]
		IFZ tok[] THEN DO NEXT                               ' empty line
		IFZ funcNumber THEN
			tok[0].ti.bpexe = $$BPEXECLR                       ' strip BP/EXE from token line
		ELSE
			tok[0].ti.bpexe = tok[0].ti.bpexe AND $$BP         ' Clear $$EXE
			IF (exeLine = line) THEN
				IF (exeFunction = funcNumber) THEN
					IF ##USERRUNNING THEN
						IFZ programAltered THEN
							tok[0].ti.bpexe = tok[0].ti.bpexe OR $$EXE ' set currentexe
						END IF
					END IF
				END IF
			END IF
		END IF
'
		XxxDeparser(@tok[], @lineText$)
		ATTACH lineText$ TO text$[line]
		ATTACH tok[] TO func[line,]
	NEXT line
'
	ATTACH func[] TO prog[funcNumber,]
'
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
' #####################################
' #####  UpdateFileFuncLabels ()  #####
' #####################################
'
FUNCTION  UpdateFileFuncLabels (updateFile, updateFunc)
	SHARED  editFile$,  editFunction,  fileType,  textAlteredSinceSave
	SHARED  mainTitle$
	SHARED  xitGrid
	SHARED  xitFileList, recentFile$[]
	SHARED  recentFunc$[]
	SHARED  CURSORLOCATION recentCursor[]
	SHARED  editFileIsReadOnly
'
	IF updateFile THEN
		part = RINSTR (editFile$, $$PathSlash$)
		IF part THEN
			fileName$ = MID$(editFile$, part + 1)
		ELSE
			fileName$ = editFile$
		END IF
		IFZ fileName$ THEN
			fileName$ = "no_file_name"
		END IF
'
' the following code segment is inappropriate because the
' currently displayed function is already mentioned on the function drop button
'
'
		partT = RINSTR (editFile$, $$PathSlash$, part-1)
		IF partT THEN
			partT2 = RINSTR (editFile$, $$PathSlash$, partT-1)
			IF partT2 THEN partT = partT2
			partT3 = RINSTR (editFile$, $$PathSlash$, partT-1)
			IF partT3 THEN partT = partT3
			title$ = MID$(editFile$, partT + 1) + "  -  " + mainTitle$
		ELSE
			title$ = fileName$ + "  -  " + mainTitle$
		END IF
		IF editFileIsReadOnly THEN title$ = "(Read Only)..." + title$
		XuiSetWindowTitle (xitGrid, #SetWindowTitle, 0, 0, 0, 0, 0, @title$)
'
		IF textAlteredSinceSave THEN
			lenName = LEN (fileName$)
			fileName$ = fileName$ + " *"
		END IF
		XuiSendMessage (xitGrid, #GetTextString, 0, 0, 0, 0, $$xitFileLabel, @oldFilename$)
		IF (fileName$ != oldFilename$) THEN
			XuiSendMessage (xitGrid, #SetTextString, 0, 0, 0, 0, $$xitFileLabel, @fileName$)
			XuiSendMessage (xitGrid, #RedrawGrid, 0, 0, 0, 0, $$xitFileLabel, 0)
		END IF
'
		IF editFile$ THEN
			uRecent = UBOUND (recentFile$[])
			IF (uRecent < $$RecentUpper) THEN
				uRecent = uRecent + 1
				REDIM recentFile$[uRecent]
				REDIM recentFunc$[uRecent]
				REDIM recentCursor[uRecent]
			END IF
			FOR i = 0 TO uRecent
				IF (recentFile$[i] == editFile$) THEN EXIT FOR
			NEXT i
			IF (i > uRecent) THEN i = uRecent
			FOR j = (i-1) TO 0 STEP -1
				recentFile$[j+1] = recentFile$[j]
				recentFunc$[j+1] = recentFunc$[j]
				recentCursor[j+1]  = recentCursor[j]
			NEXT j
			recentFile$[0] = editFile$
			XuiSendMessage (xitFileList, #SetTextArray, 0, 0, 0, 0, 0, @recentFile$[])
		END IF
		XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitFileLabel, "filename: " + editFile$)
		XuiSendMessage (xitGrid, #SetHintString, 0, 0, 0, 0, $$xitHotSave, "Save file: " + editFile$)
	END IF
'
	IF updateFunc THEN
		IF (fileType = $$Text) THEN
			funcName$ = "text"
		ELSE
			XxxFunctionName ($$XGET, @funcName$, editFunction)
			IFZ funcName$ THEN
				funcName$ = "no_func_name"
			ELSE
				funcName$ = "(" + STRING$(editFunction) + ") " + funcName$
				IF editFile$ THEN recentFunc$[0] = funcName$
			END IF
		END IF
		XuiSendMessage (xitGrid, #GetTextString, 0, 0, 0, 0, $$xitFunction, @oldFuncName$)
		IF (funcName$ != oldFuncName$) THEN
			XuiSendMessage (xitGrid, #SetTextString, 0, 0, 0, 0, $$xitFunction, @funcName$)
			XuiSendMessage (xitGrid, #Redraw, 0, 0, 0, 0, $$xitFunction, 0)
		END IF
	END IF
END FUNCTION
'
'
' ####################################
' #####  VariableTypeToValue ()  #####
' ####################################
'
' VariableTypeToValue (tt, sizeExact, wordAddr, @hexValue$, @value$)
'
' hexValue$ should have a value on entry, but will be altered with some types.
'
FUNCTION  VariableTypeToValue (tt, sizeExact, wordAddr, hexValue$, value$)
	STATIC SUBADDR sub[]
'
	$FuncInternal = 0x01
'
'	PRINT "VariableTypeToValue(16)"
	IF value$ THEN value$ = ""
	IFZ sub[] THEN GOSUB InitSubTable
	IF (tt <= 20) THEN
		GOSUB @sub[tt]
	ELSE
		hexValue$ = "                 "
		value$ = " <composite>"
	END IF
	RETURN
'
'-------------------------------------------
'
' *****  SByte  *****
'
SUB SByte
	IF sizeExact THEN
		word1 = SBYTEAT(wordAddr)
		hexValue$ = " " + HEX$(UBYTEAT(wordAddr), 2) + "              "
		value$ = STR$(word1)
	ELSE
		GOSUB SLong
	END IF
END SUB
'
'
' *****  UByte  *****
'
SUB UByte
	IF sizeExact THEN
		word1 = UBYTEAT(wordAddr)
		hexValue$ = " " + HEX$(word1, 2) + "              "
		value$ = STR$(word1)
	ELSE
		GOSUB ULong
	END IF
END SUB
'
'
' *****  SShort  *****
'
SUB SShort
	IF sizeExact THEN
		word1 = SSHORTAT(wordAddr)
		hexValue$ = " " + HEX$(USHORTAT(wordAddr), 4) + "            "
		value$ = STR$(word1)
	ELSE
		GOSUB SLong
	END IF
END SUB
'
'
' *****  UShort  *****
'
SUB UShort
	IF sizeExact THEN
		word1 = USHORTAT(wordAddr)
		hexValue$ = " " + HEX$(word1, 4) + "            "
		value$ = STR$(word1)
	ELSE
		GOSUB ULong
	END IF
END SUB
'
'
' *****  SLong  *****
'
SUB SLong
	word1 = SLONGAT(wordAddr)
'	hexValue$ = " " + HEX$(word1, 8) + "        "
	hexValue$	= " " + HEX$(value$$,16)              '*cw* 230306+
	value$ = STR$(SLONG(word1))
END SUB
'
'
' *****  ULong  *****
'
SUB ULong
	word1 = ULONGAT(wordAddr)
	hexValue$ = " " + HEX$(word1, 8) + "        "
	value$ = STR$(ULONG(word1))
END SUB
'
'
' *****  XLong  *****
'
SUB XLong
	word1 = XLONGAT(wordAddr)
'	hexValue$ = " " + HEX$(word1, 8) + "        "
	hexValue$	= " " + HEX$(word1,16)              '*cw* 230306+
	value$ = STR$(word1)
END SUB
'
'
' *****  GoAddr  *****
'
SUB GoAddr					' _g_<user's GOTO label>_<func#>
	word1 = XLONGAT(wordAddr)
	IFZ word1 THEN
'		hexValue$ = " " + HEX$(word1, 8) + "        "
		hexValue$	= " " + HEX$(word1,16)              '*cw* 230306+
		value$ = " <undefined>"
		EXIT SUB
	END IF
'	hexValue$ = "@" + HEX$(word1, 8) + "        "
	hexValue$	= " " + HEX$(word1,16)              '*cw* 230306+
	labels = XxxGetLabelGivenAddress (word1, @labels$[])
	FOR j = 0 TO (labels - 1)
		label$ = labels$[j]
		IF (LEFT$(label$, 3) = "_g_") THEN
			label$ = MID$(label$, 4)
			decor = RINSTR (label$, "_")
			IF decor THEN label$ = LEFT$(label$, decor - 1)
			IFZ j THEN
				value$ = " &" + label$ + ":"
			ELSE
				value$ = value$ + ", &" + label$ + ":"
			END IF
		END IF
	NEXT j
	IFZ value$ THEN value$ = " <undetermined> "
END SUB
'
'
' *****  SubAddr  *****
'
SUB SubAddr					' _s_<user's SUB label>_<func#>
	word1 = XLONGAT(wordAddr)
	IFZ word1 THEN
		hexValue$ = " " + HEX$(word1, 8) + "        "
		hexValue$	= " " + HEX$(word1,16)              '*cw* 230306+
		value$ = " <undefined>"
		EXIT SUB
	END IF
	hexValue$ = "@" + HEX$(word1, 8) + "        "
	labels = XxxGetLabelGivenAddress (word1, @labels$[])
	FOR j = 0 TO (labels - 1)
		label$ = labels$[j]
		IF (LEFT$(label$, 3) = "_s_") THEN
			label$ = MID$(label$, 4)
			decor = RINSTR(label$, "_")
			IF decor THEN label$ = LEFT$(label$, decor - 1)
			IFZ j THEN
				value$ = " SUB " + label$
			ELSE
				value$ = value$ + ", SUB " + label$
			END IF
		END IF
	NEXT j
	IFZ value$ THEN value$ = " <undetermined> "
END SUB
'
'
' *****  FuncAddr  *****
'
SUB FuncAddr
	word1 = XLONGAT(wordAddr)
	IFZ word1 THEN
'		hexValue$ = " " + HEX$(word1, 8) + "        "
		hexValue$	= " " + HEX$(word1,16)              '*cw* 230306+
		value$ = " <undefined>"
		EXIT SUB
	END IF
	hexValue$ = "@" + HEX$(word1, 8) + "        "
	labels = XxxGetLabelGivenAddress (word1, @labels$[])
'	IF labels THEN
'		IF ##XBDV THEN PRINT "VariableTypeToValue(181):FuncAddr", HEXX$(word1), labels$[0]
'	END IF
	FOR j = 0 TO (labels - 1)
		label$ = labels$[j]
		decor = RINSTR(label$, "_")
		uLabel = UBOUND(label$)
		IF ((decor == uLabel) || (decor == uLabel-1)) THEN
			char = label${uLabel}
			IF (char < '0') AND (char > '9') THEN decor = 0
			IF (decor == uLabel-1) THEN
				char = label${uLabel-1}
				IF (char < '1') AND (char > '6') THEN decor = 0
			END IF
		ELSE
			decor = 0
		END IF
		IF decor THEN
			function$ = LEFT$(label$, decor-1)
		ELSE
			function$ = label$
			IF (LEFT$(label$, 4)  == "func") THEN
				funcNumber = XLONG(LCLIP$(label$, 4))
				IF funcNumber THEN
					XxxPassFunctionArrays ($$XGET, @funcSymbol$[], @funcToken[], @funcScope[])
					IF (funcNumber <= (UBOUND(funcScope[]))) THEN
						IF (funcScope[funcNumber] == $FuncInternal) THEN
							function$ = funcSymbol$[funcNumber]
						END IF
					END IF
					XxxPassFunctionArrays ($$XSET, @funcSymbol$[], @funcToken[], @funcScope[])
				END IF
			END IF
		END IF
		IF function$ THEN
			IFZ j THEN
				value$ = " &" + function$ + "()"
			ELSE
				value$ = value$ + ", &" + function$ + "()"
			END IF
		END IF
	NEXT j
	IFZ value$ THEN value$ = " <undetermined> "
END SUB
'
'
' *****  Giant  *****
'
SUB Giant
	value$$   = GIANTAT(wordAddr)
	value$		= STR$(value$$)
	hexValue$	= " " + HEX$(value$$,16)
END SUB
'
'
' *****  Single  *****
'
SUB Single
	word1 = XLONGAT(wordAddr)
	value! = SMAKE(word1)
	value$ = STR$(value!)
	hexValue$ = " " + HEX$(word1, 8) + "        "
END SUB
'
'
' *****  Double  *****
'
SUB Double
	word1 = XLONGAT(wordAddr)
	value# = DOUBLEAT(wordAddr)
	hexValue$ = " " + HEX$(word1,16)
	value$ = " " + STRING(value#)
	END SUB
'
'
' *****  String  *****
'
SUB String
	word1 = XLONGAT(wordAddr)
'	PRINT "VariableTypeToValue(258)", HEXX$(wordAddr), HEXX$(word1)
	addrOK = $$FALSE
	IF AddressOk (word1) THEN
		IFZ (word1 AND 3) THEN
			infoWord = XLONGAT (word1, -12)
			IF (infoWord < 0) THEN
				addrOK = $$TRUE
			ELSE
				IF (word1 > ##UCODE) THEN
					IF (word1 < ##UCODEZ) THEN
						infoWord3 = ULONGAT (word1, -8)
						IF(infoWord3 == 0x80130001) THEN addrOK = $$TRUE
					END IF
				END IF
			END IF
		END IF
	END IF
'	PRINT "VariableTypeToValue(275)", HEXX$(infoWord3), HEXX$(addrOK)
	IFZ addrOK THEN
		value$ = " \"\""
	ELSE
		copyString$ = ""								' make a copy of word1 string
		handle = &&copyString$
		XLONGAT (handle) = word1
		value$ = LEFT$(copyString$, 61)
		XLONGAT (handle) = 0								' but don't free word1
		value$ = XstBinStringToBackString$ (@value$)
'		IF (LEN(value$) > 61) THEN
		IF (LEN(value$) > 60) THEN
			value$ = " \"" + LEFT$ (value$, 60) + "\"*"
		ELSE
			value$ = " \"" + value$ + "\""
		END IF
	END IF
	IFZ word1 THEN
		hexValue$ = " EMPTY           "
	ELSE
		hexValue$ = "@" + LJUST$(HEX$(word1, 8), 16)
	END IF
'
END SUB
'
SUB InitSubTable
	DIM sub[19]
'
	FOR i = 0 TO 19
		sub[i] = SUBADDRESS (XLong)
	NEXT i
'
	sub[$$SBYTE]    = SUBADDRESS (SByte)
	sub[$$UBYTE]    = SUBADDRESS (UByte)
	sub[$$SSHORT]   = SUBADDRESS (SShort)
	sub[$$USHORT]   = SUBADDRESS (UShort)
	sub[$$SLONG]    = SUBADDRESS (SLong)
	sub[$$ULONG]    = SUBADDRESS (ULong)
	sub[$$XLONG]    = SUBADDRESS (XLong)
	sub[$$GOADDR]   = SUBADDRESS (GoAddr)
	sub[$$SUBADDR]  = SUBADDRESS (SubAddr)
	sub[$$FUNCADDR] = SUBADDRESS (FuncAddr)
	sub[$$GIANT]    = SUBADDRESS (Giant)
	sub[$$SINGLE]   = SUBADDRESS (Single)
	sub[$$DOUBLE]   = SUBADDRESS (Double)
	sub[$$STRING]   = SUBADDRESS (String)
'
END SUB
'
END FUNCTION
'
'
' ###########################
' #####  HotStepOut ()  #####
' ###########################
'
FUNCTION  HotStepOut ()
	SHARED  userContinue,  userStepType
	SHARED  exitMainLoop,  fileType
'
	IF (fileType != $$Program) THEN
		Message ("[HotStepOut( )]\n No program loaded ")
		EXIT FUNCTION
	END IF
'
	SELECT CASE TRUE
		CASE (##USERRUNNING AND ##SIGNALACTIVE)
				IF GetStepOutFunc() THEN
					userStepType = $$BreakContinueStepOut
				ELSE
					userStepType = $$BreakContinueRunning          ' do Continue in Entry function
				END IF
				userContinue = $$TRUE
				exitMainLoop = $$TRUE
		CASE ##USERRUNNING
				Message ("[HotStepOut( )]\n Program is running ")
		CASE ELSE
				Message ("[HotStepOut( )]\n Program not started ")
	END SELECT
'
END FUNCTION
'
'
' ###############################
' #####  GetStepOutFunc ()  #####
' ###############################
'
' function = GetStepOutFunc ()
'
' Returns the non-recursive calling function
'
FUNCTION  GetStepOutFunc ()
	SHARED  FRAMEINFO  frameInfo[]
'
	u = UBOUND(frameInfo[])                  'last item is the function being run
	DO
		IF (u < 1) THEN RETURN (0)             '
		uFuncNumber = frameInfo[u].funcNumber
		DEC u
		IF(uFuncNumber > 0) THEN EXIT DO       'valid function number
	LOOP
'
	funcNumber = 0
	FOR i = u TO 0 STEP -1
		iFuncNumber = frameInfo[i].funcNumber
		IF (iFuncNumber != uFuncNumber) THEN   'look for non-recursive call
			IF (iFuncNumber > 0) THEN            'valid function number
				funcNumber = iFuncNumber
				EXIT FOR
			END IF
		END IF
	NEXT i
'
	RETURN (funcNumber)
'
END FUNCTION
'
'
' ###################################
' #####  AddFileToBackupDir ()  #####
' ###################################
'
FUNCTION  AddFileToBackupDir (skipUpdate)
	SHARED  editFile$
	SHARED  xbasicBackupDir$
	STATIC  previousFileName$
	STATIC  messageDisplayed
	FILEINFO attrInfo[]
'
	IF skipUpdate THEN
		IF xbasicBackupDir$ THEN
			IF (editFile$ != previousFileName$) THEN
				PRINT "AddFileToBackupDir()Error:FileName Not Updated", editFile$, previousFileName$
				previousFileName$ = editFile$
			END IF
			fileName$ = editFile$
			GOSUB MakeBackup
		END IF
	ELSE
		GOSUB UpdateFileName
	END IF
'
	RETURN
'
' This is called by FileLoad(), FileRecentLoad() and FileTextLoad()
' when a file has been loaded for editing, and by FileSave() when a
' file was saved with a new FileName. If the environment variable
' "XBASICBACKUPDIR64" defines a valid directory, that directory
' is checked to see if backups for this file already exist.
' If not the backup file in the working directory, if it exists,
' is copied into the backup directory as the first backup.
'
SUB UpdateFileName
	IF (editFile$ == previousFileName$) THEN EXIT SUB
	previousFileName$ = editFile$
	IFZ xbasicBackupDir$ THEN
		XstGetEnvironmentVariable ("XBASICBACKUPDIR64", @xbasicBackupDir$)
		IFZ xbasicBackupDir$ THEN EXIT SUB
		XstPathToAbsolutePath (xbasicBackupDir$, @absolutePath$)
		firstChar$ = LEFT$(xbasicBackupDir$)
		IF (xbasicBackupDir$ != absolutePath$) THEN
			IFZ messageDisplayed THEN
				error$ = "[XBASICBACKUPDIR64]\n"
				error$ = error$ + "\nEnvironment variable\nXBASICBACKUPDIR64 \n"
				error$ = error$ + "must be a full absolute path name:\n"
				error$ = error$ + xbasicBackupDir$
				Message (error$)
				messageDisplayed = $$TRUE
			END IF
			xbasicBackupDir$ = ""
			EXIT SUB
		END IF
		XstGetFileAttributes (xbasicBackupDir$, @attributes)
		IFZ (attributes AND $$FileDirectory) THEN
			IFZ messageDisplayed THEN
				error$ = "[XBASICBACKUPDIR64]\n"
				error$ = error$ + "\nEnvironment variable\nXBASICBACKUPDIR64 \n"
				error$ = error$ + "is not a valid directory:\n"
				error$ = error$ + xbasicBackupDir$
				Message (error$)
				messageDisplayed = $$TRUE
			END IF
			xbasicBackupDir$ = ""
			EXIT SUB
		END IF
		lastChar$ = RIGHT$(xbasicBackupDir$)
		IF lastChar$ THEN
			IF (lastChar$ != $$PathSlash$) THEN xbasicBackupDir$ = xbasicBackupDir$ + $$PathSlash$
		END IF
	END IF
	XstGuessFilename (@editFile$, @file$, @fileName$, @attributes)
	XstGetPathComponents (fileName$, @path$, @drive$, @dir$, @progName$, @attributes)
	backup$ = xbasicBackupDir$ + progName$
	filter$ = progName$ + "*"
END SUB
'
'
' *****  MakeBackup  *****
'
SUB MakeBackup
	XstGetPathComponents (fileName$, @path$, @drive$, @dir$, @progName$, @attributes)
	XstGetFilesAndAttributes (fileName$, ($$FileNormal OR $$FileReadOnly), @file$[], @attrInfo[])
	uFiles = UBOUND(file$[])
	IF (uFiles == 0) THEN
		IF (file$[0] == progName$) THEN
			mtime$$ = attrInfo[entry].modifyTime
			XstFileTimeToLocalDateAndTime (mtime$$, @year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
			date$ = "_"   + FORMAT$("0#", year MOD 100)
			date$ = date$ + FORMAT$("0#", month)
			date$ = date$ + FORMAT$("0#", day)
			time$ = "_"   + FORMAT$("0#", hour)
			time$ = time$ + FORMAT$("0#", minute)
			time$ = time$ + FORMAT$("0#", second)
			backup$ = xbasicBackupDir$ + progName$ + date$ + time$ + ".bak"
			XstCopyFile (fileName$, backup$)
'			PRINT "AddFileToBackupDir()MakeBackup", uFiles, fileName$, backup$
		END IF
	END IF
END SUB
'
END FUNCTION
'
'
' ##############################################
' #####  XitSystemExceptionToException ()  #####
' ##############################################
'
FUNCTION  XitSystemExceptionToException (signal, exception)
	SHARED  CPUCONTEXT  cpu
'
	PRINT "XitSystemExceptionToException(10)", signal  ', cpu.trap, HEXX$(##ERROR)
'
	SELECT CASE signal
		CASE $$SIGNONE			: exception = $$ExceptionNone								' no problem
		CASE $$SIGHUP				: exception = $$ExceptionUnknown						' hangup or death of controlling process
		CASE $$SIGINT				: exception = $$ExceptionBreakKey						' interrupt keystroke  (^backspace or ^delete)
		CASE $$SIGQUIT			: exception = $$ExceptionBreakKey						' quit keystroke (if defined and enabled)
		CASE $$SIGILL				: exception = $$ExceptionInvalidInstruction	' invalid instruction
		CASE $$SIGTRAP			: exception = $$ExceptionBreakpoint					' trap / breakpoint
		CASE $$SIGABRT			: exception = $$ExceptionBreakKey						' abort keystroke
		CASE $$SIGIOT				: exception = $$ExceptionBreakKey						' IOT instruction
		CASE $$SIGBUS				: exception = $$ExceptionAlignment					' bus error  (Misaligned or Protection Error)
		CASE $$SIGFPE				: exception = $$ExceptionInvalidOperation		' floating point trap
		CASE $$SIGKILL			: exception = $$ExceptionUnknown						' kill this process
		CASE $$SIGUSR1			: exception = $$ExceptionUnknown						' unknown #1
		CASE $$SIGSEGV			: GOSUB SigSegV
		CASE $$SIGUSR2			: exception = $$ExceptionUnknown						' unknown #2
		CASE $$SIGPIPE			: exception = $$ExceptionInvalidOperation		' write on pipe with noone on other end
		CASE $$SIGALRM			: exception = $$ExceptionTimer							' alarm clock interrupt
		CASE $$SIGTERM			: exception = $$ExceptionUnknown						' termination of process by software
		CASE $$SIGSTKFLT		: exception = $$ExceptionStackOverflow			' new
		CASE $$SIGCHLD			: exception = $$ExceptionUnknown						' child process terminated or stopped
		CASE $$SIGCONT			: exception = $$ExceptionUnknown						' continue stopped process
		CASE $$SIGSTOP			: exception = $$ExceptionUnknown						' sendable stop signal not from tty
		CASE $$SIGTSTP			: exception = $$ExceptionUnknown						' stop signal from tty
		CASE $$SIGTTIN			: exception = $$ExceptionUnknown						' to readers pgrp upon background tty read
		CASE $$SIGTTOU			: exception = $$ExceptionUnknown						' same for output if tp->t_local&TOSTOP
		CASE $$SIGURG				: exception = $$ExceptionUnknown						' new
		CASE $$SIGXCPU			: exception = $$ExceptionUnknown						' new
		CASE $$SIGXFSZ			: exception = $$ExceptionUnknown						' new
		CASE $$SIGVTALRM		: exception = $$ExceptionTimer							' virtual timer alarm
		CASE $$SIGPROF			: exception = $$ExceptionUnknown						' profile alarm
		CASE $$SIGWINCH			: exception = $$ExceptionUnknown						' window configuration change
		CASE $$SIGIO				: exception = $$ExceptionUnknown						' new
		CASE $$SIGPOLL			: exception = $$ExceptionUnknown						' pollable event occured
		CASE $$SIGPWR				: exception = $$ExceptionUnknown						' power failure
		CASE $$SIGUNUSED		: exception = $$ExceptionUnknown						' new
		CASE $$SIGRTMIN			: exception = $$ExceptionUnknown						' new
		CASE $$SIGMAX				: exception = $$ExceptionUnknown						' highest signal number
		CASE ELSE						: exception = $$ExceptionUnknown						' ??? who knows ???
	END SELECT
	RETURN
'
'
'
' *****  SigSegV  *****
'
SUB SigSegV
	exception = $$ExceptionSegmentViolation
	trap$ = ""
	'
	SELECT CASE cpu.trap
		CASE $$TrapDivideError : trap$ = "$$TrapDivideError"  ' Divide error
		CASE $$TrapDebug       : trap$ = "$$TrapDebug"        ' Debug exception
		CASE $$TrapNMI         : trap$ = "$$TrapNMI"          ' Non-maskable interrupt
		CASE $$TrapBreakpoint  : trap$ = "$$TrapBreakpoint"   ' Breakpoint
		CASE $$TrapOverflow    : exception = $$ExceptionOverflow
		CASE $$TrapBounds      : trap$ = "$$TrapBounds"       ' Bounds check
		CASE $$TrapInvalidOp   : trap$ = "$$TrapInvalidOp"    ' Invalid opcode
		CASE $$TrapDevice      : trap$ = "$$TrapDevice"       ' Coprocessor not available
		CASE $$TrapDoubleFault : trap$ = "$$TrapDoubleFault"  ' Double fault
		CASE $$TrapOverrun     : trap$ = "$$TrapOverrun"      ' Coprocessor segment overrun
		CASE $$TrapInvalidTSS  : trap$ = "$$TrapInvalidTSS"   ' Invalid TSS
		CASE $$TrapSegment     : trap$ = "$$TrapSegment"      ' Segment not present
		CASE $$TrapStack       : trap$ = "$$TrapStack"        ' Stack exception
		CASE $$TrapProtection  : trap$ = "$$TrapProtection"   ' General protection fault
		CASE $$TrapPageFault   : trap$ = "$$TrapPageFault"    ' Page fault
		CASE $$TrapSpurious    : trap$ = "$$TrapSpurious"     ' Spurious interrup bug
		CASE $$TrapCoprocessor : trap$ = "$$TrapCoprocessor"  ' Coprocessor error
		CASE $$TrapAlignment   : trap$ = "$$TrapAlignment"    ' Alignment error (80486)
		CASE $$TrapMachine     : trap$ = "$$TrapMachine"      ' Machine check
	END SELECT
'	IF trap$ THEN
		PRINT "XitSystemExceptionToException(83)", cpu.trap, trap$
'	END IF

END SUB

END FUNCTION
'
'
' ##################
' #####  L ()  #####
' ##################
'
FUNCTION  L (id)

'	s$ = STRING$(id)
'	s$ = s$ + ", " + HEXX$(##ERROR)
'	XstLog (s$)

END FUNCTION
'
'
' ######################
' #####  XitF7 ()  #####
' ######################
'
FUNCTION  XitF7 ()
	SHARED  CPUCONTEXT  cpu
	SHARED  breakPatches

	sxip = cpu.rip
	IF sxip THEN
		break = BreakProgrammer ($$BreakCheckOne, sxip, 0)
		opcode = UBYTEAT(sxip)
	END IF

'	PRINT "XitF7(17)", HEXX$(sxip), break, HEXX$(opcode), ##USERRUNNING
	HotStepGlobal()

END FUNCTION
END PROGRAM

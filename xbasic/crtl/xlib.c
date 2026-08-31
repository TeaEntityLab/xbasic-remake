/*
  xlib.c
  
   port of xbasic assembly code to c.
   
   copyright 2000 by wade maxfield
   licensed under LGPL -- see COPYING_LIB
 
   this file is likely to be very large, unless I make the statics globals 
   and give them a prefix to not polute name space.  at that time, we can
   start breaking things into a more modular form.  
*/

#include "xconst.h" /* global references, includes */

#define ADDR_F_MASK 0xfffff000
#define CPU_TYPE 0x80386 /* pick this up from OS somehow */
#define DEFAULT_TAB_SIZE 2
/*
# ########################  When any .EXE starts up, xstart.s passes
# #####  XxxMain ()  #####  8 important arguments here to XxxMain().
# ########################  The addresses below are after func entry. 
#
# ebp + 36 = arg7 = 0x00000000 for PDE : &%_StartApplication for standalone
# ebp + 32 = arg6 = esp
# ebp + 28 = arg5 = ebp
# ebp + 24 = arg4 = ##CODE = &main() : in xx.s for PDE : in ustart.s for app
# ebp + 20 = arg3 = *envx[]
# ebp + 16 = arg2 = *envp[]
# ebp + 12 = arg1 = **argv[]
# ebp +  8 = arg0 = argc
#
9999999
*/
int XxxMain(int myargc, char *myargv[], char *myenvp, char *myenvx, int
(*main_foo)(int,...), int (*StartApp)())
{

/*XxxMain:
   pushl %ebp  # standard function entry  
   movl  %esp,%ebp   # standard function entry
   pushl %ebx  # standard register saves  
   pushl %edi  # standard register
   saves    pushl %esi  # standard register saves
   movl  8(%ebp),%eax   # eax = argc
   movl  %eax,_argc  # store argc
   movl  12(%ebp),%eax  # eax = **argv[]
   movl  %eax,_argv  # store **argv[]
   movl  16(%ebp),%eax  # eax = *envp[]
   movl  %eax,_envp  # store *envp[]
   movl  20(%ebp),%eax  # eax = *envx[]      # ??? maybe ???
   movl  %eax,_envx  # store *envx[]
   movl  24(%ebp),%eax  # eax = &main()
   movl  %eax,_arg4  # store &main()
   movl  28(%ebp),%eax  # eax = &esp (entry)
   movl  %eax,_arg5  # store &esp (entry)
   movl  32(%ebp),%eax  # eax = &ebp (entry)
   movl  %eax,_arg6  # store &ebp (entry)
   movl  36(%ebp),%eax  # eax = 0x00000000 for PDE : &__StartApplication
   movl  %eax,_arg7  # store 0x00000000 for PDE : &__StartApplication
*/
  argc = myargc;
  xb_argv = myargv;
  xb_envp = myenvp;
  xb_envx = myenvx;
  xb_StartApplication = StartApp;

/*
#;
   movl  __XBASIC,%eax  # eax = zero if initialization not done yet
   orl   %eax,%eax   # set flags
   jnz   initdone # initialization done if __XBASIC != 0
   call  initmem  # allocate dyno memory, clear externals area
*/
     
   xb_xbasic =  (long)StartApp; /* this is unclear for now, it might work */
   if (!xb_xbasic)
      initmem();
      
/*
#;
#; *****  initialize fundamental system variables  *****
#;
initdone:
   movl  _argc,%eax  # eax = arg0 = argc
   movl  %eax,__ARGC # __ARGC = arg0
#;
   movl  _arg4,%eax  #
   movl  %eax,__START   # __START = &WinMain()
   movl  $XxxMain,%eax  #
   movl  %eax,__MAIN # __MAIN = &XxxMain()
   movl  _arg7,%eax  #
   movl  %eax,__APP  # __APP = 0x00000000 for PDE
#;          ; ##APP = &%_StartApplication for standalone
*/
   xb_argc = argc;
   xb_start = (long)main_foo;
   xb_main = (long)XxxMain;
   xb_app = (long)StartApp;

/*
#;
#; *****  initialize memory area constants  *****  (dyno area already done)
#;
   movl  _arg4,%eax  # WinMain is assumed to be lowest code address
   movl  %eax,__CODE # __CODE = WinMain
*/
   xb_code = (long)main_foo;
/* 
   andl  $0xFFFFF000,%eax
   movl  %eax,__CODE0   # __CODE = WinMain & 0xFFFFF000
*/
   xb_code0 = (long)main_foo & ADDR_F_MASK;
/*    
   movl  $_etext,%eax
   movl  %eax,__CODEX   # __CODEX = _etext
*/
        xb_codex = (long)xb_etext;  /* ???this makes no sense yet */
/*
   addl  $0x1000,%eax
   andl  $0xFFFFF000,%eax  # __CODEZ = (_etext + 0x1000) & 0xFFFFF000
   movl  %eax,__CODEZ    
*/
   xb_codez = (xb_codex + 0x1000 ) & ADDR_F_MASK;
   
/*   
   movl  $_dbase,%eax   # dbase is initialized memory base   
   movl  %eax,__DATA # __DATA = dbase                     
*/
  xb_data = xb_dbase;
   
/*   
   andl  $0xFFFFF000,%eax
   movl  %eax,__DATA0   # __DATA0 = dbase & 0xFFFFF000
*/
   xb_data0 = xb_dbase & ADDR_F_MASK;
/*      
   movl  $_edata,%eax
   movl  %eax,__DATAX   # __DATAX = _edata
*/
   xb_datax = (long)xb_edata;
   
/*      
   addl  $0x0FFF,%eax
   andl  $0xFFFFF000,%eax
   movl  %eax,__DATAZ   # __DATAZ = (_edata + 0xFFF) & 0xFFFFF000
*/
   xb_dataz = (xb_datax + 0xfff)   & ADDR_F_MASK;
/*   
   movl  $__XBASIC,%eax # assumed to be lowest bss address
   movl  %eax,__BSS  # __BSS = _ebss
*/    
   //???? How to enforce this is lowest bss address???
   xb_bss = xb_xbasic;                                

/*   
   andl  $0xFFFFF000,%eax
   movl  %eax,__BSS0 # __BSS0 = _ebss & 0xFFFFF000
*/
   xb_bss0 = xb_bss & ADDR_F_MASK;
/*      
   movl  $_ebss,%eax
   movl  %eax,__BSSX # __BSSX = _ebss
*/
   xb_bssx = xb_ebss;
/*   
   addl  $0x0FFF,%eax
   andl  $0xFFFFF000,%eax
   movl  %eax,__BSSZ # __BSSZ = (_ebss + 0x0FFF) + 0xFFFFF000
*/
   xb_bssz = (xb_bssx + 0xfff ) & ADDR_F_MASK;   
/*   
   movl  %esp,__STACK   # __STACK = esp
   leal  0x80(%esp),%eax
   movl  %esp,__STACKX  # __STACKX = esp + 0x80
   movl  %esp,%eax
   andl  $0xFFFFF000,%eax
   movl  %eax,__STACK0  # __STACK0 = esp & 0xFFFFF000
   leal  0x1000(%esp),%eax
   andl  $0xFFFFF000,%eax
   movl  %eax,__STACKZ  # __STACKZ = (esp + 0x1000) & 0xFFFFF000
*/
  // ??? stack stuff left alone for now.  Trying to make this less
  //     dependent on processor architecture. How should this be
  //     handled

/*
#;
#; *****  miscellaneous initialization  *****
#;
   fnclex      # initialize math coprocessor
   xorl  %eax,%eax   # initialize system variables
   movl  $80386,__CPU   # __CPU = 80386
*/
   xb_cpu = CPU_TYPE;

/*      
   movl  %eax,__ERROR   # __ERROR = 0
   movl  %eax,__WHOMASK # __WHOMASK = 0
   movl  %eax,__SOFTBREAK  # __SOFTBREAK = 0
   movl  %eax,__USERRUNNING   # __USERRUNNING = 0
   movl  %eax,__SIGNALACTIVE  # __SIGNALACTIVE = 0
   movl  %eax,__LOCKOUT # __LOCKOUT = 0
*/
   xb_error = xb_whomask = xb_softbreak = xb_userrunning = xb_signalactive = xb_lockout = 0;
/*   
   movl  $__beginAlloCode,__BEGINALLOCODE # init __BEGAINALLOCODE
   movl  $__endAlloCode,__ENDALLOCODE  # init __ENDALLOCODE
*/
   //??? This is some strange stuff.  this part of the code will have to be
   // looked at much later
   xb_beginallocode = xb__beginAlloCode; /* note preservation of case for the actual tag. pull from xlib.s properly */
   xb_endallocode = xb__endAlloCode;     /* note preservation of case for the actual tag pull from xlib.s properly */
/*      
#;
   movl  $__externals,%eax # get first address of user EXTERNAL area
   movl  %eax,%ebx      #
   addl  $65536,%ebx    # get  last address of user EXTERNAL area
   movl  %eax,__GLOBAL0 # first shared/external
   movl  %eax,__GLOBAL  # ditto
   movl  %eax,__GLOBALX # ditto (increases during compile)
   movl  %ebx,__GLOBALZ # last space for shared/external
   movl  $2,__TABSAT # default tab setting is 2
   movl  $-1,__STANDALONE  # default is standalone code (not environment)
*/
  xb_global0 = (long)externals + sizeof(externals);
  xb_globalx = xb_globalz = xb_global = xb_global0;
  
  xb_tabsat = DEFAULT_TAB_SIZE;
  
  xb_standalone = -1; /* default is not in PDE */

/*
#;
#; *****  Create ##ARGV$[] array  *****
#;
   movl  __ARGC,%esi # esi = __ARGC
   shll  $2,%esi     #esi = argc * 4 = _ of bytes in __ARGV$[]
   addl  $4,%esi     #room for null pointer as terminator marker
   call  _____calloc # ntntnt  (found Ben error here and fixed)
   movl  %esi,___ARGV$  #save pointer to __ARGV$[] array
   movl  __WHOMASK,%eax #eax = system/user int
   orl   $0x00080004,%eax  #info word = allocated array w/ 4 bytes per elem
   movl  %eax,-4(%esi)  #save __ARGV$[]'s info word
   movl  __ARGC,%ecx # ecx = __ARGC
   movl  %ecx,-8(%esi)  #store number of elements of __ARGV$[]
   cld   
   xorl  %ebx,%ebx   #ebx = argCounter = 0
#;
argv_loop:
   movl  _argv,%edx  #edx = entry **argv[]
   xorl  %eax,%eax   #prepare to search for null terminator
   movl  (%edx,%ebx,4),%edi   #edi = argv[argCounter]
   movl  %edi,%edx
   movl  $-1,%ecx #search until find null or memory fault
   repnz 
   scasb       #search for terminating null
   negl  %ecx     #ecx = strlen(argv[argCounter]), plus 1
#;       ; for terminating null
   movl  %ecx,%esi   #esi = needed length
   call  _____calloc #esi -> copy of argv[argCounter]
   movl  __WHOMASK,%eax #eax = system/user int
   orl   $0x00130001,%eax  #info word = allocated string
   movl  %eax,-4(%esi)  #save string's info word
   leal  -2(%ecx),%eax  #eax = LEN(argv[argCounter])
   movl  %eax,-8(%esi)  #save length of string
   movl  %esi,%edi   #esi -> place to store copy of argv[argCounter]
   xchgl %edx,%esi   #esi -> original, edx -> copy
   rep   
   movsb       #copy argv[argCounter]
   movl  ___ARGV$,%esi  #esi -> __ARGV$[] array
   movl  %edx,(%esi,%ebx,4)   #store pointer to copied string
   incl  %ebx     #bump argCounter
   cmpl  __ARGC,%ebx #reached argc yet?
   jb argv_loop   #nope: do another
#;
#; *****  Create ##ENVP$[] array  *****
#
   xorl  %esi,%esi   #esi = envCounter = 0
   movl  _envp,%eax  #eax = *envp[]
#;
envp_count_loop:
   movl  (%eax,%esi,4),%ebx   #ebx = envp[argCounter]
   orl   %ebx,%ebx   #null pointer?
   jz envp_alloc  #yes: done counting
   incl  %esi     #bump argCounter
   jmp   envp_count_loop
#;
envp_alloc:
   movl  %esi,%ebx   #ebx = _ of environment variables
   shll  $3,%esi     #esi = 2 * space needed for array of pointers
   call  _____calloc #esi -> __ENVP$[] array
   movl  %ebx,-8(%esi)  #store _ of elements
   movl  __WHOMASK,%eax #eax = system/user bit
   orl   $0x00080004,%eax  #eax = info word: alloc'ed array of 4-byte elems
   movl  %eax,-4(%esi)  #store info word
   movl  %esi,___ENVP$
   xorl  %ebx,%ebx   #ebx = envCounter = 0
##
envp_loop:
   cmpl  -8(%esi),%ebx  #reached last environment variable?
   jz envp_done   #yes
   movl  _envp,%edx  #edx = *envp[]
   xorl  %eax,%eax   #prepare to search for null terminator
   movl  (%edx,%ebx,4),%edi   #edi = envp[envCounter]
   movl  %edi,%edx
   movl  $-1,%ecx #search until null or memory fault
##
   repnz 
   scasb       #search for terminating null
   negl  %ecx     #ecx = LEN(envp[envCounter]), plus 1
##          # for terminating null
   movl  %ecx,%esi   #esi = needed length
   call  _____calloc #esi -> place to put copy of env var
   movl  __WHOMASK,%eax #eax = system/user int
   orl   $0x00130001,%eax  #info word = allocated string
   movl  %eax,-4(%esi)  #save string's info word
   leal  -2(%ecx),%eax  #eax = LEN(envp[envCounter])
   movl  %eax,-8(%esi)  #save length of string
   movl  %esi,%edi   #edi -> place to store copy of env var
   xchgl %edx,%esi   #esi -> original, edx -> copy
   rep   
   movsb    #copy envp[envCounter]
   movl  ___ENVP$,%esi  #esi -> __ENVP$[] array
   movl  %edx,(%esi,%ebx,4)   #store pointer to copied string
   incl  %ebx  #bump envCounter
   jmp   envp_loop
envp_done:
#;
#;
#; ********************************************
#; *****  start debugger or user program  *****
#; ********************************************
#;
   pushl _envp # push entry argument 2 - envp
   pushl _argv # push entry argument 1 - argv
   pushl _argc # push entry argument 0 - argc
   call  XxxXit_12   # start debugger or user program
#;
#; *****  program execution complete : standard function exit code  *****
#;
   popl  %esi  # standard function exit
   popl  %edi  # ditto
   popl  %ebx  # ditto
   movl  %ebp,%esp   # ditto
   popl  %ebp  # ditto
   ret      # ditto
#
   call  exit  # alternate way to terminate program : eax = code
   ret      # exit() should never return
#
# machine visible copyright - this may not be removed
#
.align   8
.string "\n"
.string "Max Reason\n"
.string "copyright 1988-2000\n"
.string "Linux XBasic assembly language support\n"
.string "\n"
.string "\0"
.align   8
*/
        
}

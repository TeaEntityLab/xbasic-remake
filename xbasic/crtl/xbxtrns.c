/*
  Modified for .c source file by Wade Maxfield
  
  NOTE:
    to make this work better as a multi-file project, all xb variables are now
    GLOBAL in scope, and have xb_ prepended to them to avoid name collision.

   Initial release to Eddie 2/21/00.  (Note: this file may continue to be changed)
#
#
# ####################  Max Reason
# #####  xlib.s  #####  copyright 1988-2000
# ####################  Linux XBasic assembly language
#
# subject to LGPL license - see COPYING_LIB
#
# maxresaon@maxreason.com
#
# for Linux XBasic
#
#
# PROGRAM "xlib"    ' fake PROGRAM statement - name this library
# VERSION "0.0106"  ' fake VERSION statement - keep version updated
#
#
# #######################################  Mostly assembly language source code
# #####  Assembly Language Library  #####  for XBasic language intrinsics like
# #######################################  ABS(), LEFT$(), MID$(), TRIM$(), etc
#
# This file contains assembly language routines for many purposes, including:
#   1. Startup initialization - XxxMain is called by xinit.s or app at startup
#   2. Error handling - handle "jmp %eeeErrorName" in XBasic source programs
#   3. Dynamic memory management - malloc, calloc, recalloc, free, etc...
#   4. Array management - DimArray, RedimArray, FreeArray
#   5. Intrinsic functions - ABS(), BIN$(), CHR$(), etc...
#   6. General support routines, especially for program development environment
#
# To create the program development environment, this file is assembled into
# object file "xlib.o" which is linked to, and becomes part of, the program
# development environment - aka PDE.  The global variables in xlib.s are
# therefore in the PDE executable file, and are read in by the PDE when it
# starts up.  The addresses of all xlib.s routines are therefore available
# to the compiler and calls to xlib.s routines in user programs are resolved
# without difficulty.
#
# External variables are not shared in the same manner in both cases.
# External variables are shared by all programs linked into a single
# executable (.DLL or .EXE).  External variables in the PDE and user
# programs are not shared with .DLL libraries.  So function libraries
# developed in the PDE should not contain external variables - at least
# not external variables meant to be shared by programs or other function
# libraries that use the .DLL as a .DLL.  External variables are only
# shared with programs linked into a single .EXE or .DLL.
#
#
#
#
# ############################################
# ############################################
# #####  DATA  #####  DATA  #####  DATA  #####  .data section
# ############################################
# ############################################
#
*/
#include "xlib.h"

long xb_xxxPointers[16*8]; /* 16, 32, 48, 64...32M,64M, 128M, 256M, 512M...512G....*/
long xb_messageBuffer[16]; /* for XxxCheckMessages() */
long xb_noFreeTest[16]; /* */

 char *xb_debugFile = "win32s.bug\0\0\0\0\0\0\0\0";

 char *xb_debugHandle = "\0\0\0\0\0\0\0\0";

 char *xb_bytesWritten = "\0\0\0\0\0\0\0\0";

 char *xb_Rmsg = "\__RuntimeError __TRAP = _d __ERROR = 0x_08X address = 0x_08X\n\0";

 long xb_whereBuffer[16*8];

 char xb_workbyte = 0xab;

 short xb_workword = 0xabcd;

 short xb_workword2 = 0xef01;

 long xb_workdword = 0xbadbeef;

 long xb_workqword[2] = {0x98765432, 0xFEDCBA98 };

 short xb_control_bits =0;

 short xb_orig_control_bits;

 char xb_search_tab[256];

 long xb_sn_save;

 long xb_oct_shift  = oct_lsd_64;

 long xb_oct_first[2];

long xb_fdebug0[4] ;/* global */
 long xb_fdebug1[4] ;
 long xb_fdebug2[4] ;
 long xb_fdebug3[4] ;
 long xb_fdebug4[4] ;
 long xb_fdebug5[4] ;
 long xb_fdebug6[4] ;
 long xb_fdebug7[4] ;
 long xb_fdebug8[4] ;
 long xb_fdebug9[4] ;
 long xb_fdebugA[4] ;
 long xb_fdebugB[4] ;
 long xb_fdebugC[4] ;
 long xb_fdebugD[4] ;
 long xb_fdebugE[4] ;
 long xb_fdebugF[4] ;

 long xb_save_eax;
 long xb_save_ebx;
 long xb_save_ecx;
 long xb_save_edx;
 long xb_save_esi;
 long xb_save_edi;
 long xb_save_esp;
 long xb_save_ebp
long xb_debug; /* global */
 long xb_daddr;
 long xb_desp;
 long xb_debp;
 long xb_despaddr0;
 long xb_debpaddr0;
 long xb_despaddr4;
 long xb_debpaddr4;
long xb_debug0; /* global */
 long xb_debug1;
 long xb_debug2;
 long xb_debug3;
 long xb_debug4;
 long xb_debug5;
 long xb_debug6;
 long xb_debug7;
 long xb_debug8;
 long xb_debug9;
 long xb_debugA;
 long xb_debugB;
 long xb_debugC;
 long xb_debugD;
 long xb_debugE;
 long xb_debugF;

/*
#
#
# ******************************
# ******************************
# *****  SYSTEM EXTERNALS  *****  persist on user task run/kill/run/kill...
# ******************************
# ******************************
#
*/
long  xb_begin,   // 4  # beginning of externals
   xb_xbasic,  // 4  # id label
   xb_inexit,  // 4  # exit() in progress - no prints
   xb_code0,   // 4  # xit code page base (first page)
   xb_code, // 4  # xit code starts here
   xb_codex,   // 4  # xit code ends here (unix _etext)
   xb_codez,   // 4  # xit code break address (last page)
   xb_ucode0,  // 4  # user code page base (first page)
   xb_ucode,   // 4  # user code starts here
   xb_ucodex,  // 4  # user code ends here
   xb_ucodez,  // 4  # user code break address (last page)
   xb_data0,   // 4  # data page base (first page)
   xb_data, // 4  # data starts
   xb_datax,   // 4  # data ends here
   xb_dataz,   // 4  # data page ends here (last page)
   xb_bss0, // 4  # bss page base (first page)
   xb_bss,     // 4  # bss starts here
   xb_bssx, // 4  # bss ends here
   xb_bssz, // 4  # bss page ends here (last page)
   xb_dyno0,   // 4  # dyno page base
   xb_dyno, // 4  # dyno headers start here
   xb_dynox,   // 4  # dyno headers end here
   xb_dynoz,   // 4  # dyno page ends here
   xb_udyno0,  // 4  # dyno page base
   xb_udyno,   // 4  # dyno headers start here
   xb_udynox,  // 4  # dyno headers end here
   xb_udynoz,  // 4  # dyno page ends here
   xb_stack0,  // 4  # stack page base (low page)
   xb_stack,   // 4  # stack ???
   xb_stackx,  // 4  # stack ???
   xb_stackz,  // 4  # stack entry page end (high page)
   xb_global0, // 4  # external block starts here
   xb_global,  // 4  # external block after system
   xb_globalx, // 4  # external block next available
   xb_globalz, // 4  # external block after
   xb_error,   // 4  # xb_error  (xbasic error number)
   xb_argc, // 4  # xb_argc   (_ elements in xb_argv$[])
   xb__argv$,  // 4  # xb_argv$[]   (argument strings)
   xb__envp$,  // 4  # xb_envp$[]   (environment strings)
   xb__oserror$,  // 4  # xb_oserror$[]   (operating-system error strings)
   xb__alarmreg,  // 4  # xb_alarmreg[]   (alarm registers, xit frames)
   xb__sysreg, // 4  # xb_sysreg[]  (xit machine registers)
   xb__reg, // 4  # xb_reg[]  (machine registers)
   xb_lockout, // 4  # xb_lockout   (within a system call)
   xb_waiting, // 4  # xb_waiting   (waiting in xnextevent() for event)
   xb_sleeping,   // 4  # xb_sleeping  (waiting for timer or other exception)
   xb_userwaiting,   // 4  # xb_userwaiting  (waiting for ^q to undo ^s)
   xb_breakout,   // 4  # xb_breakout  (break out of event/message loop)
   xb_exception,  // 4  # xb_exception
   xb_osexception,   // 4  # xb_osexception
   xb_signalactive,//   4  # xb_signalactive (xit)
   xb_walkbase,   // 4  # xb_walkbase
   xb_xwalkbase,  // 4  # xb_xwalkbase
   xb_walkoffset, // 4  # xb_walkoffset
   xb_xwalkoffset,   // 4  # xb_xwalkoffset
   xb_tabsat,  // 4  # xb_tabsat (tabs set every n columns)
   xb_whomask, // 4  # xb_whomask   (allocation owner, info word)
   xb_softbreak,  // 4  # xb_softbreak    (all xbasic systemcalls)
   xb_userrunning,   // 4  # xb_userrunning
   xb_beginallocode,//  4  # xb_beginallocode   (xitmain(), xlib0.s)
   xb_endallocode,   // 4  # xb_endallocode     (xitmain(), xliba.s)
   xb_trapvector, // 4  # xb_trapvector
   xb_entered, // 4  # xb_entered
   xb_alarmwalker,   // 4  # xb_alarmwalker     (alarm walkoffset, xit frames)
   xb_alarmloop,  // 4  # xb_alarmloop    (alarm loop addr, xit frames)
   xb_alarmtime,  // 4  # xb_alarmtime    (alarm time interval)
   xb_alarmbusy,  // 4  # xb_alarmbusy
   xb_hinstance,  // 4  # xb_hinstance - hinstance active
   xb_hinstancedll,  // 4  # xb_hinstancedll - hinstance of .dll
   xb_hinstanceexe,  // 4  # xb_hinstanceexe - hinstance of .exe
   xb_hinstancestart,// 4  # xb_hinstancestart - hinstance at .exe startup
   xb_standalone, // 4  # xb_standalone
   xb_congrid, // 4  # xb_congrid
   xb_start,   // 4  # xb_start
   xb_main,    // 4  # xb_main
   xb_app,     // 4  # xb_app
   xb_cpu,     // 4  # xb_cpu
   xb_debug,   // 4  # xb_debug
   xb_blowback;   // 4  # xb_blowback
/*
#
# the following memory area - 64KB at %%externals - holds shared
# and external variables of programs compiled into memory by the PDE.
#
# DON'T CHANGE SIZE OF "xb_externals" without looking through code for trouble
# 
*/
char  xb_externals[65536];//  # room for about 16000 variables
char  xb_externalz[16];//  # end of user shared/external area
long  xberrno;    // 4  # C / system error variable

long argc; /* the xxxmain function uses this during initialization */


static void stub(void);

/* this functions makes this a compilable file.*/
static void stub(void)
{
}


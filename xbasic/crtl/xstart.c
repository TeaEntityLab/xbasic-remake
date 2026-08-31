/*
  ported to "c" copyright 2000 by Wade Maxfield
  licensed under LGPL license - see COPYING_LIB
  released to Eddie 2/21/00.
#
#
# ####################  Max Reason
# #####  xstart  #####  copyright 1988-2000
# ####################  Linux XBasic executable support
#
# subject to LGPL license - see COPYING_LIB
#
# MaxReason@MaxReason.com
#
# for Linux XBasic
#
#
# PROGRAM "xstart"
# VERSION "0.0002"
#
#
*/
#include <stdlib.h>
#include <stdio.h>
#include "xlib.h"
#include "xbconst.h"
/*
.text
.globl   main        # C entry label
.globl   WinMain        # Windows entry label
.globl   WinMain_16     # Windows entry label ???
.globl   __StartApplication   # Whatever standalone program follows
#
#
# ########################
# #####  WinMain ()  #####
# ########################
#
# NOTE:  arg7 = 0x00000000          for PDE
#        arg7 = &%_StartApplication for standalone programs
#
.text
.align   8
#
main:          # C entry label
WinMain:       # Windows entry label
WinMain_16:       # Windows entry label ???
   pushl %ebp     # save frame pointer
   movl  %esp,%ebp   # create new frame
   pushl $0x00000000 # arg7 = 0 for PDE else &__StartApplication
   pushl %esp     # arg6 = entry stack pointer = esp
   pushl %ebp     # arg5 = entry frame pointer = ebp
   pushl $main    # arg4 = &main() ===>> __CODE
   pushl 20(%ebp) # arg3 = *envx[]
   pushl 16(%ebp) # arg2 = *envp[]
   pushl 12(%ebp) # arg1 = **argv[]
   pushl 8(%ebp)     # arg0 = argc
   call  XxxMain     # XxxMain() is in xlib.s in xb.dll
   addl  $32,%esp # remove arguments (not STDCALL)
   movl  %ebp,%esp   # ready to return
   popl  %ebp     #
   ret         # return to exit program
#
#
*/

int main(int argc, char *argv[],char *envp,char *envx)
{
#ifdef PDE
#define StartApp ((long)0)
#else
#define StartApp StartApplication
#endif
 /* a guess for now, the ebp, esp are not needed */
  XxxMain(argc,argv,envp,envx,main,StartApp);
}
/*
.text
.align   8
__StartApplication:
   nop   
   nop   
   nop   
   nop   
*/

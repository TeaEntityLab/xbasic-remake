/*                           
   copyright 2000 by Wade Maxfield
   Released under the LGPL
  released to Eddie 2/21/00   
  xzzz.c, ported from xzzz.s 
#####################################################################
# Created from /xb/lib/xzzz.s using unspas.pl V0.57(September 10, 1995)
#####################################################################
*/

/*
.text
.align   8
.globl   _etext
_etext:
.long 0, 0, 0, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0, 0
*/
long xb_etext[32];
/*
#
.data
.align   8
.globl   _edata
_edata:
.long 0, 0, 0, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0, 0
# 
*/
long xb_edata[32];
/*
.bss
.align   8
.comm _ebss, 8
*/
char xb_ebss[8];

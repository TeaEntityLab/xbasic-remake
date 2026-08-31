'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aconvert"
VERSION	"0.0001"
'
'
' convert a numeric string to any numeric datatype
' convert any numeric datatype to a numeric string
'
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
' >
' > In the absence of VAL() how do I change a string say "8" to a number,
' > so that I can calculate with it.. I've looked in all the libraries and
' > can find XstStringToNumber but I can't understand the input params.
' > GetValue does not look right also.
' > Regards
' > Bob
'
' It's so easy and natural and obvious, you just don't notice it!  :-)
'
' You will laugh, and wonder why QBasic and every language don't work this way.
'
' No matter what data-type you want to convert to or from,
' the only question is, what type do you want to convert to?
'
' All the following are valid syntax, though some will cause overflow
' errors (for example the range of SBYTE range is only -128 to +127 .
' Those that cause overflow errors are commented out, but will work
' given numeric strings within the range supported by the data-type.
'
'
FUNCTION  Entry ()
'
' create a variable of each datatype
'
	SBYTE   sbyte
  UBYTE   ubyte
  SSHORT  sshort
  USHORT  ushort
  SLONG   slong
  ULONG   ulong
  XLONG   xlong
  SINGLE  single
  DOUBLE  double
	STRING  string$
'
' create strings with various numeric formats
'
  a$ = "123"
  b$ = "1234.5678"
  c$ = "12.345678e2"
  d$ = "1.2345678d3"
  e$ = "0x1234ABCD"
  f$ = "0o12345670"
  g$ = "0b01100101"
'
  sbyte = SBYTE (a$)
' sbyte = SBYTE (b$)
' sbyte = SBYTE (c$)
' sbyte = SBYTE (d$)
' sbyte = SBYTE (e$)
' sbyte = SBYTE (f$)
  sbyte = SBYTE (g$)
'
  ubyte = UBYTE (a$)
' ubyte = UBYTE (b$)
' ubyte = UBYTE (c$)
' ubyte = UBYTE (d$)
' ubyte = UBYTE (e$)
' ubyte = UBYTE (f$)
  ubyte = UBYTE (g$)
'
  sshort = SSHORT (a$)
  sshort = SSHORT (b$)
  sshort = SSHORT (c$)
  sshort = SSHORT (d$)
' sshort = SSHORT (e$)
' sshort = SSHORT (f$)
  sshort = SSHORT (g$)
'
  ushort = USHORT (a$)
  ushort = USHORT (b$)
  ushort = USHORT (c$)
  ushort = USHORT (d$)
' ushort = USHORT (e$)
' ushort = USHORT (f$)
  ushort = USHORT (g$)
'
  slong = SLONG (a$)
  slong = SLONG (b$)
  slong = SLONG (c$)
  slong = SLONG (d$)
  slong = SLONG (e$)
  slong = SLONG (f$)
  slong = SLONG (g$)
'
  ulong = ULONG (a$)
  ulong = ULONG (b$)
  ulong = ULONG (c$)
  ulong = ULONG (d$)
  ulong = ULONG (e$)
  ulong = ULONG (f$)
  ulong = ULONG (g$)
'
  xlong = XLONG (a$)
  xlong = XLONG (b$)
  xlong = XLONG (c$)
  xlong = XLONG (d$)
  xlong = XLONG (e$)
  xlong = XLONG (f$)
  xlong = XLONG (g$)
'
  single = SINGLE (a$)
  single = SINGLE (b$)
  single = SINGLE (c$)
  single = SINGLE (d$)
  single = SINGLE (e$)
  single = SINGLE (f$)
  single = SINGLE (g$)
'
  double = DOUBLE (a$)
  double = DOUBLE (b$)
  double = DOUBLE (c$)
  double = DOUBLE (d$)
  double = DOUBLE (e$)
  double = DOUBLE (f$)
  double = DOUBLE (g$)
'
' converting to a string is just as easy
' and obvious as converting from a string
'
  string$ = STRING$ (sbyte)
  string$ = STRING$ (ubyte)
  string$ = STRING$ (sshort)
  string$ = STRING$ (ushort)
  string$ = STRING$ (slong)
  string$ = STRING$ (ulong)
  string$ = STRING$ (xlong)
  string$ = STRING$ (single)
  string$ = STRING$ (double)
END FUNCTION
END PROGRAM

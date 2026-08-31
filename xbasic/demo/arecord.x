'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"arecord"
VERSION	"0.0000"
'
IMPORT	"xst"
'
'
' #####################################
' #####  DECLARE COMPOSITE TYPES  #####
' #####################################
'
TYPE TYPE0
  UBYTE  .a
END TYPE

TYPE TYPE1
  USHORT .a
END TYPE

TYPE TYPE2
  ULONG  .a
END TYPE

TYPE TYPE3
  USHORT .a
  USHORT .b
END TYPE
'
TYPE TYPE4
  GIANT  .a
  GIANT  .b
  GIANT  .c
  GIANT  .d
END TYPE
'
TYPE TYPE5
  GIANT  .a
  GIANT  .b
  GIANT  .c
  GIANT  .d
	DOUBLE .e
	DOUBLE .f
	DOUBLE .g
	DOUBLE .h
END TYPE
'
'
' ###############################
' #####  DECLARE FUNCTIONS  #####
' ###############################
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  Print (value)
DECLARE FUNCTION  PrintGlobalTypes ()

TYPE0 #globaltype0
TYPE1 #globaltype1
TYPE2 #globaltype2
TYPE3 #globaltype3
TYPE4 #globaltype4
TYPE5 #globaltype5

TYPE0 #globaltype0[]
TYPE1 #globaltype1[]
TYPE2 #globaltype2[]
TYPE3 #globaltype3[]
TYPE4 #globaltype4[]
TYPE5 #globaltype5[]
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
  TYPE0 type0
  TYPE1 type1
  TYPE2 type2
  TYPE3 type3
	TYPE4 type4
	TYPE5 type5
'
  TYPE0 type0[]
  TYPE1 type1[]
  TYPE2 type2[]
  TYPE3 type3[]
	TYPE4 type4[]
	TYPE5 type5[]
'
	PRINT
	PRINT "   ############################"
	PRINT "   LEN   LEN  SIZE  SIZE   type"
	PRINT
  Print (LEN(TYPE0))	: Print (LEN(type0))	: Print (SIZE(TYPE0))	: Print (SIZE(type0))	: PRINT "   TYPE0"
  Print (LEN(TYPE1))	: Print (LEN(type1))	: Print (SIZE(TYPE1))	: Print (SIZE(type1))	: PRINT "   TYPE1"
  Print (LEN(TYPE2))	: Print (LEN(type2))	: Print (SIZE(TYPE2))	: Print (SIZE(type2))	: PRINT "   TYPE2"
  Print (LEN(TYPE3))	: Print (LEN(type3))	: Print (SIZE(TYPE3))	: Print (SIZE(type3))	: PRINT "   TYPE3"
  Print (LEN(TYPE4))	: Print (LEN(type4))	: Print (SIZE(TYPE4))	: Print (SIZE(type4))	: PRINT "   TYPE4"
  Print (LEN(TYPE5))	: Print (LEN(type5))	: Print (SIZE(TYPE5))	: Print (SIZE(type5))	: PRINT "   TYPE5"
'
  Print (LEN(TYPE0))	: Print (LEN(#globaltype0))	: Print (SIZE(TYPE0))	: Print (SIZE(#globaltype0))	: PRINT "   #globalTYPE0"
  Print (LEN(TYPE1))	: Print (LEN(#globaltype1))	: Print (SIZE(TYPE1))	: Print (SIZE(#globaltype1))	: PRINT "   #globalTYPE1"
  Print (LEN(TYPE2))	: Print (LEN(#globaltype2))	: Print (SIZE(TYPE2))	: Print (SIZE(#globaltype2))	: PRINT "   #globalTYPE2"
  Print (LEN(TYPE3))	: Print (LEN(#globaltype3))	: Print (SIZE(TYPE3))	: Print (SIZE(#globaltype3))	: PRINT "   #globalTYPE3"
  Print (LEN(TYPE4))	: Print (LEN(#globaltype4))	: Print (SIZE(TYPE4))	: Print (SIZE(#globaltype4))	: PRINT "   #globalTYPE4"
  Print (LEN(TYPE5))	: Print (LEN(#globaltype5))	: Print (SIZE(TYPE5))	: Print (SIZE(#globaltype5))	: PRINT "   #globalTYPE5"
'
  DIM type0[]
  DIM type1[]
  DIM type2[]
  DIM type3[]
	DIM type4[]
	DIM type5[]
'
	PRINT
  Print (LEN(TYPE0))	: Print (LEN(type0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(type0[]))	: PRINT "   TYPE0[]"
  Print (LEN(TYPE1))	: Print (LEN(type1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(type1[]))	: PRINT "   TYPE1[]"
  Print (LEN(TYPE2))	: Print (LEN(type2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(type2[]))	: PRINT "   TYPE2[]"
  Print (LEN(TYPE3))	: Print (LEN(type3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(type3[]))	: PRINT "   TYPE3[]"
  Print (LEN(TYPE4))	: Print (LEN(type4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(type4[]))	: PRINT "   TYPE4[]"
  Print (LEN(TYPE5))	: Print (LEN(type5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(type5[]))	: PRINT "   TYPE5[]"
'
  Print (LEN(TYPE0))	: Print (LEN(#globaltype0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(#globaltype0[]))	: PRINT "   #globalTYPE0[]"
  Print (LEN(TYPE1))	: Print (LEN(#globaltype1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(#globaltype1[]))	: PRINT "   #globalTYPE1[]"
  Print (LEN(TYPE2))	: Print (LEN(#globaltype2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(#globaltype2[]))	: PRINT "   #globalTYPE2[]"
  Print (LEN(TYPE3))	: Print (LEN(#globaltype3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(#globaltype3[]))	: PRINT "   #globalTYPE3[]"
  Print (LEN(TYPE4))	: Print (LEN(#globaltype4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(#globaltype4[]))	: PRINT "   #globalTYPE4[]"
  Print (LEN(TYPE5))	: Print (LEN(#globaltype5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(#globaltype5[]))	: PRINT "   #globalTYPE5[]"
'
  DIM type0[0]
  DIM type1[0]
  DIM type2[0]
  DIM type3[0]
	DIM type4[0]
	DIM type5[0]
'
  DIM #globaltype0[0]
  DIM #globaltype1[0]
  DIM #globaltype2[0]
  DIM #globaltype3[0]
	DIM #globaltype4[0]
	DIM #globaltype5[0]
'
	PRINT
  Print (LEN(TYPE0))	: Print (LEN(type0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(type0[]))	: PRINT "   TYPE0[0]"
  Print (LEN(TYPE1))	: Print (LEN(type1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(type1[]))	: PRINT "   TYPE1[0]"
  Print (LEN(TYPE2))	: Print (LEN(type2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(type2[]))	: PRINT "   TYPE2[0]"
  Print (LEN(TYPE3))	: Print (LEN(type3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(type3[]))	: PRINT "   TYPE3[0]"
  Print (LEN(TYPE4))	: Print (LEN(type4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(type4[]))	: PRINT "   TYPE4[0]"
  Print (LEN(TYPE5))	: Print (LEN(type5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(type5[]))	: PRINT "   TYPE5[0]"
'
  Print (LEN(TYPE0))	: Print (LEN(#globaltype0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(#globaltype0[]))	: PRINT "   #globalTYPE0[0]"
  Print (LEN(TYPE1))	: Print (LEN(#globaltype1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(#globaltype1[]))	: PRINT "   #globalTYPE1[0]"
  Print (LEN(TYPE2))	: Print (LEN(#globaltype2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(#globaltype2[]))	: PRINT "   #globalTYPE2[0]"
  Print (LEN(TYPE3))	: Print (LEN(#globaltype3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(#globaltype3[]))	: PRINT "   #globalTYPE3[0]"
  Print (LEN(TYPE4))	: Print (LEN(#globaltype4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(#globaltype4[]))	: PRINT "   #globalTYPE4[0]"
  Print (LEN(TYPE5))	: Print (LEN(#globaltype5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(#globaltype5[]))	: PRINT "   #globalTYPE5[0]"
'
  DIM type0[3]
  DIM type1[3]
  DIM type2[3]
  DIM type3[3]
	DIM type4[3]
	DIM type5[3]
'
  DIM #globaltype0[3]
  DIM #globaltype1[3]
  DIM #globaltype2[3]
  DIM #globaltype3[3]
	DIM #globaltype4[3]
	DIM #globaltype5[3]
'
	type5[0].a =  1234567890123456789
	type5[1].e = .1234567890123456789
'
	#globaltype5[0].a =  1234567890123456789
	#globaltype5[1].e = .1234567890123456789
'
	PRINT
  Print (LEN(TYPE0))	: Print (LEN(type0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(type0[]))	: PRINT "   TYPE0[3]"
  Print (LEN(TYPE1))	: Print (LEN(type1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(type1[]))	: PRINT "   TYPE1[3]"
  Print (LEN(TYPE2))	: Print (LEN(type2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(type2[]))	: PRINT "   TYPE2[3]"
  Print (LEN(TYPE3))	: Print (LEN(type3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(type3[]))	: PRINT "   TYPE3[3]"
  Print (LEN(TYPE4))	: Print (LEN(type4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(type4[]))	: PRINT "   TYPE4[3]"
  Print (LEN(TYPE5))	: Print (LEN(type5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(type5[]))	: PRINT "   TYPE5[3]"
'
  Print (LEN(TYPE0))	: Print (LEN(#globaltype0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(#globaltype0[]))	: PRINT "   #globalTYPE0[3]"
  Print (LEN(TYPE1))	: Print (LEN(#globaltype1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(#globaltype1[]))	: PRINT "   #globalTYPE1[3]"
  Print (LEN(TYPE2))	: Print (LEN(#globaltype2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(#globaltype2[]))	: PRINT "   #globalTYPE2[3]"
  Print (LEN(TYPE3))	: Print (LEN(#globaltype3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(#globaltype3[]))	: PRINT "   #globalTYPE3[3]"
  Print (LEN(TYPE4))	: Print (LEN(#globaltype4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(#globaltype4[]))	: PRINT "   #globalTYPE4[3]"
  Print (LEN(TYPE5))	: Print (LEN(#globaltype5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(#globaltype5[]))	: PRINT "   #globalTYPE5[3]"
'
' open files to write composite arrays to
'
	ofile0d = OPEN ("type0d.dat", $$WR)
	ofile1d = OPEN ("type1d.dat", $$WR)
	ofile2d = OPEN ("type2d.dat", $$WR)
	ofile3d = OPEN ("type3d.dat", $$WR)
	ofile4d = OPEN ("type4d.dat", $$WR)
	ofile5d = OPEN ("type5d.dat", $$WR)
'
	ofile0g = OPEN ("type0g.dat", $$WR)
	ofile1g = OPEN ("type1g.dat", $$WR)
	ofile2g = OPEN ("type2g.dat", $$WR)
	ofile3g = OPEN ("type3g.dat", $$WR)
	ofile4g = OPEN ("type4g.dat", $$WR)
	ofile5g = OPEN ("type5g.dat", $$WR)

'
	IF (ofile0d > 2) THEN WRITE [ofile0d], type0[]
	IF (ofile1d > 2) THEN WRITE [ofile1d], type1[]
	IF (ofile2d > 2) THEN WRITE [ofile2d], type2[]
	IF (ofile3d > 2) THEN WRITE [ofile3d], type3[]
	IF (ofile4d > 2) THEN WRITE [ofile4d], type4[]
	IF (ofile5d > 2) THEN WRITE [ofile5d], type5[]
'
	IF (ofile0g > 2) THEN WRITE [ofile0g], #globaltype0[]
	IF (ofile1g > 2) THEN WRITE [ofile1g], #globaltype1[]
	IF (ofile2g > 2) THEN WRITE [ofile2g], #globaltype2[]
	IF (ofile3g > 2) THEN WRITE [ofile3g], #globaltype3[]
	IF (ofile4g > 2) THEN WRITE [ofile4g], #globaltype4[]
	IF (ofile5g > 2) THEN WRITE [ofile5g], #globaltype5[]
'
	CLOSE (-1)		' close ALL files
'
' open files to read composite arrays from
'
	ifile0d = OPEN ("type0d.dat", $$RD)
	ifile1d = OPEN ("type1d.dat", $$RD)
	ifile2d = OPEN ("type2d.dat", $$RD)
	ifile3d = OPEN ("type3d.dat", $$RD)
	ifile4d = OPEN ("type4d.dat", $$RD)
	ifile5d = OPEN ("type5d.dat", $$RD)
'
	ifile0g = OPEN ("type0g.dat", $$RD)
	ifile1g = OPEN ("type1g.dat", $$RD)
	ifile2g = OPEN ("type2g.dat", $$RD)
	ifile3g = OPEN ("type3g.dat", $$RD)
	ifile4g = OPEN ("type4g.dat", $$RD)
	ifile5g = OPEN ("type5g.dat", $$RD)
'
	PRINT
	PRINT "   --------------------------------- "
	PRINT
'
	IF (ifile0d > 2) THEN Print (LOF(ifile0d))
	IF (ifile1d > 2) THEN Print (LOF(ifile1d))
	IF (ifile2d > 2) THEN Print (LOF(ifile2d))
	IF (ifile3d > 2) THEN Print (LOF(ifile3d))
	IF (ifile4d > 2) THEN Print (LOF(ifile4d))
	IF (ifile5d > 2) THEN Print (LOF(ifile5d))
'
	IF (ifile0g > 2) THEN Print (LOF(ifile0g))
	IF (ifile1g > 2) THEN Print (LOF(ifile1g))
	IF (ifile2g > 2) THEN Print (LOF(ifile2g))
	IF (ifile3g > 2) THEN Print (LOF(ifile3g))
	IF (ifile4g > 2) THEN Print (LOF(ifile4g))
	IF (ifile5g > 2) THEN Print (LOF(ifile5g))
'
' make them half as big as before - so READ only reads half the data written
'
  DIM type0[1]
  DIM type1[1]
  DIM type2[1]
  DIM type3[1]
	DIM type4[1]
	DIM type5[1]
'
  DIM #globaltype0[1]
  DIM #globaltype1[1]
  DIM #globaltype2[1]
  DIM #globaltype3[1]
	DIM #globaltype4[1]
	DIM #globaltype5[1]
'
	IF (ifile0d > 2) THEN READ [ifile0d], type0[]
	IF (ifile1d > 2) THEN READ [ifile1d], type1[]
	IF (ifile2d > 2) THEN READ [ifile2d], type2[]
	IF (ifile3d > 2) THEN READ [ifile3d], type3[]
	IF (ifile4d > 2) THEN READ [ifile4d], type4[]
	IF (ifile5d > 2) THEN READ [ifile5d], type5[]
'
	IF (ifile0g > 2) THEN READ [ifile0g], #globaltype0[]
	IF (ifile1g > 2) THEN READ [ifile1g], #globaltype1[]
	IF (ifile2g > 2) THEN READ [ifile2g], #globaltype2[]
	IF (ifile3g > 2) THEN READ [ifile3g], #globaltype3[]
	IF (ifile4g > 2) THEN READ [ifile4g], #globaltype4[]
	IF (ifile5g > 2) THEN READ [ifile5g], #globaltype5[]
'
	CLOSE (-1)		' close ALL files
'
	PRINT
	Print (UBOUND(type0[]))
	Print (UBOUND(type1[]))
	Print (UBOUND(type2[]))
	Print (UBOUND(type3[]))
	Print (UBOUND(type4[]))
	Print (UBOUND(type5[]))
'
	Print (UBOUND(#globaltype0[]))
	Print (UBOUND(#globaltype1[]))
	Print (UBOUND(#globaltype2[]))
	Print (UBOUND(#globaltype3[]))
	Print (UBOUND(#globaltype4[]))
	Print (UBOUND(#globaltype5[]))
'
	PRINT
	PRINT
	PRINT "    "; type5[0].a
	PRINT "   "; type5[1].e
	PRINT
	PRINT "    "; #globaltype5[0].a
	PRINT "   "; #globaltype5[1].e
	PRINT
'
  Print (LEN(TYPE0))	: Print (LEN(type0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(type0[]))	: PRINT "   TYPE0[1]"
  Print (LEN(TYPE1))	: Print (LEN(type1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(type1[]))	: PRINT "   TYPE1[1]"
  Print (LEN(TYPE2))	: Print (LEN(type2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(type2[]))	: PRINT "   TYPE2[1]"
  Print (LEN(TYPE3))	: Print (LEN(type3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(type3[]))	: PRINT "   TYPE3[1]"
  Print (LEN(TYPE4))	: Print (LEN(type4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(type4[]))	: PRINT "   TYPE4[1]"
  Print (LEN(TYPE5))	: Print (LEN(type5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(type5[]))	: PRINT "   TYPE5[1]"
'
  Print (LEN(TYPE0))	: Print (LEN(#globaltype0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(#globaltype0[]))	: PRINT "   #globalTYPE0[1]"
  Print (LEN(TYPE1))	: Print (LEN(#globaltype1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(#globaltype1[]))	: PRINT "   #globalTYPE1[1]"
  Print (LEN(TYPE2))	: Print (LEN(#globaltype2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(#globaltype2[]))	: PRINT "   #globalTYPE2[1]"
  Print (LEN(TYPE3))	: Print (LEN(#globaltype3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(#globaltype3[]))	: PRINT "   #globalTYPE3[1]"
  Print (LEN(TYPE4))	: Print (LEN(#globaltype4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(#globaltype4[]))	: PRINT "   #globalTYPE4[1]"
  Print (LEN(TYPE5))	: Print (LEN(#globaltype5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(#globaltype5[]))	: PRINT "   #globalTYPE5[1]"
'
	PRINT
	PRINT "  Now print #globaltype[] arrays again from"
	PRINT "  another function to make sure they're shared."
	PRINT
	PrintGlobalTypes()
'
	PRINT
	PRINT "   #####  end  #####"
	PRINT
END FUNCTION
'
'
' ######################
' #####  Print ()  #####
' ######################
'
FUNCTION  Print (value)
'
	PRINT FORMAT$ ("  ####", value);
END FUNCTION
'
'
' #################################
' #####  PrintGlobalTypes ()  #####
' #################################
'
FUNCTION  PrintGlobalTypes ()
'
  Print (LEN(TYPE0))	: Print (LEN(#globaltype0[]))	: Print (SIZE(TYPE0))	: Print (SIZE(#globaltype0[]))	: PRINT "   #globalTYPE0[1]"
  Print (LEN(TYPE1))	: Print (LEN(#globaltype1[]))	: Print (SIZE(TYPE1))	: Print (SIZE(#globaltype1[]))	: PRINT "   #globalTYPE1[1]"
  Print (LEN(TYPE2))	: Print (LEN(#globaltype2[]))	: Print (SIZE(TYPE2))	: Print (SIZE(#globaltype2[]))	: PRINT "   #globalTYPE2[1]"
  Print (LEN(TYPE3))	: Print (LEN(#globaltype3[]))	: Print (SIZE(TYPE3))	: Print (SIZE(#globaltype3[]))	: PRINT "   #globalTYPE3[1]"
  Print (LEN(TYPE4))	: Print (LEN(#globaltype4[]))	: Print (SIZE(TYPE4))	: Print (SIZE(#globaltype4[]))	: PRINT "   #globalTYPE4[1]"
  Print (LEN(TYPE5))	: Print (LEN(#globaltype5[]))	: Print (SIZE(TYPE5))	: Print (SIZE(#globaltype5[]))	: PRINT "   #globalTYPE5[1]"
END FUNCTION
END PROGRAM

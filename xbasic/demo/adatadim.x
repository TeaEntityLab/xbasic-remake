'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"adatadim"
VERSION	"0.0001"
'
IMPORT	"xst"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	DIM a[]
	DIM b[3]
	DIM c[4,5]
	DIM d[5,6,7]
'
	XstGetApplicationEnvironment (@standalone, @reserved)
'
	a0 = 9
	b0 = 9 : b1 = 9
	c0 = 9 : c1 = 9 : c2 = 9
	d0 = 9 : d1 = 9 : d2 = 9 : d3 = 9
'
	SWAP a[], z[]
	a0 = XstIsDataDimension(@z[])
	SWAP a[], z[]
'
	SWAP b[], z[]
	b0 = XstIsDataDimension(@z[])
	SWAP b[], z[]
'
	IF standalone THEN
		SWAP b[1,], z[]
		b1 = XstIsDataDimension(@z[])
		SWAP b[1,], z[]
	END IF
'
	SWAP c[], z[]
	c0 = XstIsDataDimension(@z[])
	SWAP c[], z[]
'
	SWAP c[1,], z[]
	c1 = XstIsDataDimension(@z[])
	SWAP c[1,], z[]
'
	IF standalone THEN
		SWAP c[1,2,], z[]
		c2 = XstIsDataDimension(@z[])
		SWAP c[1,2,], z[]
	END IF
'
	SWAP d[], z[]
	d0 = XstIsDataDimension(@z[])
	SWAP d[], z[]
'
	SWAP d[1,], z[]
	d1 = XstIsDataDimension(@z[])
	SWAP d[1,], z[]
'
	SWAP d[1,2,], z[]
	d2 = XstIsDataDimension(@z[])
	SWAP d[1,2,], z[]
'
	IF standalone THEN
		SWAP d[1,2,3,], z[]
		d3 = XstIsDataDimension(@z[])
		SWAP d[1,2,3,], z[]
	END IF
'
	PRINT a0
	PRINT b0, b1
	PRINT c0, c1, c2
	PRINT d0, d1, d2, d3
	a$ = INLINE$ ("press enter to terminate ===>> ")
END FUNCTION
END PROGRAM

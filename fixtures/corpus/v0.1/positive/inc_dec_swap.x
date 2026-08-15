VERSION "0.1"
FUNCTION Main
DIM a
DIM b
DIM s$
DIM t$
a = 10
b = 20
INC a
PRINT a
DEC b
PRINT b
SWAP a, b
PRINT a
PRINT b
s$ = "first"
t$ = "second"
SWAP s$, t$
PRINT s$
PRINT t$
END FUNCTION

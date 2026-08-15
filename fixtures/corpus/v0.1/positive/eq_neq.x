VERSION "0.1"
FUNCTION Main
' Test == and != comparison operators
PRINT 1 == 1
PRINT 1 == 2
PRINT 1 != 2
PRINT 1 != 1
PRINT 5 == 5
PRINT 5 != 3
DIM x
x = 42
IF (x == 42) THEN PRINT "match"
IF (x != 0) THEN PRINT "nonzero"
END FUNCTION

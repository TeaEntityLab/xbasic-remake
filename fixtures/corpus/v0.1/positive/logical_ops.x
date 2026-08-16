FUNCTION Main
' Test logical operators && || ^^
PRINT 1 && 1
PRINT 1 && 0
PRINT 0 || 1
PRINT 0 || 0
PRINT 1 ^^ 0
PRINT 1 ^^ 1
DIM a
DIM b
a = 5
b = 3
IF a > 0 && b > 0 THEN PRINT "both"
IF a > 10 || b > 0 THEN PRINT "one"
END FUNCTION

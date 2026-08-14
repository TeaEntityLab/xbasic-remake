FUNCTION Identity(x)
RETURN x
END FUNCTION
VERSION "0.1"
FUNCTION Main
DIM plain
DIM percent%
DIM single!
DIM double#
DIM text$
plain = 7
percent% = 0x2A
single! = 1.5
double# = 2e2
text$ = "symbol"
PRINT 9
PRINT 0x10
PRINT 3.25
PRINT 4e1
PRINT "literal"
PRINT plain
PRINT percent%
PRINT single!
PRINT double#
PRINT text$
IF 1 THEN
PRINT "branch"
END IF
IF 1 = 1 THEN
PRINT "compare"
PRINT Identity(42)
PRINT 3 + 4 * 2
WHILE plain > 0
plain = plain - 1
WEND
END IF
END FUNCTION

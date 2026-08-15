VERSION "0.1"
FUNCTION Main
DIM x
DIM y
x = 5
y = 0
IF x > 3 THEN PRINT "big"
IF x < 3 THEN PRINT "small"
IF x > 3 THEN y = 10
IF x < 3 THEN y = 20
PRINT y
IF x > 3 THEN PRINT "a" : PRINT "b"
PRINT "done"
END FUNCTION

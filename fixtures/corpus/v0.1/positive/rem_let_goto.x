VERSION "0.1"
FUNCTION Main
REM This is a REM comment
DIM x
DIM y
LET x = 10
LET y = 20
REM Another comment
PRINT x + y
IF x > 5 THEN
GOTO skip
PRINT "skipped"
END IF
skip:
PRINT "done"
END FUNCTION

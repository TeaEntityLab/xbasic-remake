VERSION "0.1"
FUNCTION First(a, b)
IF a = b THEN
RETURN a
END IF
RETURN b
END FUNCTION
FUNCTION Main
DIM result
result = First(3, 3)
PRINT result
result = First(3, 4)
PRINT result
END FUNCTION

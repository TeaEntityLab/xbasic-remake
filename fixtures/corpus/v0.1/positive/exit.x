VERSION "0.1"
FUNCTION Main
DIM i
DIM sum
sum = 0
FOR i = 1 TO 100
  IF sum > 10 THEN
    EXIT FOR
  END IF
  sum = sum + i
NEXT i
PRINT sum
END FUNCTION

VERSION "0.1"
FUNCTION Main
DIM i
DIM sum
sum = 0
FOR i = 2 TO 10 STEP 2
  sum = sum + i
NEXT i
PRINT sum
END FUNCTION

VERSION "0.1"
FUNCTION Main
DIM addr
DIM i
FOR i = 1 TO 2
  IF i = 1 THEN
    addr = SUBADDRESS(Double)
  ELSE
    addr = SUBADDRESS(Triple)
  END IF
  GOSUB addr
NEXT i
PRINT "done"
RETURN
Double:
PRINT "doubling"
RETURN
Triple:
PRINT "tripling"
RETURN
END FUNCTION

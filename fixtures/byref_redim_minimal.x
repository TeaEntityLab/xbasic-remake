VERSION "0.1"
DECLARE FUNCTION Grow (@a[], newsize)
FUNCTION Main
  DIM a[2]
  a[0] = 5
  a[1] = 6
  a[2] = 7
  Grow(@a[], 5)
  PRINT "ub="; UBOUND(a[])
  FOR i = 0 TO UBOUND(a[])
    PRINT "a"; i; "="; a[i]
  NEXT
END FUNCTION
FUNCTION Grow (@a[], newsize)
  REDIM a[newsize]
  a[newsize] = 99
END FUNCTION

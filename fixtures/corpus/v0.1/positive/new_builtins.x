VERSION "0.1"
FUNCTION Main
  DIM n
  n = 42
  PRINT STRING$(n)
  PRINT STRING(n)
  PRINT SQRT(16.0)
  PRINT CHR$(65, 3)
  PRINT INSTR("hello world", "world", 1)
  DIM a, b, c
  a = 5
  b = 3
  c = a XOR b
  PRINT c
END FUNCTION

VERSION "0.1"
FUNCTION Main
DIM line$
DIM count
count = 0
WHILE EOF() = 0
  line$ = READLINE$()
  IF EOF() = 0 THEN
    count = count + 1
    PRINT line$
  END IF
WEND
PRINT STR$(count)
END FUNCTION

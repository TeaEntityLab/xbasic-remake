VERSION "0.1"
FUNCTION Main
DIM ttype$
DIM tval$
DIM pos
DIM line$

WHILE EOF() = 0
  line$ = READLINE$()
  pos = INSTR(line$, ",")
  IF pos > 0 THEN
    ttype$ = LEFT$(line$, pos - 1)
    tval$ = MID$(line$, pos + 1, LEN(line$) - pos)
  ELSE
    ttype$ = line$
    tval$ = ""
  END IF

  IF ttype$ = "keyword" AND tval$ = "VERSION" THEN
    line$ = READLINE$()
    pos = INSTR(line$, ",")
    tval$ = MID$(line$, pos + 1, LEN(line$) - pos)
    PRINT "version " + tval$
  ELSEIF ttype$ = "keyword" AND tval$ = "DIM" THEN
    line$ = READLINE$()
    pos = INSTR(line$, ",")
    tval$ = MID$(line$, pos + 1, LEN(line$) - pos)
    PRINT "dim " + tval$
  ELSEIF ttype$ = "keyword" AND tval$ = "PRINT" THEN
    PRINT "print ..."
  ELSEIF ttype$ = "newline" THEN
    PRINT ""
  ELSE
    PRINT ttype$ + ":" + tval$
  END IF
WEND
END FUNCTION

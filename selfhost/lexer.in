VERSION "0.1"
FUNCTION Main
DIM src$
DIM line$
DIM pos
DIM ch
DIM tok$
DIM tokType$
DIM done

src$ = ""
WHILE EOF() = 0
  line$ = READLINE$()
  IF EOF() = 0 THEN
    src$ = src$ + line$ + CHR$(10)
  ELSE
    src$ = src$ + line$
  END IF
WEND

pos = 1

WHILE pos <= LEN(src$)
  ch = ASC(MID$(src$, pos, 1))
  IF ch = 32 OR ch = 9 OR ch = 13 THEN
    pos = pos + 1
  ELSEIF ch = 10 THEN
    PRINT "newline,"
    pos = pos + 1
  ELSEIF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) THEN
    tok$ = ""
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) OR (ch >= 48 AND ch <= 57) OR ch = 36 OR ch = 37 THEN
          tok$ = tok$ + CHR$(ch)
          pos = pos + 1
        ELSE
          done = 1
        END IF
      END IF
    WEND
    tokType$ = "ident"
    IF tok$ = "PRINT" OR tok$ = "IF" OR tok$ = "THEN" OR tok$ = "ELSE" OR tok$ = "END" THEN
      tokType$ = "keyword"
    ELSEIF tok$ = "FUNCTION" OR tok$ = "DIM" OR tok$ = "FOR" OR tok$ = "TO" OR tok$ = "NEXT" THEN
      tokType$ = "keyword"
    ELSEIF tok$ = "WHILE" OR tok$ = "WEND" OR tok$ = "RETURN" OR tok$ = "AND" OR tok$ = "OR" THEN
      tokType$ = "keyword"
    ELSEIF tok$ = "NOT" OR tok$ = "EXIT" OR tok$ = "ELSEIF" OR tok$ = "VERSION" THEN
      tokType$ = "keyword"
    END IF
    PRINT tokType$ + "," + tok$
  ELSEIF (ch >= 48 AND ch <= 57) THEN
    tok$ = ""
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF (ch >= 48 AND ch <= 57) OR ch = 46 THEN
          tok$ = tok$ + CHR$(ch)
          pos = pos + 1
        ELSE
          done = 1
        END IF
      END IF
    WEND
    PRINT "number," + tok$
  ELSEIF ch = 34 THEN
    tok$ = ""
    pos = pos + 1
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF ch = 34 THEN
          pos = pos + 1
          done = 1
        ELSE
          tok$ = tok$ + CHR$(ch)
          pos = pos + 1
        END IF
      END IF
    WEND
    PRINT "string," + tok$
  ELSE
    PRINT "symbol," + CHR$(ch)
    pos = pos + 1
  END IF
WEND
END FUNCTION

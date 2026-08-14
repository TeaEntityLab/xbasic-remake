VERSION "0.1"
FUNCTION Main
DIM src$
DIM pos
DIM ch
DIM tok$
DIM tokType$
DIM tokens$(32)
DIM tokTypes$(32)
DIM ntok
DIM i
DIM done

src$ = "PRINT 42"
pos = 1
ntok = 0

WHILE pos <= LEN(src$)
  ch = ASC(MID$(src$, pos, 1))
  IF ch = 32 THEN
    pos = pos + 1
  ELSE
    tok$ = ""
    tokType$ = ""
    IF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) THEN
      tokType$ = "ident"
      done = 0
      WHILE done = 0
        IF pos > LEN(src$) THEN
          done = 1
        ELSE
          ch = ASC(MID$(src$, pos, 1))
          IF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) OR (ch >= 48 AND ch <= 57) THEN
            tok$ = tok$ + CHR$(ch)
            pos = pos + 1
          ELSE
            done = 1
          END IF
        END IF
      WEND
      tokens$(ntok) = tok$
      tokTypes$(ntok) = tokType$
      ntok = ntok + 1
    ELSE
      IF (ch >= 48 AND ch <= 57) THEN
        tokType$ = "number"
        done = 0
        WHILE done = 0
          IF pos > LEN(src$) THEN
            done = 1
          ELSE
            ch = ASC(MID$(src$, pos, 1))
            IF ch >= 48 AND ch <= 57 THEN
              tok$ = tok$ + CHR$(ch)
              pos = pos + 1
            ELSE
              done = 1
            END IF
          END IF
        WEND
        tokens$(ntok) = tok$
        tokTypes$(ntok) = tokType$
        ntok = ntok + 1
      ELSE
        tok$ = CHR$(ch)
        tokType$ = "symbol"
        tokens$(ntok) = tok$
        tokTypes$(ntok) = tokType$
        ntok = ntok + 1
        pos = pos + 1
      END IF
    END IF
  END IF
WEND

FOR i = 0 TO ntok - 1
  PRINT tokens$(i)
  PRINT tokTypes$(i)
NEXT i
END FUNCTION

VERSION "0.1"
FUNCTION Main
DIM s$
DIM p
DIM n
DIM r$
s$ = "Hello,World"
p = INSTR(s$, ",")
PRINT p
n = VAL("42")
PRINT n
r$ = STR$(n)
PRINT r$
p = INSTR(s$, "xyz")
PRINT p
END FUNCTION

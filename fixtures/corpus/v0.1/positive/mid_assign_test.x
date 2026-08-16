VERSION "0.1"
FUNCTION Main
DIM x$
DIM y$
x$ = "This lazy man"
y$ = "is wolf"
MID$(x$, 6, 5) = y$
PRINT x$
x$ = "This lazy man"
MID$(x$, 6) = y$
PRINT x$
PRINT ISDATA(x$)
PRINT ISNODE(x$)
END FUNCTION

VERSION "0.1"
DIM topMessage$
topMessage$ = "top"
PRINT topMessage$
FUNCTION main
PRINT "lowercase main must not run"
END FUNCTION
FUNCTION Helper
PRINT "helper must not run"
END FUNCTION
FUNCTION Main
DIM mainMessage$
mainMessage$ = "main"
PRINT mainMessage$
END FUNCTION

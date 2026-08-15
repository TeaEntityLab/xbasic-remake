VERSION "0.1"
SUB Greet(name$)
PRINT "Hello "; name$
END SUB
SUB Add(a, b)
PRINT a + b
END SUB
FUNCTION Main
Greet("World")
Add(3, 4)
END FUNCTION

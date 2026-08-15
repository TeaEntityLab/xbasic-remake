VERSION "0.1"
FUNCTION Main
' Test STUFF$ 3-arg and 4-arg forms
PRINT STUFF$("This lazy man", "flabberghast", 6, 4)
PRINT STUFF$("This lazy man", "flabberghast", 6)
PRINT STUFF$("This lazy man", "is wolf", 6)
PRINT STUFF$("This lazy man", "is wolf", 6, 5)
PRINT STUFF$("hello world", "XYZ", 1)
PRINT STUFF$("hello world", "XYZ", 1, 2)
END FUNCTION

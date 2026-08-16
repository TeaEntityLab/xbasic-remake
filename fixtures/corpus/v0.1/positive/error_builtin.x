FUNCTION Main
' Test ERROR/ERROR$ builtins
DIM e
' ERROR(0) gets current error (0 initially) and clears it
e = ERROR(0)
PRINT e
' ERROR(42) sets error to 42, returns old value (0)
e = ERROR(42)
PRINT e
' ERROR(0) gets current error (42) and clears it
e = ERROR(0)
PRINT e
' ERROR$ converts error number to string
PRINT ERROR$(42)
PRINT ERROR$(0)
END FUNCTION

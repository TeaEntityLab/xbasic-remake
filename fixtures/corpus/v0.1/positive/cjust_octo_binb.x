FUNCTION Main
' CJUST$: center-justify string in field
PRINT CJUST$("cat", 7)
PRINT CJUST$("cat", 8)
PRINT CJUST$("catamaran", 3)
PRINT CJUST$("xxx", 9)
' OCTO$: octal with 0o prefix
PRINT OCTO$(255)
PRINT OCTO$(255, 12)
' BINB$: binary with 0b prefix
PRINT BINB$(255)
PRINT BINB$(255, 12)
' 2-arg BIN$ and OCT$ (no prefix)
PRINT BIN$(255, 12)
PRINT OCT$(255, 12)
' SIGN: returns 1 for >=0, -1 for <0
PRINT SIGN(3.14)
PRINT SIGN(0.0)
END FUNCTION

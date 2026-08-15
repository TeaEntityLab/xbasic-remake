VERSION "0.1"
FUNCTION Main
PRINT INSTRI("Hello World", "world")
PRINT INSTRI("Hello World", "world", 8)
PRINT RINSTRI("Hello World Hello", "hello")
PRINT RINSTRI("abcABCabc", "abc", 5)
PRINT INSTRI("abcABC", "abc")
PRINT INSTRI("abcABC", "xyz")
END FUNCTION

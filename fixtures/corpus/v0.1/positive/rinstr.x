VERSION "0.1"
FUNCTION Main
PRINT RINSTR("hello world hello", "hello")
PRINT RINSTR("abcabcabc", "bc")
PRINT RINSTR("hello world", "xyz")
PRINT RINSTR("a/b/c/d", "/", 5)
END FUNCTION

VERSION "0.1"
FUNCTION Main
' Test 2-arg MID$ (substring from start to end)
PRINT MID$("hello world", 7)
PRINT MID$("hello", 2)
PRINT MID$("abc", 1)
PRINT MID$("abc", 5)
PRINT MID$("hello", 3)
' 3-arg MID$ still works
PRINT MID$("hello world", 1, 5)
PRINT MID$("hello", 2, 3)
END FUNCTION

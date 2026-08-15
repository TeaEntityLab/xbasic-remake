VERSION "0.1"
FUNCTION Main
' Test RCLIP$, LCLIP$, INCHR, RINCHR
PRINT RCLIP$("hello", 2)
PRINT RCLIP$("  hi  ")
PRINT LCLIP$("hello", 2)
PRINT LCLIP$("  hi  ")
PRINT INCHR("hello world", "aeiou", 1)
PRINT RINCHR("hello world", "aeiou", 11)
PRINT INCHR("hello", "xyz", 1)
PRINT RINCHR("hello", "xyz", 5)
END FUNCTION

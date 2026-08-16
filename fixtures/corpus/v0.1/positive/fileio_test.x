PROGRAM "fileio_test"
VERSION "0.1"
FUNCTION Main
DIM fn
DIM line$
SHELL("echo hello > /tmp/xb_fileio_test.txt")
fn = OPEN("/tmp/xb_fileio_test.txt", 0)
PRINT fn
line$ = INFILE$(fn)
PRINT line$
PRINT LOF(fn)
PRINT POF(fn)
SEEK(fn, 0)
line$ = INFILE$(fn)
PRINT line$
CLOSE(fn)
END FUNCTION

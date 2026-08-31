# Note: you need Microsoft Visual C++ (e.g. V5.0) to build mkxbvar.exe
all: mkxbvar.exe

CC=cl
CFLAGS=-W3
LD=link
LDFLAGS=-subsystem:windows

mkxbvar.exe: mkxbvar.obj
	$(LD) $(LDFLAGS) mkxbvar.obj user32.lib

mkxbvar.obj: mkxbvar.c
	$(CC) -c $(CFLAGS) mkxbvar.c

clean:
	-del *.obj
	-del *.exe

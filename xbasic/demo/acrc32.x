'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"crc32"
VERSION	"0.0002"
'
IMPORT	"xst"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	ULONG table[]
	ULONG sum, filenum, n, a, b, magic
	UBYTE i, j, c
'
	DIM table[255]
	magic = 0xEDB88320
'
' NOTE: Before XBasic v5.0021 the line with "XOR 0xEDB88320"
' did not work properly because spasm generated the wrong
' binary machine instruction for XOR with immediate value.
' A new version of "spasm" is included with v5.0021 XBasic.
'
	FOR j = 0 TO 255
		sum = j
		FOR i = 0 TO 7
			IF (sum AND 1) THEN
				rum = sum
				sum = (sum >> 1) XOR magic
				bum = (rum >> 1) XOR 0xEDB88320
				IF (sum != bum) THEN PRINT "sum : bum = "; HEX$(sum,8); " : "; HEX$(bum,8)
			ELSE
				sum = (sum >> 1)
			END IF
		NEXT i
		table[j] = sum
		PRINT "table[" j "]=" HEXX$(sum)
	NEXT j
'
	filename$ = INLINE$("Enter file name ==>> ")
	filenum = OPEN( filename$ , $$RD)
	crc32 = 0xFFFFFFFF
	n = 0
'
	XstGetSystemTime(@a)
'
	DO
		READ [filenum], c
		INC n
		crc32 = table[(crc32 XOR c) AND 0xFF] XOR (crc32>>8)
	LOOP UNTIL EOF(filenum)
'
	crc32 = crc32 XOR 0xFFFFFFFF
	XstGetSystemTime(@b)
'
	PRINT
	PRINT "CRC32 = " HEX$(crc32) " : file size= " n " bytes : time ="; (b-a); " msecs"
  filename$ = INLINE$("\n press enter to terminate")
END FUNCTION
END PROGRAM

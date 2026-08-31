'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"zap"
VERSION	"0.0033"
'
IMPORT	"xst"
'
' This program was contributed by an XBasic programmer.  This program
' is not similar to other compression programs or algorithms except by
' coincidence, so this program will not decompress files compressed by
' any other program or utility.  You are free to snarf any part or all
' of this program for any purpose whatever with the understanding that
' this program may contain bugs and no person or entity represents the
' code in this program as suitable for any purpose whatever.  You are
' fully responsible for any use of this program and no other person is
' responsible or liable in any way under any circumstances.
'
' If you improve the Implode() and/or Explode() functions in the program
' to achieve greater compression of text and binary files, we encourage
' you to contribute your new and improved routines for future releases.
'
' If you run this program in the environment, the Entry() function fakes
' command line arguments to compress "zap.x" into "zap.zap".  Feel free
' to change "zap.x" and "zap.zap" to other filenames to test this program.
' If the first argument has a ".zap" suffix, this program decompresses,
' otherwise it compresses (unless you insert "-i" or "-o" arguments).
'
' If this program is compiled to a binary executable program (not library),
' execution begins in the Entry() function which looks at the command line
' arguments for the following arguments:
'
'   zap [-i] [-o] infilename outfilename
'
' "zap" is the name of the program
' "-i" means "Implode" or compress the non-compressed "infilename" file
'      to create the compressed "outfilename"
' "-e" means "Explode" or decompress the compressed "infilename" file
'      to create the uncompressed "outfilename"
' the "-i" and "-e" switches are not necessary since zap recognizes
'      already compressed files from a "zap" header in the file
'
' If this program is compiled to a object/binary library (not program),
' the entry function does nothing.  To compress data your program calls
' Implode(), and to decompress data your program calls Explode().
' Alternatively you can copy all functions in this program except Entry()
' into your program and declare all functions with INTERNAL FUNCTION.
'
'
'
' Compress data.  Transfer data to result array:
'   1. Compress strings that already occured in the data into offset and length.
'   2. Compress strings of repeated bytes, like  "##########", into length and byte.
'   3. Insert uncompressable bytes 0x00 to 0xFF as 0x000 to 0x0FF.
'   4. Insert uncompressable strings >= 4 bytes after header and length.
'
' data in file.zap - what it means (after initial 8 to 16 bytes header)
'
'   0x000 to 0x0FF - a byte with the same value as the 12-bit value.
'   0x100 to 0xFDF - relative offset to the byte after the end of a
'                    string of bytes to insert at the current location.
'                    0x0100 is subtracted from the 12-bit value to get
'                    the actual offset.  A 12-bit value of 0x100 is
'                    therefore an offset of 0x000 and refers to a
'                    string of bytes whose last byte is the byte
'                    before the current location.
'                    Following every relative offset is a 4-bit value
'                    that specifies the length of the string to insert
'                    at the current location, except that 3 is added
'                    to this value to get the actual string length.
'                    The length can be 0x0 = 3 to 0xF = 18 bytes.
'   0xFE0 to 0xFF7 - string of literal bytes stored as inverted bytes
'                    where the length is (header - 0xFE0 + 4), where
'                    header is 0xFE0 to 0xFF7 (4 to 27 bytes).
'            0xFFC - string of literal bytes stored as inverted bytes
'                    followed by an 8-bit length (0-255 mean 16-271)
'                    followed by the bytes (inverted by NOT operator)
'            0xFF8 - reserved
'            0xFF9 - reserved
'            0xFFA - says the following 12-bit value is the same as the
'                    0x100 to 0xFDF case except the length is 8-bit,
'                    and the offset is not adjusted by 0x100.
'            0xFFB - says the following 12-bit value is the same as the
'                    0x100 to 0xFDF case except the length is 12-bit.
'                    and the offset is not adjusted by 0x100.
'            0xFFD - string of identical bytes
'                    followed by an 4-bit length (0-15 means 3-18)
'                    followed by repeated byte
'            0xFFE - string of identical bytes
'                    followed by an 8-bit length (0-255 means 16-271)
'                    followed by repeated byte
'            0xFFF - end of file
'
'
INTERNAL FUNCTION  Entry       ()
INTERNAL FUNCTION  GetPrefix   (@prefix$)
INTERNAL FUNCTION  GetString   (addr, bytes, @string$)
'
EXPORT
DECLARE FUNCTION  CommandLine (UBYTE @i[], @ofile, @ilength, @direction, @version)
DECLARE FUNCTION  Implode (addr, bytes, @count, @version, UBYTE @data[])
DECLARE FUNCTION  Explode (addr, bytes, @count, @version, UBYTE @data[])
END EXPORT
EXTERNAL FUNCTION  XstFindMemoryMatch (@start, after, match, min, max)
'
$$Version     =    2  ' non-zero algorithm version # follows "zap" signature
$$MatchMin    =    3
$$MatchMax    =   18
$$MatchMax4   =   18
$$MatchMax8   =  274
$$MatchMax12  = 4370

$$Reference   = 4096
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	UBYTE  i[]
	UBYTE  o[]
'
' Define codes relative to #Basis so only #Basis
' needs to be changed to change the code size from
' the current 12-bits to other values - generally
' in the 9-bit to 12-bit range.
'
	#Basis						= 0x1000				' 0x1000 = 4096
	#RelativeBase			= 0x0100				' 0x0100 =  256
	#RelativeMax			= #Basis - 33		' 0x0FDF = 4063
	#CodeLiteral4			= #Basis - 32		' 0x0FE0 = 4064
	#CodeLiteral8			= #Basis -  8		' 0x0FF8 = 4088
	#CodeReserved0		= #Basis -  7		' 0x0FF9 = 4089
	#CodeRelative8		= #Basis -  6		' 0x0FFA = 4090
	#CodeRelative12		= #Basis -  5		' 0x0FFB = 4091
	#CodeRunLength4		= #Basis -  4		' 0x0FFC = 4092
	#CodeRunLength8		= #Basis -  3		' 0x0FFD = 4093
	#CodeReserved1		= #Basis -  2		' 0x0FFE = 4094
	#CodeEndOfFile		= #Basis -  1		' 0x0FFF = 4095
'
'
' if compiled as a library, this function does nothing
'
	IF LIBRARY (0) THEN RETURN
'
' to run in environment to test, the following section sets up
' the command line arguments to look like the zap program was
' executed with two arguments.  you can test on various files
' by changing argv$[1] and argv$[2].
'
	XstGetApplicationEnvironment (@standalone, @extra)
'
' if running in the environment, fake command line arguments to test
'
' pass = 0 compresses "zap.x" into "zap.zap"
' pass = 1 decompresses "zap.zap" into "zap.xxx"
'
' 1: run with pass = 0 to create compressed file "zap.zap"
' 2: run with pass = 1 to create uncompressed file "zap.xxx"
' 3: make sure uncompressed file "zap.xxx" is the same as original file "zap.x"
'
	pass = 1
	pass = 0							' comment out second time
'
	IFZ standalone THEN
		IFZ pass THEN
			argc = 4
			DIM argv$[3]
			argv$[0] = "zap"
			argv$[1] = "-i"
			argv$[2] = "/tmp/zap.x"
			argv$[3] = "/tmp/zap.zap"
			XstSetCommandLineArguments (argc, @argv$[])
		ELSE
			argc = 4
			DIM argv$[3]
			argv$[0] = "zap"
			argv$[1] = "-e"
			argv$[2] = "/tmp/zap.zap"
			argv$[3] = "/tmp/zap.xxx"
			XstSetCommandLineArguments (argc, @argv$[])
		END IF
	END IF
'
' normal standalone execution begins below
'
	XstGetSystemTime (@preload)
	error = CommandLine (@i[], @ofile, @ilength, @direction, @version)
	IF error THEN RETURN ($$TRUE)
'
' call the function that implodes or explodes i[] to create o[]
'
	XstGetSystemTime (@first)
	SELECT CASE direction
		CASE 'i'	:	Implode (&i[], ilength, @count, version, @o[])
		CASE 'e'	:	Explode (&i[], ilength, @count, version, @o[])
		CASE ELSE	: RETURN ($$TRUE)
	END SELECT
	XstGetSystemTime (@final)
	PRINT final-first; " = "; final; " -"; first; " : "; first-preload; " ="; first; " -"; preload
'
	WRITE [ofile], o[]									' save o[] result file
	CLOSE (ofile)
END FUNCTION
'
'
' ##########################
' #####  GetPrefix ()  #####
' ##########################
'
FUNCTION  GetPrefix (prefix$)
'
' short prefix with 3865 bytes
'
'	prefix$ = " whether extracted shortages measurements thoughts exported imported facility sounds fixed lateral stores opens until patrols explorers personal externals interactions internals scales experiences adapters ships surplus classify targets active finds deleted integrated units beginnings minimums overviews regions loads fields ranges respectively forget products surely profiled passed around shared represents determines wasted significantly calling digital usually combinations receives kinds backgrounds wells doubles really pages always records edited loops anything accounts positions focu
'	PRINT LEN (prefix$)
'
' long prefix with 4132 bytes
'
	prefix$ = "once storage true reason close final words much were exceptions continue modify depends incorrect smaller rather elastic inserted validated books goods synchronized governmental typically thus thinks frames consistency furthermore shells essentials notify manipulated whether extracted shortages measurements thoughts exported imported facility sounds fixed lateral stores opens until patrols explorers personal externals interactions internals scales experiences adapters ships surplus classify targets active finds deleted integrated units beginnings minimums overviews regions loads fields ranges respectively forget products surely profiled passed around shared represents determines wasted significantly calling digital usually combinations receives kinds backgrounds wells doubles really pages always records edited loops anything accounts positions focuses results arguments various converts path eventually knowledge accumulates worlds insiders left increases searchers bytes obtains executes symbols earlier rectangles checks dialogs reality templates actually disable wants helpful collections techniques cases immediately apparatus providers indicates viewers effects downstream threesome rotates patents sensations monitors visible itself invents tests during customs contextual statements children individuals levels sizes keyboards pictures technology means mighty pixels steps enhanced indentical certainly calculated interfaces many longer appearances shows partners sequences headers spaces working seconds groups iterates namesake sends contents given couldn't probably mental aspects such items panels still completed two boxed themselves foundation details below blocks connected promptly universal locations features remotes differences updated basics encoded graphics separates wouldn't quality chapters layers beings binary cannot numbers something directly outlines generally likely toggles bothers locals justice attributes status removes screens brains everywhere sincerely lengthy operations makers videos containers allowances previously printers "
	prefix$ = prefix$ + "lines mostly summary points designers those while scripts accessed drivers utility managers above surroundings dismay exchanged disks corresponds thanks written handles resources errors describes doesn't inputs been perceptions commons questions orders within hastle seen assigns fundamentals automation limited creates throughout they newly textures expressed values formats similar people chooses performs needs includes runs understands existing addresses however necessary correctly lists ones components languages button must related methods originals requires anyone transforms subjects already pleased property granted based notes implements concepts points reserved times extensions directory what clicks comments hardware generic created several instructions library parameters theirs types buildings switches perceptions appropriately devices characters because multiples references installed routines mains options performances entity into copyrights introductions declares singles visuals enters arithmetic additional important where returns before bits sets releases distributed same starts associated modules buffers automatics outputs sections between either each simpler more lines first compress supports after problems colors contacts understands machines compatible selects develops creates compilers variables calls then sources currents settings buttons changes instances purposes changes demonstrates consciousness another names modes users provides builds also documentation defines can values memory used software includes configures strings algorithms only drawings descriptions running codes without defaults therefore images processes supports particulars standards computers coordinates objects when others structures about numbers have these different services data implements controls not contains examples displays commands should specifics are systems using initial which you from available will follows programs functions with messages versions samples files directory for that information this and applications windows the "
'	PRINT LEN (prefix$)
'
' alternatively load the prefix string from a disk file
'
'	zfile = OPEN ("zapwords.txt", $$RD)
'	IF (zfile <= 0) THEN RETURN
'	zlength = LOF (zfile)
'	IF (zlength < 3840) THEN RETURN
'	prefix$ = NULL$ (zlength)
'	READ [zfile], prefix$
'	CLOSE (zfile)
'
'	PRINT "LEN (prefix$) = "; LEN (prefix$)
END FUNCTION
'
'
' ##########################
' #####  GetString ()  #####
' ##########################
'
FUNCTION  GetString (addr, count, string$)
'
	string$ = ""
	IF (count <= 0) THEN RETURN
	string$ = NULL$(count)
'
	FOR d = 0 TO count-1
		string${d} = UBYTEAT(addr)
		INC addr
	NEXT d
END FUNCTION
'
'
' ############################
' #####  CommandLine ()  #####
' ############################
'
' command line syntax
'
'   zap [-i|-e] inputfilename outputfilename"
'
' -i switch means "Implode() aka compress the input file"
' -e switch means "Explode() aka decompress the input file"
' if no switch given, figure out implode vs explode from file header
'
' CommandLine() gets the command line arguments, gets the data
' from the input file into UBYTE array i[], determines direction
' of operation (implode vs explode), and returns these results.
'
' if input file is a compressed file with a "zap" signature,
' version is the algorithm version taken from the input file.
'
'
FUNCTION  CommandLine (UBYTE i[], ofile, ilength, direction, version)
'
	DIM i[]															' return no data unless read in
	ofile$ = ""													' return no ofile$ unless found
	version = 0													' return no version unless found
	direction = 0												' return no direction unless found
'
	XstGetCommandLineArguments (@argc, @argv$[])		' get command line
'
' get [-switch], inputfilename, outputfilename from command line
'
	IF (argc > 1) THEN
		FOR i = 1 TO argc-1								' for all command line arguments
			arg$ = TRIM$(argv$[i])					' get next argument
			IF arg$ THEN										' if not empty
				char = arg${0}								' get 1st byte
				IF (char = '-') THEN					' command line switch?
					next = arg${1}									' get switch character
					SELECT CASE next								' which switch?
						CASE 'i'	: direction = 'i'		' implode = compress
						CASE 'e'	: direction = 'e'		' explode = decompress
					END SELECT
				ELSE													' not a switch argument
					IFZ ifile$ THEN							' if 1st filename not yet given
						ifile$ = arg$							' get 1st filename aka source file
					ELSE
						IFZ ofile$ THEN						' if 2nd filename not yet given
							ofile$ = arg$						' get 2nd filename aka result file
						END IF
					END IF
				END IF
			END IF
		NEXT i
	END IF
'
' see if we have valid input file and output filename : read input file
'
	IF ifile$ THEN											' need input filename
		IF ofile$ THEN										' and output filename
			ifile = OPEN (ifile$, $$RD)
			IF (ifile <= 0) THEN RETURN			' can't open input filename
			ilength = LOF (ifile)						' input filename length
			IF (ilength <= 0) THEN					' bogus file
				CLOSE (ifile)
				RETURN (1)
			END IF
			upper = ilength-1
			DIM i[upper]
			READ [ifile], i[]								' read input file into i[]
			CLOSE (ifile)
			IF (upper >= 8) THEN						' zap file head is 8+ bytes
				IF (i[0] = 'z') THEN
					IF (i[1] = 'a') THEN
						IF (i[2] = 'p') THEN			' "zap" begins compressed files
							IFZ direction THEN			' if direction is not specified
								direction = 'e'				' explode already compressed files
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	END IF
'
	IF (direction = 'e') THEN						' Explode() this "zap" file
		version = i[3]										' get zap.x version number
	ELSE																' no "zap" header, so compress
		version = $$Version								' algorithm version number
		direction = 'i'										' say Implode()
	END IF
'
	IF i[] THEN													' if we have input data
		IF ofile$ THEN										' if we have output filename
			ofile = OPEN (ofile$, $$WRNEW)	' open output file
			IF (ofile > 0) THEN							' if output file opened okay
				RETURN ($$FALSE)							' then return arguments - no error
			END IF
		END IF
	END IF
'
' an error occured, clear out arguments and return error = $$TRUE
'
	DIM i[]															' no input data
	version = 0													' invalid version
	direction = 0												' invalid direction
	IF (ofile > 0) THEN									' output file open?
		CLOSE (ofile)											' close output file
		ofile = 0													' clear argument
	END IF
	RETURN ($$TRUE)											' error = $$TRUE
END FUNCTION
'
'
' ########################
' #####  Implode ()  #####
' ########################
'
FUNCTION  Implode (addr, bytes, count, version, UBYTE o[])
	SHARED  words$
	UBYTE  i[]
'
	DIM o[]
	count = 0
	length = bytes
	IF (length <= 0) THEN RETURN ($$TRUE)		' error
'
	IFZ words$ THEN GetPrefix (@words$)			' get prefix data
	zlength = LEN(words$)
'
	DIM i[zlength+bytes-1]
	FOR i = 0 TO zlength-1
		i[i] = words${i}											' put prefix data in i[]
	NEXT i
'
	at = addr
	FOR z = zlength TO zlength+bytes-1
		i[z] = UBYTEAT (at)										' append input data to prefix
		INC at
	NEXT z
'
	upper = bytes - 1				'
	count = 0								' result count starts at zero
	addra = addr						' address of first byte to compress
	addrz = addra + upper		' address of last byte to compress
	addra = &i[] + zlength	'
	addrz = addra + upper		'
'
	output = 0							' output data offset
	outhalf = 0							'
	input = addra						' address to get bytes from input data
	DIM o[upper+upper+255]	' let result be up to twice as many bytes
'
	o[0] = 'z'							' signature = "zap"
	o[1] = 'a'							'
	o[2] = 'p'							'
	o[3] = version					' algorithm version # byte
	output = 8							' leave room for length, etc
'
' compress input bytes to create o[]
'
'	XstGetSystemTime (@msa)
'
	DO WHILE (input <= addrz)						' compress all input bytes
		start = input - #Basis + 0x0120		' compute beginning of window
'		IF (start < addra) THEN start = addra		' can't start before beginning
		matchFirst = UBYTEAT (input)			' first byte to match
		matchLength = -1									' no match found yet
		matchIndex = -1										' no match found yet
		index = start											' start at beginning of window
		run = input												' start of runlength check
		runs = 0
'
		DO WHILE (run < addrz)						' don't exceed input data
			INC run													' check next byte
			INC runs												' # of identical bytes
			IF (runs = 258) THEN EXIT DO		' no more than 258 in a row
		LOOP WHILE (UBYTEAT(run) = matchFirst)
'
' look for previous match of $$MatchMin to $$MatchMax bytes
'
		ss = start
		zz = input
		min = $$MatchMin
		max = addrz - input + 1
		IF (max > $$MatchMax12) THEN max = $$MatchMax12
		match = $$FALSE
		DO
			match = XstFindMemoryMatch (@ss, zz, input, @min, @max)
			IF match THEN
				matchLength = min
				matchIndex = ss
				INC min
			END IF
		LOOP WHILE match
'
' the short routine above replaces the following longer/slower routine
'
'		DO WHILE (index <= (input-$$MatchMin))
'			IF (UBYTEAT(index) = matchFirst) THEN
'				l = 0													' length of match = 1
'				a = input											' first byte of match in input
'				b = index											' first byte of match in check
'				DO WHILE (a < addrz)					' match up to end of input data
'					INC a
'					INC b
'					INC l
'					IF (UBYTEAT(a) != UBYTEAT(b)) THEN EXIT DO
'				LOOP WHILE (b < input)
'				IF (l >= $$MatchMin) THEN
'					IF (l > matchLength) THEN
'						matchLength = l
'						matchIndex = index
'						IF (matchLength >= $$MatchMax12) THEN
'							matchLength = $$MatchMax12
'							EXIT DO
'						END IF
'					END IF
'				END IF
'			END IF
'			INC index
'		LOOP
'
		IF (runs > 2) THEN
			IF (matchLength < 0) OR (runs > (matchLength + 1)) THEN
'				INC rrrr : PRINT rrrr;; runs;; matchLength;; HEX$(matchFirst,2)
				IF (ogot >= 4) THEN GOSUB Flush	' store literal string efficiently
				SELECT CASE TRUE
					CASE (runs <= 18)
								data = #CodeRunLength4	' header : runlength encode 3-18 bytes
								GOSUB Out12							' output header
								data = runs - 3					' length = length - 3
								GOSUB Out4							' output length
					CASE (runs <= 271)
								data = #CodeRunLength8	' header : runlength encode 16-271 bytes
								GOSUB Out12							' output header
								data = runs - 16				' length = length - 16
								GOSUB Out8							' output length
					CASE ELSE
								PRINT "Implode() : RunLength : Disaster : (runs > 271)"
				END SELECT
'
				data = matchFirst								' data = repeated byte
				GOSUB Out8											'
				input = input + runs						'
'				PRINT "      got : "; RJUST$(STRING$(runs),6); " consectutive '"; CHR$(matchFirst); "' bytes"
				ogot = 0
				DO LOOP
			END IF
		END IF
'
' find a string that matches bytes at current location
'
		IF (matchLength < $$MatchMin) THEN
			IF (oinput = input) THEN
				IF (ogot >= 270) THEN GOSUB Flush		' flush max length literal
			END IF
			IF (oinput = input) THEN		' repeated individual byte out
				INC ogot									' count repeated individual bytes
			ELSE
				ogot = 1									' no previous got
				iaddr = input							' capture start of individual bytes
				oaddr = output						' capture start of stored bytes
				ohalf = outhalf						' capture half byte state
			END IF
'			PRINT RJUST$("OutByte : ",12); RJUST$(STRING$(upper),6);; RJUST$(STRING$(input-addra),6);; RJUST$(STRING$(output),6);;;;;;;;;;; HEX$(matchFirst,4);;; CHR$(matchFirst)
			data = matchFirst
			GOSUB Out12
			INC input
			INC obs
			oinput = input
		ELSE
			IF (ogot >= 4) THEN GOSUB Flush
			ogot = 0
			GOSUB OutBytes
			input = input + matchLength
		END IF
	LOOP
'
	IF (ogot >= 4) THEN GOSUB Flush
'
	data = #CodeEndOfFile
	GOSUB Out12
	REDIM o[output]
	count = output+1
'	XstGetSystemTime (@msb)
	o[4] = length AND 0x00FF
	o[5] = (length >> 8) AND 0x00FF
	o[6] = (length >> 16) AND 0x00FF
	o[7] = (length >> 24) AND 0x00FF
'
'	PRINT output+1, msb-msa
'	PRINT upper, input-addra, output, outhalf, osave, obs, obsx, obs-obsx
'	PRINT
'
	RETURN ($$FALSE)
'
'
' *****  Flush  *****
'
SUB Flush
	obsx = obsx + ogot
	osave = osave + (ogot - 4)
'	GetString (iaddr, ogot, @i$)
'	PRINT RJUST$("Literals : ",12); RJUST$(STRING$(upper),6);; RJUST$(STRING$(input-addra),6);; RJUST$(STRING$(output),6);;;;;;;;; RJUST$(STRING$(ogot),6);; "\""; i$; "\"  ::: save "; (ogot - 4);; " nybbles"
	output = oaddr						' back up output to start of literal string
	outhalf = ohalf						' ditto
	IF outhalf THEN o[output] = o[output] AND 0x0F
'
	SELECT CASE TRUE
		CASE (ogot <= 27)
					data = #CodeLiteral4 + ogot - 4		' header : literal string of 4 to 27 bytes
					GOSUB Out12												' output header : length imbedded in header
		CASE (ogot <= 271)
					data = #CodeLiteral8							' header : literal string of 16 to 271 bytes
					GOSUB Out12												' output header
					data = ogot - 16									' length = length - 16
					GOSUB Out8												' output length
		CASE ELSE
					PRINT "Implode() : Flush : Disaster : (ogot > 271)"
	END SELECT
'
	s = iaddr									' source addr
	FOR s = iaddr TO iaddr+ogot-1
		data = UBYTEAT(s)				' data byte
		data = NOT data					' invert byte to make file unreadable
		data = data AND 0x00FF	' must keep data <= 0x00FF or bug city
		GOSUB Out8
	NEXT s
	ogot = 0									' done
	oinput = -1								' done
	data = 0									' zero byte
	GOSUB Out8								' clear garbage
	DEC output								' restore output offset
END SUB
'
'
' *****  Out4  *****
'
SUB Out4
	IFZ outhalf THEN
		outhalf = $$TRUE
		o[output] = data AND 0x0F
	ELSE
		outhalf = $$FALSE
		outbyte = o[output]
		outbyte = outbyte OR (data << 4)
		o[output] = outbyte
		INC output
	END IF
'	PRINT RJUST$("Out4 : ",12); RJUST$(STRING$(upper),6);; RJUST$(STRING$(input-addra),6);; RJUST$(STRING$(output),6);; RJUST$(STRING$(data),6)
END SUB
'
'
' *****  Out8  *****
'
SUB Out8
	IFZ outhalf THEN
		o[output] = data
		INC output
	ELSE
		outbyte = o[output]
		outbyte = outbyte OR (data << 4)
		o[output] = outbyte
		INC output
		o[output] = (data >> 4) AND 0x0F
	END IF
'	PRINT RJUST$("Out8 : ",12); RJUST$(STRING$(upper),6);; RJUST$(STRING$(input-addra),6);; RJUST$(STRING$(output),6);; RJUST$(STRING$(data),6);; CHR$(data AND 0x00FF)
END SUB
'
'
' *****  Out12  *****
'
SUB Out12
	IFZ outhalf THEN
		o[output] = data
		outhalf = $$TRUE
		INC output
		o[output] = (data >> 8) AND 0x000F
	ELSE
		outbyte = o[output]
		outbyte = outbyte OR (data << 4)
		o[output] = outbyte
		INC output
		outhalf = $$FALSE
		o[output] = data >> 4
		INC output
	END IF
'	PRINT RJUST$("Out12 : ",12); RJUST$(STRING$(upper),6);; RJUST$(STRING$(input-addra),6);; RJUST$(STRING$(output),6);; RJUST$(STRING$(data),6);; CHR$(data AND 0x00FF)
END SUB
'
'
' *****  OutBytes  *****
'
SUB OutBytes
	SELECT CASE TRUE
		CASE (matchLength <= $$MatchMax)
					offset = input - matchIndex - matchLength
					data = offset + 0x0100
					GOSUB Out12
					data = matchLength - $$MatchMin
					GOSUB Out4
		CASE (matchLength <= $$MatchMax8)
					data = #CodeRelative8						' header for 8 bit length
					GOSUB Out12
					offset = input - matchIndex - matchLength
					data = offset
					GOSUB Out12
					data = matchLength - $$MatchMax - 1
					GOSUB Out8
		CASE (matchLength <= $$MatchMax12)
					data = #CodeRelative12					' header for 12 bit length
					GOSUB Out12
					offset = input - matchIndex - matchLength
					data = offset
					GOSUB Out12
					data = matchLength - $$MatchMax8 - 1
					GOSUB Out12
		CASE ELSE
					PRINT "Implode() : OutBytes : Disaster : "; matchLength
	END SELECT
'
'	GetString (matchIndex, matchLength, @i$)
'	PRINT RJUST$("OutBytes : ",12); RJUST$(STRING$(upper),6);; RJUST$(STRING$(input-addra),6);; RJUST$(STRING$(output),6);; RJUST$(STRING$(matchIndex-addra),6);; RJUST$(STRING$(matchLength),6);; "\""; i$; "\""
'	jjj = kkk
'	kkk = jjj
END SUB
END FUNCTION
'
'
' ########################
' #####  Explode ()  #####
' ########################
'
FUNCTION  Explode (addr, bytes, count, version, UBYTE o[])
	SHARED  words$
'
	do = 0
	DIM o[]
	count = 0
	length = bytes
	upper = length - 1
	IF (upper < 0) THEN RETURN
'
	addra = addr
	addrz = addra + upper
	input = addra
	inhalf = 0
	output = 0
'
	a = UBYTEAT(input)	: input = input + 1
	b = UBYTEAT(input) 	: input = input + 1
	c = UBYTEAT(input)	: input = input + 1
	d = UBYTEAT(input)	: input = input + 1
	e = XLONGAT(input)	: input = input + 4
'
	IF (a != 'z') THEN RETURN ($$TRUE)
	IF (b != 'a') THEN RETURN ($$TRUE)
	IF (c != 'p') THEN RETURN ($$TRUE)
	IF (d = 0x00) THEN RETURN ($$TRUE)	' non-zero version #s only
	IF (e <=  0 ) THEN RETURN ($$TRUE)	' e = length of uncompressed file
'
'	PRINT "Explode() : length in header ="; e; " bytes : bytes = "; bytes
'
	IFZ words$ THEN GetPrefix (@words$)
	zlength = LEN (words$)
	DIM o[zlength+e+255]
	output = zlength
'
	FOR i = 0 TO zlength-1
		o[i] = words${i}
	NEXT i
'
' ??? should (data > #CodeLiteral4) be (data >= #CodeLiteral4) ???
'
	DO WHILE (input <= addrz)
		GOSUB In12
		SELECT CASE TRUE
			CASE (data = #CodeEndOfFile)	:	EXIT DO
			CASE (data = #CodeReserved1)	: GOSUB Reserved
			CASE (data = #CodeRunLength8)	: GOSUB ExplodeIdenticalLong
			CASE (data = #CodeRunLength4)	: GOSUB ExplodeIdenticalShort
			CASE (data = #CodeRelative12)	: GOSUB ExplodePreviousString12
			CASE (data = #CodeRelative8)	: GOSUB ExplodePreviousString8
			CASE (data = #CodeReserved0)	: GOSUB Reserved
			CASE (data = #CodeLiteral8)		: GOSUB ExplodeLiteralLong
			CASE (data > #CodeLiteral4)		: GOSUB ExplodeLiteralShort
			CASE (data = #CodeLiteral4)		: GOSUB ExplodeLiteralShort
			CASE (data > 0x00FF)					: GOSUB ExplodePreviousString4
			CASE (data < 0x0100)					: GOSUB ExplodeLiteralByte
			CASE ELSE											: GOSUB Reserved
		END SELECT
	LOOP
'
	count = e
	DEC output
	FOR i = 0 TO e-1
		o[i] = o[i+zlength]
	NEXT i
'
	REDIM o[count-1]
	output = output - zlength
	RETURN ($$FALSE)
'
'
' *****  Reserved  *****
'
SUB Reserved
	PRINT "Implode() : Reserved : Disaster : (unrecognized header : ignore)"
END SUB
'
'
' *****  In4  *****
'
SUB In4
	IFZ inhalf THEN
		data = UBYTEAT(input) AND 0x000F
		inhalf = $$TRUE
	ELSE
		data = (UBYTEAT(input) AND 0x00F0) >> 4
		inhalf = $$FALSE
		INC input
	END IF
END SUB
'
'
' *****  In8  *****
'
SUB In8
	IFZ inhalf THEN
		data = UBYTEAT(input)
		INC input
	ELSE
		data = (UBYTEAT(input) AND 0x00F0) >> 4
		INC input
		data = data OR ((UBYTEAT(input) AND 0x000F) << 4)
	END IF
END SUB
'
'
' *****  In12  *****
'
SUB In12
	IFZ inhalf THEN
		data = UBYTEAT(input)
		INC input
		data = data OR ((UBYTEAT(input) AND 0x000F) << 8)
		inhalf = $$TRUE
	ELSE
		data = (UBYTEAT(input) AND 0x00F0) >> 4
		bottom = (UBYTEAT(input) AND 0x00F0) >> 4
		INC input
		data = data OR (UBYTEAT(input) << 4)
		top = UBYTEAT(input) << 4
		inhalf = $$FALSE
		INC input
	END IF
END SUB
'
'
' *****  ExplodeIdenticalLong  *****
'
SUB ExplodeIdenticalLong
	IF do THEN PRINT "eil : "
	GOSUB In8
	length = data + 16						' length of string
	GOSUB In8
	FOR o = 1 TO length
		o[output] = data
		INC output
	NEXT o
END SUB
'
'
' *****  ExplodeIdenticalShort  *****
'
SUB ExplodeIdenticalShort
	IF do THEN PRINT "eis : "
	GOSUB In4
	length = data + 3							' length of string
	GOSUB In8
	FOR o = 1 TO length
		o[output] = data
		INC output
	NEXT o
END SUB
'
'
' *****  ExplodeLiteralLong  *****
'
SUB ExplodeLiteralLong
	IF do THEN PRINT "ell : "
	GOSUB In8
	length = data + 16						' length of string
	FOR o = 1 TO length
		GOSUB In8
		data = NOT data
		data = data AND 0x00FF
		o[output] = data
		INC output
	NEXT o
END SUB
'
'
' *****  ExplodeLiteralShort  *****
'
SUB ExplodeLiteralShort
	IF do THEN PRINT "els : "
	xdata = data
	length = data - #CodeLiteral4 + 4		' length of string
	FOR o = 1 TO length
		GOSUB In8
		data = NOT data
		data = data AND 0x00FF
		o[output] = data
		INC output
	NEXT o
	IF do THEN GetString (&o[output-length], length, @aaa$)
	IF do THEN PRINT HEX$(&o[at],4);; length;; xdata;; "\""; aaa$; "\""
END SUB
'
'
' *****  ExplodePreviousString4  *****
'
SUB ExplodePreviousString4
	IF do THEN PRINT "eps4 : "
	at = output - (data - 256)
	GOSUB In4
	length = data + $$MatchMin		' length of string
	at = at - length
	IF do THEN GetString (&o[at], length, @aaa$)
	IF do THEN PRINT HEX$(&o[at],4);; length;; data;; "\""; aaa$; "\""
	FOR o = 1 TO length
		o[output] = o[at]
		INC output
		INC at
	NEXT o
END SUB
'
'
' *****  ExplodePreviousString8  *****
'
SUB ExplodePreviousString8
	IF do THEN PRINT "eps8 : "
	GOSUB In12
	at = output - data
	GOSUB In8
	length = data + $$MatchMax4 + 1			' length of string
	at = at - length
	IF do THEN GetString (&o[at], length, @aaa$)
	IF do THEN PRINT HEX$(&o[at],4);; length;; data;; "\""; aaa$; "\""
	FOR o = 1 TO length
		o[output] = o[at]
		INC output
		INC at
	NEXT o
END SUB
'
'
' *****  ExplodePreviousString12  *****
'
SUB ExplodePreviousString12
	IF do THEN PRINT "eps12 : "
	GOSUB In12
	at = output - data
	GOSUB In12
	length = data + $$MatchMax8 + 1		' length of string
	at = at - length
	IF do THEN GetString (&o[at], length, @aaa$)
	IF do THEN PRINT HEX$(&o[at],4);; length;; data;; "\""; aaa$; "\""
	FOR o = 1 TO length
		o[output] = o[at]
		INC output
		INC at
	NEXT o
END SUB
'
'
' *****  ExplodeLiteralByte  *****
'
SUB ExplodeLiteralByte
	IF do THEN PRINT "elb : "
	o[output] = data
	INC output
END SUB
END FUNCTION
END PROGRAM

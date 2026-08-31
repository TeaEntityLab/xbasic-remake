'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"asound"
VERSION	"0.0000"
'
IMPORT	"xst"						' XBasic standard library
IMPORT	"winmm"					' one of the win32 API libraries
IMPORT	"kernel32"			' one of the win32 API libraries
'
' this program needs file "winmm.dec" in your XBasic directory
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
' This loop plays a series of beeps by calling the
' Beep() function in the win32 "kernel32" API library.
' Windows95/98 ignore frequency and duration arguments.
'
	duration = 10
	FOR frequency = 100 TO 1000 STEP 200
		result = Beep (frequency, duration)
		PRINT result, duration, frequency
		XstSleep (1000)
	NEXT
'
'
' But Windows95/98 do play WAV files, so you can make
' your program play a variety of interesting sounds.
' This loop plays a series of WAV sound files that are
' in my windows sound directory.  Not every file this
' loop tries to play exists, but that's okay because
' it just returns a 0 (failed) instead of 1 (success)
' and moves on to the next sound.  If your system does
' not have the specified WAV files, find a WAV file on
' your system and replace it in the following line.
' result = sndPlaySoundA (&"c:/windows/media/sound/sound1.wav", sync)
' Note: XBasic understands "/" as directory separators,
' but if you prefer "\" characters, you must double up,
' as in "c:\\windows\\media\\sound\\sound1.wav".
'
	sync = 0
	async = 1
	sound$ = "c:/windows/media/sound/sound"
'
	FOR i = 1 TO 59
		play$ = sound$ + STRING$ (i)
		result = sndPlaySoundA (&play$, sync)
		PRINT result, play$
	NEXT
END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "aformat"
VERSION "0.0000"
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
'
FUNCTION  Entry ()
	left$ = "left"
	center$ = "center"
	right$ = "right"
	PRINT
	PRINT "<"; FORMAT$ ("  ######.#####", 23);              ">"
	PRINT "<"; FORMAT$ (" $######.#####", 234567$$);        ">"
	PRINT "<"; FORMAT$ ("*#######.#####", 23.456789!);      ">"
	PRINT "<"; FORMAT$ ("*#######.#####", 23.456789#);      ">"
	PRINT "<"; FORMAT$ ("<<<<<<<<<<<<<<", "left");          ">"
	PRINT "<"; FORMAT$ ("||||||||||||||", "center");        ">"
	PRINT "<"; FORMAT$ (">>>>>>>>>>>>>>", "right");         ">"
	PRINT "<"; FORMAT$ ("<<<<<<<<<<<<<<", left$);           ">"
	PRINT "<"; FORMAT$ ("||||||||||||||", center$);         ">"
	PRINT "<"; FORMAT$ (">>>>>>>>>>>>>>", right$);          ">"
	PRINT "<"; FORMAT$ ("<<<<<<<<<<<<<<", left$+left$);     ">"
	PRINT "<"; FORMAT$ ("||||||||||||||", center$+center$); ">"
	PRINT "<"; FORMAT$ (">>>>>>>>>>>>>>", right$+right$);   ">"
END FUNCTION
END PROGRAM

'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "acgibin"
VERSION "0.0003"
'
' This program shows how to create interactive web pages, using the
' Common Gateway Interface (CGI) and XBasic as the programming tool.
'
' This program reads the input data and saves it into to text variables
' commandline$ and formdata$, then builds a simple web page and sends it
' to the server.
'
' This CGI must be called from a web page with a code like this:
'
' <p><a href="http://default/cgi-bin/acgibin.exe?param1=val1&param2=val2&param3=val3">acgibin</a></p>
'
' or
'
' <form method="POST" action="http://default/cgi-bin/acgibin.exe?param1=val1&param2=val2&param3=val3">
' <p><input type="submit" value="acgibin" name="B1">.......</p>
' </form>
'
' Feel free to make to copy, modify or enhance this program.
' For further information call Alberto Alva E.  email: talvae@esan.com.pe
'
' this program slightly beautified by "some jerk", but not altered functionally
'
IMPORT "xst"
IMPORT "kernel32"		' Windows API

DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  Send (a$)
DECLARE FUNCTION  CGIStart (pageTitle$)
DECLARE FUNCTION  CGIBody ()
DECLARE FUNCTION  CGIEnd (footer$)
'
$$STD_INPUT_HANDLE = -10
$$STD_OUTPUT_HANDLE = -11
'
' Standard handles declaration
'
XLONG #hStdIn
XLONG #hStdOut
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	pageTitle$="acgibin"
	footer$="end of test"
'
	CGIStart (pageTitle$)
	CGIBody ()
	CGIEnd (footer$)
END FUNCTION
'
'
' #####################
' #####  Send ()  #####
' #####################
'
FUNCTION  Send (a$)
	a$ = a$ + "\r\n"
	length = LEN(a$)
	sent = 0
	WriteFile (#hStdOut, &a$, length, &sent, 0)
END FUNCTION
'
'
' #########################
' #####  CGIStart ()  #####
' #########################
'
FUNCTION  CGIStart (pageTitle$)
'
' Get Standard Handles
'
	#hStdIn = GetStdHandle($$STD_INPUT_HANDLE)
	#hStdOut = GetStdHandle($$STD_OUTPUT_HANDLE)
'
' Get Enviroment variables
'
	Xst()
	name$ = "HTTP_ACCEPT" 			:	XstGetEnvironmentVariable (@name$, @#accept$)
	name$ = "AUTH_TYPE" 				:	XstGetEnvironmentVariable (@name$, @#authType$)
	name$ = "CONTENT_LENGTH"		:	XstGetEnvironmentVariable (@name$, @#contentLength$)
	name$ = "CONTENT_TYPE"			:	XstGetEnvironmentVariable (@name$, @#contentType$)
	name$ = "GATEWAY_INTERFACE"	:	XstGetEnvironmentVariable (@name$, @#gatewayInterface$)
	name$ = "PATH_INFO"					:	XstGetEnvironmentVariable (@name$, @#pathInfo$)
	name$ = "PATH_TRANSLATED"		:	XstGetEnvironmentVariable (@name$, @#pathTranslated$)
	name$ = "QUERY_STRING"			: XstGetEnvironmentVariable (@name$, @#queryString$)
	name$ = "HTTP_REFERER"			: XstGetEnvironmentVariable (@name$, @#referer$)
	name$ = "REMOTE_ADDR"				: XstGetEnvironmentVariable (@name$, @#remoteAddr$)
	name$ = "REMOTE_HOST"				: XstGetEnvironmentVariable (@name$, @#remoteHost$)
	name$ = "REMOTE_IDENT"			: XstGetEnvironmentVariable (@name$, @#remoteIdent$)
	name$ = "REMOTE_USER"				: XstGetEnvironmentVariable (@name$, @#remoteUser$)
	name$ = "REQUEST_METHOD"		:	XstGetEnvironmentVariable (@name$, @#requestMethod$)
	name$ = "SCRIPT_NAME"				: XstGetEnvironmentVariable (@name$, @#scriptname$)
	name$ = "SERVER_SOFTWARE"		: XstGetEnvironmentVariable (@name$, @#serverSoftware$)
	name$ = "SERVER_NAME"				: XstGetEnvironmentVariable (@name$, @#servername$)
	name$ = "SERVER_PORT"				: XstGetEnvironmentVariable (@name$, @#serverPort$)
	name$ = "SERVER_PROTOCOL"		: XstGetEnvironmentVariable (@name$, @#serverProtocol$)
	name$ = "HTTP_USER_AGENT"		: XstGetEnvironmentVariable (@name$, @#userAgent$)
'
' get Input Data (formData from STDIN (if method is POST) and commandLine from #queryString$)
'
	length = XLONG (#contentLength$)
	IF (#requestMethod$ == "POST") THEN
		read = 0
		buffer$ = CHR$ (0, length)
		ReadFile (#hStdIn, &buffer$, length, &read, 0)
		#formData$ = LEFT$ (buffer$, read)
	END IF
	#commandLine$= #queryString$
'
' send Header
'
	Send ("status: 200 OK")
	Send ("content-type: text/html\n\r")
	Send ("<html><head><title>" + pageTitle$+ "</title></head>")
END FUNCTION
'
'
' ########################
' #####  CGIBody ()  #####
' ########################
'
FUNCTION  CGIBody ()
'
' The following code must be replace with your code
'
	Send ("<body bgcolor=\"#000000\" text=\"#FF8000\">")
	Send ("<font face=\"Comic Sans MS\">")
	Send ("<h1 align=\"center\">XBasic CGI Test Page</h1>")
	IF #requestMethod$ = "POST" THEN
		Send ("<p align=\"center\"><em>The Form Data posted is  :  "+ #formData$ + "</em></p>")
	END IF
	Send ("<p align=\"center\"><em>The Command Line is  :  " + #commandLine$ + " </em></p>")
	Send ("<hr>")

	Send ("<p>The Principal Enviroment Variables are:</p><div align=\"center\"><center>")

	Send ("<table border=\"1\" cellpadding=\"2\">")
	Send ("<tr><td align=\"center\" width=\"50%\">VARIABLE NAME</td>")
	Send ("<td align=\"center\" width=\"50%\">VARIABLE VALUE</td></tr>")

	Send ("<tr><td align=\"center\" width=\"50%\">REQUEST_METHOD</td>")
	Send ("<td align=\"center\" width=\"50%\">"+#requestMethod$+"</td></tr>")

	Send ("<tr><td align=\"center\" width=\"50%\">CONTENT_TYPE</td>")
	Send ("<td align=\"center\" width=\"50%\">"+#contentType$+"</td></tr>")

	Send ("<tr><td align=\"center\" width=\"50%\">CONTENT_LENGTH</td>")
	Send ("<td align=\"center\" width=\"50%\">"+#contentLength$+"</td></tr>")

	Send ("<tr><td align=\"center\" width=\"50%\">QUERY_STRING</td>")
	Send ("<td align=\"center\" width=\"50%\">"+#queryString$+"</td></tr>")

	Send ("<tr><td align=\"center\" width=\"50%\">REMOTE_ADDR</td>")
	Send ("<td align=\"center\" width=\"50%\">"+#remoteAddr$+"</td></tr>")

	Send ("</table>")
	Send ("</center></div>")
	Send ("</font>")
END FUNCTION
'
'
' #######################
' #####  CGIEnd ()  #####
' #######################
'
FUNCTION  CGIEnd (footer$)
'
' include a personalized footer here and close the web page
'
	Send ("<font face=\"Comic Sans MS\" font size=\"1\">")
	Send ("<p></p>")
	Send ("<hr>")
	Send ("<p>Questions : Alberto Alva E. <a href=\"mailto:talvae@esan.com.pe\">talvae@esan.com.pe</a></p>")

	Send ("<p>"+footer$+"</p>")
	Send ("</font>")
	Send ("</body></html>")
END FUNCTION
END PROGRAM

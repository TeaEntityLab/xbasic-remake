'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aserver"
VERSION	"0.0001"
'
IMPORT	"xst"
IMPORT	"xin"
IMPORT	"xui"
'
' IMPORTANT : The Windows XBasic "xin" sockets/network/internet
' function library is disabled if file "c:/windows/xb.ini" exits
' and contains the line "xin=false".  The best way to enable the
' "xin" function library is to comment-out that line with a '
' comment-character prefix - change "xin=false" to "' xin=false".
' You can then re-disable the "xin" library if you wish by simply
' removing the ' comment character.  Why is this silly "xin=false"
' initialization-string needed?  For unknown reasons, in computers
' that do not have TCP/IP networking but DO have dial-up networking,
' initialization in "xin" malfunctions unless a dial-up connection
' has been made since the computer started.  Why is unclear, and
' hopefully this silly workaround can be eliminated someday.
'
' This "aserver.x" program is a time stamp server program that
' works with the "aclient.x" program to test and demonstrate the
' simplest possible client and server programs.  This "aserver.x"
' program connects to port 0x2020.  All this program does is wait
' for a "time" stamp request, then create a time stamp string and
' send it to the requesting client, which can be "aclient.x" for
' testing purposes, but could be any client that connects to the
' IP address of this system on port 0x2020.
'
DECLARE FUNCTION  Entry      ()
DECLARE FUNCTION  Blowback   ()
'
	$$SERVER_PORT    = 0x2020
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	HOST  host
'
	XinSetDebug (1)							' turn on bug print
	client = $$FALSE						' no client socket yet
	connected = $$FALSE					' not connected to a client yet
	buffer$ = NULL$ (255)				' place to capture request strings
'
	XstClearConsole ()
	GOSUB PrintBanner						' print aclient.x startup banner
	GOSUB Initialize						' initialize network function library
	GOSUB PrintLocalHostInfo		' print information about this system
	GOSUB PrintNetworkAddress		' print network address of this system
	GOSUB OpenSocket						' open a network communications socket
	GOSUB BindSocket						' bind the socket to port $$SERVER_PORT
	GOSUB Listen								' have socket listen for connect request
'
' Need nested loop so when a client disconnects the server loops
' around and waits for and accepts the next client to connect.
'
	DO													' wait for a client to connect
		DO												' keep waiting for client connection
			GOSUB Accept						' accept any client connection attempts
		LOOP UNTIL client					' keep waiting for a client to connect
'
		GOSUB GetAddresses				' get and print server/client addresses
'
		DO
			GOSUB ReadTimeRequest		' read request for timestamp from client
			IFZ client THEN EXIT DO	' maybe the client disconnected or failed
			GOSUB WriteTimeStamp		' write the time stamp string to client
		LOOP WHILE client					' continue as long as client is connected
	LOOP WHILE socket						' continue as long as server is alive
'
	Blowback ()
	RETURN ($$FALSE)

'
'
' *****  PrintBanner  *****
'
SUB PrintBanner
	PRINT
	PRINT "####################################################"
	PRINT "#####  XBasic Network Functions Test : Server  #####"
	PRINT "####################################################"
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	PRINT
	PRINT "#####  Xin ()  #####"
	PRINT "#####  XinInitialize (@local, @hosts, @sockets, @version, @comments$, @notes$)  #####"
'
	Xin ()
	XinInitialize (@local, @hosts, @version, @sockets, @comments$, @notes$)
'
' *****  print basic network information  *****
'
	PRINT
	PRINT "local                  = "; HEX$ (local,8)
	PRINT "hosts                  = "; HEX$ (hosts,8)
	PRINT "sockets                = "; HEX$ (sockets,8)
	PRINT "version                = "; HEX$ (version,8)
	PRINT "comments$              = "; comments$
	PRINT "notes$                 = "; notes$
END SUB
'
'
' *****  PrintLocalHostInfo  *****
'
SUB PrintLocalHostInfo
	PRINT
	PRINT "#####  XinHostNumberToInfo (base, @info)  #####"
'
	XinHostNumberToInfo (0, @host)
	hostaddress = host.address
	address$$ = host.address
	host$ = host.name
'
	PRINT
	PRINT "host.name              = \""; host.name; "\""
	PRINT "host.alias[0]          = \""; host.alias[0]; "\""
	PRINT "host.alias[1]          = \""; host.alias[1]; "\""
	PRINT "host.alias[2]          = \""; host.alias[2]; "\""
	PRINT "host.system            = \""; host.system; "\""
	PRINT "host.hostnumber        = "; HEX$ (host.hostnumber,8)
	PRINT "host.address           = "; HEX$ (host.address,8); " = "; STRING$(host.address AND 0x000000FF) + "." + STRING$((host.address >> 8) AND 0x000000FF) + "." + STRING$((host.address >> 16) AND 0x000000FF) + "." + STRING$((host.address >> 24) AND 0x000000FF)
'
	FOR i = 0 TO 7
		PRINT "host.addresses[" + STRING$(i) + "]      = "; HEX$ (host.addresses[i],8); " = "; STRING$(host.addresses[i] AND 0x000000FF) + "." + STRING$((host.addresses[i] >> 8) AND 0x000000FF) + "." + STRING$((host.addresses[i] >> 16) AND 0x000000FF) + "." + STRING$((host.addresses[i] >> 24) AND 0x000000FF)
	NEXT i
'
	PRINT "host.addressBytes      = "; HEX$ (host.addressBytes,8)
	PRINT "host.addressFamily     = "; HEX$ (host.addressFamily,8)
	PRINT "host.protocolFamily    = "; HEX$ (host.protocolFamily,8)
	PRINT "host.protocol          = "; HEX$ (host.protocol,8)
END SUB
'
'
' *****  PrintNetworkAddress  *****
'
SUB PrintNetworkAddress
	PRINT
	XinAddressNumberToString (@address$$, @address$)
	PRINT "<"; HEX$(address$$,16); "> <"; address$; "> <";
	XinAddressStringToNumber (@address$, @addr$$)
	PRINT address$; "> <"; HEX$(addr$$,16); ">"
END SUB
'
'
' *****  OpenSocket  *****
'
SUB OpenSocket
	PRINT
	PRINT "#####  error = XinSocketOpen (@socket, addressType, socketType, flags)  #####"
'
	flags = 0
	socketType = 0
	addressType = 0
	error = XinSocketOpen (@socket, @addressType, @socketType, flags)
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8)
	PRINT "socket                 = "; HEX$ (socket, 8)
	PRINT "addressType            = "; HEX$ (addressType, 8)
	PRINT "socketType             = "; HEX$ (socketType, 8)
	PRINT "flags                  = "; HEX$ (flags, 8)
'
	IF error THEN
		Blowback ()
		RETURN
	END IF
END SUB
'
'
' *****  BindSocket  *****
'
SUB BindSocket
	PRINT
	PRINT "#####  error = XinSocketBind (socket, block, @address$$, @port)  #####"
'
	block = 0
	port = $$SERVER_PORT
	address = hostaddress
	error = XinSocketBind (socket, block, @address$$, @port)
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8)
	PRINT "socket                 = "; HEX$ (socket, 8)
	PRINT "block                  = "; HEX$ (block, 8)
	PRINT "address                = "; HEX$ (address, 8)
	PRINT "port                   = "; HEX$ (port, 8)
'
	IF error THEN
		Blowback ()
		RETURN
	END IF
END SUB
'
'
' *****  Listen  *****
'
SUB Listen
	PRINT
	PRINT "#####  error = XinSocketListen (socket, block, flags)  #####"
'
	flags = 0
	block = 0
	error = XinSocketListen (socket, block, flags)
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8)
	PRINT "socket                 = "; HEX$ (socket, 8)
	PRINT "block                  = "; HEX$ (block, 8)
	PRINT "flags                  = "; HEX$ (flags, 8)
'
	IF error THEN
		Blowback ()
		RETURN
	END IF
END SUB
'
'
' *****  Accept  *****
'
SUB Accept
	flags = 0
	client = 0
	block = 100
'
'
	error = XinSocketAccept (socket, block, @client, flags)
'
	IF (error OR client) THEN
		PRINT
		PRINT "#####  error = XinSocketAccept (socket, block, @client, flags)  #####"
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "block                  = "; HEX$ (block, 8)
		PRINT "client                 = "; HEX$ (client, 8)
		PRINT "flags                  = "; HEX$ (flags, 8)
	END IF
'
	IF error THEN
		Blowback ()
		RETURN
	END IF
END SUB
'
'
' *****  GetAddresses  *****
'
SUB GetAddresses
	PRINT
	PRINT "#####  error = XinSocketGetAddress (socket, @port, @address$$, @remote, @rport, @raddress$$)  #####"
'
	error = XinSocketGetAddress (socket, @port, @address$$, @remote, @rport, @raddress$$)
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8)
	PRINT "socket                 = "; HEX$ (socket, 8)
	PRINT "port                   = "; HEX$ (port, 8)
	PRINT "address$$              = "; HEX$ (address$$, 16)
	PRINT "remote                 = "; HEX$ (remote, 8)
	PRINT "rport                  = "; HEX$ (rport, 8)
	PRINT "raddress$$             = "; HEX$ (raddress$$, 16)
END SUB
'
'
' *****  ReadTimeRequest  *****
'
SUB ReadTimeRequest
	PRINT
	PRINT "#####  error = XinSocketRead (client, block, address, readbytes, flags, @bytes)  #####"
'
	error = 0
	bytes = 0
	flags = 0
	block = 100							' wait 100us each loop
	readbytes = 4						' number of bytes to read, in "time" request
	request$ = NULL$(4)			' room for "time" request string
	address = &request$			' address to read request into
'
	DO UNTIL error
		error = XinSocketRead (client, block, address, readbytes, flags, @bytes)
'
		IFZ error THEN
			IF bytes THEN
				readbytes = readbytes - bytes
				address = address + bytes
			END IF
		END IF
	LOOP WHILE (readbytes > 0)
'
	error$ = ""
	IF error THEN
		err = ERROR (0)
		IF err THEN error = err
		XstErrorNumberToName (error, @error$)
	END IF
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8); " : "; error$
	PRINT "client                 = "; HEX$ (client, 8)
	PRINT "block                  = "; HEX$ (block, 8)
	PRINT "address                = "; HEX$ (address, 8)
	PRINT "readbytes              = "; HEX$ (readbytes, 8)
	PRINT "flags                  = "; HEX$ (flags, 8)
	PRINT "bytes                  = "; HEX$ (bytes, 8)
	PRINT "request$               = \""; request$; "\""
'
	IF error THEN
		XinSocketGetStatus (client, 0, 0, 0, @status, 0, 0, 0)
		IFZ (status AND $$SocketStatusConnected) THEN
			XinSocketClose (client)
			client = 0
		END IF
	END IF
END SUB
'
'
' *****  WriteTimeStamp  *****
'
SUB WriteTimeStamp
	GOSUB GetTimeStamp									' returns time stamp in time$
'
	PRINT
	PRINT "#####  error = XinSocketWrite (client, block, address, writebytes, flags, @bytes, @error)  #####"
'
	error = 0
	flags = 0
	block = 100													' wait 100us each loop
	address = &time$										' address of time stamp string
	writebytes = LEN (time$)						' # of bytes in time stamp string
'
	DO UNTIL error
		bytes = 0
		error = 0
		error = XinSocketWrite (client, block, address, writebytes, flags, @bytes)
'
		IFZ error THEN
			IF (bytes > 0) THEN
				writebytes = writebytes - bytes		' bytes left to send
				address = address + bytes					' move past written bytes
			END IF
		END IF
	LOOP WHILE (writebytes > 0)							' write again if necessary
'
	IF error THEN
		err = ERROR (0)
		IF err THEN error = err
	END IF
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8)
	PRINT "socket                 = "; HEX$ (socket, 8)
	PRINT "block                  = "; HEX$ (block, 8)
	PRINT "address                = "; HEX$ (address, 8)
	PRINT "maxbytes               = "; HEX$ (maxbytes, 8)
	PRINT "flags                  = "; HEX$ (flags, 8)
	PRINT "bytes                  = "; HEX$ (bytes, 8)
	PRINT "write                  = \""; LEFT$(time$,bytes); "\""
'
	IF error THEN
		XinSocketGetStatus (client, 0, 0, 0, @status, 0, 0, 0)
		IFZ (status AND $$SocketStatusConnected) THEN
			XinSocketClose (client)
			client = 0
		END IF
	END IF
END SUB
'
'
' *****  GetTimeStamp  *****
'
SUB GetTimeStamp
	time$ = ""
	XstGetDateAndTime (@year, @month, @day, @weekday, @hour, @minute, @second, @nanosecond)
	time$ = time$ + RIGHT$ ("0000" + STRING$(year), 4)
	time$ = time$ + RIGHT$ ("00" + STRING$(month), 2)
	time$ = time$ + RIGHT$ ("00" + STRING$(day), 2) + ":"
	time$ = time$ + RIGHT$ ("00" + STRING$(hour), 2)
	time$ = time$ + RIGHT$ ("00" + STRING$(minute), 2)
	time$ = time$ + RIGHT$ ("00" + STRING$(second), 2) + "."
	time$ = time$ + RIGHT$ ("000000000" + STRING$ (nanosecond), 9)
'
	PRINT
	PRINT "time                   = \""; time$; "\""
END SUB
END FUNCTION
'
'
' #########################
' #####  Blowback ()  #####
' #########################
'
FUNCTION  Blowback ()
'
	PRINT
	PRINT "#####  aserver.x : Blowback()  #####"
'
	XinSocketClose (-1)				' close all my sockets
'	XinSetDebug (0)						' turn off bug printer
END FUNCTION
END PROGRAM

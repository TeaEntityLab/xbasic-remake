'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aclient"
VERSION	"0.0001"
'
IMPORT	"xst"
IMPORT  "xin"
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
' This "aclient.x" program is a client to the "aserver.x" server
' program to test and demonstrate the simplest possible client
' and server programs.  The "aserver.x" server program is on
' port 0x2020 and all it does is send a time stamp string when
' it receives a "time" request from a client.
'
' You will need to change the $$SERVER_ADDRESS constant below to
' the IP address of the system running the "aserver.x" program.
' If you do not know the "dot notation" IP address of the system
' running "aserver.x", enter "ping systemname" at the command
' prompt on that system to make it print.
'
'
DECLARE FUNCTION  Entry      ( )
DECLARE FUNCTION  Blowback   ( )
'
' remember, you need to change $$SERVER_ADDRESS below
'
	$$SERVER_PORT     = 0x2020            ' port # of "aserver.x"
	$$SERVER_ADDRESS$ = "76.7.4.3"        ' IP address of "aserver.x"
'	$$SERVER_PORT     = 23                ' port # of "aserver.x"
'	$$SERVER_ADDRESS$ = "192.168.2.12"		' IP address of "aserver.x"
'
	$$ENDPROLOG = 0
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	HOST  host
'
	XinSetDebug (1)							' print info
	socket = $$FALSE						' no server socket yet
	connected = $$FALSE					' not connected to server yet
	buffer$ = NULL$ (255)				' place to capture timestamp string
'
	XstClearConsole ()					' clear console for readability
	GOSUB PrintBanner						' print aclient.x startup banner
	GOSUB Initialize						' initialize network function library
	GOSUB PrintLocalHostInfo		' print information about this system
	GOSUB PrintNetworkAddress		' print network address of this system
	GOSUB OpenSocket						' open a network communications socket
	GOSUB BindSocket						' bind the socket to a local port
	GOSUB ConnectRequest				' request connection to server
'
	DO UNTIL connected
		GOSUB ConnectStatus				' wait for connection to server
	LOOP
'
	GOSUB GetAddresses					' get client/server address and port
'
	FOR i = 0 TO 3							' request 4 timestamp strings
		GOSUB WriteTimeRequest		' write "time" to timestamp server
		IFZ socket THEN EXIT FOR	' were we rudely disconnected ???
		GOSUB ReadTimeStamp				' read reply timestamp string
		IFZ socket THEN EXIT FOR	' were we rudely disconnected ???
	NEXT i											'
'
	Blowback ()
	RETURN
'
'
' *****  PrintBanner  *****
'
SUB PrintBanner
	PRINT
	PRINT "####################################################"
	PRINT "#####  XBasic Network Functions Test : Client  #####"
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
	error = Xin ()
	IF error THEN
		XstErrorNumberToName (error, @error$)
		PRINT error$
		RETURN
	END IF
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
	port = 0
	address = 0
	error = XinSocketBind (socket, block, @address$$, @port)
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8)
	PRINT "socket                 = "; HEX$ (socket, 8)
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
' *****  ConnectRequest  *****
'
SUB ConnectRequest
	XinAddressStringToNumber (@$$SERVER_ADDRESS$, @serveraddress$$)
	serverport = $$SERVER_PORT
	block = 0
'
	PRINT
	PRINT "#####  error = XinSocketConnectRequest (socket, block, serveraddress$$, serverport)  #####"

	error = XinSocketConnectRequest (socket, block, serveraddress$$, serverport)
'
	PRINT
	PRINT "error                  = "; HEX$ (error, 8)
	PRINT "socket                 = "; HEX$ (socket, 8)
	PRINT "block                  = "; HEX$ (block, 8)
	PRINT "serveraddress$$        = "; HEX$ (serveraddress$$, 16)
	PRINT "serverport             = "; HEX$ (serverport, 8)
'
	IF error THEN
		Blowback ()
		RETURN
	END IF
END SUB
'
'
' *****  ConnectStatus  ******
'
SUB ConnectStatus
	error = 0
	block = 100
	error = XinSocketConnectStatus (socket, block, @connected)
'
	IF (error OR connected) THEN
		PRINT
		PRINT "#####  error = XinSocketConnectStatus (socket, block, @connected)  #####"
'
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "socket                 = "; HEX$ (socket, 8)
		PRINT "block                  = "; HEX$ (block, 8)
		PRINT "connected              = "; HEX$ (connected, 8)
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
	PRINT "port                   = "; HEX$ (port, 8)
	PRINT "address$$              = "; HEX$ (address$$, 16)
	PRINT "rport                  = "; HEX$ (rport, 8)
	PRINT "raddress$$             = "; HEX$ (raddress$$, 16)
END SUB
'
'
' *****  WriteTimeRequest  *****
'
SUB WriteTimeRequest
	sent = 0
	error = 0
	block = 100										' wait 100us each time
	request$ = "time"
	address = &request$
	writebytes = SIZE (request$)
'
	PRINT
	PRINT "#####  error = XinSocketWrite (socket, block, address, writebytes, flags, @bytes, @error)  #####"
'
	DO UNTIL error
		flags = 0
		bytes = 0
		error = 0
		error = XinSocketWrite (socket, block, address, writebytes, flags, @bytes)
'
		IFZ error THEN
			IF (bytes > 0) THEN
				writebytes = writebytes - bytes		' bytes left to send
				address = address + bytes					' move past written bytes
			END IF
		END IF
	LOOP UNTIL (writebytes <= 0)						' write again if necessary
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
	PRINT "write                  = \""; LEFT$(request$,bytes); "\""
'
	IF error THEN
		XinSocketGetStatus (socket, 0, 0, 0, @status, 0, 0, 0)
		IFZ (status AND $$SocketStatusConnected) THEN
			XinSocketClose (socket)
			socket = 0
		END IF
	END IF
END SUB
'
'
' *****  ReadTimeStamp  *****
'
SUB ReadTimeStamp
	address = &buffer$
	maxbytes = SIZE (buffer$)
'
	PRINT
	PRINT "#####  error = XinSocketRead (socket, block, address, maxbytes, flags, @bytes, @error)  #####"
'
	DO UNTIL error
		flags = 0
		bytes = 0
		error = 0
		block = 100
		error = XinSocketRead (socket, block, address, maxbytes, flags, @bytes)
	LOOP UNTIL bytes
'
	time$ = LEFT$ (buffer$, bytes)
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
	PRINT "read                   = \""; time$; "\""
'
	IF error THEN
		XinSocketGetStatus (socket, 0, 0, 0, @status, 0, 0, 0)
		IFZ (status AND $$SocketStatusConnected) THEN
			XinSocketClose (socket)
			socket = 0
		END IF
	END IF
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
	PRINT "#####  aclient.x : Blowback()  #####"
'
	XinSocketClose (-1)		' close all my sockets
	XinSetDebug (0)				' turn off bug printer
END FUNCTION
END PROGRAM

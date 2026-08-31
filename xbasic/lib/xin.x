'
'
' ####################  Max Reason
' #####  PROLOG  #####  copyright 1988-2000
' ####################  Linux XBasic internet/network/sockets library
'
' subject to LGPL license - see COPYING_LIB
'
' maxreason@maxreason.com
'
' for Linux XBasic
'
'
PROGRAM	"xin"
VERSION	"6.4.5"
'
IMPORT	"xlib"
IMPORT	"xst"
IMPORT	"xui"
IMPORT  "clib"
'
' This function library operates on a pseudo-non-blocking basis.
' Functions do not "hang" or "lock-up" indefinitely until complete.
' Many functions do have a "block" argument that takes an interval
' in microseconds to block, but values above 20000 aka 20ms are
' converted to 20000 before the select() function is called.
' Blocking times greater than 20 milliseconds thus never occur.
' To get the effect of blocking, programs must create a short
' loop that calls the function repeatedly until it succeeds.
' Short blocking times are supported so that programs do not
' waste cycles polling for results - the operating system will
' context switch to other tasks that have work to do.
'
' Note that network "servers" Open/Bind/Listen/Accept to allow
' network "clients" to connect to them, while network clients
' Open/Bind/Connect to a specific network server.  If a server
' wants to establish a "peer" connection to another server, it
' sets itself up as a server (so the peer can connect to it),
' then also connects to the "peer" server as a client would.
'
EXPORT
'TYPE SOCKET
'	XLONG     .socket						' socket number of this socket
'	XLONG     .remote						' remote socket connected to this socket
'	XLONG     .syssocket				' socket number to operating system
'	XLONG     .sysremote				' remote socket number to operating system
'	GIANT     .address					' IP address this socket is bound to
'	XLONG     .port							' port this socket is connected to
'	XLONG     .whomask					' whomask of program that owns this socket
'	XLONG     .hostnumber				' host identifier for XinGetHostData()
'	XLONG     .status						' socket status - see $$STATUS constants
'	XLONG     .socketType				' type of socket - $$SOCK_STREAM
'	XLONG     .addressType			' address type - $$AF_INET
'	XLONG     .addressBytes			' bytes in address - 4 for short IP
'	XLONG     .addressFamily		' address family - $$AF_INET
'	XLONG     .protocolFamily		' protocol family - $$PF_INET
'	USHORT    .protocol					' active protocol - $$TCP
'	USHORT    .service					' service - $$FTP
'END TYPE
'
'TYPE HOST
'	STRING*32 .name							' "mhpcc.edu"
'	STRING*32 .alias[2]					' "mhpcc.net", "mhpcc.org", "mhpcc.com"
'	STRING*16 .system						' "Windows", "WindowsNT", "UNIX", "Linux"
'	GIANT     .address					' 0x0104215C - can hold longer IP address
'	GIANT     .addresses[7]			' host can support 8 more IP addresses
'	XLONG     .hostnumber				' native host number
'	XLONG     .addressBytes			' 4 for original IP addresses
'	XLONG     .addressFamily		' $$AF_INET
'	XLONG     .protocolFamily		' $$PF_INET
'	XLONG     .protocol					' protocol # for "TCP"
'	XLONG     .resv							'
'	XLONG     .resw							'
'	XLONG     .resx							'
'	XLONG     .resy							'
'	XLONG     .resz							'
'END TYPE
'
'
' Structure to contain information about address of a service provider.
'
'TYPE ADDRINFO
'  SLONG     .ai_flags         ' Input flags.
'  SLONG     .ai_family        ' Protocol family for socket.
'  SLONG     .ai_socktype      ' Socket type.
'  SLONG     .ai_protocol      ' Protocol for socket.
'  SLONG     .ai_addrlen       ' Length of socket address.
'  XLONG     .ai_addr          ' Socket address for socket TYPE SOCKADDR
'  XLONG     .ai_canonname     ' address of Canonical name CSTRING for service location.
'  XLONG     .ai_next          ' address of next ADDRINFO in list.
'END TYPE
'
' Used in XxxXinSocket
'
'TYPE SOCKETOPEN
'	XLONG  .syssocket
'	XLONG  .whomask
'END TYPE
'
'
'
TYPE SOCKET
	SLONG     .socket						' socket number of this socket
	SLONG     .remote						' remote socket connected to this socket
	SLONG     .syssocket				' socket number to operating system
	SLONG     .sysremote				' remote socket number to operating system
	GIANT     .address					' IP address this socket is bound to
	SLONG     .port							' port this socket is connected to
	SLONG     .whomask					' whomask of program that owns this socket
	SLONG     .hostnumber				' host identifier for XinGetHostData()
	SLONG     .status						' socket status - see $$STATUS constants
	SLONG     .socketType				' type of socket - $$SOCK_STREAM
	SLONG     .addressType			' address type - $$AF_INET
	SLONG     .addressBytes			' bytes in address - 4 for short IP
	SLONG     .addressFamily		' address family - $$AF_INET
	SLONG     .protocolFamily		' protocol family - $$PF_INET
	USHORT    .protocol					' active protocol - $$TCP
	USHORT    .service					' service - $$FTP
END TYPE
'
TYPE HOST
	STRING*32 .name							' "mhpcc.edu"
	STRING*32 .alias[2]					' "mhpcc.net", "mhpcc.org", "mhpcc.com"
	STRING*16 .system						' "Windows", "WindowsNT", "UNIX", "Linux"
	GIANT     .address					' 0x0104215C - can hold longer IP address
	GIANT     .addresses[7]			' host can support 8 more IP addresses
	SLONG     .hostnumber				' native host number
	SLONG     .addressBytes			' 4 for original IP addresses
	SLONG     .addressFamily		' $$AF_INET
	SLONG     .protocolFamily		' $$PF_INET
	SLONG     .protocol					' protocol # for "TCP"
	SLONG     .resv							'
	SLONG     .resw							'
	SLONG     .resx							'
	SLONG     .resy							'
	SLONG     .resz							'
END TYPE
'
'
' Structure to contain information about address of a service provider.
'
TYPE ADDRINFO
  SLONG     .ai_flags         ' Input flags.
  SLONG     .ai_family        ' Protocol family for socket.
  SLONG     .ai_socktype      ' Socket type.
  SLONG     .ai_protocol      ' Protocol for socket.
  SLONG     .ai_addrlen       ' Length of socket address.
  SLONG     .ai_addr          ' Socket address for socket TYPE SOCKADDR
  SLONG     .ai_canonname     ' address of Canonical name CSTRING for service location.
  SLONG     .ai_next          ' address of next ADDRINFO in list.
END TYPE
'
' Used in XxxXinSocket
'
TYPE SOCKETOPEN
	SLONG  .syssocket
	SLONG  .whomask
END TYPE
'
DECLARE FUNCTION  Xin                      ( )
DECLARE FUNCTION  XinInitialize            (@base, @hosts, @version, @sockets, @comments$, @notes$)
DECLARE FUNCTION  XinAddressNumberToString (addr$$, @addr$)
DECLARE FUNCTION  XinAddressStringToNumber (addr$, @addr$$)
DECLARE FUNCTION  XinGetCanonicalName      (canonicalName$)
DECLARE FUNCTION  XinGetDomainName         (domain$)
DECLARE FUNCTION  XinHostNameToInfo        (host$, HOST @info)
DECLARE FUNCTION  XinHostNumberToInfo      (hostnum, HOST @info)
DECLARE FUNCTION  XinHostAddressToInfo     (hostaddr, HOST @info)
DECLARE FUNCTION  XinSocketOpen            (@socket, addressFamily, socketType, flags)
DECLARE FUNCTION  XinSocketBind            (socket, block, address$$, port)
DECLARE FUNCTION  XinSocketListen          (socket, block, flags)
DECLARE FUNCTION  XinSocketAccept          (socket, block, @remote, flags)
DECLARE FUNCTION  XinSocketConnectRequest  (socket, block, address$$, port)
DECLARE FUNCTION  XinSocketConnectStatus   (socket, block, @connected)
DECLARE FUNCTION  XinSocketGetAddress      (socket, @port, @address$$, @remote, @rport, @raddress$$)
DECLARE FUNCTION  XinSocketGetStatus       (socket, @remote, @syssocket, @syserror, @status, @socketType, @readbytes, @writebytes)
DECLARE FUNCTION  XinSocketRead            (socket, block, address, maxbytes, flags, @bytes)
DECLARE FUNCTION  XinSocketSetOptions      (socket, level, optname, addrOptval, bytes)
DECLARE FUNCTION  XinSocketToSystemSocket  (socket, @sysSocket)
DECLARE FUNCTION  XinSocketWrite           (socket, block, address, maxbytes, flags, @bytes)
DECLARE FUNCTION  XinSocketClose           (socket)
DECLARE FUNCTION  XinSetDebug              (state)
DECLARE FUNCTION  XinSetSocketBlocking     (socket)
DECLARE FUNCTION  XinSetSocketNonBlocking  (socket)
'
DECLARE FUNCTION  XxxXinFreeIfaddrs           ()
DECLARE FUNCTION  XxxXinGetIfaddrs            (addrAddrs)
DECLARE FUNCTION  XxxXinSocket                (addressFamily, socketType, flags)
DECLARE FUNCTION  XxxXinSocketConnectRequest  (socket, block, address$$, port)
DECLARE FUNCTION  XxxXinGetNameInfo           (sockaddr, socklen, host$, server$, flags)
DECLARE FUNCTION  XxxXinNTOP                  (af, addr_n, p$)
DECLARE FUNCTION  XxxXinPTON                  (af, p$, sin6Addr$)
DECLARE FUNCTION  ZzzXinCopySocket            (SOCKET socketdb[])   '*cw* 220920++
END EXPORT
'
' blowback functions
'
DECLARE  FUNCTION  XxxXinBlowback          ( )
INTERNAL FUNCTION  Blowback                ( )
'
' support functions
'
INTERNAL FUNCTION  GetLastError            ( )
INTERNAL FUNCTION  AddHost                 (@host, addr, host$)
INTERNAL FUNCTION  SetSocketBlocking       (socket)
INTERNAL FUNCTION  SetSocketNonBlocking    (socket)
INTERNAL FUNCTION  SystemErrorToError      (errno, @error)
'
' emulate C macros for file descriptor bitmaps
'
INTERNAL FUNCTION  FDCLR                   (fildes, FD_SET @fd_set)
INTERNAL FUNCTION  FDSET                   (fildes, FD_SET @fd_set)
INTERNAL FUNCTION  FDISSET                 (fildes, FD_SET @fd_set)
INTERNAL FUNCTION  FDZERO                  (FD_SET @fd_set)
INTERNAL FUNCTION  FDCOUNT                 (FD_SET @fd_set)
'
' emulate Windows functions with UNIX funtions
'
INTERNAL FUNCTION  closesocket             (syssocket)
INTERNAL FUNCTION  ioctlsocket             (syssocket, command, addrValue)
'
EXTERNAL CFUNCTION xb_geterrno		         ()
EXTERNAL CFUNCTION xb_seterrno		         (value)
EXTERNAL FUNCTION  XxxXgrAlarmBlock        ()
EXTERNAL FUNCTION  XxxXgrAlarmUnblock      ()
EXTERNAL FUNCTION  XxxLog2                 (text$, int)
'
' *****  constants  *****
'
' Possible values for `ai_flags' field in `addrinfo' structure.
'
	$$AI_PASSIVE     = 0x0001    ' Socket address is intended for `bind'.
	$$AI_CANONNAME   = 0x0002    ' Request for canonical name.
	$$AI_NUMERICHOST = 0x0004    ' Don't use name resolution.
	$$AI_V4MAPPED    = 0x0008    ' IPv4 mapped addresses are acceptable.
	$$AI_ALL         = 0x0010    ' Return IPv4 mapped and IPv6 addresses.
	$$AI_ADDRCONFIG  = 0x0020    ' Use configuration of this host to choose returned address type..

'
EXPORT
'	$$NETWORKVERSION         = 0x0200
	$$NETWORKVERSION         = 0x0101
'
' SOCKET.status bit definitions
'
	$$SocketStatusOpenSuccess        = 0x00000001		' XinSocketOpen()
	$$SocketStatusBindSuccess        = 0x00000002		' XinSocketBind()
	$$SocketStatusListenSuccess      = 0x00000004		' XinSocketListen()
	$$SocketStatusAcceptSuccess      = 0x00000008		' XinSocketAccept()
	$$SocketStatusConnectRequest     = 0x00000010		' XinSocketConnect()
	$$SocketStatusConnectSuccess     = 0x00000020		' XinSocketConnecting()
	$$SocketStatusConnected          = 0x00000040		' clear on disconnect detect
	$$SocketStatusRemote             = 0x00000080		' remote socket accepted by XinSocketAccept()
'
	$$SocketStatusWaitingReadBuffer  = 0x00000100		' XinSocketRead()
	$$SocketStatusWaitingWriteBuffer = 0x00000200		' XinSocketWrite()
	$$SocketStatusUndefined1         = 0x00000400
	$$SocketStatusUndefined2         = 0x00000800
	$$SocketStatusUndefined3         = 0x00001000
	$$SocketStatusUndefined4         = 0x00002000
	$$SocketStatusUndefined5         = 0x00004000
	$$SocketStatusFailed             = 0x00008000		' network/socket failure
'
' flags argument in XinSocketRead()
'
	$$SocketReadPeekData             = 0x00000002		' leave data in socket
END EXPORT
'
'
' ####################
' #####  Xin ()  #####
' ####################
'
FUNCTION  Xin ()
	SHARED  initialized
	SHARED  bitmask[]
	SOCKADDR_IN  sockaddrin
	SOCKADDR  sockaddr
	HOST  host
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "Linux XBasic sockets/network/internet function library"
	a$ = "maxreason@maxreason.com"
	a$ = ""
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IF initialized THEN RETURN
'
' bitmask[] is for FDCLR(), FDSET(), FDISSET() - only for UNIX / Linux
'
	##WHOMASK = 0
	DIM bitmask[31]
	##WHOMASK = whomask
'
	bitmask [ 0] = 0x00000001
	bitmask [ 1] = 0x00000002
	bitmask [ 2] = 0x00000004
	bitmask [ 3] = 0x00000008
	bitmask [ 4] = 0x00000010
	bitmask [ 5] = 0x00000020
	bitmask [ 6] = 0x00000040
	bitmask [ 7] = 0x00000080
	bitmask [ 8] = 0x00000100
	bitmask [ 9] = 0x00000200
	bitmask [10] = 0x00000400
	bitmask [11] = 0x00000800
	bitmask [12] = 0x00001000
	bitmask [13] = 0x00002000
	bitmask [14] = 0x00004000
	bitmask [15] = 0x00008000
	bitmask [16] = 0x00010000
	bitmask [17] = 0x00020000
	bitmask [18] = 0x00040000
	bitmask [19] = 0x00080000
	bitmask [20] = 0x00100000
	bitmask [21] = 0x00200000
	bitmask [22] = 0x00400000
	bitmask [23] = 0x00800000
	bitmask [24] = 0x01000000
	bitmask [25] = 0x02000000
	bitmask [26] = 0x04000000
	bitmask [27] = 0x08000000
	bitmask [28] = 0x10000000
	bitmask [29] = 0x20000000
	bitmask [30] = 0x40000000
	bitmask [31] = 0x80000000
'
  IF LIBRARY(0) THEN RETURN
  PRINT "Testing Xin.x"
'
' Note:
' - 'initialized' is no longer used to signal of Xin() has been called, but to
'   signal if XinInitialize() has been called.
' - Xin() should not call XinInitialize() to prevent badly configured systems
'   (TCP/IP) to crash the PDE (note: the PDE calls Xin()).
'
' comment out the next two lines to execute this function to debug xin.x
'
'	initialized = $$TRUE
'	XinInitialize (@local, @hosts, @version, @sockets, @comments$, @notes$)
'	IF error THEN initialized = $$FALSE
'	/** Comment the following line out if you want the net tests to run!*/
'	RETURN (error)
'
'	#debug = $$TRUE
'
' *****  clear the console window to reduce confusion  *****
'
	XstClearConsole ()
'
' *****  begin network tests  *****
'
	IF #debug THEN
		PRINT
		PRINT "###########################################"
		PRINT "#####  XBasic Network Functions Test  #####"
		PRINT "###########################################"
		PRINT
		PRINT "#####  XinInitialize (@local, @hosts, @sockets, @version, @comments$, @notes$)  #####"
	END IF
'
	error = XinInitialize (@local, @hosts, @version, @sockets, @comments$, @notes$)
'
' *****  print basic network information  *****
'
	IF #debug THEN
		PRINT
		PRINT "local                  = "; HEX$ (local,8)
		PRINT "hosts                  = "; HEX$ (hosts,8)
		PRINT "sockets                = "; HEX$ (sockets,8)
		PRINT "version                = "; HEX$ (version,8)
		PRINT "comments$              = "; comments$
		PRINT "notes$                 = "; notes$
	END IF
'
'
' *****  print local host information  *****
'
'
	IF #debug THEN
		PRINT "Xin(155)", #debug
		PRINT "#####  XinHostNumberToInfo (base, @info)  #####"
	END IF
'
	XinHostNumberToInfo (0, @host)
	hostaddress = host.address
	address$$ = host.address
	host$ = host.name
'
	IF #debug THEN
		PRINT
		PRINT "host.name              = \""; host.name; "\""
		PRINT "host.alias[0]          = \""; host.alias[0]; "\""
		PRINT "host.alias[1]          = \""; host.alias[1]; "\""
		PRINT "host.alias[2]          = \""; host.alias[2]; "\""
		PRINT "host.system            = \""; host.system; "\""
		PRINT "host.hostnumber        = "; HEX$ (host.hostnumber,8)
		PRINT "host.address           = "; HEX$ (host.address,8); " = "; STRING$(host.address AND 0x000000FF) + "." + STRING$((host.address >> 8) AND 0x000000FF) + "." + STRING$((host.address >> 16) AND 0x000000FF) + "." + STRING$((host.address >> 24) AND 0x000000FF)
	END IF
'
	FOR i = 0 TO 7
		PRINT "host.addresses[" + STRING$(i) + "]      = "; HEX$ (host.addresses[i],8); " = "; STRING$(host.addresses[i] AND 0x000000FF) + "." + STRING$((host.addresses[i] >> 8) AND 0x000000FF) + "." + STRING$((host.addresses[i] >> 16) AND 0x000000FF) + "." + STRING$((host.addresses[i] >> 24) AND 0x000000FF)
	NEXT i
'
	IF #debug THEN
		PRINT "host.addressBytes      = "; HEX$ (host.addressBytes,8)
		PRINT "host.addressFamily     = "; HEX$ (host.addressFamily,8)
		PRINT "host.protocolFamily    = "; HEX$ (host.protocolFamily,8)
		PRINT "host.protocol          = "; HEX$ (host.protocol,8)
	END IF
'
' test ip address/string functions
'
	PRINT
	XinAddressNumberToString (@address$$, @address$)
	PRINT "<"; HEX$(address$$,16); "> <"; address$; "> <";
	XinAddressStringToNumber (@address$, @addr$$)
	PRINT address$; "> <"; HEX$(addr$$,16); ">"
'
'
' *****  open a socket  *****
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketOpen (@socket, addressType, socketType, flags)  #####"
	END IF
'
	flags = 0
	socketType = 0
	addressType = 0
	error = XinSocketOpen (@socket, @addressType, @socketType, flags)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "socket                 = "; HEX$ (socket, 8)
		PRINT "addressType            = "; HEX$ (addressType, 8)
		PRINT "socketType             = "; HEX$ (socketType, 8)
		PRINT "flags                  = "; HEX$ (flags, 8)
	END IF
'
'
' bind to an address and/or port
'
	PRINT
	PRINT "#####  error = XinSocketBind (socket, block, address$$, port)  #####"
'
	block = 0
	port = 0x2020
	error = XinSocketBind (socket, block, address$$, port)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "socket                 = "; HEX$ (socket, 8)
		PRINT "block                  = "; HEX$ (block, 8)
		PRINT "address$$              = "; HEX$ (address$$, 16)
		PRINT "port                   = "; HEX$ (port, 8)
	END IF
'
'
' listen for a client to connect
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketListen (socket, block, flags)  #####"
	END IF

	error = XinSocketListen (socket, block, flags)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "socket                 = "; HEX$ (socket, 8)
		PRINT "block                  = "; HEX$ (block, 8)
		PRINT "flags                  = "; HEX$ (flags, 8)
	END IF
'
'
' accept a connection
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketAccept (socket, block, @remote, flags)  #####"
	END IF
'
	DO UNTIL error
		error = 0
		remote = 0
		block = 20000
		error = XinSocketAccept (socket, block, @remote, flags)
	LOOP UNTIL remote
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "socket                 = "; HEX$ (socket, 8)
		PRINT "block                  = "; HEX$ (block, 8)
		PRINT "remote                 = "; HEX$ (remote, 8)
		PRINT "flags                  = "; HEX$ (flags, 8)
	END IF
'
' check status of socket
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketGetStatus (socket, @remote, @syssocket, @syserror, @status, @sockettype, @readbytes, @writebytes)  #####"
	END IF
'
	error = XinSocketGetStatus (socket, @remote, @syssocket, @syserror, @status, @sockettype, @readbytes, @writebytes)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error,8)
		PRINT "socket                 = "; HEX$ (socket,8)
		PRINT "remote                 = "; HEX$ (remote,8)
		PRINT "syssocket              = "; HEX$ (syssocket,8)
		PRINT "sysremote              = "; HEX$ (sysremote,8)
		PRINT "syserror               = "; HEX$ (syserror,8)
		PRINT "status                 = "; HEX$ (status,8)
		PRINT "sockettype             = "; HEX$ (sockettype,8)
		PRINT "readbytes              = "; HEX$ (readbytes,8)
		PRINT "writebytes             = "; HEX$ (writebytes,8)
	END IF
'
' check status of remote socket
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketGetStatus (rsocket, @rremote, @sysremote, @remerror, @rstatus, @rtype, @rreadbytes, @rwritebytes)  #####"
	END IF
'
	rsocket = remote
	error = XinSocketGetStatus (rsocket, @rremote, @rsyssocket, @rsyserror, @rstatus, @rtype, @readbytes, @writebytes)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error,8)
		PRINT "rsocket                = "; HEX$ (rsocket,8)
		PRINT "rremote                = "; HEX$ (rremote,8)
		PRINT "rsyssocket             = "; HEX$ (rsyssocket,8)
		PRINT "rsyserror              = "; HEX$ (rsyserror,8)
		PRINT "rstatus                = "; HEX$ (rstatus,8)
		PRINT "rtype                  = "; HEX$ (rtype,8)
		PRINT "rreadbytes             = "; HEX$ (readbytes,8)
		PRINT "rwritebytes            = "; HEX$ (writebytes,8)
	END IF
'
' get network addresses of this socket and remote socket
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketGetAddress (socket, @port, @address$$, @remote, @rport, @raddress$$)  #####"
	END IF
'
	error = XinSocketGetAddress (socket, @port, @address$$, @remote, @rport, @raddress$$)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error,8)
		PRINT "port                   = "; HEX$ (port,8)
		PRINT "address$$              = "; HEX$ (address$$,16)
		PRINT "rport                  = "; HEX$ (rport,8)
		PRINT "raddress$$             = "; HEX$ (raddress$$,16)
	END IF
'
'
'
' read and write four timestamp requests from client "aclient.x"
'
	FOR i = 0 TO 3
		GOSUB ReadTimeRequest
		GOSUB WriteTimeString
	NEXT i
'
' blowback
'
	Blowback ()
	RETURN
'
'
'
'
' *****  ReadTimeRequest  *****  read bytes from "aclient.x"
'
SUB ReadTimeRequest
	buffer$ = NULL$ (4096)
	address = &buffer$
	maxbytes = 4096
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketRead (socket, block, address, maxbytes, flags, @bytes)  #####"
	END IF
'
	DO UNTIL error
		bytes = 0
		error = 0
		read$ = ""
		block = 20000
		error = XinSocketRead (socket, block, address, maxbytes, flags, @bytes)
	LOOP UNTIL bytes
'
	IFZ error THEN read$ = LEFT$ (buffer$, bytes)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "socket                 = "; HEX$ (socket, 8)
		PRINT "block                  = "; HEX$ (block, 8)
		PRINT "address                = "; HEX$ (address, 8)
		PRINT "maxbytes               = "; HEX$ (maxbytes, 8)
		PRINT "flags                  = "; HEX$ (flags, 8)
		PRINT "bytes                  = "; HEX$ (bytes, 8)
		PRINT "read                   = \""; read$; "\""
	END IF
END SUB
'
'
' *****  WriteTimeString  *****  write bytes to "aclient.x"
'
SUB WriteTimeString
	GOSUB GetTime
	address = &time$
	maxbytes = SIZE (time$)
'
	IF #debug THEN
		PRINT
		PRINT "#####  error = XinSocketWrite (socket, block, address, maxbytes, flags, @bytes)  #####"
	END IF
'
	bytes = 0
	error = 0
	block = 20000
	error = XinSocketWrite (socket, block, address, maxbytes, flags, @bytes)
'
	IF #debug THEN
		PRINT
		PRINT "error                  = "; HEX$ (error, 8)
		PRINT "socket                 = "; HEX$ (socket, 8)
		PRINT "block                  = "; HEX$ (block, 8)
		PRINT "address                = "; HEX$ (address, 8)
		PRINT "maxbytes               = "; HEX$ (maxbytes, 8)
		PRINT "flags                  = "; HEX$ (flags, 8)
		PRINT "bytes                  = "; HEX$ (bytes, 8)
		PRINT "write                  = \""; LEFT$ (time$, bytes)
	END IF
END SUB
'
'
' *****  GetTime  *****
'
SUB GetTime
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
	length = LEN (time$)
	address = &time$
	sendlen = 0
'
	IF #debug THEN
		PRINT
		PRINT "time                   = \""; time$; "\""
	END IF
END SUB
END FUNCTION
'
'
' ##############################
' #####  XinInitialize ()  #####
' ##############################
'
'	error = XinInitialize (@local, @hosts, @version, @sockets, @comments$, @notes$)
'
'
FUNCTION  XinInitialize (base, hosts, version, sockets, comment$, note$)
	SHARED  initialized
	SHARED  HOST  host[]
	SHARED  WSADATA  wsadata
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
' Note:
' - 'initialized' is used to signal if XinInitialize() has been called, so in
'   general it's $$FALSE here.
'
'	IFZ initialized THEN									' Xin() never called
'		IF #debug THEN PRINT "XinInitialize() : error : Xin() library not initialized : call Xin() first"
'		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
'		old = ERROR (error)
'		RETURN ($$TRUE)
'	END IF
'
' *****  initialize arguments  *****
'
	base = 0
	hosts = 0
	sockets = 0
	version = 0
	system$ = ""
	notes$ = ""
'
'
' *****  get basic network information  *****
'
'	##WHOMASK = 0
'	##LOCKOUT = $$TRUE
'	error = WSAStartup ($$NETWORKVERSION, &wsadata)
'	##LOCKOUT = lockout
'	##WHOMASK = whomask
'
'	IF error THEN
'		xb_seterrno(GetLastError())
'		IF #debug THEN PRINT "WSAStartup() : error : "; xb_geterrno()
'		SystemErrorToError (xb_geterrno(), @error)
'		old = ERROR (error)
'		RETURN ($$TRUE)
'	END IF
'
'
' *****  get local host name  *****
'
	buffer$ = NULL$ (511)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = gethostname (&buffer$, 511)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "gethostname() : error : "; xb_geterrno()
		error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureUnavailable
		XstSetSystemError (xb_geterrno())
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
'
' *****  get default local host name  *****
'
	host$ = TRIM$(CSTRING$(&buffer$))
	IFZ host$ THEN RETURN ($$TRUE)
'
'
' *****  add the default host to the host[] array  *****
'
	addr = 0
	name$ = host$
	AddHost (@host, @addr, @name$)
'
	IF (host < 0) THEN RETURN ($$TRUE)
	IF (addr <= 0) THEN RETURN ($$TRUE)
	IFZ host[] THEN RETURN ($$TRUE)
	IFZ name$ THEN RETURN ($$TRUE)
'
'
' *****  set up return arguments  *****
'
	base = 0
	hosts = UBOUND (host[])+1
	version = wsadata.wVersion
	sockets = wsadata.iMaxSockets
	comment$ = CSTRING$ (&wsadata.szDescription)
	note$ = CSTRING$ (&wsadata.szSystemStatus)
	initialized = $$TRUE
	RETURN ($$FALSE)
END FUNCTION
'
'
' #########################################
' #####  XinAddressNumberToString ()  #####
' #########################################
'
FUNCTION  XinAddressNumberToString (address$$, address$)
	SHARED  initialized
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinAddressNumberToString() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	address$ = ""
	IFZ address$$ THEN RETURN ($$TRUE)
'
	address = address$$
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	addr = inet_ntoa (address)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	address$ = CSTRING$ (addr)
	IFZ address$ THEN RETURN ($$TRUE)
	RETURN ($$FALSE)
END FUNCTION
'
'
' #########################################
' #####  XinAddressStringToNumber ()  #####
' #########################################
'
FUNCTION  XinAddressStringToNumber (address$, address$$)
	SHARED  initialized
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinAddressStringToNumber() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	address$$ = 0
	IFZ address$ THEN RETURN ($$TRUE)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	address$$ = inet_addr (&address$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ address THEN RETURN ($$TRUE)
	RETURN ($$FALSE)
END FUNCTION
'
'
' ####################################
' #####  XinGetCanonicalName ()  #####
' ####################################
'
' error = XinGetCanonicalName (@canonicalName$)
'
FUNCTION  XinGetCanonicalName (canonicalName$)
	ADDRINFO hints, info, p
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	canonicalName$ = ""
'
' *****  get local host name  *****
'
	buffer$ = NULL$ (1024)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = gethostname (&buffer$, 1023)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "gethostname() : error : "; xb_geterrno()
		error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureUnavailable
		XstSetSystemError (xb_geterrno())
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
'
' *****  get default local host name  *****
'
	host$ = TRIM$(CSTRING$(&buffer$))
	IFZ host$ THEN RETURN ($$TRUE)
'
	hints.ai_family   = $$AF_UNSPEC       ' either IPV4 or IPV6
	hints.ai_socktype = $$SOCK_STREAM
	hints.ai_flags    = $$AI_CANONNAME
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getaddrinfo(&host$, &"telnet", &hints, &&info)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "getaddrinfo() : error : "; xb_geterrno()
		error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureUnavailable
		XstSetSystemError (xb_geterrno())
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	canonicalName$ = CSTRING$(info.ai_canonname)  ' take the first occurrence
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	freeaddrinfo (&info)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
END FUNCTION
'
'
' #################################
' #####  XinGetDomainName ()  #####
' #################################
'
' error = XinGetDomainName (@domain$)
'
' *****  get local domain name  *****
'
FUNCTION  XinGetDomainName (domain$)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	buffer$ = NULL$ (63)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getdomainname (&buffer$, 64)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "getdomainname() : error : "; xb_geterrno()
		error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureUnavailable
		XstSetSystemError (xb_geterrno())
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF

	domain$ = TRIM$(CSTRING$(&buffer$))
	IFZ domain$ THEN RETURN ($$TRUE)

END FUNCTION
'
'
' ##################################
' #####  XinHostNameToInfo ()  #####
' ##################################
'
FUNCTION  XinHostNameToInfo (name$, HOST data)
	SHARED  HOST  host[]
	SHARED  initialized
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinHostNameToInfo() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	addr = 0
	host = -1
'
	error = AddHost (@host, @addr, @name$)
'
	IF error THEN
		IF #debug THEN PRINT "XinHostNameToInfo() : error : AddHost() call returned error = " ; error
		RETURN ($$TRUE)
	END IF
'
	IF (host < 0) THEN RETURN ($$TRUE)
'	IF (addr <= 0) THEN RETURN ($$TRUE)
	IFZ host[] THEN RETURN ($$TRUE)
	IFZ name$ THEN RETURN ($$TRUE)
'
	upper = UBOUND (host[])
'
	FOR i = 0 TO upper
		IF (name$ == host[i].name) THEN
			data = host[i]
			RETURN
		END IF
	NEXT i
'
	RETURN ($$TRUE)
END FUNCTION
'
'
' ####################################
' #####  XinHostNumberToInfo ()  #####
' ####################################
'
FUNCTION  XinHostNumberToInfo (id, HOST host)
	SHARED  initialized
	SHARED  HOST  host[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinHostNumberToInfo() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (host[])
	IF (id < 0) THEN RETURN ($$TRUE)
	IF (id > upper) THEN RETURN ($$TRUE)
'
	host = host[id]
	RETURN ($$FALSE)
END FUNCTION
'
'
' #####################################
' #####  XinHostAddressToInfo ()  #####
' #####################################
'
FUNCTION  XinHostAddressToInfo (address, HOST data)
	SHARED  HOST  host[]
	SHARED  initialized
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinHostAddressToInfo() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ address THEN RETURN ($$TRUE)
	upper = UBOUND (host[])
	name$ = ""
	host = -1
'
	error = AddHost (@host, @address, @name$)
'
	IF error THEN
		IF #debug THEN PRINT "XinHostAddressToInfo() : error : AddHost() call returned error = " ; error
		error = ($$ErrorObjectComputer << 8) OR $$ErrorNatureUnknown
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ host THEN RETURN ($$TRUE)
'
	FOR i = 0 TO UBOUND (host[])
		IF (address == host[i].address) THEN
			data = host[i]
			RETURN $$FALSE
		END IF
	NEXT i
'
	RETURN ($$TRUE)
END FUNCTION
'
'
' ##############################
' #####  XinSocketOpen ()  #####
' ##############################
'
' error = XinSocketOpen (@socket, addressFamily, socketType, flags)
'
FUNCTION  XinSocketOpen (socket, addressFamily, socketType, flags)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	SHARED  HOST  host[]
	SOCKET  zero
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketOpen() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' *****  if zero, fill addressFamily and socketType with defaults  *****
'
	IF (addressFamily <= 0) THEN addressFamily = host[0].addressFamily
	IF (socketType <= 0) THEN socketType = $$SOCK_STREAM
'
' *****  open a socket  *****
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	syssocket = socket (addressFamily, socketType, flags)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF #debug THEN PRINT "XinSocketOpen(38)"
	IF (syssocket = -1) THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketOpen() : error : "; xb_geterrno()
		SystemErrorToError (xb_geterrno(), @error)
		XstSetSystemError (xb_geterrno())
		old = ERROR (error)
		socket = $$FALSE
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[] THEN
		##WHOMASK = 0
		DIM socket[1]
		##WHOMASK = whomask
	END IF
'
	upper = UBOUND (socket[])
'
	slot = -1
	FOR i = 1 TO upper
		IFZ socket[i].socket THEN
			slot = i
			EXIT FOR
		END IF
	NEXT i
'
	IF (slot < 0) THEN
		slot = upper + 1
		upper = upper + 1
		##WHOMASK = 0
		REDIM socket[upper]
		##WHOMASK = whomask
	END IF
'
	socket = slot
	socket[socket] = zero
	socket[socket].socket = socket
	socket[socket].whomask = whomask
	socket[socket].syssocket = syssocket
	socket[socket].socketType = socketType
	socket[socket].addressFamily = addressFamily
	socket[socket].protocol = host[0].protocolFamily
	socket[socket].status = $$SocketStatusOpenSuccess
	IF #debug PRINT "XinSocketOpen()", socket, syssocket
'
END FUNCTION
'
'
' ##############################
' #####  XinSocketBind ()  #####
' ##############################
'
FUNCTION  XinSocketBind (socket, block, address$$, port)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	SOCKADDR_IN  sockaddrin
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketBind() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketBind() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	syssocket = socket[socket].syssocket
'
	IF (status AND $$SocketStatusBindSuccess) THEN
		IF #debug THEN PRINT "XinSocketBind() : error : socket bind already complete : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (port <= 0) THEN port = 0
	addressFamily = socket[socket].addressFamily
	IF (address$$ <= 0) THEN address$$ = $$INADDR_ANY
'
' the Windows 2nd argument is sockaddrin
' the Linux 2nd argument is sockaddr - but they overlay and are byte for byte equal - ???
'
	sockaddrin.sin_family = socket[socket].addressFamily
	sockaddrin.sin_port = htons (port)
	sockaddrin.sin_addr = address$$
'
	length = LEN (sockaddrin)
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = bind (syssocket, &sockaddrin, length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (error = -1) THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketBind() : error : "; xb_geterrno()
		SystemErrorToError (xb_geterrno(), @error)
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = status OR $$SocketStatusBindSuccess
	socket[socket].status = status
	address$$ = sockaddrin.sin_addr
	port = sockaddrin.sin_port

END FUNCTION
'
'
' ################################
' #####  XinSocketListen ()  #####
' ################################
'
FUNCTION  XinSocketListen (socket, block, flags)
	SHARED  initialized
	SHARED  SOCKET  socket[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketListen() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketListen() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[socket].socket THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketListen() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	syssocket = socket[socket].syssocket
'
	IFZ syssocket THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketListen() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ (status AND $$SocketStatusBindSuccess) THEN
		IF #debug THEN PRINT "XinSocketListen() : error : need socket bind first : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusListenSuccess) THEN
		IF #debug THEN PRINT "XinSocketListen() : error : socket listen already successful : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = listen (syssocket, 1)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (error = -1) THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketListen() : error : "; xb_geterrno()
		SystemErrorToError (xb_geterrno(), @error)
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = status OR $$SocketStatusListenSuccess
	socket[socket].status = status
END FUNCTION
'
'
' ################################
' #####  XinSocketAccept ()  #####
' ################################
'
FUNCTION  XinSocketAccept (socket, block, remote, flags)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	SOCKADDR_IN  sockaddrin
	FD_SET  readset
	FD_SET  writeset
	FD_SET  errorset
	TIMEVAL  timeval
	AUTOX  length
	SOCKET  zero
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketAccept() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	remote = $$FALSE
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketAccept() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[socket].socket THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketAccept() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	syssocket = socket[socket].syssocket
'
	IFZ syssocket THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketAccept() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ (status AND $$SocketStatusListenSuccess) THEN
		IF #debug THEN PRINT "XinSocketAccept() : error : need socket listen first : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusAcceptSuccess) THEN
		IF #debug THEN PRINT "XinSocketAccept() : error : socket accept already successful : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnectRequest) THEN
		IF #debug THEN PRINT "XinSocketAccept() : error : socket connect request already pending : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnectSuccess) THEN
		IF #debug THEN PRINT "XinSocketAccept() : error : socket connect request already successful : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	SELECT CASE TRUE
		CASE (block < 1)			: block = 0				' do not block
		CASE (block < 10)			: block = 10			' min block = 10us
		CASE (block > 20000)	: block = 20000		' max block = 20ms
	END SELECT
'
	IF (block <= 0) THEN
		timeval.tv_sec = 0				' non-blocking
		timeval.tv_usec = 0				'
	ELSE
		timeval.tv_sec = 0				' blocking up to 20ms maximum
		timeval.tv_usec = block		'
	END IF
'
	FDZERO (@readset)
	FDZERO (@errorset)
	FDSET (syssocket, @readset)
	FDSET (syssocket, @errorset)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	XxxXgrAlarmBlock ()
	count = select (syssocket+1, &readset, 0, &errorset, &timeval)
	XxxXgrAlarmUnblock ()
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
' (count = 0) means no connection attempt yet
'
	IF (count = 0) THEN RETURN ($$FALSE)
'
' (count < 0) means an error occured
'
	IF (count < 0) THEN
		IF #debug THEN PRINT "XinSocketAccept(122) : error : select() reported error : "; socket; xb_geterrno()
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
		socket[socket].status = status OR $$SocketStatusFailed
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' (count > 0) means something was detected
'
' see if the socket or network died prior to accept success
'
	hit = FDISSET (syssocket, @errorset)
	IF hit THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketAccept(136) : error : select() reported error : "; socket; xb_geterrno()
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
		socket[socket].status = status OR $$SocketStatusFailed
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' select() indicates success of an accept by saying socket is readable
'
	remote = $$FALSE
	sysremote = $$FALSE
'
	hit = FDISSET (syssocket, @readset)
	IF hit THEN
		length = SIZE (sockaddrin)
'
		##WHOMASK = 0
		##LOCKOUT = $$TRUE
		sysremote = accept (syssocket, &sockaddrin, &length)
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
		IF (sysremote <= 0) THEN
			xb_seterrno(GetLastError())
			IF #debug THEN PRINT "XinSocketAccept(160) : error : accept() reported error : "; socket; xb_geterrno()
			error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
			socket[socket].status = status OR $$SocketStatusFailed
			old = ERROR (error)
			remote = $$FALSE
			RETURN ($$TRUE)
		END IF
'
		upper = UBOUND (socket[])
'
		slot = -1
		FOR i = 1 TO upper
			IFZ socket[i].socket THEN
				slot = i
				EXIT FOR
			END IF
		NEXT i
'
		IF (slot < 0) THEN
			slot = upper + 1
			upper = upper + 1
			##WHOMASK = 0
			REDIM socket[upper]
			##WHOMASK = whomask
		END IF
'
		remote = slot
		socket[remote] = zero
		socket[remote].hostnumber = -1
		socket[remote].socket = remote
		socket[remote].remote = socket
		socket[remote].whomask = whomask
		socket[remote].syssocket = sysremote
		socket[remote].sysremote = syssocket
		socket[remote].port = sockaddrin.sin_port
		socket[remote].address = sockaddrin.sin_addr
		socket[remote].protocol = socket[socket].protocol
		socket[remote].socketType = socket[socket].socketType
		socket[remote].addressType = socket[socket].addressType
		socket[remote].addressBytes = socket[socket].addressBytes
		socket[remote].addressFamily = sockaddrin.sin_family
		socket[remote].status = $$SocketStatusRemote OR $$SocketStatusConnected
'
		socket[socket].status = status OR $$SocketStatusAcceptSuccess OR $$SocketStatusConnected
		socket[socket].sysremote = sysremote
		socket[socket].remote = remote
		RETURN ($$FALSE)
	END IF
END FUNCTION
'
'
' ########################################
' #####  XinSocketConnectRequest ()  #####
' ########################################
'
FUNCTION  XinSocketConnectRequest (socket, block, address$$, port)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	SOCKADDR_IN  sockaddrin
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	syssocket = socket[socket].syssocket
'
	IFZ (status AND $$SocketStatusBindSuccess) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : need socket bind first : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnectRequest) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : socket connect request already made : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnectSuccess) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : socket connect success already detected : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnected) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : socket connect request already connected : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' set socket non-blocking so connect() doesn't block
'
	error = SetSocketNonBlocking
	IF error THEN RETURN ($$TRUE)
'
' send connect request - connect probably will not happen now
'
	sockaddrin.sin_family = $$AF_INET
	sockaddrin.sin_addr = address$$
	' Note: the user specifies the port-number in 'host order'; but sin_port
	' must be in 'network order' (big endian).
	sockaddrin.sin_port = htons(port)

	length = LEN (sockaddrin)
	connected = $$FALSE
	xb_seterrno($$FALSE)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = connect (syssocket, &sockaddrin, length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	SELECT CASE TRUE
		CASE (error = 0)	: connected = $$TRUE
												SetSocketNonBlocking (socket)
												status = status OR $$SocketStatusConnectRequest
												status = status OR $$SocketStatusConnectSuccess
		CASE (error < 0)	: xb_seterrno(GetLastError())
												SELECT CASE xb_geterrno()
													CASE $$WSAEWOULDBLOCK:
														xb_seterrno($$FALSE)
														status = status OR $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusConnected
													CASE ELSE:
														IF #debug THEN PRINT "XinSocketConnectRequest() : error : "; socket; xb_geterrno()
														status = status AND NOT $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusConnected
														status = status OR $$SocketStatusFailed
												END SELECT
		CASE (error > 0)	: xb_seterrno(GetLastError())
												SELECT CASE xb_geterrno()
													CASE $$WSAEWOULDBLOCK	: xb_seterrno($$FALSE)
													CASE ELSE							: IF #debug THEN PRINT "XinSocketConnectRequest() : error : "; socket; xb_geterrno()
												END SELECT
												status = status AND NOT $$SocketStatusConnectRequest
												status = status AND NOT $$SocketStatusConnected
												status = status OR $$SocketStatusFailed
	END SELECT
'
	socket[socket].status = status
	IF xb_geterrno() THEN RETURN (xb_geterrno())
'
' if not connected, see if a short block was requested
'
	IFZ connected THEN
		SELECT CASE TRUE
			CASE (block < 1)			: block = 0				' do not block
			CASE (block < 10)			: block = 10			' min block = 10us
			CASE (block > 20000)	: block = 20000		' max block = 20ms
		END SELECT
'
		IF block THEN
			error = XinSocketConnectStatus (socket, block, @connected)
			IF error THEN
				status = status AND NOT $$SocketStatusConnectRequest
				status = status AND NOT $$SocketStatusConnected
				status = status OR $$SocketStatusFailed
				socket[socket].status = status
				RETURN ($$TRUE)
			END IF
		END IF
	END IF
'
' if connected, mark status as connected
'
	IF connected THEN
		status = status OR $$SocketStatusConnectRequest
		status = status OR $$SocketStatusConnectSuccess
	END IF
'
	socket[socket].status = status
'
	IF connected THEN
		error = SetSocketBlocking (socket)
		IF error THEN RETURN ($$TRUE)
	END IF
	RETURN ($$FALSE)
END FUNCTION
'
'
' #######################################
' #####  XinSocketConnectStatus ()  #####
' #######################################
'
FUNCTION  XinSocketConnectStatus (socket, block, @connected)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	FD_SET  readset
	FD_SET  writeset
	FD_SET  errorset
	TIMEVAL  timeval
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketConnectStatus() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	connected = $$FALSE
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketConnectStatus() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	syssocket = socket[socket].syssocket
'
	IF (socket[socket].socket <= 0) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketConnectStatus() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ syssocket THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketConnectStatus() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ (status AND $$SocketStatusConnectRequest) THEN
		IFZ (status AND $$SocketStatusAcceptSuccess) THEN
			IF #debug THEN PRINT "XinSocketConnectStatus() : error : need socket accept or connect request first : "; socket
			error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
			old = ERROR (error)
			RETURN ($$TRUE)
		END IF
	END IF
'
	IF (status AND $$SocketStatusConnected) THEN		' already connected
		connected = $$TRUE
		RETURN ($$FALSE)
	END IF
'
' figure blocking time
'
	SELECT CASE TRUE
		CASE (block < 1)			: block = 0				' do not block
		CASE (block < 10)			: block = 10			' min block = 10us
		CASE (block > 20000)	: block = 20000		' max block = 20ms
	END SELECT
'
	IF (block <= 0) THEN
		timeval.tv_sec = 0				' non-blocking
		timeval.tv_usec = 0				'
	ELSE
		timeval.tv_sec = 0				' blocking up to 20ms maximum
		timeval.tv_usec = block		'
	END IF
'
	connected = $$FALSE
'
	FDZERO (@writeset)
	FDZERO (@errorset)
	FDSET (syssocket, @writeset)
	FDSET (syssocket, @errorset)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	count = select (syssocket+1, 0, &writeset, &errorset, &timeval)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
' (count = 0) means no connection attempt yet
' (count < 0) means an error occured
' (count > 0) means connection success - probably
'
	SELECT CASE TRUE
		CASE (count = 0)		: RETURN ($$FALSE)		' not yet connected
		CASE (count < 0)		: xb_seterrno(GetLastError())
													IF #debug THEN PRINT "XinSocketConnectStatus() : error : select() reported error : "; socket; xb_geterrno()
													error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
													status = status AND NOT $$SocketStatusConnectSuccess
													status = status AND NOT $$SocketStatusConnected
													status = status OR $$SocketStatusFailed
													socket[socket].status = status
													connected = $$FALSE
													old = ERROR (error)
													RETURN ($$TRUE)
		CASE (count > 0)		: hit = FDISSET (syssocket, @errorset)
													IF hit THEN
														xb_seterrno(GetLastError())
														IF #debug THEN PRINT "XinSocketConnectStatus() : error : select() reported error : "; socket; xb_geterrno()
														error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
														status = status AND NOT $$SocketStatusConnectSuccess
														status = status AND NOT $$SocketStatusConnected
														status = status OR $$SocketStatusFailed
														socket[socket].status = status
														connected = $$FALSE
														old = ERROR (error)
														RETURN ($$TRUE)
													END IF
													hit = FDISSET (syssocket, @writeset)
													IF hit THEN
														status = status OR $$SocketStatusConnectSuccess
														status = status OR $$SocketStatusConnected
														socket[socket].status = status
														SetSocketBlocking (socket)
														connected = $$TRUE
														RETURN ($$FALSE)
													END IF
	END SELECT
END FUNCTION
'
'
' ####################################
' #####  XinSocketGetAddress ()  #####
' ####################################
'
FUNCTION  XinSocketGetAddress (socket, port, address$$, remote, rport, raddress$$)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	SOCKADDR_IN  sockaddrin
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketGetAddress() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	port = 0
	rport = 0
	remote = 0
	address$$ = 0
	raddress$$ = 0
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		IF #debug THEN PRINT "XinSocketGetAddress() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[socket].socket THEN
		IF #debug THEN PRINT "XinSocketGetAddress() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	syssocket = socket[socket].syssocket
'
	IF (syssocket <= 0) THEN
		IF #debug THEN PRINT "XinSocketGetAddress() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' getting address information is handled differently for server and client sockets
'
	remote = socket[socket].remote
	sysremote = socket[remote].syssocket
	IF remote THEN GOSUB Server ELSE GOSUB Client
	RETURN ($$FALSE)
'
'
' *****  Server  *****
'
' server sockets have remote socket numbers for the remote sockets connected to them
' to get the address of a remote client socket, servers getpeername() the remote socket
'
SUB Server
	length = SIZE (sockaddrin)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getsockname (sysremote, &sockaddrin, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	xb_seterrno(GetLastError())
'
	address$$ = sockaddrin.sin_addr
	port = sockaddrin.sin_port
'
	length = SIZE (sockaddrin)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getpeername (sysremote, &sockaddrin, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	raddress$$ = sockaddrin.sin_addr
	rport = sockaddrin.sin_port
END SUB
'
'
' *****  Client  *****
'
' client sockets do not have an associated "remote" socket like servers do
' to get the address of the remote server socket, clients getpeername() of their own socket
'
SUB Client
	length = SIZE (sockaddrin)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getsockname (syssocket, &sockaddrin, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	address$$ = sockaddrin.sin_addr
	port = sockaddrin.sin_port
'
	length = SIZE (sockaddrin)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getpeername (syssocket, &sockaddrin, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	raddress$$ = sockaddrin.sin_addr
	rport = sockaddrin.sin_port
	remote = 0
END SUB
END FUNCTION
'
'
' ###################################
' #####  XinSocketGetStatus ()  #####
' ###################################
'
FUNCTION  XinSocketGetStatus (socket, @remote, @syssocket, @syserror, @status, @socketType, @readbytes, @writebytes)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	AUTOX  rbytes
	AUTOX  wbytes
	AUTOX  serror
	AUTOX  stype
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketGetStatus() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	stype = 0
	serror = 0
	rbytes = 0
	wbytes = 0
	remote = 0
	status = 0
	syssocket = 0
	readbytes = 0
	writebytes = 0
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		IF #debug THEN PRINT "XinSocketGetStatus() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[socket].socket THEN
		IF #debug THEN PRINT "XinSocketGetStatus() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	syssocket = socket[socket].syssocket
'
	IF (syssocket <= 0) THEN
		IF #debug THEN PRINT "XinSocketGetStatus() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	remote = socket[socket].remote
	status = socket[socket].status
'
' get size of socket read buffer
'
	level = $$SOL_SOCKET
	optname = $$SO_RCVBUF
	length = LEN (rbytes)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getsockopt (syssocket, level, optname, &rbytes, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ error THEN readbytes = rbytes
'
' get size of socket read buffer
'
	level = $$SOL_SOCKET
	optname = $$SO_SNDBUF
	length = LEN (wbytes)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getsockopt (syssocket, level, optname, &wbytes, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ error THEN writebytes = wbytes
'
' get pending socket error if any
'
	level = $$SOL_SOCKET
	optname = $$SO_ERROR
	length = LEN (serror)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getsockopt (syssocket, level, optname, &serror, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ error THEN syserror = serror
'
' get socket type - as in $$SOCKET_STREAM, the only supported type
'
	level = $$SOL_SOCKET
	optname = $$SO_TYPE
	length = LEN (stype)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = getsockopt (syssocket, level, optname, &stype, &length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ error THEN socketType = stype
	RETURN ($$FALSE)
END FUNCTION
'
'
' ##############################
' #####  XinSocketRead ()  #####
' ##############################
'
FUNCTION  XinSocketRead (socket, block, address, maxbytes, flags, bytes)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	FD_SET  readset
	FD_SET  writeset
	FD_SET  errorset
	TIMEVAL  timeval
	AUTOX  length
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IF lockout THEN XxxLog2 (@"Xgr()lockout", lockout) : lockout = 0
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketRead() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	bytes = 0
	error = $$FALSE
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		IF #debug THEN PRINT "XinSocketRead() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (socket != socket[socket].socket) THEN
		IF #debug THEN PRINT "XinSocketRead() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	remote = socket[socket].remote
	IFZ remote THEN remote = socket
	syssocket = socket[socket].syssocket
	sysremote = socket[socket].sysremote
'
	IF sysremote THEN
		IF (status AND $$SocketStatusAcceptSuccess) THEN syssocket = sysremote
	END IF
'
	IFZ syssocket THEN
		IF #debug THEN PRINT "XinSocketRead() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ address THEN
		IF #debug THEN PRINT "XinSocketRead() : error : (address = 0) : "; socket
		error = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (maxbytes <= 0) THEN
		IF #debug THEN PRINT "XinSocketRead() : error : (maxbytes <= 0) : "; socket
		error = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ syssocket THEN
		IF #debug THEN PRINT "XinSocketRead() : error : no remote socket : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ (status AND $$SocketStatusConnected) THEN
		IF #debug THEN PRINT "XinSocketRead() : error : socket not connected : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	DO
		IF (block < 0) THEN block = 0
		IF (block > 20) THEN
			time = 20000                  '20000 microseconds = 20 milliseconds
			block = block - 20
		ELSE
			time = block * 1000
			block = 0
		END IF
		'
		timeval.tv_sec = 0
		timeval.tv_usec = time
		'
		FDZERO (@readset)
		FDZERO (@errorset)
		FDSET (syssocket, @readset)
		FDSET (syssocket, @errorset)
		'
		##WHOMASK = 0
		##LOCKOUT = $$TRUE
		count = select (syssocket+1, &readset, 0, &errorset, &timeval)
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IF (count > 0) THEN EXIT DO     ' exit if socket has data to read
		XxxCheckMessages ()
		IF ##USERABORT THEN EXIT DO
	LOOP WHILE block                  ' loop until block time expires
'
' (count = 0) means no data ready to read
'
	IF (count = 0) THEN RETURN ($$FALSE)
'
' (count < 0) means an error occured
'
	IF (count < 0) THEN
		xb_seterrno(GetLastError())
		IF ERROR (-1) THEN
			PRINT "ERROR (-1)", ERROR (-1)
			IF #debug THEN PRINT "XinSocketRead(129) : error : select() reported error : "; socket; xb_geterrno()
			error = ($$ErrorObjectSystemFunction << 8) + $$ErrorNatureFailed
			old = ERROR (error)
			PRINT "ERROR()", old
			RETURN ($$TRUE)
		END IF
		RETURN ($$FALSE)
	END IF
'
' (count > 0) means something was detected
'
' see if the socket or network died prior to select()
'
	hit = FDISSET (syssocket, @errorset)
	IF hit THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketRead(145) : error : select() reported error : "; socket; xb_geterrno()
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
		status = status AND NOT $$SocketStatusConnected
		status = status OR $$SocketStatusFailed
		socket[socket].status = status
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' see if select() indicates bytes are available to read
'
	hit = FDISSET (syssocket, @readset)
	IF hit THEN
		##WHOMASK = 0
		##LOCKOUT = $$TRUE
		bytes = recv (syssocket, address, maxbytes, flags)
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
		SELECT CASE TRUE
			CASE (bytes > 0)	: address = address + bytes
			CASE (bytes = 0)	: error = ($$ErrorObjectSocket << 8) + $$ErrorNatureDisconnected
													status = status AND NOT $$SocketStatusConnectSuccess
													status = status AND NOT $$SocketStatusConnectRequest
													status = status AND NOT $$SocketStatusAcceptSuccess
													status = status AND NOT $$SocketStatusConnected
													socket[socket].status = status
													IF remote THEN
														status = socket[remote].status
														status = status AND NOT $$SocketStatusConnectSuccess
														status = status AND NOT $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusAcceptSuccess
														status = status AND NOT $$SocketStatusConnected
														socket[remote].status = status
													END IF
													old = ERROR (error)
													RETURN ($$TRUE)
			CASE (bytes < 0)	: xb_seterrno(GetLastError())
													connected = $$TRUE
													error = $$TRUE
													bytes = 0
													SELECT CASE xb_geterrno()
														CASE $$WSAEWOULDBLOCK
														CASE $$WSAECONNABORTED	: connected = $$FALSE
														CASE $$WSAECONNRESET		: connected = $$FALSE
														CASE $$WSAESHUTDOWN			: connected = $$FALSE
														CASE $$WSAENOTCONN			: connected = $$FALSE
														CASE $$WSAENETDOWN			: connected = $$FALSE
														CASE ELSE								: connected = $$FALSE
													END SELECT
													IF #debug THEN PRINT "XinSocketWrite(195) : error : recv() reported error : "; socket; xb_geterrno()
													IFZ connected THEN
														error = ($$ErrorObjectSocket << 8) + $$ErrorNatureDisconnected
														status = status AND NOT $$SocketStatusConnectSuccess
														status = status AND NOT $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusAcceptSuccess
														status = status AND NOT $$SocketStatusConnected
														socket[socket].status = status
														IF remote THEN
															status = socket[remote].status
															status = status AND NOT $$SocketStatusConnectSuccess
															status = status AND NOT $$SocketStatusConnectRequest
															status = status AND NOT $$SocketStatusAcceptSuccess
															status = status AND NOT $$SocketStatusConnected
															socket[remote].status = status
														END IF
													END IF
													old = ERROR (error)
													RETURN ($$TRUE)
		END SELECT
	END IF
END FUNCTION
'
'
' ####################################
' #####  XinSocketSetOptions ()  #####
' ####################################
'
' $$SO_REUSEADDR should be set before bind
' SO_LINGER    should be set before close
'
'
FUNCTION  XinSocketSetOptions (socket, level, optname, addrOptval, bytes)
	SHARED  initialized
	SHARED  SOCKET  socket[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketSetOptions() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketSetOptions() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[socket].socket THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketSetOptions() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	syssocket = socket[socket].syssocket
'
	IFZ syssocket THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketSetOptions() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (optname AND $$SO_REUSEADDR) THEN
		IF (status AND $$SocketStatusBindSuccess) THEN
			IF #debug THEN PRINT "XinSocketSetOptions() : error : need $$SO_REUSEADDR before socket bind : "; socket
			error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
			old = ERROR (error)
			RETURN ($$TRUE)
		END IF
	END IF
'
'	IF (status AND $$SocketStatusListenSuccess) THEN
'		IF #debug THEN PRINT "XinSocketSetOptions() : error : socket listen already successful : "; socket
'		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
'		old = ERROR (error)
'		RETURN ($$TRUE)
'	END IF
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = setsockopt (syssocket, level, optname, addrOptval, bytes)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (error = -1) THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketSetOptions() : error : "; xb_geterrno()
		SystemErrorToError (xb_geterrno(), @error)
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
'	status = status OR $$SocketStatusListenSuccess
'	socket[socket].status = status
END FUNCTION
'
'
' ########################################
' #####  XinSocketToSystemSocket ()  #####
' ########################################
'
' XinSocketToSystemSocket (socket, @sysSocket)
'
' sysSocket = zero if no match found
'
FUNCTION  XinSocketToSystemSocket (socket, sysSocket)
	SHARED  SOCKET  socket[]
'
	sysSocket = 0
	IF socket[] THEN
		upper = UBOUND (socket[])
		IF (socket <= upper) THEN
			IF (socket == socket[socket].socket) THEN
				sysSocket = socket[socket].syssocket
			ELSE
				PRINT "XinSocketToSystemSocket()", socket, socket[socket].socket, socket[socket].syssocket
			END IF
		END IF
	END IF
'
END FUNCTION
'
'
' ###############################
' #####  XinSocketWrite ()  #####
' ###############################
'
FUNCTION  XinSocketWrite (socket, block, address, maxbytes, flags, bytes)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	FD_SET  readset
	FD_SET  writeset
	FD_SET  errorset
	TIMEVAL  timeval
	AUTOX  length
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketWrite() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	bytes = 0
	error = $$FALSE
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		IF #debug THEN PRINT "XinSocketWrite() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ address THEN
		IF #debug THEN PRINT "XinSocketWrite() : error : (address = 0) : "; socket
		error = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (maxbytes <= 0) THEN
		IF #debug THEN PRINT "XinSocketWrite() : error : (maxbytes <= 0) : "; socket
		error = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	remote = socket[socket].remote
	IFZ remote THEN remote = socket
	syssocket = socket[socket].syssocket
	sysremote = socket[socket].sysremote
	IF (status AND $$SocketStatusAcceptSuccess) THEN syssocket = sysremote
'
	IFZ syssocket THEN
		IF #debug THEN PRINT "XinSocketWrite() : error : no remote socket : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ (status AND $$SocketStatusConnected) THEN
		IF #debug THEN PRINT "XinSocketWrite() : error : socket not connected : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	SELECT CASE TRUE
		CASE (block < 1)			: block = 0				' do not block
		CASE (block < 10)			: block = 10			' min block = 10us
		CASE (block > 20000)	: block = 20000		' max block = 20ms
	END SELECT
'
	IF (block <= 0) THEN
		timeval.tv_sec = 0				' non-blocking
		timeval.tv_usec = 0				'
	ELSE
		timeval.tv_sec = 0				' blocking up to 20ms maximum
		timeval.tv_usec = block		'
	END IF
'
	FDZERO (@writeset)
	FDZERO (@errorset)
	FDSET (syssocket, @writeset)
	FDSET (syssocket, @errorset)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	count = select (syssocket+1, 0, &writeset, &errorset, &timeval)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
' (count = 0) means no connection attempt yet
'
	IF (count = 0) THEN RETURN ($$FALSE)
'
' (count < 0) means an error occured
'
	IF (count < 0) THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketWrite() : error : select() reported error : "; socket; xb_geterrno()
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
		socket[socket].status = status OR $$SocketStatusFailed
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' (count > 0) means something was detected
'
' see if the socket or network died prior to accept success
'
	hit = FDISSET (syssocket, @errorset)
	IF hit THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "XinSocketWrite() : error : select() reported error : "; socket; xb_geterrno()
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
		socket[socket].status = status OR $$SocketStatusFailed
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' see if select() indicates bytes can be written
'
	hit = FDISSET (syssocket, @writeset)
	IF hit THEN
		##WHOMASK = 0
		##LOCKOUT = $$TRUE
		bytes = send (syssocket, address, maxbytes, flags)
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
		SELECT CASE TRUE
			CASE (bytes > 0)	: address = address + bytes
			CASE (bytes = 0)	: error = ($$ErrorObjectSocket << 8) + $$ErrorNatureDisconnected
													status = status AND NOT $$SocketStatusConnectSuccess
													status = status AND NOT $$SocketStatusConnectRequest
													status = status AND NOT $$SocketStatusAcceptSuccess
													status = status AND NOT $$SocketStatusConnected
													socket[socket].status = status
													IF remote THEN
														status = socket[remote].status
														status = status AND NOT $$SocketStatusConnectSuccess
														status = status AND NOT $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusAcceptSuccess
														status = status AND NOT $$SocketStatusConnected
														socket[remote].status = status
													END IF
													old = ERROR (error)
													RETURN ($$TRUE)
			CASE (bytes < 0)	: xb_seterrno(GetLastError())
													connected = $$TRUE
													error = $$TRUE
													bytes = 0
													SELECT CASE xb_geterrno()
														CASE $$WSAEWOULDBLOCK
														CASE $$WSAECONNABORTED	: connected = $$FALSE
														CASE $$WSAECONNRESET		: connected = $$FALSE
														CASE $$WSAESHUTDOWN			: connected = $$FALSE
														CASE $$WSAENOTCONN			: connected = $$FALSE
														CASE $$WSAENETDOWN			: connected = $$FALSE
														CASE ELSE								: connected = $$FALSE
													END SELECT
													IF #debug THEN PRINT "XinSocketWrite() : error : recv() reported error : "; socket; xb_geterrno()
													IFZ connected THEN
														error = ($$ErrorObjectSocket << 8) + $$ErrorNatureDisconnected
														status = status AND NOT $$SocketStatusConnectSuccess
														status = status AND NOT $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusAcceptSuccess
														status = status AND NOT $$SocketStatusConnected
														socket[socket].status = status
														IF remote THEN
															status = socket[remote].status
															status = status AND NOT $$SocketStatusConnectSuccess
															status = status AND NOT $$SocketStatusConnectRequest
															status = status AND NOT $$SocketStatusAcceptSuccess
															status = status AND NOT $$SocketStatusConnected
															socket[remote].status = status
														END IF
													END IF
													old = ERROR (error)
													RETURN ($$TRUE)
		END SELECT
	END IF
END FUNCTION
'
'
' ###############################
' #####  XinSocketClose ()  #####
' ###############################
'
FUNCTION  XinSocketClose (socket)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	SHARED  SOCKETOPEN socketopen[]
	SOCKET  zero
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	FOR i = 0 TO UBOUND(socketopen[])
		IF socketopen[i].whomask THEN
			syssocket = socketopen[i].syssocket
			IF syssocket THEN
				##WHOMASK = 0
				##LOCKOUT = $$TRUE
				close (syssocket)
				##LOCKOUT = lockout
				##WHOMASK = whomask
				socketopen[i].syssocket = 0
			END IF
			socketopen[i].whomask = 0
		END IF
	NEXT i
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketClose() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (socket[])
'
' socket = -1 means "close all my sockets"
'
	IF (socket = -1) THEN
		FOR i = 0 TO upper
			who = socket[i].whomask
			socket = socket[i].socket
			syssocket = socket[i].syssocket
			IF socket THEN
				IF syssocket THEN
					IF socket[i].whomask THEN
						IF whomask THEN
							IF #debug THEN PRINT "XinSocketClose(-1) : "; socket[i].socket; socket[i].syssocket;; HEX$(socket[i].whomask,8)
							##WHOMASK = 0
							##LOCKOUT = $$TRUE
							closesocket (syssocket)
							##LOCKOUT = lockout
							##WHOMASK = whomask
							socket[i] = zero
						END IF
					ELSE
						IFZ whomask THEN
							IF #debug THEN PRINT "XinSocketClose(-1) : "; socket; syssocket
							##WHOMASK = 0
							##LOCKOUT = $$TRUE
							closesocket (syssocket)
							##LOCKOUT = lockout
							##WHOMASK = whomask
							socket[i] = zero
						END IF
					END IF
				END IF
			END IF
		NEXT i
		socket = -1
		RETURN ($$FALSE)
	END IF
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		IF #debug THEN PRINT "XinSocketClose() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	who = socket[socket].whomask
	syssocket = socket[socket].syssocket
'
	IF (syssocket <= 0) THEN
		IF #debug THEN PRINT "XinSocketClose() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = closesocket (syssocket)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF #debug THEN PRINT "XinSocketClose() : "; socket; syssocket
	socket[socket] = zero
'
	FOR i = 1 TO upper
		IF (socket = socket[i].remote) THEN
			socket[i].status = socket[i].status AND NOT $$SocketStatusConnected
			socket[i].remote = 0
		END IF
	NEXT i
END FUNCTION
'
'
' ############################
' #####  XinSetDebug ()  #####
' ############################
'
FUNCTION  XinSetDebug (state)
'
	#debug = state
	PRINT "XinSetDebug()", #debug
END FUNCTION
'
'
' #####################################
' #####  XinSetSocketBlocking ()  #####
' #####################################
'
FUNCTION  XinSetSocketBlocking (socket)

	rc = SetSocketBlocking (socket)
	RETURN rc

END FUNCTION
'
'
' ########################################
' #####  XinSetSocketNonBlocking ()  #####
' ########################################
'
FUNCTION  XinSetSocketNonBlocking (socket)

	rc = SetSocketNonBlocking (socket)
	RETURN rc

END FUNCTION
'
'
' ##################################
' #####  XxxXinFreeIfaddrs ()  #####
' ##################################
'
FUNCTION  XxxXinFreeIfaddrs ()
	SHARED  holdIfaddress

	whomask = ##WHOMASK
	lockout = ##LOCKOUT

	IF holdIfaddress THEN
		##WHOMASK = 0
		##LOCKOUT = $$TRUE
		freeifaddrs (holdIfaddress)
		##LOCKOUT = lockout
		##WHOMASK = whomask
		holdIfaddress = 0
	END IF

END FUNCTION
'
'
' #################################
' #####  XxxXinGetIfaddrs ()  #####
' #################################
'
FUNCTION  XxxXinGetIfaddrs (addrAddrs)
	SHARED  holdIfaddress

	whomask = ##WHOMASK
	lockout = ##LOCKOUT

	XxxXinFreeIfaddrs ()

	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	getifaddrs (&addrAddrs)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	holdIfaddress = addrAddrs

END FUNCTION
'
'
' #############################
' #####  XxxXinSocket ()  #####
' #############################
'
' syssocket = XxxXinSocket (addressFamily, socketType, flags)
'
FUNCTION  XxxXinSocket (addressFamily, socketType, flags)
	SHARED  SOCKETOPEN socketopen[]

	lockout = ##LOCKOUT
	whomask = ##WHOMASK

	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	syssocket = socket (addressFamily, socketType, flags)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	uSyssocket = UBOUND(socketopen[])
	IF (syssocket > uSyssocket) THEN
		REDIM socketopen[syssocket]
	END IF
	socketopen[syssocket].syssocket = syssocket
	socketopen[syssocket].whomask   = whomask

	RETURN syssocket

END FUNCTION
'
'
' ########################################
' #####  XinSocketConnectRequest ()  #####
' ########################################
'
FUNCTION  XxxXinSocketConnectRequest (socket, block, address$$, port)
	SHARED  initialized
	SHARED  SOCKET  socket[]
	SOCKADDR_IN  sockaddrin
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : undefined socket #"
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	status = socket[socket].status
	syssocket = socket[socket].syssocket
'
	IFZ (status AND $$SocketStatusBindSuccess) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : need socket bind first : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnectRequest) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : socket connect request already made : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnectSuccess) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : socket connect success already detected : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (status AND $$SocketStatusConnected) THEN
		IF #debug THEN PRINT "XinSocketConnectRequest() : error : socket connect request already connected : "; socket
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureInvalidRequest
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' set socket non-blocking so connect() doesn't block
'
	error = SetSocketNonBlocking
	IF error THEN RETURN ($$TRUE)
'
' send connect request - connect probably will not happen now
'
	sockaddrin.sin_family = $$AF_INET
	sockaddrin.sin_addr = address$$
	' Note: the user specifies the port-number in 'host order'; but sin_port
	' must be in 'network order' (big endian).
	sockaddrin.sin_port = htons(port)

	length = LEN (sockaddrin)
	connected = $$FALSE
	xb_seterrno($$FALSE)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = connect (syssocket, &sockaddrin, length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	SELECT CASE TRUE
		CASE (error = 0)	: connected = $$TRUE
												SetSocketNonBlocking (socket)
												status = status OR $$SocketStatusConnectRequest
												status = status OR $$SocketStatusConnectSuccess
		CASE (error < 0)	: xb_seterrno(GetLastError())
												SELECT CASE xb_geterrno()
													CASE $$WSAEWOULDBLOCK:
														xb_seterrno($$FALSE)
														status = status OR $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusConnected
													CASE ELSE:
														IF #debug THEN PRINT "XinSocketConnectRequest() : error : "; socket; xb_geterrno()
														status = status AND NOT $$SocketStatusConnectRequest
														status = status AND NOT $$SocketStatusConnected
														status = status OR $$SocketStatusFailed
												END SELECT
		CASE (error > 0)	: xb_seterrno(GetLastError())
												SELECT CASE xb_geterrno()
													CASE $$WSAEWOULDBLOCK	: xb_seterrno($$FALSE)
													CASE ELSE							: IF #debug THEN PRINT "XinSocketConnectRequest() : error : "; socket; xb_geterrno()
												END SELECT
												status = status AND NOT $$SocketStatusConnectRequest
												status = status AND NOT $$SocketStatusConnected
												status = status OR $$SocketStatusFailed
	END SELECT
'
	socket[socket].status = status
	IF xb_geterrno() THEN RETURN (xb_geterrno())
'
' if not connected, see if a short block was requested
'
	IFZ connected THEN
		SELECT CASE TRUE
			CASE (block < 1)			: block = 0				' do not block
			CASE (block < 10)			: block = 10			' min block = 10us
			CASE (block > 20000)	: block = 20000		' max block = 20ms
		END SELECT
'
		IF block THEN
			error = XinSocketConnectStatus (socket, block, @connected)
			IF error THEN
				status = status AND NOT $$SocketStatusConnectRequest
				status = status AND NOT $$SocketStatusConnected
				status = status OR $$SocketStatusFailed
				socket[socket].status = status
				RETURN ($$TRUE)
			END IF
		END IF
	END IF
'
' if connected, mark status as connected
'
	IF connected THEN
		status = status OR $$SocketStatusConnectRequest
		status = status OR $$SocketStatusConnectSuccess
	END IF
'
	socket[socket].status = status
'
	IF connected THEN
		error = SetSocketBlocking (socket)
		IF error THEN RETURN ($$TRUE)
	END IF
	RETURN ($$FALSE)
END FUNCTION
'
'
' ##################################
' #####  XxxXinGetNameInfo ()  #####
' ##################################
'
' rc = XxxXinGetNameInfo (sockaddr, socklen, @host$, @server$, flags)
'
FUNCTION  XxxXinGetNameInfo (sockaddr, socklen, host$, server$, flags)

	whomask = ##WHOMASK
	lockout = ##LOCKOUT

'	IF host$ THEN
		addrhost = &host$
		lenhost  = LEN(host$)
'	ELSE
'		addrhost = 0
'		lenhost  = 0
'	END IF
'	IF server$ THEN
		addrserver = &server$
		lenserver  = LEN(server$)
'	ELSE
'		addrserver = 0
'		lenserver  = 0
'	END IF

	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	rc = getnameinfo (sockaddr, socklen, addrhost, lenhost, addrserver, lenserver, flags)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	RETURN rc

END FUNCTION
'
'
' ###########################
' #####  XxxXinNTOP ()  #####
' ###########################
'
FUNCTION  XxxXinNTOP (af, addr_n, p$)
	lockout = ##LOCKOUT
	whomask = ##WHOMASK

	IFZ addr_n THEN RETURN $$TRUE

	SELECT CASE af
		CASE $$AF_INET  : max_len = 22
		CASE $$AF_INET6 : max_len = 46
		CASE ELSE       : RETURN $$TRUE
	END SELECT

	pc$ = NULL$(max_len)

	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	rc = inet_ntop (af, addr_n, &pc$, max_len)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	PRINT HEXX$(rc), HEXX$(&pc$)

	p$ = CSTRING$(&pc$)
	RETURN rc

END FUNCTION
'
'
' ###########################
' #####  XxxXinPTON ()  #####
' ###########################
'
' rc = XxxXinPTON (af, p$, @n@@[])
'
FUNCTION  XxxXinPTON (af, p$, sin6Addr$)
	lockout = ##LOCKOUT
	whomask = ##WHOMASK

	SELECT CASE af
		CASE $$AF_INET  : sin6Addr$ = NULL$(4)
		CASE $$AF_INET6 : sin6Addr$ = NULL$(16)
		CASE ELSE       : RETURN $$TRUE
	END SELECT

	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	rc = inet_pton (af, &p$, &sin6Addr$)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	RETURN rc

END FUNCTION
'
'
' #################################
' #####  ZzzXinCopySocket ()  #####
' #################################
'
FUNCTION  ZzzXinCopySocket (SOCKET socketdb[])
	SHARED  SOCKET  socket[]

	upper = UBOUND(socket[])
	DIM socketdb[upper]
	saddress = &socket[]
	daddress = &socketdb[]
	copybytes = SIZE(socket[])
	XstCopyMemory (saddress, daddress, copybytes)

END FUNCTION
'
'
' ###############################
' #####  XxxXinBlowback ()  #####
' ###############################
'
FUNCTION  XxxXinBlowback ()
	SHARED  initialized
'
	IFZ initialized THEN									' Xin() never called
		IF #debug THEN PRINT "XxxXinBlowback() : error : Xin() library not initialized : call Xin() first"
		error = ($$ErrorObjectLibrary << 8) OR $$ErrorNatureNotInitialized
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	Blowback ()
END FUNCTION
'
'
' #########################
' #####  Blowback ()  #####
' #########################
'
FUNCTION  Blowback ()
	SHARED  initialized
	SHARED  HOST  host[]
	SHARED  SOCKET  socket[]
	SHARED  SOCKETOPEN socketopen[]
	SOCKET  zero
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	FOR i = 0 TO UBOUND(socketopen[])
		IF socketopen[i].whomask THEN
			syssocket = socketopen[i].syssocket
			IF syssocket THEN
				##WHOMASK = 0
				##LOCKOUT = $$TRUE
				close (syssocket)
				##LOCKOUT = lockout
				##WHOMASK = whomask
				socketopen[i].syssocket = 0
			END IF
			socketopen[i].whomask = 0
		END IF
	NEXT i
'
	IFZ initialized THEN RETURN
'
	upper = UBOUND (socket[])
'
	IF #debug THEN PRINT "xin.x : Blowback() : upper : "; upper
'
	FOR i = 1 TO upper
		who = socket[i].whomask
		socket = socket[i].socket
		syssocket = socket[i].syssocket
		IF socket THEN
			IF syssocket THEN
				IF socket[i].whomask THEN
					##WHOMASK = 0
					##LOCKOUT = $$TRUE
					closesocket (syssocket)
					##LOCKOUT = lockout
					##WHOMASK = whomask
					socket[i] = zero
					IF #debug THEN PRINT "#####  closesocket ("; STRING$(syssocket); ")  #####"
				END IF
			END IF
		END IF
	NEXT i
'
'	##WHOMASK = 0
'	##LOCKOUT = $$TRUE
'	WSACleanup ()						' WSACleanup() is in Windows only
'	##LOCKOUT = lockout
'	##WHOMASK = whomask
END FUNCTION
'
'
' #############################
' #####  GetLastError ()  #####
' #############################
'
FUNCTION  GetLastError ()
'
	XstGetSystemError (@syserror)
	RETURN (syserror)
END FUNCTION
'
'
' ########################
' #####  AddHost ()  #####
' ########################
'
FUNCTION  AddHost (host, addr, host$)
	SHARED  HOST  host[]
	PROTOENT  protoent
	HOSTENT  hostent, hostenttmp
	HOST  hhhh
'
	calledHostName = $$FALSE
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	host = -1
	upper = UBOUND (host[])
'
' see if host name is recognized
'
	IF host$ THEN
		##WHOMASK = 0
		##LOCKOUT = $$TRUE
		hostenttmp = gethostbyname (&host$)  ' *obsolete* use getaddrinfo() and getnameinfo()
		hostent = hostenttmp
		calledHostName = $$TRUE
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IF hostent THEN addr = 0
	END IF
'
' see if host number is recognized
'
	IF addr THEN
		IFZ calledHostName THEN
			host$ = ""
			length = 4
			address = addr
			family = $$AF_INET
			##WHOMASK = 0
			##LOCKOUT = $$TRUE
			hostenttmp = gethostbyaddr (&address, length, family)
			hostent = hostenttmp
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
	END IF
'
	IFZ hostent THEN host$ = "" : addr = 0 : RETURN ($$TRUE)
	host$ = CSTRING$ (hostent.h_name)
	IFZ host$ THEN host$ = "" : addr = 0 : RETURN ($$TRUE)
	addr = hostent.h_addr_list
	addr = XLONGAT (addr)
'
'
' see if host is already in host[]
'
	FOR i = 0 TO upper
		name$ = host[i].name
		alias0$ = host[i].alias[0]
		alias1$ = host[i].alias[1]
		alias2$ = host[i].alias[2]
		address = host[i].address
		IF (host$ = name$) THEN host = i : EXIT FOR
		IF (host$ = alias0$) THEN host = i : EXIT FOR
		IF (host$ = alias1$) THEN host = i : EXIT FOR
		IF (host$ = alias2$) THEN host = i : EXIT FOR
		IF (addr = address) THEN host = i : EXIT FOR
	NEXT i
'
	IF (host >= 0) THEN RETURN ($$FALSE)		' host already in host[]
'
'
' *****  make new slot in host[] for this new host  *****
'
	INC upper
	host = upper
'
	##WHOMASK = 0
	REDIM host[host]
	##WHOMASK = whomask
'
	hosts = upper + 1
	host$ = CSTRING$ (hostent.h_name)
'
'
'
' NOTE : the following routines are disabled because Caldera Linux blows up due
' the contents of the hostent.h_aliases being a pointer to strings instead of
' pointer to a list of pointers to strings.
'
'	GOTO PastWhereCalderaLinuxCrashes
'
'
' *****  add alias names to host[].alias[] array  *****
'
'	alias = 0
	host[host].name = host$
'
'	IF hostent.h_aliases THEN
'		at = 0
'		at = hostent.h_aliases
'		DO
'			IFZ addr THEN EXIT DO
' This is where it was failing...pointer de-referenced one to many times
' as noted above.  Need some way to decide which way to dereference (once
' or twice)
'			at = XLONGAT (at)
'			name$ = CSTRING$ (at)
'			name$ = TRIM$ (name$)
'			PRINT(name$)
'			at = at + 4
'			IF name$ THEN
'				host[host].alias[alias] = name$
'				IF (alias < 2) THEN INC alias ELSE EXIT DO
'			END IF
'		LOOP
'	END IF
'
' new code for above
'
	addr = hostent.h_aliases
	IF addr THEN
		FOR n = 0 TO 2
			item = XLONGAT(addr, [n])
			IFZ item THEN EXIT FOR
			name$ = CSTRING$ (item)
'			PRINT "AddHost()alias", name$
			host[host].alias[n] = name$
		NEXT n
	END IF
'
'
' *****  add additional IP addresses to host[].address[] array  *****
'
'	n = 0
'	addr = hostent.h_addr_list
'	IF addr THEN item = XLONGAT (addr)
'	IF item THEN ipaddr = XLONGAT (item)
'	IF ipaddr THEN host[host].address = ipaddr : addr = addr + 4
'
'	IF addr THEN
'		DO
'			item = XLONGAT (addr)
'			IFZ item THEN EXIT DO
'			data = XLONGAT (item)
'			IF data THEN
'				host[host].addresses[n] = data
'				IF (n >= 7) THEN EXIT DO
'				INC n
'			END IF
'			addr = addr + 4
'		LOOP
'	END IF
'
' new code for above
'
	addr = hostent.h_addr_list
	IF addr THEN
		FOR n = 0 TO 7
			item = XLONGAT(addr, [n])
			IFZ item THEN EXIT FOR
			host[host].addresses[n] = GIANTAT(item)           ' copy 16 bytes
'			PRINT "AddHost()addr", n, HEXX$(host[host].addresses[n], 8)
		NEXT n
	END IF
'
PastWhereCalderaLinuxCrashes:

'
'
' *****  get protocol number for "TCP"  *****
'
	protoent.p_name = 0
	protoent.p_aliases = 0
	protoent.p_proto = 0
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	protoent = getprotobyname (&"tcp")
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ protoent THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "getprotobyname() : error : "; xb_geterrno()
		error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureUnavailable
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	XstGetOSName (@system$)
	system$ = TRIM$ (system$)
	protocol$ = CSTRING$ (protoent.p_name)
'
	host[host].protocol = protoent.p_proto
	host[host].system = system$
	host[host].addressBytes = 4
	host[host].addressFamily = $$AF_INET
	host[host].protocolFamily = $$PF_INET
	RETURN ($$FALSE)
END FUNCTION
'
'
' ##################################
' #####  SetSocketBlocking ()  #####
' ##################################
'
FUNCTION  SetSocketBlocking (socket)
	SHARED  SOCKET  socket[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		IF #debug THEN PRINT "SetSocketBlocking() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[socket].socket THEN
		IF #debug THEN PRINT "SetSocketBlocking() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	syssocket = socket[socket].syssocket
'
	value = 0
	command = $$FIONBIO
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = ioctlsocket (syssocket, command, &value)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "SetSocketBlocking() : error : attempt to set socket blocking failed : "; socket; xb_geterrno()
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
		connected = $$TRUE
'
		SELECT CASE xb_geterrno()
			CASE $$WSAEWOULDBLOCK
			CASE $$WSAECONNABORTED	: connected = $$FALSE
			CASE $$WSAECONNRESET		: connected = $$FALSE
			CASE $$WSAESHUTDOWN			: connected = $$FALSE
			CASE $$WSAENOTCONN			: connected = $$FALSE
			CASE $$WSAENETDOWN			: connected = $$FALSE
			CASE ELSE								:
		END SELECT
'
		IFZ connected THEN
			error = ($$ErrorObjectSocket << 8) + $$ErrorNatureDisconnected
			status = status AND NOT $$SocketStatusConnected
			status = status OR $$SocketStatusFailed
			socket[socket].status = status
			old = ERROR (error)
			RETURN (xb_geterrno())
		ELSE
			error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
			socket[socket].status = status OR $$SocketStatusFailed
			old = ERROR (error)
			RETURN (xb_geterrno())
		END IF
	END IF
'
	RETURN ($$FALSE)
END FUNCTION
'
'
' #####################################
' #####  SetSocketNonBlocking ()  #####
' #####################################
'
FUNCTION  SetSocketNonBlocking (socket)
	SHARED  SOCKET  socket[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	upper = UBOUND (socket[])
'
	IF ((socket <= 0) OR (socket > upper)) THEN
		IF #debug THEN PRINT "SetSocketNonBlocking() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ socket[socket].socket THEN
		IF #debug THEN PRINT "SetSocketNonBlocking() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	syssocket = socket[socket].syssocket
'
	IFZ syssocket THEN
		IF #debug THEN PRINT "SetSocketNonBlocking() : error : undefined socket # : "; socket
		error = ($$ErrorObjectSocket << 8) OR $$ErrorNatureUndefined
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	value = 1
	command = $$FIONBIO
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	error = ioctlsocket (syssocket, command, &value)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		xb_seterrno(GetLastError())
		IF #debug THEN PRINT "SetSocketNonBlocking() : error : attempt to set socket non-blocking failed : "; socket; xb_geterrno()
		error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
		connected = $$TRUE
'
		SELECT CASE xb_geterrno()
			CASE $$WSAEWOULDBLOCK
			CASE $$WSAECONNABORTED	: connected = $$FALSE
			CASE $$WSAECONNRESET		: connected = $$FALSE
			CASE $$WSAESHUTDOWN			: connected = $$FALSE
			CASE $$WSAENOTCONN			: connected = $$FALSE
			CASE $$WSAENETDOWN			: connected = $$FALSE
			CASE ELSE								:
		END SELECT
'
		IFZ connected THEN
			error = ($$ErrorObjectSocket << 8) + $$ErrorNatureDisconnected
			status = status AND NOT $$SocketStatusConnected
			status = status OR $$SocketStatusFailed
			socket[socket].status = status
			old = ERROR (error)
			RETURN (xb_geterrno())
		ELSE
			error = ($$ErrorObjectSocket << 8) + $$ErrorNatureFailed
			socket[socket].status = status OR $$SocketStatusFailed
			old = ERROR (error)
			RETURN (xb_geterrno())
		END IF
	END IF
'
	RETURN ($$FALSE)
END FUNCTION
'
'
' ###################################
' #####  SystemErrorToError ()  #####
' ###################################
'
FUNCTION  SystemErrorToError (errno, error)
'
	SELECT CASE errno
		CASE $$WSAEINTR							:
		CASE $$WSAEBADF							:
		CASE $$WSAEACCES						:
		CASE $$WSAEFAULT						:
		CASE $$WSAEINVAL						: error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureInvalidVersion
		CASE $$WSAEMFILE						:
		CASE $$WSAEWOULDBLOCK				:
		CASE $$WSAEINPROGRESS				:
		CASE $$WSAENOTSOCK					:
		CASE $$WSAEDESTADDRREQ			:
		CASE $$WSAEMSGSIZE					:
		CASE $$WSAEPROTOTYPE				:
		CASE $$WSAENOPROTOOPT				:
		CASE $$WSAEPROTONOSUPPORT		:
		CASE $$WSAESOCKTNOSUPPORT		:
		CASE $$WSAEOPNOTSUPP				:
		CASE $$WSAEPFNOSUPPORT			:
		CASE $$WSAEAFNOSUPPORT			:
		CASE $$WSAEADDRINUSE				:
		CASE $$WSAEADDRNOTAVAIL			:
		CASE $$WSAENETDOWN					:
		CASE $$WSAENETUNREACH				:
		CASE $$WSAENETRESET					:
		CASE $$WSAECONNABORTED			:
		CASE $$WSAECONNRESET				:
		CASE $$WSAENOBUFS						:
		CASE $$WSAEISCONN						:
		CASE $$WSAENOTCONN					:
		CASE $$WSAESHUTDOWN					:
		CASE $$WSAETOOMANYREFS			:
		CASE $$WSAETIMEDOUT					:
		CASE $$WSAECONNREFUSED			:
		CASE $$WSAELOOP							:
		CASE $$WSAENAMETOOLONG			:
		CASE $$WSAEHOSTDOWN					:
		CASE $$WSAEHOSTUNREACH			:
		CASE $$WSAENOTEMPTY					:
		CASE $$WSAEPROCLIM					:
		CASE $$WSAEUSERS						:
		CASE $$WSAEDQUOT						:
		CASE $$WSAESTALE						:
		CASE $$WSAEREMOTE						:
		CASE $$WSAESYSNOTREADY			: error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureUnavailable
		CASE $$WSAEVERNOTSUPPORTED	: error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureInvalidVersion
		CASE $$WSAENOTINITILISED		:
		CASE $$WSAENOTINITILIZED		:
		CASE $$WSAEDISCON						:
		CASE $$WSAHOST_NOT_FOUND		:
		CASE $$WSATRY_AGAIN					:
		CASE $$WSANO_RECOVERY				:
		CASE $$WSANO_DATA						:
		CASE $$WSANO_ADDRESS				:
		CASE ELSE										: error = ($$ErrorObjectNetwork << 8) + $$ErrorNatureUnknown
	END SELECT
END FUNCTION
'
'
' ######################
' #####  FDCLR ()  #####
' ######################
'
FUNCTION  FDCLR (fildes, FD_SET fd_set)
	SHARED  bitmask[]
'
	bit = fildes AND 0x001F
	mask = bitmask[bit]
	word = fildes >> 5
	upper = 7
'
	IF (word > upper) THEN RETURN ($$TRUE)
'
	fd_set.fd_array[word] = fd_set.fd_array[word] AND NOT mask
'	FDCOUNT (@fd_set)
END FUNCTION
'
'
' ######################
' #####  FDSET ()  #####
' ######################
'
FUNCTION  FDSET (fildes, FD_SET fd_set)
	SHARED  bitmask[]
'
	bit = fildes AND 0x001F
	mask = bitmask[bit]
	word = fildes >> 5
	upper = 7
'
	IF (word > upper) THEN RETURN ($$TRUE)
'
	fd_set.fd_array[word] = fd_set.fd_array[word] OR mask
'	FDCOUNT (@fd_set)
END FUNCTION
'
'
' ########################
' #####  FDISSET ()  #####
' ########################
'
FUNCTION  FDISSET (fildes, FD_SET fd_set)
	SHARED  bitmask[]
'
	bit = fildes AND 0x001F
	mask = bitmask[bit]
	word = fildes >> 5
	upper = 7
'
	IF (word > upper) THEN RETURN ($$TRUE)
'
	return = fd_set.fd_array[word] AND mask
'	FDCOUNT (@fd_set)
	RETURN (return)
END FUNCTION
'
'
' #######################
' #####  FDZERO ()  #####
' #######################
'
FUNCTION  FDZERO (FD_SET fd_set)
'
	upper = 7
'
	FOR i = 0 TO upper
		fd_set.fd_array[i] = 0
	NEXT i
'	fd_set.fd_count = 0
END FUNCTION
'
'
' ########################
' #####  FDCOUNT ()  #####
' ########################
'
FUNCTION  FDCOUNT (FD_SET fd_set)
'
	count = 0
	upper = 7
'
	FOR i = 0 TO upper
		entry = fd_set.fd_array[i]
		IF entry THEN
			FOR j = 0 TO 31
				bit = entry AND 0x0001
				IF bit THEN INC count
				entry = entry >> 1
			NEXT j
		END IF
	NEXT i
'	fd_set.fd_count = count
END FUNCTION
'
'
' ############################
' #####  closesocket ()  #####
' ############################
'
' closesockey is a Microsoft function
' close       is a Linux function to close any file descriptor
'
FUNCTION  closesocket (syssocket)
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	return = close (syssocket)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	RETURN (return)
END FUNCTION
'
'
' ############################
' #####  ioctlsocket ()  #####
' ############################
'
FUNCTION  ioctlsocket (syssocket, command, addrValue)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	return = ioctl (syssocket, command, addrValue)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	RETURN (return)
END FUNCTION
END PROGRAM

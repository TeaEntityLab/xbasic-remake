//! RT-XIN-SOCKETS: real BSD-socket lowering for the `Xin*` network builtins
//! (C backend only — the interpreter keeps zero-default stubs because its
//! memory model has no raw addresses; the demos' `&string` addresses only
//! become real data pointers in compiled C).
//!
//! Semantics follow the demo usage (aserver.x / aclient.x):
//! - `XinSocketOpen (@socket, @addressType, @socketType, flags)` → TCP socket
//! - `XinSocketBind (socket, block, @address$$, @port)` → INADDR_ANY:port
//! - `XinSocketAccept (socket, block, @client, flags)` → blocking accept
//! - `XinSocketRead/Write (sock, block, address, bytes, flags, @got)` —
//!   `address` is a RAW data pointer (`&string$` lowers to the string's data
//!   pointer in C), recv/send straight into/out of the buffer
//! - `$$SocketStatusConnected` = 0x40 (xin.s:422)

use super::c_emit_expr::{emit_byref_addr, emit_byref_value};
use super::{IrExpr, ValueType};

/// Emit a `Xin*` builtin call. Returns false when `name` is not a Xin builtin
/// (caller falls through to the unknown-call stub).
pub(crate) fn emit_xin_call(name: &str, args: &[IrExpr], out: &mut String) -> bool {
    // (c-name, arg-lowerings): V = by value, A = byref address.
    let spec: Option<(&str, &[ArgKind])> = match name {
        "XinInitialize" => Some((
            "xb_xin_initialize",
            &[ArgKind::Addr, ArgKind::Addr, ArgKind::Addr, ArgKind::Addr, ArgKind::Addr, ArgKind::Addr],
        )),
        "XinSetDebug" => Some(("xb_xin_set_debug", &[ArgKind::Value])),
        "XinSocketOpen" => Some((
            "xb_xin_socket_open",
            &[ArgKind::Addr, ArgKind::Addr, ArgKind::Addr, ArgKind::Value],
        )),
        "XinSocketBind" => Some((
            "xb_xin_socket_bind",
            &[ArgKind::Value, ArgKind::Value, ArgKind::Addr, ArgKind::Addr],
        )),
        "XinSocketListen" => Some((
            "xb_xin_socket_listen",
            &[ArgKind::Value, ArgKind::Value, ArgKind::Value],
        )),
        "XinSocketAccept" => Some((
            "xb_xin_socket_accept",
            &[ArgKind::Value, ArgKind::Value, ArgKind::Addr, ArgKind::Value],
        )),
        "XinSocketRead" | "XinSocketWrite" => Some((
            if name == "XinSocketRead" {
                "xb_xin_socket_read"
            } else {
                "xb_xin_socket_write"
            },
            &[ArgKind::Value, ArgKind::Value, ArgKind::Value, ArgKind::Value, ArgKind::Value, ArgKind::Addr],
        )),
        "XinSocketClose" => Some(("xb_xin_socket_close", &[ArgKind::Value])),
        "XinSocketGetStatus" => Some((
            "xb_xin_socket_get_status",
            &[
                ArgKind::Value, ArgKind::Value, ArgKind::Value, ArgKind::Value, ArgKind::Addr,
                ArgKind::Value, ArgKind::Value, ArgKind::Value,
            ],
        )),
        "XinSocketGetAddress" => Some((
            "xb_xin_socket_get_address",
            &[ArgKind::Value, ArgKind::Addr, ArgKind::Addr, ArgKind::Addr, ArgKind::Addr, ArgKind::Addr],
        )),
        "XinSocketConnectRequest" => Some((
            "xb_xin_socket_connect_request",
            &[ArgKind::Value, ArgKind::Value, ArgKind::Value, ArgKind::Value],
        )),
        "XinSocketConnectStatus" => Some((
            "xb_xin_socket_connect_status",
            &[ArgKind::Value, ArgKind::Value, ArgKind::Addr],
        )),
        "XinAddressStringToNumber" => Some((
            "xb_xin_address_string_to_number",
            &[ArgKind::StrValue, ArgKind::Addr],
        )),
        "XinAddressNumberToString" => Some((
            "xb_xin_address_number_to_string",
            &[ArgKind::Addr, ArgKind::Addr],
        )),
        "XinHostNumberToInfo" => Some(("xb_xin_host_number_to_info", &[ArgKind::Value, ArgKind::Addr])),
        _ => return false,
    };
    let (c_name, kinds) = spec.unwrap();
    out.push_str(c_name);
    out.push('(');
    for (i, (arg, kind)) in args.iter().zip(kinds.iter()).enumerate() {
        if i > 0 {
            out.push_str(", ");
        }
        match kind {
            ArgKind::Value => emit_byref_value(arg, out),
            ArgKind::StrValue => emit_byref_value(arg, out),
            ArgKind::Addr => emit_byref_addr(arg, out),
        }
    }
    // Pad missing args with zero-defaults (mirrors eval_args).
    for kind in kinds.iter().skip(args.len()) {
        out.push_str(", ");
        match kind {
            ArgKind::Addr => out.push_str("0"),
            _ => out.push_str("0"),
        }
    }
    out.push(')');
    true
}

enum ArgKind {
    Value,
    /// Byref string passed as its value (char*), not char**.
    StrValue,
    Addr,
}

/// Usage-gated BSD-socket runtime helpers (emitted once when any `xb_xin_`
/// helper is referenced).
pub(crate) fn emit_xin_runtime(out: &mut String) {
    out.push_str("#include <sys/socket.h>\n");
    out.push_str("#include <netinet/in.h>\n");
    out.push_str("#include <arpa/inet.h>\n");
    out.push_str("#include <unistd.h>\n");
    out.push_str("#include <signal.h>\n");
    // Writes to a peer-closed socket must return an error (EPIPE), not kill
    // the process with SIGPIPE — matches the Xin* error-return semantics.
    out.push_str("__attribute__((constructor)) static void xb_xin_init(void) { signal(SIGPIPE, SIG_IGN); }\n");

    out.push_str("static char* xb_xin_empty(void) { return xb_str(\"\"); }\n");
    out.push_str(
        "static int64_t xb_xin_initialize(int32_t* local, int32_t* hosts, int32_t* version, int32_t* sockets, char** comments, char** notes) { if(local)*local=0; if(hosts)*hosts=0; if(version)*version=0x6405; if(sockets)*sockets=0; if(comments)*comments=xb_xin_empty(); if(notes)*notes=xb_xin_empty(); return 0; }\n",
    );
    out.push_str("static int64_t xb_xin_set_debug(int32_t d) { (void)d; return 0; }\n");
    out.push_str(
        "static int64_t xb_xin_socket_open(int32_t* sock, int32_t* atype, int32_t* stype, int32_t flags) { (void)flags; int s = (int)socket(AF_INET, SOCK_STREAM, 0); if(atype)*atype=AF_INET; if(stype)*stype=SOCK_STREAM; if(sock)*sock=s; return s<0 ? -1 : 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_bind(int32_t sock, int32_t block, int64_t* address, int32_t* port) { (void)block; struct sockaddr_in a; memset(&a,0,sizeof a); a.sin_family=AF_INET; a.sin_addr.s_addr=htonl(INADDR_ANY); a.sin_port=htons((uint16_t)*port); int r = bind(sock,(struct sockaddr*)&a,sizeof a); if(r==0){ socklen_t n=sizeof a; if(getsockname(sock,(struct sockaddr*)&a,&n)==0 && port) *port=(int32_t)ntohs(a.sin_port); } return r<0 ? -1 : 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_listen(int32_t sock, int32_t block, int32_t flags) { (void)block; (void)flags; return listen(sock,5)<0 ? -1 : 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_accept(int32_t sock, int32_t block, int32_t* client, int32_t flags) { (void)block; (void)flags; int c = (int)accept(sock,0,0); if(client)*client=c; return c<0 ? -1 : 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_read(int32_t sock, int32_t block, int64_t address, int32_t nbytes, int32_t flags, int32_t* bytes) { (void)block; (void)flags; if(bytes)*bytes=0; if(!address || nbytes<=0) return -1; ssize_t n = recv(sock,(char*)(intptr_t)address,(size_t)nbytes,0); if(n<=0) return -1; if(bytes)*bytes=(int32_t)n; return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_write(int32_t sock, int32_t block, int64_t address, int32_t nbytes, int32_t flags, int32_t* bytes) { (void)block; (void)flags; if(bytes)*bytes=0; if(!address || nbytes<=0){ if(bytes)*bytes=nbytes; return 0; } ssize_t n = send(sock,(char*)(intptr_t)address,(size_t)nbytes,0); if(n<0) return -1; if(bytes)*bytes=(int32_t)n; return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_close(int32_t sock) { if(sock>=0) close(sock); return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_get_status(int32_t sock, int32_t a, int32_t b, int32_t c, int32_t* status, int32_t d, int32_t e, int32_t f) { (void)a;(void)b;(void)c;(void)d;(void)e;(void)f; if(status){ int err=0; socklen_t ln=sizeof err; if(getsockopt(sock,SOL_SOCKET,SO_ERROR,&err,&ln)!=0 || err!=0) *status=0; else *status=0x40; } return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_get_address(int32_t sock, int32_t* port, int64_t* address, int32_t* remote, int32_t* rport, int64_t* raddress) { struct sockaddr_in a; socklen_t n=sizeof a; memset(&a,0,sizeof a); if(getsockname(sock,(struct sockaddr*)&a,&n)==0){ if(port)*port=(int32_t)ntohs(a.sin_port); if(address)*address=(int64_t)ntohl(a.sin_addr.s_addr); } struct sockaddr_in r; n=sizeof r; memset(&r,0,sizeof r); if(getpeername(sock,(struct sockaddr*)&r,&n)==0){ if(remote)*remote=(int64_t)ntohl(r.sin_addr.s_addr); if(rport)*rport=(int32_t)ntohs(r.sin_port); if(raddress)*raddress=(int64_t)ntohl(r.sin_addr.s_addr); } return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_connect_request(int32_t sock, int32_t block, int64_t serveraddr, int32_t serverport) { (void)block; struct sockaddr_in a; memset(&a,0,sizeof a); a.sin_family=AF_INET; a.sin_addr.s_addr=htonl((uint32_t)serveraddr); a.sin_port=htons((uint16_t)serverport); return connect(sock,(struct sockaddr*)&a,sizeof a)<0 ? -1 : 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_socket_connect_status(int32_t sock, int32_t block, int32_t* connected) { (void)block; if(connected){ int err=0; socklen_t ln=sizeof err; if(getsockopt(sock,SOL_SOCKET,SO_ERROR,&err,&ln)==0 && err==0) *connected=1; else *connected=0; } return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_address_string_to_number(char* s, int64_t* num) { if(num)*num = s ? (int64_t)ntohl(inet_addr(s)) : 0; return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_address_number_to_string(int64_t* num, char** s) { if(s){ struct in_addr a; a.s_addr=htonl((uint32_t)*num); char* d = xb_alloc(16); snprintf(d,16,\"%s\",inet_ntoa(a)); *s=d; } return 0; }\n",
    );
    out.push_str(
        "static int64_t xb_xin_host_number_to_info(int32_t n, int32_t* host) { (void)n; if(host)*host=0; return 0; }\n",
    );
}

// Keep the ValueType import referenced (arg types are checked by the caller's
// byref helpers; this silences unused-import churn if the helpers change).
const _: Option<ValueType> = None;

//! RT-XIN-SOCKETS integration: the compiled C backend implements the `Xin*`
//! BSD-socket builtins for real. Compile aserver.x through the C pipeline,
//! run it, connect a TCP client, send the `time` request, and assert a
//! timestamp response arrives.
//!
//! (The interpreter keeps zero-default stubs for Xin* — its memory model has
//! no raw addresses — so aclient/aserver are SKIPped in demo_parity.)

use std::io::{Read, Write};
use std::net::TcpStream;
mod common;

use std::process::{Command, Stdio};
use std::time::Duration;

fn repo_root() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

/// Minimal XBasic socket client exercising the client-side builtins
/// (XinAddressStringToNumber, XinSocketConnectRequest/Status) against a
/// compiled aserver. Written to temp, compiled through the C pipeline.
const XCLIENT_X: &str = r#"XEOF
$$SERVER_PORT = 0x2021
FUNCTION Main ()
  DIM socket, error, addr, connected, request$, response$, bytes
  error = XinSocketOpen (@socket, @addressType, @socketType, 0)
  PRINT "open error="; error
  error = XinAddressStringToNumber ("127.0.0.1", @addr)
  PRINT "addr="; HEX$ (addr, 8)
  error = XinSocketConnectRequest (socket, 0, addr, $$SERVER_PORT)
  PRINT "connect error="; error
  error = XinSocketConnectStatus (socket, 0, @connected)
  PRINT "connected="; connected
  request$ = "time"
  error = XinSocketWrite (socket, 0, &request$, LEN (request$), 0, @bytes)
  PRINT "write error="; error; " bytes="; bytes
  response$ = NULL$ (64)
  error = XinSocketRead (socket, 0, &response$, 64, 0, @bytes)
  PRINT "read error="; error; " bytes="; bytes
  PRINT "response=["; response$; "]"
  XinSocketClose (socket)
END FUNCTION
XEOF"#;

#[test]
fn xin_sockets_xbasic_client_roundtrip() {
    let root = repo_root();
    let xb = common::xb_bin();
    let tmp = std::env::temp_dir().join("xin_sockets_client");
    let _ = std::fs::create_dir_all(&tmp);

    // Compile the server.
    // Patch the .x source to port 0x2021 (8225): the other test in this
    // binary runs an aserver on 0x2020 in parallel. Patching the source
    // covers both the #define and inlined constant uses.
    let raw = std::fs::read_to_string(root.join("xbasic-6.4.5/demo/aserver.x")).unwrap();
    let patched_src = raw.replace("0x2020", "0x2021");
    let server_src = tmp.join("aserver.x");
    std::fs::write(&server_src, patched_src).unwrap();
    let emit = Command::new(&xb)
        .arg("--emit-c")
        .arg(&server_src)
        .output()
        .expect("emit");
    let server_c = tmp.join("aserver.c");
    std::fs::write(&server_c, &emit.stdout).unwrap();
    let server_bin = tmp.join("aserver_bin");
    let cc = Command::new(common::cc::cc())
        .args([
            "-O1",
            "-w",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
        ])
        .arg(&server_c)
        .arg("-o")
        .arg(&server_bin)
        .output()
        .expect("cc");
    assert!(cc.status.success(), "cc failed for aserver");

    // Compile the client.
    let client_src = tmp.join("xclient.x");
    std::fs::write(
        &client_src,
        XCLIENT_X
            .replace(
                "XEOF
", "",
            )
            .replace("XEOF", ""),
    )
    .unwrap();
    let emit = Command::new(&xb)
        .arg("--emit-c")
        .arg(&client_src)
        .output()
        .expect("emit");
    assert!(emit.status.success(), "emit failed for xclient");
    let client_c = tmp.join("xclient.c");
    std::fs::write(&client_c, &emit.stdout).unwrap();
    let client_bin = tmp.join("xclient_bin");
    let cc = Command::new(common::cc::cc())
        .args([
            "-O1",
            "-w",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
        ])
        .arg(&client_c)
        .arg("-o")
        .arg(&client_bin)
        .output()
        .expect("cc");
    assert!(
        cc.status.success(),
        "cc failed for xclient: {}",
        String::from_utf8_lossy(&cc.stderr)
    );

    // Run server, then client; capture the client's stdout.
    let mut server = Command::new(&server_bin)
        .env("XB_ALLOW_NETWORK", "1")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .expect("spawn aserver");

    let out = (|| -> Result<std::process::Output, Box<dyn std::error::Error>> {
        // Let the server reach accept (a probe connection would consume an
        // accept cycle and can SIGPIPE the server on the dead socket).
        std::thread::sleep(Duration::from_millis(1500));
        // Retry the client: early runs may race the server's accept loop.
        let mut last = None;
        for _ in 0..3 {
            let out = Command::new(&client_bin)
                .env("XB_ALLOW_NETWORK", "1")
                .stdin(Stdio::null())
                .output()?;
            let ok = out.status.success()
                && String::from_utf8_lossy(&out.stdout).contains("connect error=0");
            if ok {
                return Ok(out);
            }
            last = Some(out);
            std::thread::sleep(Duration::from_millis(500));
        }
        Ok(last.unwrap())
    })();

    let _ = server.kill();
    let _ = server.wait();

    let out = out.expect("client run");
    assert!(
        out.status.success(),
        "xclient failed (rc={:?}): stderr={} stdout={}",
        out.status.code(),
        String::from_utf8_lossy(&out.stderr),
        String::from_utf8_lossy(&out.stdout)
    );
    let stdout = String::from_utf8_lossy(&out.stdout).to_string();
    for expect in [
        "open error=0",
        "addr=7F000001",
        "connect error=0",
        "connected=1",
        "write error=0 bytes=4",
        "read error=0 bytes=25",
    ] {
        assert!(
            stdout.contains(expect),
            "missing {expect:?} in:
{stdout}"
        );
    }
    assert!(
        stdout.contains("response=["),
        "no response in:
{stdout}"
    );
    let _ = std::fs::remove_dir_all(&tmp);
}

#[test]
fn xin_sockets_aserver_serves_timestamp() {
    let root = repo_root();
    let xb = common::xb_bin();
    let tmp = std::env::temp_dir().join("xin_sockets_test");
    let _ = std::fs::create_dir_all(&tmp);

    // Compile aserver through the C pipeline.
    let src = root.join("xbasic-6.4.5/demo/aserver.x");
    let emit = Command::new(&xb)
        .arg("--emit-c")
        .arg(&src)
        .output()
        .expect("emit");
    let c_file = tmp.join("aserver.c");
    std::fs::write(&c_file, &emit.stdout).unwrap();
    let bin = tmp.join("aserver_bin");
    let cc = Command::new(common::cc::cc())
        .args([
            "-O1",
            "-w",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
        ])
        .arg(&c_file)
        .arg("-o")
        .arg(&bin)
        .output()
        .expect("cc");
    assert!(cc.status.success(), "cc failed for aserver");

    // Start the server (port 0x2020 = 8224).
    let mut server = Command::new(&bin)
        .env("XB_ALLOW_NETWORK", "1")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .expect("spawn aserver");

    let result = (|| -> Result<(), Box<dyn std::error::Error>> {
        // Wait for listen.
        let mut stream = None;
        for _ in 0..50 {
            match TcpStream::connect("127.0.0.1:8224") {
                Ok(s) => {
                    stream = Some(s);
                    break;
                }
                Err(_) => std::thread::sleep(Duration::from_millis(100)),
            }
        }
        let mut stream = stream.ok_or("aserver never listened on 8224")?;
        stream.set_read_timeout(Some(Duration::from_secs(5)))?;

        // Send the 4-byte "time" request (aserver's protocol).
        stream.write_all(b"time")?;
        stream.flush()?;

        // Read the timestamp response.
        let mut buf = [0u8; 128];
        let n = stream.read(&mut buf)?;
        let response = String::from_utf8_lossy(&buf[..n]).to_string();
        assert!(
            !response.trim().is_empty(),
            "empty timestamp response from aserver"
        );
        // Timestamp format: digits and separators (e.g. 00000000:000000.000000000).
        assert!(
            response.chars().next().map(|c| c.is_ascii_digit()) == Some(true),
            "unexpected response format: {response:?}"
        );
        Ok(())
    })();

    let _ = server.kill();
    let _ = server.wait();
    let _ = std::fs::remove_dir_all(&tmp);
    result.expect("xin socket integration");
}

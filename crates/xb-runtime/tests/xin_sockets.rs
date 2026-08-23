//! RT-XIN-SOCKETS integration: the compiled C backend implements the `Xin*`
//! BSD-socket builtins for real. Compile aserver.x through the C pipeline,
//! run it, connect a TCP client, send the `time` request, and assert a
//! timestamp response arrives.
//!
//! (The interpreter keeps zero-default stubs for Xin* — its memory model has
//! no raw addresses — so aclient/aserver are SKIPped in demo_parity.)

use std::io::{Read, Write};
use std::net::TcpStream;
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

#[test]
fn xin_sockets_aserver_serves_timestamp() {
    let root = repo_root();
    let xb = root.join("target/release/xb");
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
    let cc = Command::new("cc")
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

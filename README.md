# trojan-nginx

Build prerequisites:

* curl, coreutils, git, make, openssl, tar, patch
* cmake, clang-5.0, perl, golang (BoringSSL)
* libluajit-5.1-dev, gcc, binutils (Nginx)
* golang-cfssl (for making certificates)

How to:

* `sh build-nginx.sh`
* `sh test.sh`
* Optionally, `sh test-chromium.sh` with Wireshark (requires chromium).

What you are seeing:

* A Trojan client listening at 127.0.0.1:1080.
* A Trojan server listening at *:10443.
* Trojan client and server communicate via TLS (badly configured yet).
* A dummy HTTP server listening at 127.0.0.1:10080.
* Requests to the Trojan server are redirected to the dummy server if a shared secret "hunter2" is not shown.

A browser should work if set to use the SOCKS5 proxy at 127.0.0.1:1080.

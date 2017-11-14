#!/bin/sh
set -e
./client/sbin/nginx -p client -c conf/nginx_trojan_client.conf
./server/sbin/nginx -p server -c conf/nginx_trojan_server.conf
sleep 1

# Wireshark sees Chromium's TLS signatures
chromium --temp-profile --headless --disable-gpu https://localhost:10443 2>/dev/null
sleep 1
# Wireshark sees Nginx's TLS signatures
chromium --temp-profile --headless --disable-gpu --proxy-server="socks5://127.0.0.1:1080" http://127.0.0.1:10080 2>/dev/null

./client/sbin/nginx -p client -c conf/nginx_trojan_client.conf -s stop
./server/sbin/nginx -p server -c conf/nginx_trojan_server.conf -s stop

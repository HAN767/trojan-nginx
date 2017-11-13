#!/bin/sh
set -e
./client/sbin/nginx -p client -c conf/nginx_trojan_client.conf
./server/sbin/nginx -p server -c conf/nginx_trojan_server.conf
sleep 1

alias printf=`which printf`
printf "\n\ncurl socks5 test\n\n"
curl -v --socks5-hostname 127.0.0.1:1080 http://google.com

printf "\n\nbad secret test\n\n"
printf "hunter1\r\n\x01\x01\x7f\x00\x00\x01\x27\x60\r\nGET / HTTP/1.0\r\n\r\n" | openssl s_client -quiet -connect 127.0.0.1:10443

printf "\n\ngood secret test\n\n"
printf "hunter2\r\n\x01\x01\x7f\x00\x00\x01\x27\x60\r\nGET / HTTP/1.0\r\n\r\n" | openssl s_client -quiet -connect 127.0.0.1:10443

printf "\n\ngood secret test 2\n\n"
printf "hunter2\r\n\x01\x03\x0agoogle.com\x00\x50\r\nGET / HTTP/1.0\r\n\r\n" | openssl s_client -quiet -connect 127.0.0.1:10443

printf "\n\nregular request test\n\n"
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client -quiet -connect 127.0.0.1:10443

./client/sbin/nginx -p client -c conf/nginx_trojan_client.conf -s stop
./server/sbin/nginx -p server -c conf/nginx_trojan_server.conf -s stop

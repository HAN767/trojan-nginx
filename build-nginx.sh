#!/bin/sh
set -e
PREFIX="$PWD"
BUILDROOT="$PWD/build"

# Which chromium version to track for BoringSSL
chromium_os=linux
chromium_channel=beta

# Clang is used to build BoringSSL at Google.
CLANG=clang-5.0
CLANGXX=clang++-5.0

# Paths from libluajit-5.1-dev for stream-lua-nginx-module
export LUAJIT_INC="/usr/include/luajit-2.1"
export LUAJIT_LIB="/usr/lib/x86_64-linux-gnu"

NGINX=nginx-1.13.6

NGINX_CFLAGS="-O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIE -Wdate-time -D_FORTIFY_SOURCE=2"
NGINX_LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE"
NGINX_COMMON_FLAGS="
  --with-threads
  --with-openssl=../boringssl
  --without-http-cache
  --with-stream
  --with-stream_ssl_module
  --add-module=../stream-lua-nginx-module"
NGINX_CLIENT_FLAGS="
  --without-http
  --without-stream_limit_conn_module
  --without-stream_access_module
  --without-stream_geo_module
  --without-stream_map_module
  --without-stream_split_clients_module
  --without-stream_return_module
  --without-stream_upstream_hash_module
  --without-stream_upstream_least_conn_module
  --without-stream_upstream_zone_module"
NGINX_SERVER_FLAGS="
  --without-http_charset_module
  --without-http_gzip_module
  --without-http_ssi_module
  --without-http_userid_module
  --without-http_access_module
  --without-http_auth_basic_module
  --without-http_mirror_module
  --without-http_autoindex_module
  --without-http_rewrite_module
  --without-http_proxy_module
  --without-http_fastcgi_module
  --without-http_uwsgi_module
  --without-http_scgi_module
  --without-http_memcached_module
  --without-http_limit_conn_module
  --without-http_limit_req_module
  --without-http_empty_gif_module
  --without-http_browser_module
  --without-http_upstream_hash_module
  --without-http_upstream_ip_hash_module
  --without-http_upstream_least_conn_module
  --without-http_upstream_keepalive_module
  --without-http_upstream_zone_module"

rm -rf build client server
mkdir -p "$BUILDROOT"; cd "$BUILDROOT"

# According to chromium_browser_vs_google_chrome.md:
# Distributions are encouraged to track stable channel releases: see [...] http://omahaproxy.appspot.com/ [...]
chromium_version=$(curl -s "https://omahaproxy.appspot.com/all?os=$chromium_os&channel=$chromium_channel" | tail -n1 | cut -d, -f3)
echo chromium_version=$chromium_version
[ "$chromium_version" ] || exit 1
boringssl_revision=$(curl -s "https://chromium.googlesource.com/chromium/src.git/+/$chromium_version/DEPS?format=TEXT" | base64 -d | grep -A1 boringssl_revision | tail -n1 | grep -o '[0-9a-f]*')
echo boringssl_revision=$boringssl_revision
[ "$boringssl_revision" ] || exit 1

git clone https://boringssl.googlesource.com/boringssl
cd "$BUILDROOT/boringssl"
git checkout $boringssl_revision

mkdir build; cd build
# -fPIE flags are for the Nginx PIE build.
CC=$CLANG CXX=$CLANGXX CFLAGS=-fPIE CXXFLAGS=-fPIE LDFLAGS=-fPIE cmake -DCMAKE_BUILD_TYPE=Release ..
make -j4
cd "$BUILDROOT/boringssl"
mkdir -p .openssl/lib
cp build/crypto/libcrypto.a build/ssl/libssl.a .openssl/lib
cd .openssl
ln -s ../include

cd "$BUILDROOT"
git clone -b bsdread https://github.com/klzgrad/stream-lua-nginx-module.git

curl -O https://nginx.org/download/$NGINX.tar.gz
tar xf $NGINX.tar.gz
cd "$NGINX"
patch -p1 <"$PREFIX/patches/nginx-1.13.6-001.patch"
patch -p1 <"$PREFIX/patches/nginx-1.13.6-002.patch"

./configure --prefix="$PREFIX/client" --with-cc-opt="$NGINX_CFLAGS" --with-ld-opt="$NGINX_LDFLAGS" $NGINX_COMMON_FLAGS $NGINX_CLIENT_FLAGS
# Workaround for Nginx looking for OpenSSL configure script
touch "$BUILDROOT/boringssl/.openssl/include/openssl/ssl.h"
make -j4
make install
strip --remove-section=.comment --remove-section=.note "$PREFIX/client/sbin/nginx"

make clean
./configure --prefix="$PREFIX/server" --with-cc-opt="$NGINX_CFLAGS" --with-ld-opt="$NGINX_LDFLAGS" $NGINX_COMMON_FLAGS $NGINX_SERVER_FLAGS
# Workaround for Nginx looking for OpenSSL configure script
touch "$BUILDROOT/boringssl/.openssl/include/openssl/ssl.h"
make -j4
make install
strip --remove-section=.comment --remove-section=.note "$PREFIX/server/sbin/nginx"

cd "$PREFIX/server"
git clone https://github.com/openresty/lua-resty-core.git
mkdir -p conf
cd conf
for i in "$PREFIX/conf"/*; do
  ln -s "$i"
done
yes '' | openssl req -x509 -newkey rsa:2048 -keyout cert.key -out cert.pem -days 100 -nodes

cd "$PREFIX/client"
mkdir -p conf
cd conf
for i in "$PREFIX/conf/"*; do
  ln -s "$i"
done

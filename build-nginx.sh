#!/bin/sh
set -e
PREFIX=$PWD

rm -rf build client server
mkdir -p build
cd build

NGINX=nginx-1.13.6
curl -O https://nginx.org/download/$NGINX.tar.gz
tar xf $NGINX.tar.gz
git clone -b bsdread https://github.com/klzgrad/stream-lua-nginx-module.git

cd $NGINX
LUAJIT_INC=/usr/include/luajit-2.1 LUAJIT_LIB=/usr/lib/x86_64-linux-gnu ./configure --with-cc-opt="-O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2" --with-ld-opt="-Wl,-z,relro -Wl,-z,now -fPIC" --prefix=$PREFIX/client --with-threads --without-http --without-http-cache --with-stream --with-stream_ssl_module --add-module=$PWD/../stream-lua-nginx-module --without-stream_limit_conn_module --without-stream_access_module --without-stream_geo_module --without-stream_map_module --without-stream_split_clients_module --without-stream_return_module --without-stream_upstream_hash_module --without-stream_upstream_least_conn_module --without-stream_upstream_zone_module
make -j4
make install
strip --remove-section=.comment --remove-section=.note $PREFIX/client/sbin/nginx

make clean
LUAJIT_INC=/usr/include/luajit-2.1 LUAJIT_LIB=/usr/lib/x86_64-linux-gnu ./configure --with-cc-opt="-O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2" --with-ld-opt="-Wl,-z,relro -Wl,-z,now -fPIC" --prefix=$PREFIX/server --with-threads --with-stream --with-stream_ssl_module --add-module=$PWD/../stream-lua-nginx-module --without-http_charset_module --without-http_gzip_module --without-http_ssi_module --without-http_userid_module --without-http_access_module --without-http_auth_basic_module --without-http_mirror_module --without-http_autoindex_module --without-http_geo_module --without-http_map_module --without-http_split_clients_module --without-http_referer_module --without-http_rewrite_module --without-http_proxy_module --without-http_fastcgi_module --without-http_uwsgi_module --without-http_scgi_module --without-http_memcached_module --without-http_limit_conn_module --without-http_limit_req_module --without-http_empty_gif_module --without-http_browser_module --without-http_upstream_hash_module --without-http_upstream_ip_hash_module --without-http_upstream_least_conn_module --without-http_upstream_keepalive_module --without-http_upstream_zone_module --without-http-cache
make -j4
make install
strip --remove-section=.comment --remove-section=.note $PREFIX/server/sbin/nginx

cd ../../server
git clone https://github.com/openresty/lua-resty-core.git
mkdir -p conf
cd conf
for i in ../../conf/*; do
  ln -s $i
done
yes '' | openssl req -x509 -newkey rsa:2048 -keyout cert.key -out cert.pem -days 100 -nodes

cd ../../client
mkdir -p conf
cd conf
for i in ../../conf/*; do
  ln -s $i
done

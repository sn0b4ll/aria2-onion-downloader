#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/aria2_log.txt

# Nginx config first part
touch /conf/nginx.conf
echo "error_log  logs/error.log;
pid        logs/nginx.pid;

load_module /usr/lib/nginx/modules/ngx_stream_module.so;

events {}

stream {
  server {
    listen 16001;
    proxy_pass tor_services;
  }

  upstream tor_services {" > /conf/nginx.conf

for i in `seq -w 01 ${TORSERVNUM}`
do
	echo "Creating $i"
	echo "forward-socks4a / localhost:140$i .
	listen-address 127.0.0.1:150$i" > /conf/privoxy$i.conf

	mkdir -p /var/lib/tor/140$i
	tor --runasdaemon 1 --SOCKSPort 140$i --DataDirectory /var/lib/140$i
	privoxy /conf/privoxy$i.conf 

	# Nginx config middle part
	echo "    server localhost:150$i;" >> /conf/nginx.conf
done

# Nginx config second part
echo "  }
}" >> /conf/nginx.conf

nginx -c /conf/nginx.conf

exec aria2c --conf-path=/conf/aria2.conf --log=/log/aria2_log.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}


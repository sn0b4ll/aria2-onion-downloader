#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/logs.txt

echo "forward-socks4a / localhost:${TORPORT} .
listen-address 127.0.0.1:${PRIVOPORT}" > /conf/privoxy.conf

tor --runasdaemon 1 --SOCKSPort ${TORPORT} 
privoxy /conf/privoxy.conf 

exec aria2c --conf-path=/conf/aria2.conf --log=/log/logs.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}


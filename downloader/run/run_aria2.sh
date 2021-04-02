#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/logs.txt

#echo "forward-socks4a / localhost:${TORPORT} .
#listen-address 127.0.0.1:${PRIVOPORT}" > /conf/privoxy.conf
echo "forward-socks4a / localhost:14001 .
listen-address 127.0.0.1:15001" > /conf/privoxy1.conf
echo "forward-socks4a / localhost:14002 .
listen-address 127.0.0.1:15002" > /conf/privoxy2.conf

mkdir -p /var/lib/tor/14001
mkdir -p /var/lib/tor/14002
tor --runasdaemon 1 --SOCKSPort 14001 --ControlPort 14101 --DataDirectory /var/lib/14001
tor --runasdaemon 1 --SOCKSPort 14002 --ControlPort 14102 --DataDirectory /var/lib/14002
privoxy /conf/privoxy1.conf 
privoxy /conf/privoxy2.conf 

exec aria2c --conf-path=/conf/aria2.conf --log=/log/logs.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}


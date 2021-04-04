#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/aria2_log.txt

for i in `seq -w 01 ${TORSERVNUM}`
do
	echo "Creatin $i"
	echo "forward-socks4a / localhost:140$i .
	listen-address 127.0.0.1:150$i" > /conf/privoxy$i.conf

	mkdir -p /var/lib/tor/140$i
	tor --runasdaemon 1 --SOCKSPort 140$i --ControlPort 141$i --DataDirectory /var/lib/140$i
	privoxy /conf/privoxy$i.conf 
done

exec aria2c --conf-path=/conf/aria2.conf --log=/log/aria2_log.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}


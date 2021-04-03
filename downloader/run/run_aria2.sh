#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/logs.txt

#echo "forward-socks4a / localhost:${TORPORT} .
#listen-address 127.0.0.1:${PRIVOPORT}" > /conf/privoxy.conf

max=${TORSERVNUM}
for i in `seq 01 $max`
do
	echo "Creatin $i"
	echo "forward-socks4a / localhost:140$i .
	listen-address 127.0.0.1:150$i" > /conf/privoxy$i.conf

	mkdir -p /var/lib/tor/140$i
	tor --runasdaemon 1 --SOCKSPort 140$i --ControlPort 141$i --DataDirectory /var/lib/140$i
	privoxy /conf/privoxy$i.conf 
done

exec aria2c --conf-path=/conf/aria2.conf --log=/log/logs.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}


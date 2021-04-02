#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/logs.txt

#echo "forward-socks4a / localhost:${TORPORT} .
#listen-address 127.0.0.1:${PRIVOPORT}" > /conf/privoxy.conf

max=9
for i in `seq 1 $max`
do
	echo "Creatin $i"
	echo "forward-socks4a / localhost:1400$i .
	listen-address 127.0.0.1:1500$i" > /conf/privoxy$i.conf

	mkdir -p /var/lib/tor/1400$i
	tor --runasdaemon 1 --SOCKSPort 1400$i --ControlPort 1410$i --DataDirectory /var/lib/1400$i
	privoxy /conf/privoxy$i.conf 
done

exec aria2c --conf-path=/conf/aria2.conf --log=/log/logs.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}


#!/bin/sh
set -e

python /home/creatorrc/creatorrc.py --speetor && mv -f tor_config.txt /conf/torrc

touch /conf/aria2.session
touch /log/aria2_log.txt

tor --runasdaemon 1 -f /conf/torrc

exec v2ray run -c /conf/config.json &
exec aria2c --conf-path=/conf/aria2.conf --log=/log/aria2_log.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}


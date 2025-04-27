#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/aria2_log.txt
touch /log/v2ray_access.log
touch /log/v2ray_error.log

python /home/creatorrc/creatorrc.py --speetor && mv -f tor_config.txt /conf/torrc && tor --runasdaemon 1 -f /conf/torrc || tor --runasdaemon 1

exec v2ray run -c /conf/config.json &
exec aria2c --conf-path=/conf/aria2.conf --log=/log/aria2_log.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET} --async-dns=false


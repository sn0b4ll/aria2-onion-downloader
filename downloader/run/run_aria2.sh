#!/bin/sh
set -e

touch /conf/aria2.session
touch /log/logs.txt

exec aria2c --conf-path=/conf/aria2.conf --log=/log/logs.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET}

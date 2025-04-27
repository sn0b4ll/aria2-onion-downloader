#!/bin/bash
set -e

touch /conf/aria2.session
touch /log/aria2_log.txt
touch /log/v2ray_access.log
touch /log/v2ray_error.log

echo "Generating V2Ray config based on TORSERVNUM=$TORSERVNUM..."

if ! [[ "$TORSERVNUM" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: TORSERVNUM environment variable must be set to a positive integer." >&2
  echo "Example: export TORSERVNUM=50 (when running the container)" >&2
  exit 1
fi

# Generate the entire JSON output and redirect its output to the config file
{
  cat <<EOF
{
  "log": {
    "access": "/log/v2ray_access.log",
    "error": "/log/v2ray_error.log",
    "loglevel": "debug"
  },
  "inbounds": [
    {
      "port": 16001,
      "listen": "127.0.0.1",
      "protocol": "http",
      "streamSettings": {
        "network": "tcp",
        "tlsSettings": {
          "allowInsecure": true,
          "allowInsecureCiphers": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
EOF

  for ((i=1; i<=$TORSERVNUM; i++)); do
    printf "    {\n"
    printf "      \"protocol\": \"socks\",\n"
    printf "      \"sendThrough\": \"127.0.0.%s\",\n" "$i"
    printf "      \"tag\": \"tor-%s\",\n" "$i"
    printf "      \"settings\": {\n"
    printf "        \"servers\": [\n"
    printf "          {\n"
    printf "            \"address\": \"127.0.0.1\",\n"
            printf "            \"port\": 9050\n"
            printf "          }\n"
            printf "        ]\n"
            printf "      }\n"
            printf "    }"

    if [ "$i" -lt "$TORSERVNUM" ]; then
      printf ",\n"
    else
      printf "\n"
    fi
  done

  cat <<EOF
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "network": "tcp",
        "balancerTag": "balancer"
      }
    ],
    "balancers": [
      {
        "tag": "balancer",
        "selector": [
          "tor-"
        ],
        "strategy": {
          "type": "random"
        }
      }
    ]
  }
}
EOF
} > /conf/config.json

echo "V2Ray config generated at /conf/config.json"

python /home/creatorrc/creatorrc.py --speetor && mv -f tor_config.txt /conf/torrc && tor --runasdaemon 1 -f /conf/torrc || tor --runasdaemon 1

exec v2ray run -c /conf/config.json &
exec aria2c --conf-path=/conf/aria2.conf --log=/log/aria2_log.txt --rpc-listen-port=${RPCPORT} --rpc-secret=${RPCSECRET} --async-dns=false
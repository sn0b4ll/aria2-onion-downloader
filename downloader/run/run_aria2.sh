#!/bin/bash
set -e

touch /conf/aria2.session
touch /log/aria2_log.txt
touch /log/v2ray_access.log
touch /log/v2ray_error.log
touch /log/get_tor_ua.log

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

if [ "$GETTORUA" = "true" ]; then
echo "Getting latest Tor Browser User-Agent..."
if ! python /run/get_tor_ua.py >> /log/get_tor_ua.log 2>&1; then
    echo "Warning: get_tor_ua.py script exited with an error. Check /log/get_tor_ua.log"
  fi
fi

python /home/creatorrc/creatorrc.py --speetor && mv -f tor_config.txt /conf/torrc && tor --runasdaemon 1 --ControlPort 9051 -f /conf/torrc || tor --runasdaemon 1 --ControlPort 9051

exec v2ray run -c /conf/config.json &

ARIA2_ARGS=(
  --conf-path=/conf/aria2.conf
  --log=/log/aria2_log.txt
  --rpc-listen-port=${RPCPORT}
  --rpc-secret=${RPCSECRET}
  --no-want-digest-header=true
  --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
  --async-dns=false
)

# If there are any .txt files in /conf, use aria2c -i to read URLs.
# If multiple .txt files exist, concatenate them into a single temp input file.
shopt -s nullglob
txt_files=(/conf/*.txt)
if [ ${#txt_files[@]} -gt 0 ]; then
  if [ ${#txt_files[@]} -eq 1 ]; then
    INPUT_FILE="${txt_files[0]}"
  else
    INPUT_FILE="/conf/aria2_input_from_conf.txt"
    cat "${txt_files[@]}" > "$INPUT_FILE"
  fi
  echo "Found ${#txt_files[@]} .txt file(s) in /conf; starting aria2c with -i $INPUT_FILE"
  exec aria2c "${ARIA2_ARGS[@]}" -i "$INPUT_FILE"
else
  exec aria2c "${ARIA2_ARGS[@]}"
fi
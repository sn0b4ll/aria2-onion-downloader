#!/usr/bin/env bash

set -euxo pipefail

# Identify architecture
case "$(arch -s)" in
    'i386' | 'i686')
        MACHINE='32'
        ;;
    'amd64' | 'x86_64')
        MACHINE='64'
        ;;
    'armv5tel')
        MACHINE='arm32-v5'
        ;;
    'armv6l')
        MACHINE='arm32-v6'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
    'armv7' | 'armv7l')
        MACHINE='arm32-v7a'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
    'armv8' | 'aarch64')
        MACHINE='arm64-v8a'
        ;;
    'mips')
        MACHINE='mips32'
        ;;
    'mipsle')
        MACHINE='mips32le'
        ;;
    'mips64')
        MACHINE='mips64'
        ;;
    'mips64le')
        MACHINE='mips64le'
        ;;
    'ppc64')
        MACHINE='ppc64'
        ;;
    'ppc64le')
        MACHINE='ppc64le'
        ;;
    'riscv64')
        MACHINE='riscv64'
        ;;
    's390x')
        MACHINE='s390x'
        ;;
    *)
        echo "error: The architecture is not supported."
        exit 1
        ;;
esac

TMP_DIRECTORY="$(mktemp -d)/"
ZIP_FILE="${TMP_DIRECTORY}v2ray-linux-$MACHINE.zip"
DOWNLOAD_LINK="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-$MACHINE.zip"

download_v2ray() {
    curl -L -H 'Cache-Control: no-cache' -o "$ZIP_FILE" "$DOWNLOAD_LINK" -#
    if [ "$?" -ne '0' ]; then
        echo 'error: Download failed! Please check your network or try again.'
        exit 1
    fi
    curl -L -H 'Cache-Control: no-cache' -o "$ZIP_FILE.dgst" "$DOWNLOAD_LINK.dgst" -#
    if [ "$?" -ne '0' ]; then
        echo 'error: Download failed! Please check your network or try again.'
        exit 1
    fi
}

verification_v2ray() {
    for LISTSUM in 'md5' 'sha1' 'sha256' 'sha512'; do
        SUM="$(${LISTSUM}sum $ZIP_FILE | sed 's/ .*//')"
        CHECKSUM="$(grep $(echo $LISTSUM | tr [:lower:] [:upper:]) $ZIP_FILE.dgst | uniq | sed 's/.* //')"
        if [ "$SUM" != "$CHECKSUM" ]; then
            echo 'error: Check failed! Please check your network or try again.'
            exit 1
        fi
    done
}

decompression() {
    unzip -q "$ZIP_FILE" -d "$TMP_DIRECTORY"
}

install_v2ray() {
    install -m 755 "${TMP_DIRECTORY}v2ray" "/usr/local/bin/v2ray"
    install -d /usr/local/lib/v2ray/
    install -m 755 "${TMP_DIRECTORY}geoip.dat" "/usr/local/lib/v2ray/geoip.dat"
    install -m 755 "${TMP_DIRECTORY}geosite.dat" "/usr/local/lib/v2ray/geosite.dat"
}

information() {
    echo 'installed: /usr/local/bin/v2ray'
    echo 'installed: /usr/local/lib/v2ray/geoip.dat'
    echo 'installed: /usr/local/lib/v2ray/geosite.dat'
    rm -r "$TMP_DIRECTORY"
    echo "removed: $TMP_DIRECTORY"
    echo "You may need to execute a command to remove dependent software: apk del curl unzip"
    echo "info: V2Ray is installed."
}

main() {
    download_v2ray
    decompression
    install_v2ray
    information
}

main

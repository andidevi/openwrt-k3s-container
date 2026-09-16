#!/bin/ash
set -eu

# OpenWrt-Startvorgabe (angepasst auf apk / 25.12.5), k8s-fest:
# absolute Pfade, keine CWD-Abhängigkeit.
#   setup.sh einmalig -> /var/lock anlegen -> tmate sicherstellen/starten -> exec /sbin/init
#
# Kein HostNetworking / keine Host-Mounts / keine Kernel-Module vom Host nötig.

cd /

if [ ! -d /scripts ] && [ -x /setup.sh ]; then
  /setup.sh || true
fi

mkdir -p /var/lock /var/log /tmp/.uci

# Overlay-PVC prüfen (soll auf /overlay gemountet sein)
if mountpoint -q /overlay 2>/dev/null || [ -d /overlay ]; then
  echo "overlay dir present: /overlay"
else
  echo "WARN: /overlay missing" >&2
fi

# tmate nicht blockierend starten (gibt SSH-Zeile ins Log aus); im K8s ohne TTY nur wenn möglich
if command -v tmate >/dev/null 2>&1; then
  (tmate -F 2>&1 | while read -r l; do echo "[tmate] $l"; done) &
fi

exec /sbin/init

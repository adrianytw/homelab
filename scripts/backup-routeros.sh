#!/usr/bin/env bash
set -euo pipefail

unencrypted="${ROUTEROS_BACKUP_UNENCRYPTED:-0}"
if [[ "$unencrypted" != 1 ]]; then
  : "${ROUTEROS_BACKUP_PASSWORD:?set ROUTEROS_BACKUP_PASSWORD or explicitly set ROUTEROS_BACKUP_UNENCRYPTED=1}"
fi

router="${ROUTEROS_HOST:-router}"
ts="${BACKUP_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
backup_root="${BACKUP_DIR:-$HOME/homelab-backups}/routeros"
out="${backup_root}/${ts}"
remote_base="homelab-${ts}-routeros"
remote_backup="${remote_base}.backup"
remote_export="${remote_base}.rsc"

mkdir -p "$out"
chmod 700 "$out"

ros_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

run_ros() {
  ssh "$router" "$1"
}

capture() {
  local name="$1"
  local cmd="$2"
  run_ros "$cmd" >"${out}/${name}"
}

cleanup_remote() {
  run_ros "/file remove [find name=\"${remote_backup}\"]" >/dev/null 2>&1 || true
  run_ros "/file remove [find name=\"${remote_export}\"]" >/dev/null 2>&1 || true
}

trap 'echo "backup failed; remote temp files may remain: '"${remote_backup}"' '"${remote_export}"'" >&2' ERR

if [[ "$unencrypted" == 1 ]]; then
  echo "warning: creating explicitly approved unencrypted RouterOS backup" >&2
  run_ros "/system backup save name=\"${remote_base}\" dont-encrypt=yes"
  backup_description="unencrypted binary RouterOS backup"
else
  password="$(ros_escape "$ROUTEROS_BACKUP_PASSWORD")"
  run_ros "/system backup save name=\"${remote_base}\" password=\"${password}\""
  backup_description="encrypted binary RouterOS backup"
fi
run_ros "/export file=\"${remote_base}\""

scp "${router}:${remote_backup}" "${out}/routeros.backup" >/dev/null
scp "${router}:${remote_export}" "${out}/routeros.rsc" >/dev/null

capture "resource.txt" "/system resource print"
capture "packages.txt" "/system package print"
capture "addresses.txt" "/ip address print detail"
capture "dhcp.txt" "/ip pool print detail; /ip dhcp-server print detail; /ip dhcp-server network print detail; /ip dhcp-server lease print detail"
capture "dns.txt" "/ip dns print"
capture "firewall-filter.rsc" "/ip firewall filter export"
capture "firewall-nat.rsc" "/ip firewall nat export"
capture "wireguard.rsc" "/interface wireguard export"
capture "containers.txt" "/interface veth print; /container print; /container config print; /container mounts print; /disk print; /file print where name~\"usb|adguard\""
capture "services.txt" "/ip service print detail"
capture "snmp.txt" "/snmp print; /snmp community print detail without-paging"

cat >"${out}/README.md" <<EOF
# RouterOS Backup ${ts}

Router: ${router}

Files:
- routeros.backup: ${backup_description}
- routeros.rsc: full RouterOS text export
- firewall-filter.rsc: firewall filter export
- firewall-nat.rsc: firewall NAT export
- wireguard.rsc: WireGuard export
- dhcp.txt: DHCP pools, servers, networks, leases
- dns.txt: RouterOS DNS settings
- containers.txt: AdGuard container/veth/storage state
- services.txt: RouterOS service exposure state
- snmp.txt: SNMP service and community access policy (RouterOS omits passwords)
- resource.txt, packages.txt, addresses.txt: system baseline

Treat this directory as sensitive. Do not commit or share raw backup files.
EOF

chmod 600 "${out}"/*

cleanup_remote
trap - ERR

echo "$out"

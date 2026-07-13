#!/usr/bin/env bash
set -euo pipefail
umask 077

unencrypted="${ROUTEROS_BACKUP_UNENCRYPTED:-0}"
if [[ "$unencrypted" != 1 ]]; then
  : "${ROUTEROS_BACKUP_PASSWORD:?set ROUTEROS_BACKUP_PASSWORD or explicitly set ROUTEROS_BACKUP_UNENCRYPTED=1}"
fi

router="${ROUTEROS_HOST:-router}"
ts="${BACKUP_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
backup_root="${BACKUP_DIR:-$HOME/homelab-backups}/routeros"
out="${backup_root}/.${ts}.partial"
final_out="${backup_root}/${ts}"
remote_base="homelab-${ts}-routeros"
remote_backup="${remote_base}.backup"
remote_export="${remote_base}.rsc"

mkdir -p "$backup_root"
chmod 700 "$backup_root"
exec 9>"$backup_root/.lock"
flock -n 9 || { echo "RouterOS backup already running" >&2; exit 1; }
[[ ! -e "$final_out" ]] || { echo "backup timestamp collision" >&2; exit 1; }
mkdir "$out"
chmod 700 "$out"

ros_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

run_ros() {
  ssh -o BatchMode=yes -o ConnectTimeout=8 -o GSSAPIAuthentication=no -o PreferredAuthentications=publickey "$router" "$1"
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

complete=0
cleanup() {
  rc=$?
  trap - EXIT INT TERM
  cleanup_remote
  ((complete == 1)) || rm -rf "$out"
  ((rc == 0)) || echo "backup failed; remote cleanup attempted" >&2
  exit "$rc"
}
trap cleanup EXIT INT TERM

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

scp -q -o BatchMode=yes -o ConnectTimeout=8 -o GSSAPIAuthentication=no -o PreferredAuthentications=publickey "${router}:${remote_backup}" "${out}/routeros.backup"
scp -q -o BatchMode=yes -o ConnectTimeout=8 -o GSSAPIAuthentication=no -o PreferredAuthentications=publickey "${router}:${remote_export}" "${out}/routeros.rsc"

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
capture "certificates.txt" "/certificate print detail without-paging"
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
- certificates.txt: certificate names, validity, trust, and fingerprints (no private keys)
- snmp.txt: SNMP service and community access policy (RouterOS omits passwords)
- resource.txt, packages.txt, addresses.txt: system baseline
- SHA256SUMS: integrity manifest for this pack

Treat this directory as sensitive. Do not commit or share raw backup files.
EOF

(cd "$out" && sha256sum ./* >SHA256SUMS)
chmod 600 "${out}"/*
(cd "$out" && sha256sum -c SHA256SUMS >/dev/null)

cleanup_remote
remaining=$(run_ros "/file print count-only where name~\"${remote_base}\"" | tr -d '[:space:]')
[[ "$remaining" == 0 ]] || { echo "RouterOS temporary backup files remain" >&2; exit 1; }
mv "$out" "$final_out"
complete=1
trap - EXIT INT TERM

echo "$final_out"

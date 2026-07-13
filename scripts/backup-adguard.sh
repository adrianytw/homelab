#!/usr/bin/env bash
set -euo pipefail
umask 077

repo=$(cd "$(dirname "$0")/.." && pwd)
router=${ROUTEROS_HOST:-router}
root=${ADGUARD_BACKUP_DIR:-$HOME/homelab-backups/adguard}
identity=${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}
state=${XDG_STATE_HOME:-$HOME/.local/state}/homelab
secret="$repo/cluster/apps/healthchecks/ping-key.enc.yaml"
stamp=${BACKUP_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}
partial="$root/.$stamp.partial"
dest="$root/$stamp"
archive="$partial/AdGuardHome.yaml.age"
created=0
complete=0
ping_key=""
if command -v sops >/dev/null && [[ -f "$secret" ]]; then
  ping_key=$(sops --decrypt --extract '["stringData"]["ping-key"]' "$secret" 2>/dev/null || true)
fi
ping() {
  [[ -z "$ping_key" ]] || ! command -v curl >/dev/null || curl -fsS --retry 2 --max-time 15 \
    "https://health.ops.nairdev.com/ping/${ping_key}/adguard-config-backup${1:-}" >/dev/null || true
}
cleanup() {
  rc=$?
  trap - EXIT
  ((created == 0)) || rm -rf "$partial"
  if ((complete == 1)); then ping ""; else ping /fail; fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cmd in ssh age age-keygen sha256sum flock; do command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }; done
test -r "$identity" || { echo "age identity is not readable" >&2; exit 1; }
recipient=${AGE_RECIPIENT:-$(age-keygen -y "$identity")}
[[ "$recipient" == age1* ]] || { echo "invalid age recipient" >&2; exit 1; }

mkdir -p "$root"
chmod 0700 "$root"
mkdir -p "$state"
chmod 0700 "$state"
exec 9>"$state/backup.lock"
flock -n 9 || { echo "another homelab backup is running" >&2; exit 1; }
[[ ! -e "$dest" && ! -e "$partial" ]] || { echo "backup timestamp collision" >&2; exit 1; }
mkdir "$partial"
created=1
chmod 0700 "$partial"
ping /start
ssh_opts=(-o BatchMode=yes -o ConnectTimeout=8 -o GSSAPIAuthentication=no -o PreferredAuthentications=publickey "$router")
container_cmd() { ssh "${ssh_opts[@]}" "/container shell 0 cmd=\"$1\""; }
remote_hash() { container_cmd 'sha256sum /opt/adguardhome/conf/AdGuardHome.yaml' | awk '{print $1}'; }

before=$(remote_hash)
[[ "$before" =~ ^[0-9a-f]{64}$ ]] || { echo "invalid source checksum" >&2; exit 1; }
container_cmd 'cat /opt/adguardhome/conf/AdGuardHome.yaml' | age -r "$recipient" -o "$archive.partial"
after=$(remote_hash)
[[ "$before" == "$after" ]] || { echo "AdGuard configuration changed during backup" >&2; exit 1; }
test "$(age -d -i "$identity" "$archive.partial" | sha256sum | awk '{print $1}')" = "$before"
mv "$archive.partial" "$archive"

printf '%s  %s\n' "$before" AdGuardHome.yaml >"$partial/PLAINTEXT_SHA256"
(cd "$partial" && sha256sum "$(basename "$archive")" >SHA256SUMS)
printf '%s\n' 'Encrypted AdGuard Home configuration captured without stopping DNS.' >"$partial/README.txt"
chmod 0600 "$partial"/*
(cd "$partial" && sha256sum -c SHA256SUMS >/dev/null)

mv "$partial" "$dest"
created=0
complete=1
trap - EXIT INT TERM
ping ""
printf '%s\n' "$dest/AdGuardHome.yaml.age"

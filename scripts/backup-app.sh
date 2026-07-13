#!/usr/bin/env bash
set -euo pipefail

host=${BACKUP_HOST:-nmac}
root=${APP_BACKUP_DIR:-$HOME/homelab-backups/data}
identity=${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}
app=${1:-}
case "$app" in glance|uptime-kuma|ntfy|healthchecks|prometheus|grafana) ;; *) echo "invalid application" >&2; exit 2;; esac

ssh_cmd() { local a q=(); for a; do printf -v a %q "$a"; q+=("$a"); done; ssh -o BatchMode=yes -o ConnectTimeout=8 "$host" "${q[*]}"; }
maint() { ssh_cmd sudo -n /usr/local/sbin/homelab-maintenance "$@"; }
recover() { rc=$?; trap - EXIT INT TERM; [[ -z ${dest:-} ]] || rm -f "$dest"/*.partial; ((prepared == 0)) || maint recover "$app" >/dev/null 2>&1 || true; ((rc == 0)) || echo "backup failed; automatic recovery attempted" >&2; exit "$rc"; }
trap recover EXIT INT TERM
prepared=0

for cmd in ssh age age-keygen sops tar sha256sum python3 flock; do command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }; done
test -r "$identity" || { echo "age identity is not readable" >&2; exit 1; }
recipient=${AGE_RECIPIENT:-$(age-keygen -y "$identity")}
[[ "$recipient" == age1* ]] || { echo "invalid age recipient" >&2; exit 1; }
SOPS_AGE_KEY_FILE="$identity" sops --decrypt cluster/apps/ntfy/admin-credentials.enc.yaml >/dev/null

mkdir -p "$root/$app"
chmod 0700 "$root" "$root/$app"
[[ $(stat -c %a "$root") == 700 && $(stat -c %a "$root/$app") == 700 ]] || { echo "unsafe backup directory mode" >&2; exit 1; }
exec 9>"$root/$app/.lock"
flock -n 9 || { echo "backup already running for $app" >&2; exit 1; }
stamp=$(date -u +%Y%m%dT%H%M%SZ)
dest="$root/$app/$stamp"
mkdir "$dest" || { echo "backup timestamp collision" >&2; exit 1; }
chmod 0700 "$dest"

mapfile -t sizes < <(maint inspect "$app" | /usr/bin/cut -f2)
(( ${#sizes[@]} > 0 )) || { echo "no application volume" >&2; exit 1; }
bytes=0; for size in "${sizes[@]}"; do [[ "$size" =~ ^[0-9]+$ ]] || exit 1; ((bytes += size)); done
available=$(df -PB1 "$dest" | awk 'NR==2 {print $4}')
((available > bytes * 2 + 104857600)) || { echo "insufficient backup free space" >&2; exit 1; }

maint prepare "$app"
prepared=1
archives=("$app.tar.age")
[[ "$app" != prometheus ]] || archives+=(alertmanager-data.tar.age)
for i in "${!archives[@]}"; do
  archive="$dest/${archives[$i]}"
  volume=primary; ((i == 0)) || volume=extra
  maint stream "$app" "$volume" | age -r "$recipient" -o "$archive.partial"
  chmod 0600 "$archive.partial"
  age -d -i "$identity" "$archive.partial" | tar -tf - >/dev/null
  mv "$archive.partial" "$archive"
done
(cd "$dest" && sha256sum ./*.tar.age > SHA256SUMS)
chmod 0600 "$dest"/*
find "$dest" -maxdepth 1 -type f ! -perm 0600 -print -quit | grep -q . && { echo "unsafe backup file mode" >&2; exit 1; }
(cd "$dest" && sha256sum -c SHA256SUMS >/dev/null)

case "$app" in uptime-kuma|ntfy|healthchecks|grafana)
  scratch=$(mktemp -d); age -d -i "$identity" "$dest/$app.tar.age" | tar -xf - -C "$scratch"
  python3 - "$scratch" <<'PY'
import sqlite3, sys
from pathlib import Path
dbs = [p for p in Path(sys.argv[1]).rglob('*') if p.suffix in ('.db', '.sqlite')]
assert dbs, 'no SQLite database found'
for db in dbs:
    with sqlite3.connect(f'file:{db}?mode=ro', uri=True) as con:
        assert con.execute('PRAGMA quick_check').fetchone() == ('ok',), f'SQLite quick_check failed: {db}'
PY
  rm -rf "$scratch"
esac

maint recover "$app"
prepared=0
trap - EXIT INT TERM
printf '%s\n' "$dest/$app.tar.age"

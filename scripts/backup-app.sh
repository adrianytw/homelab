#!/usr/bin/env bash
set -euo pipefail

host=${BACKUP_HOST:-nmac}
root=${APP_BACKUP_DIR:-$HOME/homelab-backups/data}
identity=${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}
state=${XDG_STATE_HOME:-$HOME/.local/state}/homelab
app=${1:-}
case "$app" in glance|uptime-kuma|ntfy|healthchecks|prometheus|grafana) ;; *) echo "invalid application" >&2; exit 2;; esac

ssh_cmd() { local a q=(); for a; do printf -v a %q "$a"; q+=("$a"); done; ssh -o BatchMode=yes -o ConnectTimeout=8 -o GSSAPIAuthentication=no -o PreferredAuthentications=publickey "$host" "${q[*]}"; }
maint() { ssh_cmd sudo -n /usr/local/sbin/homelab-maintenance "$@"; }
recover() { rc=$?; trap - EXIT; [[ -z ${scratch:-} ]] || rm -rf "$scratch"; (( ${work_created:-0} == 0 )) || rm -rf "$work"; ((prepared == 0)) || maint recover "$app" >/dev/null 2>&1 || true; ((rc == 0)) || echo "backup failed; automatic recovery attempted" >&2; exit "$rc"; }
trap recover EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
prepared=0

for cmd in ssh age age-keygen tar sha256sum python3 flock; do command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }; done
test -r "$identity" || { echo "age identity is not readable" >&2; exit 1; }
recipient=${AGE_RECIPIENT:-$(age-keygen -y "$identity")}
[[ "$recipient" == age1* ]] || { echo "invalid age recipient" >&2; exit 1; }

if [[ ${HOMELAB_BACKUP_LOCK_HELD:-0} != 1 ]]; then
  mkdir -p "$state"
  chmod 0700 "$state"
  exec 8>"$state/backup.lock"
  flock -n 8 || { echo "another homelab backup is running" >&2; exit 1; }
fi

mkdir -p "$root/$app"
chmod 0700 "$root" "$root/$app"
[[ $(stat -c %a "$root") == 700 && $(stat -c %a "$root/$app") == 700 ]] || { echo "unsafe backup directory mode" >&2; exit 1; }
exec 9>"$root/$app/.lock"
flock -n 9 || { echo "backup already running for $app" >&2; exit 1; }
stamp=$(date -u +%Y%m%dT%H%M%SZ)
work="$root/$app/.$stamp.partial"
final="$root/$app/$stamp"
work_created=0
[[ ! -e "$work" && ! -e "$final" ]] || { echo "backup timestamp collision" >&2; exit 1; }
mkdir "$work"
work_created=1
chmod 0700 "$work"

inspection=$(maint inspect "$app")
mapfile -t sizes < <(printf '%s\n' "$inspection" | /usr/bin/cut -f2)
(( ${#sizes[@]} > 0 )) || { echo "no application volume" >&2; exit 1; }
bytes=0; for size in "${sizes[@]}"; do [[ "$size" =~ ^[0-9]+$ ]] || exit 1; ((bytes += size)); done
available=$(df -PB1 "$work" | awk 'NR==2 {print $4}')
((available > bytes * 2 + 104857600)) || { echo "insufficient backup free space" >&2; exit 1; }

maint prepare "$app"
prepared=1
archives=("$app.tar.age")
[[ "$app" != prometheus ]] || archives+=(alertmanager-data.tar.age)
for i in "${!archives[@]}"; do
  archive="$work/${archives[$i]}"
  volume=primary; ((i == 0)) || volume=extra
  maint stream "$app" "$volume" | age -r "$recipient" -o "$archive.partial"
  chmod 0600 "$archive.partial"
  age -d -i "$identity" "$archive.partial" | tar -tf - >/dev/null
  mv "$archive.partial" "$archive"
done
(cd "$work" && sha256sum ./*.tar.age > SHA256SUMS)
chmod 0600 "$work"/*
find "$work" -maxdepth 1 -type f ! -perm 0600 -print -quit | grep -q . && { echo "unsafe backup file mode" >&2; exit 1; }
(cd "$work" && sha256sum -c SHA256SUMS >/dev/null)

case "$app" in uptime-kuma|ntfy|healthchecks|grafana)
  scratch=$(mktemp -d); chmod 0700 "$scratch"; mkdir "$scratch/data"
  age -d -i "$identity" "$work/$app.tar.age" | tar -xf - -C "$scratch/data"
  python3 - "$scratch/data" "$app" <<'PY'
import sqlite3, sys
from pathlib import Path
dbs = [p for p in Path(sys.argv[1]).rglob('*') if p.suffix in ('.db', '.sqlite')]
assert dbs, 'no SQLite database found'
for db in dbs:
    with sqlite3.connect(f'file:{db}?mode=ro', uri=True) as con:
        assert con.execute('PRAGMA quick_check').fetchone() == ('ok',), f'SQLite quick_check failed: {db}'
        if sys.argv[2] == 'uptime-kuma' and db.name == 'kuma.db':
            wanted = {'Glance', 'Uptime Kuma', 'ntfy', 'Healthchecks', 'Prometheus',
                      'Grafana', 'Home Assistant', 'Router', 'AdGuard',
                      'Test workload', 'AdGuard DNS'}
            names = {row[0] for row in con.execute('SELECT name FROM monitor')}
            assert wanted <= names, f'missing monitors: {sorted(wanted - names)}'
PY
  rm -rf "$scratch"
  scratch=""
esac

maint recover "$app"
prepared=0
mv "$work" "$final"
work_created=0
trap - EXIT INT TERM
printf '%s\n' "$final/$app.tar.age"

#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/fixture"
mkdir -m 0700 "$tmp/scratch"
printf fixture >"$tmp/fixture/data.txt"
python3 - <<PY
import sqlite3
with sqlite3.connect('$tmp/fixture/kuma.db') as db:
    db.execute('create table monitor (id integer primary key, name text)')
    names = ('Glance', 'Uptime Kuma', 'ntfy', 'Healthchecks', 'Prometheus',
             'Grafana', 'Home Assistant', 'Router', 'AdGuard',
             'Test workload', 'AdGuard DNS')
    db.executemany('insert into monitor(name) values (?)', ((name,) for name in names))
PY
printf age-secret-key-fixture >"$tmp/identity"

cat >"$tmp/bin/ssh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOCK_LOG"
case "$*" in
  *"homelab-maintenance inspect uptime-kuma"*) printf 'primary\t1024\n' ;;
  *"homelab-maintenance stream uptime-kuma primary"*) /usr/bin/tar -C "$MOCK_FIXTURE" -cf - . ;;
esac
EOF
cat >"$tmp/bin/age-keygen" <<'EOF'
#!/usr/bin/env bash
printf 'age1fixturefixturefixturefixturefixturefixturefixturefixture\n'
EOF
cat >"$tmp/bin/age" <<'EOF'
#!/usr/bin/env bash
if [[ " $* " == *" -r "* ]]; then
  [[ ${MOCK_ENCRYPT_FAIL:-0} == 0 ]] || exit 9
  out=${!#}
  if [[ ${MOCK_TRUNCATE:-0} == 1 ]]; then head -c 10 >"$out"; else /bin/cat >"$out"; fi
else
  /bin/cat "${!#}"
fi
EOF
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp/bin/sops"
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" MOCK_LOG="$tmp/log" MOCK_FIXTURE="$tmp/fixture"
export TMPDIR="$tmp/scratch"
export XDG_STATE_HOME="$tmp/state"

wrapper="$repo/ansible/files/homelab-maintenance"
if "$wrapper" inspect arbitrary >/dev/null 2>&1; then echo 'wrapper accepted arbitrary app' >&2; exit 1; fi
if "$wrapper" inspect uptime-kuma /tmp >/dev/null 2>&1; then echo 'wrapper accepted a raw path' >&2; exit 1; fi
if "$repo/scripts/backup-app.sh" arbitrary >/dev/null 2>&1; then echo 'backup accepted arbitrary app' >&2; exit 1; fi

mkdir -p "$XDG_STATE_HOME/homelab"
exec 8>"$XDG_STATE_HOME/homelab/backup.lock"
flock -n 8
if APP_BACKUP_DIR="$tmp/backups-locked" SOPS_AGE_KEY_FILE="$tmp/identity" "$repo/scripts/backup-app.sh" glance >/dev/null 2>&1; then
  echo 'backup ignored the global lock' >&2; exit 1
fi
flock -u 8

run_failure() {
  : >"$MOCK_LOG"
  if APP_BACKUP_DIR="$tmp/backups-$1" SOPS_AGE_KEY_FILE="$tmp/identity" "$repo/scripts/backup-app.sh" uptime-kuma >/dev/null 2>&1; then
    echo "$1 failure unexpectedly succeeded" >&2; exit 1
  fi
  grep -q 'homelab-maintenance prepare uptime-kuma' "$MOCK_LOG"
  grep -q 'homelab-maintenance recover uptime-kuma' "$MOCK_LOG"
  ! find "$tmp/backups-$1" -name '*.partial' -print -quit | grep -q .
  ! find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .
}
MOCK_ENCRYPT_FAIL=1 run_failure encryption
MOCK_TRUNCATE=1 run_failure truncated

python3 - <<PY
import sqlite3
with sqlite3.connect('$tmp/fixture/kuma.db') as db:
    db.execute("delete from monitor where name = 'AdGuard DNS'")
PY
: >"$MOCK_LOG"
if APP_BACKUP_DIR="$tmp/backups-missing-monitor" SOPS_AGE_KEY_FILE="$tmp/identity" "$repo/scripts/backup-app.sh" uptime-kuma >/dev/null 2>&1; then
  echo 'missing monitor unexpectedly passed backup validation' >&2; exit 1
fi
grep -q 'homelab-maintenance recover uptime-kuma' "$MOCK_LOG"
! find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .
python3 - <<PY
import sqlite3
with sqlite3.connect('$tmp/fixture/kuma.db') as db:
    db.execute("insert into monitor(name) values ('AdGuard DNS')")
PY

: >"$MOCK_LOG"
archive=$(APP_BACKUP_DIR="$tmp/backups-ok" SOPS_AGE_KEY_FILE="$tmp/identity" "$repo/scripts/backup-app.sh" uptime-kuma)
[[ -f "$archive" && $(stat -c %a "$archive") == 600 ]]
age -d -i "$tmp/identity" "$archive" | tar -tf - >/dev/null
grep -q 'homelab-maintenance recover uptime-kuma' "$MOCK_LOG"
! find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .
echo 'backup app test ok'

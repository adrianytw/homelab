#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
state=${XDG_STATE_HOME:-$HOME/.local/state}/homelab
secret="$repo/cluster/apps/healthchecks/ping-key.enc.yaml"
mkdir -p "$state"
chmod 0700 "$state"
exec 9>"$state/backup.lock"
flock -n 9 || exit 0
export HOMELAB_BACKUP_LOCK_HELD=1

ping_key=""
if [[ -f "$secret" ]]; then
  ping_key=$(sops --decrypt --extract '["stringData"]["ping-key"]' "$secret" 2>/dev/null || true)
fi
ping() {
  [[ -z "$ping_key" ]] || curl -fsS --retry 2 --max-time 15 \
    "https://health.ops.nairdev.com/ping/${ping_key}/k3s-app-backups${1:-}" >/dev/null || true
}
finish() {
  rc=$?
  trap - EXIT
  if ((rc == 0)); then ping ""; else ping /fail; fi
  exit "$rc"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

ping /start
cd "$repo"
make backup-apps

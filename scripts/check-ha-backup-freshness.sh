#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
root=${HA_BACKUP_DIR:-$HOME/homelab-backups/home-assistant}
secret="$repo/cluster/apps/healthchecks/ping-key.enc.yaml"
max_age=${HA_BACKUP_MAX_AGE_SECONDS:-691200}

ping_key=""
if [[ -f "$secret" ]]; then
  ping_key=$(sops --decrypt --extract '["stringData"]["ping-key"]' "$secret" 2>/dev/null || true)
fi
ping() {
  [[ -z "$ping_key" ]] || curl -fsS --retry 2 --max-time 15 \
    "https://health.ops.nairdev.com/ping/${ping_key}/ha-backup-freshness${1:-}" >/dev/null || true
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

pack=$(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)
[[ -n "$pack" ]] || { echo "no Home Assistant backup found" >&2; exit 1; }
archive=$(find "$pack" -maxdepth 1 -type f -name '*.tar.age' -print -quit)
checksum=$(find "$pack" -maxdepth 1 -type f -name '*.sha256' -print -quit)
[[ -n "$archive" && -n "$checksum" ]] || { echo "incomplete Home Assistant backup pack: $pack" >&2; exit 1; }
(cd "$pack" && sha256sum -c "$(basename "$checksum")" >/dev/null)
age=$(( $(date +%s) - $(stat -c %Y "$archive") ))
((age <= max_age)) || { echo "Home Assistant backup is older than $max_age seconds" >&2; exit 1; }

echo "Home Assistant backup freshness ok: $(basename "$pack")"

#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
state=${XDG_STATE_HOME:-$HOME/.local/state}/homelab
mkdir -p "$state"
chmod 0700 "$state"
current=$(mktemp "$state/crontab.XXXXXX")
error=$(mktemp "$state/crontab-error.XXXXXX")
trap 'rm -f "$current" "$error"' EXIT

if crontab -l >"$current" 2>"$error"; then
  :
elif grep -q '^no crontab for ' "$error"; then
  :
else
  cat "$error" >&2
  exit 1
fi

{
  sed '/^# BEGIN homelab backups$/,/^# END homelab backups$/d' "$current"
  echo '# BEGIN homelab backups'
  printf '15 3 * * * cd %q && env PATH=%q scripts/backup-daily.sh 2>&1 | /usr/bin/logger -t homelab-backup\n' "$repo" "$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
  printf '45 3 * * * cd %q && env PATH=%q scripts/backup-adguard.sh 2>&1 | /usr/bin/logger -t homelab-adguard-backup\n' "$repo" "$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
  printf '0 5 * * * cd %q && env PATH=%q scripts/check-ha-backup-freshness.sh 2>&1 | /usr/bin/logger -t homelab-ha-backup\n' "$repo" "$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
  echo '# END homelab backups'
} | crontab -

crontab -l | sed -n '/^# BEGIN homelab backups$/,/^# END homelab backups$/p'

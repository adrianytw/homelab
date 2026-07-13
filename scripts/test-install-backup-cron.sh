#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"

cat >"$tmp/bin/crontab" <<'EOF'
#!/usr/bin/env bash
case ${1:-} in
  -l)
    if [[ ${MOCK_CRONTAB_FAIL:-0} == 1 ]]; then echo 'permission denied' >&2; exit 1; fi
    [[ -f "$MOCK_CRONTAB" ]] || { echo 'no crontab for test' >&2; exit 1; }
    cat "$MOCK_CRONTAB"
    ;;
  -) cat >"$MOCK_CRONTAB" ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$tmp/bin/crontab"

export PATH="$tmp/bin:$PATH" HOME="$tmp/home" MOCK_CRONTAB="$tmp/crontab"
"$repo/scripts/install-backup-cron.sh" >/dev/null
"$repo/scripts/install-backup-cron.sh" >/dev/null

[[ $(grep -c '^# BEGIN homelab backups$' "$MOCK_CRONTAB") == 1 ]]
[[ $(grep -c '^# END homelab backups$' "$MOCK_CRONTAB") == 1 ]]
[[ $(grep -c 'scripts/backup-daily.sh' "$MOCK_CRONTAB") == 1 ]]
[[ $(grep -c 'scripts/backup-adguard.sh' "$MOCK_CRONTAB") == 1 ]]
[[ $(grep -c 'scripts/check-ha-backup-freshness.sh' "$MOCK_CRONTAB") == 1 ]]

before=$(sha256sum "$MOCK_CRONTAB" | awk '{print $1}')
if MOCK_CRONTAB_FAIL=1 "$repo/scripts/install-backup-cron.sh" >/dev/null 2>&1; then
  echo 'generic crontab read failure unexpectedly passed' >&2; exit 1
fi
[[ $(sha256sum "$MOCK_CRONTAB" | awk '{print $1}') == "$before" ]]

echo 'backup cron install test ok'

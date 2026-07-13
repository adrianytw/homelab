#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
printf 'dns:\n  bind_hosts: [0.0.0.0]\n' >"$tmp/config"
printf age-secret-key-fixture >"$tmp/identity"

cat >"$tmp/bin/ssh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *sha256sum*)
    sha256sum "$MOCK_CONFIG" | awk -v n="${MOCK_HASH_CALLS:-0}" '{print $1, "/opt/adguardhome/conf/AdGuardHome.yaml"}'
    calls=$(cat "$MOCK_COUNT"); calls=$((calls + 1)); printf '%s' "$calls" >"$MOCK_COUNT"
    if [[ ${MOCK_CHANGE:-0} == 1 && $calls == 1 ]]; then printf '# changed\n' >>"$MOCK_CONFIG"; fi
    ;;
  *cat*) cat "$MOCK_CONFIG" ;;
esac
EOF
cat >"$tmp/bin/age-keygen" <<'EOF'
#!/usr/bin/env bash
printf 'age1fixturefixturefixturefixturefixturefixturefixturefixture\n'
EOF
cat >"$tmp/bin/age" <<'EOF'
#!/usr/bin/env bash
if [[ " $* " == *" -r "* ]]; then /bin/cat >"${!#}"; else /bin/cat "${!#}"; fi
EOF
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp/bin/sops"
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" MOCK_CONFIG="$tmp/config" MOCK_COUNT="$tmp/count"
export XDG_STATE_HOME="$tmp/state"

printf 0 >"$MOCK_COUNT"
archive=$(ADGUARD_BACKUP_DIR="$tmp/ok" SOPS_AGE_KEY_FILE="$tmp/identity" BACKUP_TIMESTAMP=ok "$repo/scripts/backup-adguard.sh")
[[ -f "$archive" && $(stat -c %a "$archive") == 600 && $(stat -c %a "$(dirname "$archive")") == 700 ]]
(cd "$(dirname "$archive")" && sha256sum -c SHA256SUMS >/dev/null)

printf 0 >"$MOCK_COUNT"
if MOCK_CHANGE=1 ADGUARD_BACKUP_DIR="$tmp/fail" SOPS_AGE_KEY_FILE="$tmp/identity" BACKUP_TIMESTAMP=fail "$repo/scripts/backup-adguard.sh" >/dev/null 2>&1; then
  echo 'changing AdGuard source unexpectedly passed' >&2; exit 1
fi
[[ ! -e "$tmp/fail/fail" ]]

mkdir -p "$tmp/collision/collision"
printf keep >"$tmp/collision/collision/sentinel"
if ADGUARD_BACKUP_DIR="$tmp/collision" SOPS_AGE_KEY_FILE="$tmp/identity" BACKUP_TIMESTAMP=collision "$repo/scripts/backup-adguard.sh" >/dev/null 2>&1; then
  echo 'timestamp collision unexpectedly passed' >&2; exit 1
fi
[[ $(<"$tmp/collision/collision/sentinel") == keep ]]

echo 'backup AdGuard test ok'

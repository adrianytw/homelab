#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/fixture"
printf 'fixture\n' >"$tmp/fixture/data.txt"
printf 'age-secret-key-fixture\n' >"$tmp/identity"

cat >"$tmp/bin/ssh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOCK_LOG"
case "$*" in
  *"get pvc "*) printf 'pvc-volume' ;;
  *"get pv "*) printf '/var/lib/rancher/k3s/storage/pvc-volume_core_uptime-kuma-data' ;;
  *"du -sb "*) printf '1024\t%s\n' "$MOCK_FIXTURE" ;;
  *" tar "*) /usr/bin/tar -C "$MOCK_FIXTURE" -cf - . ;;
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
  out="${!#}"
  if [[ ${MOCK_TRUNCATE:-0} == 1 ]]; then head -c 10 >"$out"; else /bin/cat >"$out"; fi
else
  /bin/cat "${!#}"
fi
EOF
cat >"$tmp/bin/sops" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$tmp/bin/sqlite3" <<'EOF'
#!/usr/bin/env bash
printf 'ok\n'
EOF
chmod +x "$tmp/bin/"*

export PATH="$tmp/bin:$PATH" MOCK_LOG="$tmp/log" MOCK_FIXTURE="$tmp/fixture"
if APP_BACKUP_DIR="$tmp/backups" SOPS_AGE_KEY_FILE="$tmp/identity" "$repo/scripts/backup-app.sh" arbitrary 2>/dev/null; then
  echo "allowlist accepted an arbitrary app" >&2
  exit 1
fi

run_failure() {
  : >"$MOCK_LOG"
  if APP_BACKUP_DIR="$tmp/backups-$1" SOPS_AGE_KEY_FILE="$tmp/identity" "$repo/scripts/backup-app.sh" uptime-kuma >/dev/null 2>&1; then
    echo "$1 failure unexpectedly succeeded" >&2
    exit 1
  fi
  grep -q 'scale deployment/uptime-kuma --replicas=1' "$MOCK_LOG"
  grep -q 'patch kustomization/uptime-kuma' "$MOCK_LOG"
  grep -q 'patch kustomization/flux-system' "$MOCK_LOG"
}

MOCK_ENCRYPT_FAIL=1 run_failure encryption
MOCK_TRUNCATE=1 run_failure truncated
echo "backup app test ok"

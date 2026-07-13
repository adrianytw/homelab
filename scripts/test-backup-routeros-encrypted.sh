#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
printf age-secret-key-fixture >"$tmp/identity"

cat >"$tmp/bin/age-keygen" <<'EOF'
#!/usr/bin/env bash
printf 'age1fixturefixturefixturefixturefixturefixturefixturefixture\n'
EOF
cat >"$tmp/bin/age" <<'EOF'
#!/usr/bin/env bash
if [[ " $* " == *" -r "* ]]; then /bin/cat >"${!#}"; else /bin/cat "${!#}"; fi
EOF
cat >"$tmp/bin/sops" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$tmp/backup" <<'EOF'
#!/usr/bin/env bash
set -e
[[ ${MOCK_FAIL:-0} == 0 ]] || exit 9
[[ ${#ROUTEROS_BACKUP_PASSWORD} == 48 && ${ROUTEROS_BACKUP_UNENCRYPTED:-0} != 1 ]]
pack="$BACKUP_DIR/routeros/$BACKUP_TIMESTAMP"
mkdir -p "$pack"
printf fixture >"$pack/routeros.backup"
(cd "$pack" && sha256sum routeros.backup >SHA256SUMS)
EOF
cat >"$tmp/review" <<'EOF'
#!/usr/bin/env bash
set -e
(cd "$BACKUP_PACK" && sha256sum -c SHA256SUMS >/dev/null)
printf reviewed >"$REVIEW_OUT"
EOF
chmod +x "$tmp/bin/"* "$tmp/backup" "$tmp/review"
export PATH="$tmp/bin:$PATH" XDG_STATE_HOME="$tmp/state"

archive=$(ROUTEROS_AGE_BACKUP_DIR="$tmp/out" SOPS_AGE_KEY_FILE="$tmp/identity" \
  ROUTEROS_BACKUP_SCRIPT="$tmp/backup" ROUTEROS_REVIEW_SCRIPT="$tmp/review" \
  BACKUP_TIMESTAMP=ok "$repo/scripts/backup-routeros-encrypted.sh")
[[ -f "$archive" && $(stat -c %a "$archive") == 600 && $(stat -c %a "$(dirname "$archive")") == 700 ]]
(cd "$(dirname "$archive")" && sha256sum -c SHA256SUMS >/dev/null)
age -d -i "$tmp/identity" "$archive" | tar -tf - | grep -q 'ok/routeros.backup'
age -d -i "$tmp/identity" "$archive" | tar -tf - | grep -q 'ok/routeros-backup-password.txt.age'
mkdir "$tmp/unpack"
age -d -i "$tmp/identity" "$archive" | tar -xf - -C "$tmp/unpack"
[[ $(age -d -i "$tmp/identity" "$tmp/unpack/ok/routeros-backup-password.txt.age" | tr -d '\n' | wc -c) == 48 ]]
! find "$tmp/state" -type d -name 'routeros-stage.*' -print -quit | grep -q .

if MOCK_FAIL=1 ROUTEROS_AGE_BACKUP_DIR="$tmp/fail" SOPS_AGE_KEY_FILE="$tmp/identity" \
  ROUTEROS_BACKUP_SCRIPT="$tmp/backup" ROUTEROS_REVIEW_SCRIPT="$tmp/review" \
  BACKUP_TIMESTAMP=fail "$repo/scripts/backup-routeros-encrypted.sh" >/dev/null 2>&1; then
  echo 'RouterOS source failure unexpectedly passed' >&2; exit 1
fi
! find "$tmp/fail" -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .
! find "$tmp/state" -type d -name 'routeros-stage.*' -print -quit | grep -q .

mkdir -p "$tmp/collision/collision"
printf keep >"$tmp/collision/collision/sentinel"
if ROUTEROS_AGE_BACKUP_DIR="$tmp/collision" SOPS_AGE_KEY_FILE="$tmp/identity" \
  ROUTEROS_BACKUP_SCRIPT="$tmp/backup" ROUTEROS_REVIEW_SCRIPT="$tmp/review" \
  BACKUP_TIMESTAMP=collision "$repo/scripts/backup-routeros-encrypted.sh" >/dev/null 2>&1; then
  echo 'RouterOS timestamp collision unexpectedly passed' >&2; exit 1
fi
[[ $(<"$tmp/collision/collision/sentinel") == keep ]]

echo 'encrypted RouterOS backup test ok'

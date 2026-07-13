#!/usr/bin/env bash
set -euo pipefail
umask 077

repo=$(cd "$(dirname "$0")/.." && pwd)
root=${ROUTEROS_AGE_BACKUP_DIR:-$HOME/homelab-backups/routeros-encrypted}
identity=${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}
state=${XDG_STATE_HOME:-$HOME/.local/state}/homelab
secret="$repo/cluster/apps/healthchecks/ping-key.enc.yaml"
backup_script=${ROUTEROS_BACKUP_SCRIPT:-$repo/scripts/backup-routeros.sh}
review_script=${ROUTEROS_REVIEW_SCRIPT:-$repo/scripts/review-routeros-backup.sh}
stamp=${BACKUP_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}
work="$root/.$stamp.partial"
final="$root/$stamp"
stage=""
created=0
complete=0

ping_key=""
if command -v sops >/dev/null && [[ -f "$secret" ]]; then
  ping_key=$(sops --decrypt --extract '["stringData"]["ping-key"]' "$secret" 2>/dev/null || true)
fi
ping() {
  [[ -z "$ping_key" ]] || ! command -v curl >/dev/null || curl -fsS --retry 2 --max-time 15 \
    "https://health.ops.nairdev.com/ping/${ping_key}/routeros-backup${1:-}" >/dev/null || true
}
cleanup() {
  rc=$?
  trap - EXIT
  [[ -z "$stage" ]] || rm -rf "$stage"
  ((created == 0)) || rm -rf "$work"
  if ((complete == 1)); then ping ""; else ping /fail; fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cmd in age age-keygen flock openssl sha256sum tar; do command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }; done
[[ -x "$backup_script" && -x "$review_script" ]] || { echo "RouterOS backup helpers are not executable" >&2; exit 1; }
test -r "$identity" || { echo "age identity is not readable" >&2; exit 1; }
recipient=${AGE_RECIPIENT:-$(age-keygen -y "$identity")}
[[ "$recipient" == age1* ]] || { echo "invalid age recipient" >&2; exit 1; }

mkdir -p "$root" "$state"
chmod 0700 "$root" "$state"
exec 9>"$state/backup.lock"
flock -n 9 || { echo "another homelab backup is running" >&2; exit 1; }
[[ ! -e "$work" && ! -e "$final" ]] || { echo "backup timestamp collision" >&2; exit 1; }
mkdir "$work"
created=1
chmod 0700 "$work"
stage=$(mktemp -d "$state/routeros-stage.XXXXXX")
chmod 0700 "$stage"
ping /start

password_file="$stage/routeros-backup-password.txt.age"
routeros_password=$(openssl rand -hex 24)
printf '%s\n' "$routeros_password" | age -r "$recipient" -o "$password_file"
chmod 0600 "$password_file"
BACKUP_DIR="$stage" BACKUP_TIMESTAMP="$stamp" ROUTEROS_BACKUP_PASSWORD="$routeros_password" "$backup_script" >/dev/null
unset routeros_password
pack="$stage/routeros/$stamp"
mv "$password_file" "$pack/routeros-backup-password.txt.age"
rm "$pack/SHA256SUMS"
(cd "$pack" && sha256sum ./* >SHA256SUMS)
chmod 0600 "$pack"/*
BACKUP_PACK="$pack" REVIEW_OUT="$stage/review.md" "$review_script" >/dev/null

archive="$work/routeros-$stamp.tar.age"
tar --numeric-owner -C "$stage/routeros" -cf - "$stamp" | age -r "$recipient" -o "$archive.partial"
age -d -i "$identity" "$archive.partial" | tar -tf - >/dev/null
mv "$archive.partial" "$archive"
(cd "$work" && sha256sum "$(basename "$archive")" >SHA256SUMS)
printf '%s\n' 'Age-encrypted RouterOS pack; transient unencrypted staging was removed after validation.' >"$work/README.txt"
chmod 0600 "$work"/*
(cd "$work" && sha256sum -c SHA256SUMS >/dev/null)

rm -rf "$stage"
stage=""
mv "$work" "$final"
created=0
complete=1
trap - EXIT INT TERM
ping ""
printf '%s\n' "$final/$(basename "$archive")"

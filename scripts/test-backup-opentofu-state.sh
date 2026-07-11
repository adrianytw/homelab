#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
mkdir -p "$repo/scripts" "$repo/opentofu/routeros"
cp "$(dirname "$0")/backup-opentofu-state.sh" "$repo/scripts/"

git -C "$repo" init -q
git -C "$repo" config user.email test@example.invalid
git -C "$repo" config user.name test
touch "$repo/fixture"
git -C "$repo" add fixture
git -C "$repo" commit -qm fixture

printf '%s\n' '{"serial":1,"lineage":"fixture","meta":{},"encryption_version":"v1","encrypted_data":"fixture"}' >"$repo/opentofu/routeros/terraform.tfstate"
OPENTOFU_BACKUP_DIR="$tmp/backups" BACKUP_TIMESTAMP=test "$repo/scripts/backup-opentofu-state.sh" routeros >/dev/null

destination="$tmp/backups/test/routeros"
test "$(stat -c %a "$tmp/backups/test" "$destination")" = $'700\n700'
test "$(stat -c %a "$destination"/* | sort -u)" = 600
(cd "$destination" && sha256sum -c SHA256SUMS >/dev/null)
test "$(cat "$destination/GIT_COMMIT")" = "$(git -C "$repo" rev-parse HEAD)"

printf '%s\n' '{"version":4,"serial":1,"lineage":"fixture","meta":{},"encryption_version":"fake","encrypted_data":"fake","outputs":{},"resources":[]}' >"$repo/opentofu/routeros/terraform.tfstate"
if OPENTOFU_BACKUP_DIR="$tmp/plaintext" "$repo/scripts/backup-opentofu-state.sh" routeros 2>/dev/null; then
  echo "plaintext state was accepted" >&2
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

stack="${1:-all}"
case "$stack" in
  routeros | adguard) stacks=("$stack") ;;
  all) stacks=(routeros adguard) ;;
  *) echo "usage: $0 {routeros|adguard|all}" >&2; exit 2 ;;
esac

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_root="${OPENTOFU_BACKUP_DIR:-$HOME/homelab-backups/opentofu}"
timestamp="${BACKUP_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
commit="$(git -C "$repo" rev-parse HEAD)"
umask 077

validate() {
  local file="$1"
  [[ -f "$file" ]] || { echo "state not found: $file" >&2; return 1; }
  python3 - "$file" <<'PY' || {
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        state = json.load(handle)
except (OSError, ValueError):
    raise SystemExit(1)

valid = (
    isinstance(state, dict)
    and isinstance(state.get("serial"), int)
    and not isinstance(state.get("serial"), bool)
    and isinstance(state.get("lineage"), str)
    and isinstance(state.get("meta"), dict)
    and isinstance(state.get("encrypted_data"), str)
    and bool(state["encrypted_data"])
    and isinstance(state.get("encryption_version"), str)
    and bool(state["encryption_version"])
    and not {"version", "terraform_version", "outputs", "resources"}.intersection(state)
)
raise SystemExit(0 if valid else 1)
PY
    echo "state is not an OpenTofu encrypted envelope: $file" >&2
    return 1
  }
}

for name in "${stacks[@]}"; do
  source_dir="$repo/opentofu/$name"
  validate "$source_dir/terraform.tfstate"
  [[ ! -f "$source_dir/terraform.tfstate.backup" ]] || validate "$source_dir/terraform.tfstate.backup"
done

for name in "${stacks[@]}"; do
  source_dir="$repo/opentofu/$name"
  destination="$backup_root/$timestamp/$name"

  install -d -m 700 "$backup_root/$timestamp" "$destination"

  for file in terraform.tfstate terraform.tfstate.backup; do
    [[ -f "$source_dir/$file" ]] || continue
    cp "$source_dir/$file" "$destination/$file"
  done

  printf '%s\n' "$commit" >"$destination/GIT_COMMIT"
  (cd "$destination" && sha256sum terraform.tfstate*) >"$destination/SHA256SUMS"
  chmod 600 "$destination"/*
  echo "$destination"
done

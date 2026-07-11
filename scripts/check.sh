#!/usr/bin/env bash
set -euo pipefail

for script in scripts/*.sh; do
  bash -n "$script"
done

required=(
  COMMANDS.md
  README.md
  docs/architecture.md
  docs/discovered-state.md
  docs/operating-policy.md
  docs/routeros-baseline-review.md
  docs/reference/homelab-architecture-final-prompt.md
  runbooks/routeros-backup-restore.md
  runbooks/routeros-baseline-review.md
  Makefile
  opentofu/routeros/versions.tofu
  opentofu/routeros/encryption.tofu
  opentofu/routeros/leases.tofu
  opentofu/adguard/versions.tofu
  opentofu/adguard/encryption.tofu
  opentofu/adguard/provider.tofu
  opentofu/COMMANDS.md
)

for path in "${required[@]}"; do
  test -f "$path"
done

for runbook in runbooks/*.md; do
  [[ "$runbook" == "runbooks/README.md" ]] && continue
  for heading in "## Purpose" "## Prerequisites" "## Validation" "## Rollback"; do
    if ! grep -qx "$heading" "$runbook"; then
      echo "missing '$heading' in $runbook" >&2
      exit 1
    fi
  done
done

if command -v tofu >/dev/null; then
  tofu fmt -check -recursive opentofu
fi

mapfile -d '' repo_files < <(git ls-files --cached --others --exclude-standard -z)
scan_files=()
for path in "${repo_files[@]}"; do
  [[ "$path" == scripts/check.sh ]] || scan_files+=("$path")
done
if ((${#scan_files[@]})) && grep -IlZE '(BEGIN [A-Z ]*PRIVATE KEY|AGE-SECRET-KEY-1|ghp_[[:alnum:]]{20,}|github_pat_[[:alnum:]_]{20,}|AKIA[0-9A-Z]{16})' "${scan_files[@]}"; then
  echo "possible plaintext secret found" >&2
  exit 1
fi

echo "check ok"

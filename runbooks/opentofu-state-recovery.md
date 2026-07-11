# OpenTofu State Recovery

## Purpose

Recover an independently encrypted RouterOS or AdGuard local state before an OCI backend exists.

## Prerequisites

- Matching repository commit and provider lock file are available.
- `TF_VAR_state_passphrase` is recovered outside Git.
- Provider credentials and trusted CA material are available.
- A backup under `~/homelab-backups/opentofu/<timestamp>/<stack>/` has a passing `SHA256SUMS` and recorded `GIT_COMMIT`.

## Restore

From the repository root, verify before copying anything:

```sh
backup="$HOME/homelab-backups/opentofu/<timestamp>/<stack>"
(cd "$backup" && sha256sum -c SHA256SUMS)
test "$(cat "$backup/GIT_COMMIT")" = "$(git rev-parse HEAD)"
```

If the commit differs, check out the recorded revision first. Preserve any current state, then restore with restrictive permissions:

```sh
stack=routeros # or adguard
root="opentofu/$stack"
preserved="$root/terraform.tfstate.pre-restore.$(date -u +%Y%m%dT%H%M%SZ)"
test ! -e "$root/terraform.tfstate" || cp -p "$root/terraform.tfstate" "$preserved"
install -m 0600 "$backup/terraform.tfstate" "$root/terraform.tfstate"
```

Do not open, reformat, or commit state files.

## Validation

```sh
tofu -chdir="opentofu/$stack" init
tofu -chdir="opentofu/$stack" state list
tofu -chdir="opentofu/$stack" plan -detailed-exitcode
```

The state must decrypt, expected resources must be listed, and plan must exit `0`. Exit `2`, any replacement/destroy, or unrelated update is a failed recovery and must not be applied.

## Rollback

Restore the timestamped `terraform.tfstate.pre-restore.*` file created by the procedure or the next-earlier checksum-verified backup. Never roll back by deleting the live RouterOS lease or AdGuard rewrite.

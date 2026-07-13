# Application Backup And Restore

## Purpose

Create and validate encrypted application-PVC backups, and restore one to
scratch without touching live data.

## Prerequisites

- `age`, `age-keygen`, `sops`, `sqlite3`, and passwordless backup-time sudo on
  `nmac` are available.
- The SOPS age identity is readable at `$SOPS_AGE_KEY_FILE` (or the standard
  SOPS age path).
- This computer has enough free space for the encrypted archive and scratch.

Create one or all allowlisted backups:

```sh
make backup-app APP=uptime-kuma
make backup-apps
```

Only `glance`, `uptime-kuma`, `ntfy`, `healthchecks`, `prometheus`, and
`grafana` are accepted. The command verifies SSH, sudo, SOPS decryption, Flux,
the bound local-path PVC, space, permissions, checksum, archive listing, and
SQLite databases. It never writes a plaintext archive or deletes an old one.
A ten-minute transient systemd rollback plus the local exit trap restore the
deployment and Flux if the command is interrupted.

Restore to scratch first:

```sh
archive="$HOME/homelab-backups/data/uptime-kuma/<UTC timestamp>/uptime-kuma.tar.age"
scratch="$(mktemp -d)"
age -d -i "$SOPS_AGE_KEY_FILE" "$archive" | tar -xpf - -C "$scratch"
find "$scratch" -type f -name '*.db' -exec sqlite3 {} 'PRAGMA quick_check;' \;
sqlite3 "$(find "$scratch" -type f -name kuma.db -print -quit)" \
  'select count(*) from monitor;'
```

## Validation

- `sha256sum -c SHA256SUMS` passes before decryption.
- Every SQLite `quick_check` returns `ok`; Uptime Kuma reports seven monitors.
- Scratch ownership, modes, ACLs, xattrs, and SELinux labels match the source.
- Keep the previous archive and any failed scratch tree until validation ends.

## Rollback

Scratch validation does not alter live data: delete the scratch directory. If
an interrupted backup leaves a workload stopped, wait up to ten minutes for the
transient rollback, then resume its Flux Kustomization and scale only its
deployment to one replica.

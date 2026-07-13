# Application Backup And Restore

## Purpose

Create and validate encrypted application-PVC backups, and restore one to
scratch without touching live data.

## Prerequisites

- `age`, `age-keygen`, `sops`, Python 3, and the guarded maintenance wrapper on
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
`grafana` are accepted. The root-owned wrapper resolves fixed PVCs internally
and refuses paths outside `/srv/data/k3s-storage`. The command verifies space,
modes, checksums, archive listing, and SQLite databases. It never writes a
plaintext archive or deletes an old one.
A ten-minute transient systemd rollback plus the local exit trap restore the
deployment and Flux if the command is interrupted.

Restore to scratch first:

```sh
archive="$HOME/homelab-backups/data/uptime-kuma/<UTC timestamp>/uptime-kuma.tar.age"
scratch="$(mktemp -d)"
age -d -i "$SOPS_AGE_KEY_FILE" "$archive" | tar -xpf - -C "$scratch"
python3 - "$scratch" <<'PY'
import sqlite3, sys
from pathlib import Path
db = next(Path(sys.argv[1]).rglob('kuma.db'))
with sqlite3.connect(f'file:{db}?mode=ro', uri=True) as con:
    assert con.execute('pragma quick_check').fetchone() == ('ok',)
    assert con.execute('select count(*) from monitor').fetchone() == (7,)
PY
```

## Validation

- `sha256sum -c SHA256SUMS` passes before decryption.
- Every SQLite `quick_check` returns `ok`; Uptime Kuma reports eight monitors.
- Scratch ownership, modes, ACLs, xattrs, and SELinux labels match the source.
- Keep the previous archive and any failed scratch tree until validation ends.

## Rollback

Scratch validation does not alter live data: delete the scratch directory. If
an interrupted backup leaves a workload stopped, wait up to ten minutes for the
transient rollback, then run `sudo -n /usr/local/sbin/homelab-maintenance
recover <app>` from `nmac`.

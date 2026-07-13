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

This off-host computer runs `scripts/backup-daily.sh` from cron at 03:15 local
time. Install or refresh the idempotent cron block with
`scripts/install-backup-cron.sh`. The runner uses a global lock, reports
start/success/failure to Healthchecks, and continues the backup if Healthchecks
is temporarily unavailable. Cron supplies no credentials; SSH key access and
the local SOPS age identity must already work non-interactively.
The same managed block captures AdGuard configuration at 03:45, creates an
age-encrypted RouterOS pack Sunday at 04:15, and checks Home Assistant backup
freshness at 05:00.

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
    wanted = {'Glance', 'Uptime Kuma', 'ntfy', 'Healthchecks', 'Prometheus',
              'Grafana', 'Home Assistant', 'Router', 'AdGuard',
              'Test workload', 'AdGuard DNS'}
    names = {row[0] for row in con.execute('select name from monitor')}
    assert wanted <= names, f'missing monitors: {sorted(wanted - names)}'
PY
```

## Validation

- `sha256sum -c SHA256SUMS` passes before decryption.
- Every SQLite `quick_check` returns `ok`; all eleven desired Uptime Kuma
  monitors are present. Extra manual monitors are allowed.
- The scratch archive listing and application-level checks pass. The encrypted
  stream preserves numeric metadata recorded by tar, but this scratch check does
  not claim production ACL, xattr, or SELinux-label restoration.
- Keep the previous archive and any failed scratch tree until validation ends.
- `crontab -l` contains exactly one managed `homelab backups` block.
- Healthchecks records a successful `k3s-app-backups` run after the six archives
  validate.

## Rollback

Scratch validation does not alter live data: delete the scratch directory. If
an interrupted backup leaves a workload stopped, wait up to ten minutes for the
transient rollback, then run `sudo -n /usr/local/sbin/homelab-maintenance
recover <app>` from `nmac`.

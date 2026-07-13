# RouterOS Backup And Restore

## Purpose

Create binary backup and text export before any RouterOS change.

## Gate

Do this before DHCP, DNS, firewall, WireGuard, or container-network changes.

## Prerequisites

- SSH/admin access to RouterOS works.
- Off-router backup target is available; default is `~/homelab-backups`.
- RouterOS version and packages are recorded.
- `ROUTEROS_BACKUP_PASSWORD` is set in the local shell and is not committed.

## Backup Command

```sh
ROUTEROS_BACKUP_PASSWORD='set-this-locally' make backup-routeros
```

Optional overrides:

```sh
BACKUP_DIR="$HOME/homelab-backups" ROUTEROS_HOST=router ROUTEROS_BACKUP_PASSWORD='set-this-locally' make backup-routeros
```

The script creates temporary timestamped files on RouterOS, copies them to:

```text
~/homelab-backups/routeros/<timestamp>/
```

Then it removes only this run's generated RouterOS files.

## Validation

- `routeros.backup` exists off-router and is encrypted with the provided password.
- `routeros.rsc` exists off-router.
- `firewall-filter.rsc`, `firewall-nat.rsc`, `wireguard.rsc`, `dhcp.txt`, `dns.txt`, `containers.txt`, `services.txt`, and `snmp.txt` exist.
- `snmp.txt` confirms the Prometheus community is source-restricted, read-only, and authPriv/private, with the default public community disabled.
- `README.md` exists in the backup directory.
- RouterOS no longer has files matching this run's timestamp.

## Rollback

- Use `routeros.backup` only for whole-router recovery.
- Use `routeros.rsc` and scoped exports for review/replay. Do not blindly apply them to a live router.
- Keep the previous backup pack until a newer backup has been validated.

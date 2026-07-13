# AdGuard Container Recovery

## Purpose

Recover RouterOS-hosted AdGuard.

## Known State

- Container: `adguardhome:latest`
- veth: `veth1-adguard`
- IP: `10.0.0.2/24`
- Root: `/usb1-part1/adguardhome`

## Prerequisites

- RouterOS backup/export exists.
- AdGuard config export exists if available.
- Current container/veth settings captured by `make inventory-router`.

## Validation

Run `scripts/backup-adguard.sh` for a zero-downtime configuration backup. It
hashes `AdGuardHome.yaml` before and after streaming it directly into age
encryption, rejects a changing source, and persists no plaintext configuration.
The off-host cron runs it daily at 03:45 local time under the shared backup lock
and reports start, success, or failure to the `adguard-config-backup`
Healthchecks check.
This protects configuration only; the container work database remains outside
the unattended backup until a reviewed DNS maintenance window exists.

- RouterOS DNS forwards to `10.0.0.2`.
- AdGuard UI responds on LAN/VPN.

## Rollback

Restore AdGuard config export and RouterOS container settings from backup.

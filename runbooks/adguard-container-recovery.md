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

- RouterOS DNS forwards to `10.0.0.2`.
- AdGuard UI responds on LAN/VPN.

## Rollback

Restore AdGuard config export and RouterOS container settings from backup.

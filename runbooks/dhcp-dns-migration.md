# DHCP DNS Migration

## Purpose

Ensure clients use RouterOS DNS at `192.168.88.1`.

## Current Discovered State

DHCP network already advertises `192.168.88.1`.

## Prerequisites

- RouterOS backup/export exists.
- `make inventory-router` captured DHCP and DNS state.
- RouterOS resolves through AdGuard at `10.0.0.2`.

## Validation

- Renew one client lease.
- Confirm client DNS server is `192.168.88.1`.
- Confirm router forwards to AdGuard `10.0.0.2`.

## Rollback

Restore previous DHCP network settings from RouterOS export.

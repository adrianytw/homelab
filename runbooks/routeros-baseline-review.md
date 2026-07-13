# RouterOS Baseline Review

## Purpose

Turn a RouterOS backup/export pack into a sanitized review document before approving any RouterOS changes.

## Prerequisites

- `make backup-routeros` has produced a backup pack under `~/homelab-backups/routeros/<timestamp>/`.
- The backup pack contains `routeros.backup`, `routeros.rsc`, firewall, DHCP, DNS, WireGuard, container, service, and SNMP captures.
- No RouterOS configuration changes are made during this review.

## Validation

- `make review-routeros` creates `docs/routeros-baseline-review.md`.
- Review output names DHCP, DNS, AdGuard, WireGuard, firewall/NAT, service exposure, SNMP monitoring policy, MacBook lease, and Home Assistant lease state.
- Review output contains no sensitive key material or binary backup content.

## Rollback

Delete or regenerate `docs/routeros-baseline-review.md`; this workflow does not modify RouterOS.

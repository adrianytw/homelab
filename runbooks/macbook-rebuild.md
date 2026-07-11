# MacBook Rebuild

## Purpose

Rebuild `nmac` as the k3s host.

## Prerequisites

- RouterOS DHCP/DNS is healthy.
- Host backup and `/srv/data` backup are available.
- SSH access for `nairda` is configured.

## Validation

- SSH works as `nairda`.
- `/srv/data` exists.
- Cockpit is LAN/VPN-only.
- k3s is installed only after prerequisites pass.

## Rollback

Use backup archive and Ansible bootstrap once playbooks exist.

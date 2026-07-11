# Cockpit Emergency Administration

## Purpose

Use Cockpit for break-glass visibility.

## Access

- `https://192.168.88.20:9090`
- optional: `https://cockpit.nairdev.com:9090`

## Prerequisites

- Access is from LAN/VPN.
- SSH to `nmac` is available as fallback.

## Rules

- LAN/VPN only.
- Do not route through k3s ingress initially.
- Do not replace Ansible, OpenTofu, or Flux as source of truth.

## Validation

- Cockpit login works.
- Host, storage, firewall, and libvirt views load.

## Rollback

Disable optional DNS rewrite or stop `cockpit.socket` if access must be removed.

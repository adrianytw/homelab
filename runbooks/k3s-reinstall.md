# k3s Reinstall

## Purpose

Reinstall k3s after host rebuild or cluster failure.

## Prerequisites

- MacBook bootstrap is complete.
- `/srv/data` is restored or intentionally empty.
- SOPS age key is available before reconciling encrypted secrets.

## Validation

- Kubernetes API reachable from LAN/VPN only.
- Traefik owns ports 80/443.
- local-path storage uses `/srv/data/k3s-storage`.

## Rollback

Remove failed k3s install and restore `/srv/data` before reconciling workloads.

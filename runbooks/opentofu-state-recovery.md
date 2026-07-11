# OpenTofu State Recovery

## Purpose

Recover local OpenTofu state before OCI backend exists.

## Default Backup Path

`~/homelab-backups`

## Prerequisites

- Encrypted state backup exists.
- Matching OpenTofu code revision is available.
- Required provider credentials are available from local env or SOPS/manual bootstrap.

## Validation

- State backup is encrypted.
- State is Git-ignored.
- `tofu plan` uses recovered state without wanting destructive replacement.

## Rollback

Restore prior encrypted state backup.

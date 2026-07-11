# Flux Recovery

## Purpose

Recover GitOps reconciliation.

## Gate

Flux only after manual manifests are proven.

## Prerequisites

- k3s is healthy.
- SOPS age key is restored.
- Canonical repo is reachable outside the cluster.

## Validation

- Canonical repo exists outside cluster.
- SOPS secrets decrypt.
- Flux reconciles known-good manifests.

## Rollback

Suspend Flux resources and apply last known-good manual manifests.
